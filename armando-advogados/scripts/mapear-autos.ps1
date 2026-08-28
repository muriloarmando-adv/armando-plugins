<#
.SYNOPSIS
  Mapeia autos processuais: capa, indice de pecas, fronteiras de juntada, linha do
  tempo, prazos e alertas. Diz tambem se o extrato esta vencido.

.DESCRIPTION
  Le os autos ja convertidos em Markdown pelo pdf2md.ps1 (ou o PDF direto) e
  produz um mapa navegavel. Serve para NAO ler 375 paginas: le-se o mapa, decide-se
  o que abrir, e abre-se so isso por faixa de linha.

  O script LOCALIZA. Ele nao interpreta o processo e nao conta prazo. A leitura das
  pecas decisorias continua obrigatoria.

  Reconhece as tres montagens em uso no escritorio:
    - PJe (TRF1/TRF3/TJBA/TJPI/TJTO...): capa com campos fixos + tabela "Documentos
      Id. / Data da Assinatura / Documento / Tipo" + rodape "Assinado eletronicamente
      por: NOME - data hora".
    - PJe-JT (TRT): capa com "Data da Autuacao" + SUMARIO na ULTIMA folha + rodape
      "Documento assinado eletronicamente por NOME, em data, as hora - <id>".
    - eSAJ (TJSP): sem capa e sem indice; foliacao "fls. N", carimbo lateral de
      autenticacao e o par CONCLUSAO -> DESPACHO/SENTENCA -> "Int. Cidade, data".

.PARAMETER Path
  Um ou mais arquivos .md, .txt, .docx ou .pdf. PDF e convertido antes.

.PARAMETER Out
  Grava o mapa em arquivo. RECOMENDADO: no console o Windows corrompe acentos.

.PARAMETER Hoje
  Data de referencia para o alerta de extrato vencido (padrao: hoje).

.PARAMETER Contexto
  Caracteres de trecho por achado (padrao 160).

.PARAMETER MaxEventos
  Teto de linhas por tabela (padrao 300).

.PARAMETER Cru
  Nao descarta linhas de carimbo repetido na deteccao de datas e alertas.

.EXAMPLE
  .\mapear-autos.ps1 "C:\autos\0000004-49.2026.5.18.0018.md" -Out "C:\autos\mapa.md"
.EXAMPLE
  .\mapear-autos.ps1 "C:\autos\processo.pdf" -Out "C:\autos\mapa.md" -Hoje 2026-08-27
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, Position = 0)][string[]]$Path,
    [string]$Out,
    [datetime]$Hoje = (Get-Date),
    [int]$Contexto = 160,
    [int]$MaxEventos = 300,
    [switch]$Cru,
    [switch]$Cronologia
)

$ErrorActionPreference = 'Stop'

# ----------------------------------------------------------------------------
# Utilitarios
# ----------------------------------------------------------------------------

function ConvertTo-Ascii {
    <# Tira acento e cedilha. Todos os padroes deste script sao ASCII puro: assim a
       regex nao depende da codificacao com que o .md foi gravado. #>
    param([string]$s)
    if ([string]::IsNullOrEmpty($s)) { return '' }
    $d = $s.Normalize([System.Text.NormalizationForm]::FormD)
    $sb = New-Object System.Text.StringBuilder
    foreach ($c in $d.ToCharArray()) {
        if ([System.Globalization.CharUnicodeInfo]::GetUnicodeCategory($c) -ne
            [System.Globalization.UnicodeCategory]::NonSpacingMark) {
            [void]$sb.Append($c)
        }
    }
    return $sb.ToString()
}

function Get-Trecho {
    param([string]$linha, [int]$max)
    $t = ($linha -replace '\s+', ' ').Trim()
    if ($t.Length -le $max) { return $t }
    return $t.Substring(0, $max) + '...'
}

function Get-TrechoCentrado {
    <# Recorta em torno do match. Sem isso o trecho impresso comeca no inicio da linha
       e frequentemente NAO contem o termo que disparou o achado - o leitor tinha de
       abrir a linha so para descobrir por que ela foi listada.
       A posicao vem da string sem acento, que pode ser mais curta que a original;
       a proporcao basta para uma janela de 160 caracteres. #>
    param([string]$linha, [int]$pos, [int]$posMax, [int]$max)
    $t = ($linha -replace '\s+', ' ')
    if ($t.Length -le $max) { return $t.Trim() }
    $p = if ($posMax -gt 0) { [int]($pos * $t.Length / $posMax) } else { 0 }
    $ini = [Math]::Max(0, [Math]::Min($p - [int]($max / 3), $t.Length - $max))
    $s = $t.Substring($ini, [Math]::Min($max, $t.Length - $ini)).Trim()
    if ($ini -gt 0) { $s = '...' + $s }
    if (($ini + $max) -lt $t.Length) { $s = $s + '...' }
    return $s
}

function Format-Celula {
    param([string]$s)
    return (($s -replace '\|', '/') -replace '\s+', ' ').Trim()
}

function Test-NumeroCNJ {
    <# Digito verificador do numero unico CNJ: modulo 97 base 10 (ISO 7064).
       NNNNNNN DD AAAA J TR OOOO -> NNNNNNN AAAA J TR OOOO + '00'. #>
    param([string]$digitos)
    if ($digitos.Length -ne 20) { return $false }
    $base = $digitos.Substring(0, 7) + $digitos.Substring(9, 11) + '00'
    $mod = 0
    foreach ($c in $base.ToCharArray()) { $mod = (($mod * 10) + [int]::Parse($c)) % 97 }
    return ([int]$digitos.Substring(7, 2) -eq (98 - $mod))
}

function Format-CNJ {
    param([string]$d)
    return ('{0}-{1}.{2}.{3}.{4}.{5}' -f $d.Substring(0,7), $d.Substring(7,2),
        $d.Substring(9,4), $d.Substring(13,1), $d.Substring(14,2), $d.Substring(16,4))
}

function New-Data {
    param([int]$dd, [int]$mm, [int]$aa)
    if ($dd -lt 1 -or $dd -gt 31 -or $mm -lt 1 -or $mm -gt 12 -or $aa -lt 1970 -or $aa -gt 2100) { return $null }
    try { return (New-Object System.DateTime($aa, $mm, $dd)) }
    catch { return $null }
}

function Get-Fonte {
    <# Devolve o caminho de um .md legivel, convertendo PDF se preciso. #>
    param([string]$arquivo)
    if ([System.IO.Path]::GetExtension($arquivo).ToLowerInvariant() -ne '.pdf') { return $arquivo }

    $candidatos = @(
        (Join-Path $PSScriptRoot '..\skills\armando-pdf-markdown\scripts\pdf2md.ps1'),
        'C:\Users\muril\.claude\skills\armando-pdf-markdown\scripts\pdf2md.ps1'
    )
    $conv = $candidatos | Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1
    if (-not $conv) { throw "PDF recebido, mas pdf2md.ps1 nao foi localizado. Converta antes e passe o .md." }

    $destino = Join-Path ([System.IO.Path]::GetTempPath()) `
        ([System.IO.Path]::GetFileNameWithoutExtension($arquivo) + '-mapa.md')
    Write-Host "  convertendo PDF -> $destino" -ForegroundColor DarkGray
    & $conv $arquivo -Out $destino | Out-Null
    if (-not (Test-Path -LiteralPath $destino)) { throw "Conversao do PDF falhou: $arquivo" }
    return $destino
}

function Get-Linhas {
    param([string]$arquivo)
    if ([System.IO.Path]::GetExtension($arquivo).ToLowerInvariant() -eq '.docx') {
        $lib = Join-Path $PSScriptRoot 'lib-peca.ps1'
        if (-not (Test-Path -LiteralPath $lib)) { throw "docx exige lib-peca.ps1 ao lado deste script." }
        . $lib
        return ((Get-TextoDaPeca -Path $arquivo) -split "`r?`n")
    }
    return @(Get-Content -LiteralPath $arquivo -Encoding UTF8)
}

# ----------------------------------------------------------------------------
# Catalogos
# ----------------------------------------------------------------------------

# Campos de capa. Chave = rotulo ASCII em minuscula; valor = quanto capturar.
$CAMPOS_CAPA = @(
    @{ Rotulo = 'Numero';                 Padrao = 'n[uy]mero\s*:\s*(.+)$' },
    @{ Rotulo = 'Classe';                 Padrao = 'classe\s*:\s*(.+?)(?:\s+orgao julgador|\s+ultima distribuicao|$)' },
    @{ Rotulo = 'Orgao julgador';         Padrao = 'orgao julgador(?:\s+colegiado)?\s*:\s*(.+?)(?:\s+ultima distribuicao|\s+valor da causa|$)' },
    @{ Rotulo = 'Ultima distribuicao';    Padrao = 'ultima distribuicao\s*:?\s*(\d{2}/\d{2}/\d{4})' },
    @{ Rotulo = 'Data da autuacao';       Padrao = 'data da autuacao\s*:?\s*(\d{2}/\d{2}/\d{4})' },
    @{ Rotulo = 'Valor da causa';         Padrao = 'valor (?:da causa|da acao)\s*:?\s*(r\$\s?[\d\.]+,\d{2}|[\d\.]+,\d{2})' },
    @{ Rotulo = 'Classe - Assunto';       Padrao = 'classe\s*[-–—]\s*assunto\s*:\s*(.{3,110}?)(?:\s+requerente|\s+requerido|\s+autor|\s+reu\b|$)' },
    @{ Rotulo = 'Assuntos';               Padrao = 'assuntos?\s*:\s*(.{3,110}?)(?:\s+nivel de sigilo|\s+segredo de justica|\s+requerente|\s+requerido|$)' },
    @{ Rotulo = 'Sigilo';                 Padrao = '(?:nivel de sigilo|segredo de justica\??)\s*:?\s*(.+?)(?:\s+justica gratuita|$)' },
    @{ Rotulo = 'Justica gratuita';       Padrao = 'justica gratuita\??\s*:?\s*(sim|nao)' },
    @{ Rotulo = 'Liminar/tutela pedida';  Padrao = 'pedido de liminar[^:?]*\??\s*:?\s*(sim|nao)' },
    @{ Rotulo = 'Processo referencia';    Padrao = 'processo referencia\s*:?\s*(.+)$' },
    @{ Rotulo = 'Relator';                Padrao = '\brelator.?\s*:\s*(.+?)(?:\s{2,}|$)' },
    @{ Rotulo = 'Juiz/Juiza';             Padrao = '\bjui[zs].?(?:\s+de\s+direito)?(?:\(a\))?\s*(?:de direito)?\s*dr?\(?a?\)?\s*:\s*(.+?)(?:\s{2,}|$)' }
)

# Partes: rotulos de polo usados na capa do PJe e no cabecalho do eSAJ.
$ROTULOS_PARTE = 'autor|autora|r[eé]u|r[eé]|requerente|requerido|requerida|reclamante|reclamado|reclamada|' +
                 'exequente|executado|executada|embargante|embargado|impetrante|impetrado|agravante|' +
                 'agravado|apelante|apelado|denunciado|investigado|indiciado|vitima|paciente|' +
                 'excipiente|excepto|consignante|consignatario|terceiro interessado|advogado|advogada'

# Ordem importa: o primeiro que casar nomeia a peca.
$CATALOGO_PECAS = @(
    @{ Rotulo = 'Acordao';                   Padrao = '\bac.rd(ao|aos)\b' },
    @{ Rotulo = 'Voto';                      Padrao = '^\s*#*\s*(voto|voto vencido|voto do relator)\b' },
    @{ Rotulo = 'Sentenca';                  Padrao = '\bsenten.a(s)?\b' },
    @{ Rotulo = 'Saneamento';                Padrao = '\bsaneador(a)?\b|\bsaneamento\b|\borganiza.ao do processo\b' },
    @{ Rotulo = 'Decisao';                   Padrao = '\bdecis.o\b' },
    @{ Rotulo = 'Despacho';                  Padrao = '\bdespacho\b|\bconclus.o\b' },
    @{ Rotulo = 'Peticao inicial';           Padrao = '\bpeti.ao inicial\b|\bexordial\b|\breclama.ao trabalhista\b|\btermo de ajuizamento\b|^\s*#*\s*inicial\b' },
    @{ Rotulo = 'Emenda a inicial';          Padrao = '\bemenda\s+(a\s+)?inicial\b' },
    @{ Rotulo = 'Contestacao';               Padrao = '\bcontesta.ao\b|\bdefesa escrita\b' },
    @{ Rotulo = 'Resposta a acusacao';       Padrao = '\bresposta\s+(a\s+)?acusa.ao\b|\bdefesa previa\b' },
    @{ Rotulo = 'Reconvencao';               Padrao = '\breconven.ao\b' },
    @{ Rotulo = 'Replica / impugnacao';      Padrao = '\breplica\b|\bimpugna.ao\b' },
    @{ Rotulo = 'Denuncia';                  Padrao = '\bden.ncia\b' },
    @{ Rotulo = 'Inquerito / relatorio pol'; Padrao = '\binquerito\b|\brelatorio final\b|\bindiciamento\b|\brelatorio de missao\b|\bboletim de ocorrencia\b' },
    @{ Rotulo = 'Alegacoes finais';          Padrao = '\balega.oes finais\b|\bmemoriais\b' },
    @{ Rotulo = 'Embargos de declaracao';    Padrao = '\bembargos de declara.ao\b' },
    @{ Rotulo = 'Embargos / EPE';            Padrao = '\bembargos\s+(a|do|de)\s+(execu.ao|terceiro|devedor)\b|\bexce.ao de pre-executividade\b|\bembargos a arrematacao\b' },
    @{ Rotulo = 'Apelacao';                  Padrao = '\bapela.ao\b' },
    @{ Rotulo = 'Recurso ordinario/revista'; Padrao = '\brecurso ordinario\b|\brecurso de revista\b' },
    @{ Rotulo = 'Agravo';                    Padrao = '\bagravo\b' },
    @{ Rotulo = 'REsp / RE';                 Padrao = '\brecurso especial\b|\brecurso extraordinario\b' },
    @{ Rotulo = 'Contrarrazoes';             Padrao = '\bcontrarraz.es\b|\bcontra-razoes\b' },
    @{ Rotulo = 'Habeas corpus';             Padrao = '\bhabeas corpus\b' },
    @{ Rotulo = 'Mandado de seguranca';      Padrao = '\bmandado de seguran.a\b' },
    @{ Rotulo = 'Cumprimento / execucao';    Padrao = '\bcumprimento de senten.a\b|\bexecu.ao (fiscal|de titulo|provisoria|definitiva)\b|\bcarta de senten.a\b|\bcertidao de divida ativa\b|\bcda\b' },
    @{ Rotulo = 'Ata / termo de audiencia';  Padrao = '\bata de audi.ncia\b|\btermo de audi.ncia\b|\bassentada\b|\btermo de audiencia de instrucao\b' },
    @{ Rotulo = 'Laudo / pericia';           Padrao = '\blaudo\b|\bpericia\b|\bperito\b|\bquesitos\b|\bparecer tecnico\b' },
    @{ Rotulo = 'Calculo / liquidacao';      Padrao = '\bmemoria de calculo\b|\bplanilha de calculo\b|\bliquida.ao\b|\bdemonstrativo de debito\b|\bcalculos?\b' },
    @{ Rotulo = 'Constricao patrimonial';    Padrao = '\bpenhora\b|\bsisbajud\b|\brenajud\b|\binfojud\b|\barresto\b|\bavalia.ao\b|\bleilao\b|\bhasta publica\b|\bbloqueio\b|\bbusca e apreensao\b' },
    @{ Rotulo = 'Certidao';                  Padrao = '\bcertid.o\b' },
    @{ Rotulo = 'Citacao / intimacao';       Padrao = '\bcita.ao\b|\bintima.ao\b|\bnotifica.ao\b|\bmandado\b|\bcarta precatoria\b|\baviso de recebimento\b|\ba\.?r\.?\b|\becarta\b|\bedital\b|\bdiligencia\b' },
    @{ Rotulo = 'Procuracao / habilitacao';  Padrao = '\bprocura.ao\b|\bsubstabelecimento\b|\bhabilita.ao\b' },
    @{ Rotulo = 'Alvara / oficio';           Padrao = '\balvar.\b|\bof.cio\b' },
    # 'conciliacao' NAO entra aqui: audiencia de conciliacao e audiencia, nao acordo.
    # Enquanto entrava, o corpo da carta de citacao virava "acordo homologado" num
    # processo que nunca teve acordo nenhum.
    @{ Rotulo = 'Acordo / homologacao';      Padrao = '\bacordo\b|\bhomologa.ao\b|\btransacao\b|\bautocomposicao\b' },
    @{ Rotulo = 'Volume (autos fisicos)';    Padrao = '^\s*#*\s*volume\b|\bprocesso migrado\b|\bautos digitalizados\b' },
    @{ Rotulo = 'Manifestacao / peticao';    Padrao = '\bmanifesta.ao\b|\bpeti.ao\b|\brequerimento\b|\bcota ministerial\b|\bparecer do mp\b' }
)

# Formulas de alta precisao, validas em QUALQUER posicao da linha. Existem porque
# peca sem titulo e comum: a denuncia que so tem enderecamento, e a sentenca do JEC,
# que vive DENTRO do termo de audiencia e nunca aparece como peca autonoma.
$CATALOGO_FORMULAS = @(
    @{ Rotulo = 'Denuncia (MP)';               Padrao = 'oferec(e|er)\s+den.ncia|denuncia-se|incurso nas penas do art|como incurso no art' },
    @{ Rotulo = 'Dispositivo de sentenca';     Padrao = '\b(ante o exposto|isto posto|pelo exposto|diante do exposto|posto isso)\b.{0,40}\bjulgo\b|\bjulgo\s+(procedente|improcedente|parcialmente|extint)' },
    @{ Rotulo = 'Sentenca proferida em ata';   Padrao = 'foi proferida a seguinte senten.a|passo a proferir senten.a' },
    @{ Rotulo = 'Acordao / sessao';            Padrao = 'acordam os? (senhores )?(desembargadores|ministros|juizes)|vistos, relatados e discutidos' },
    @{ Rotulo = 'Recebimento da denuncia';     Padrao = 'recebo a den.ncia|recebida a den.ncia' },
    @{ Rotulo = 'Abertura de peca de parte';   Padrao = 'vem,?\s+(respeitosamente|mui respeitosamente).{0,90}(propor|apresentar|impetrar|interpor|oferecer|requerer)|vem a presen.a de vossa excelencia' },
    @{ Rotulo = 'Certidao de cartorio';        Padrao = '^\s*certifico\b|certifico e dou fe' },
    @{ Rotulo = 'Conclusao ao juiz';           Padrao = 'fa.o (estes autos )?conclusos|fa.o conclusos' },
    @{ Rotulo = 'Ordem de expediente';         Padrao = '\b(intime-se|cite-se|notifique-se|expe.a-se|cumpra-se|publique-se|arquivem-se|remetam-se)\b' },
    @{ Rotulo = 'Deferimento / indeferimento'; Padrao = '\b(defiro|indefiro|homologo|declaro extint|concedo a liminar|denego a ordem|decreto a revelia)\b' }
)

$CATALOGO_ALERTAS = @(
    @{ Sev = 'ALTA';  Rotulo = 'Transito em julgado';     Padrao = '\btr.nsit(o|ou|ado)\s+em\s+julgado\b' },
    @{ Sev = 'ALTA';  Rotulo = 'Revelia / confissao';     Padrao = '\brevel(ia)?\b|\bconfess(o|a)\b' },
    @{ Sev = 'ALTA';  Rotulo = 'Intempestividade';        Padrao = '\bintempestiv' },
    @{ Sev = 'ALTA';  Rotulo = 'Decurso de prazo';        Padrao = '\bdecurso de prazo\b|\bpreclu(so|sa|sao|iu)\b|\bin albis\b' },
    @{ Sev = 'ALTA';  Rotulo = 'Prescricao / decadencia'; Padrao = '\bprescri.|\bdecadenc' },
    @{ Sev = 'ALTA';  Rotulo = 'Extincao / arquivamento'; Padrao = '\bextin(cao|to|ta|guir|guiu)\b|\barquivamento\b|\bbaixa definitiva\b' },
    @{ Sev = 'ALTA';  Rotulo = 'Constricao patrimonial';  Padrao = '\bpenhora\b|\bbloqueio\b|\bindisponibilidade\b|\bleilao\b|\bhasta publica\b|\barresto\b|\bsequestro\b|\bbusca e apreensao\b' },
    @{ Sev = 'ALTA';  Rotulo = 'Multa / astreinte';       Padrao = '\bastreinte\b|\bmulta diaria\b|\bmulta cominatoria\b|\bmulta de 10%\b' },
    @{ Sev = 'ALTA';  Rotulo = 'Medida de liberdade';     Padrao = '\bpris.o\b|\bmedida cautelar (pessoal|diversa)\b|\bmandado de pris.o\b|\bpreventiva\b|\bmonitoracao eletronica\b' },
    @{ Sev = 'ALTA';  Rotulo = 'Sigilo / segredo';        Padrao = '\bsigilo(so|sa)?\b|\bsegredo de justi.a\b' },
    @{ Sev = 'ALTA';  Rotulo = 'Desconsideracao / redir'; Padrao = '\bdesconsidera.ao da personalidade\b|\bredirecionamento\b|\bincluir no polo passivo\b|\bgrupo economico\b|\bsucessao (de empresas|trabalhista)\b' },
    @{ Sev = 'MEDIA'; Rotulo = 'Audiencia';               Padrao = '\baudi.ncia\b|\bsessao de julgamento\b|\bpauta\b' },
    @{ Sev = 'MEDIA'; Rotulo = 'Pericia';                 Padrao = '\bpericia\b|\bperito\b|\blaudo\b' },
    @{ Sev = 'ALTA';  Rotulo = 'Art. 40 LEF / intercorr.'; Padrao = '\bart\.? ?40\b.{0,30}(lei|lef)|\bprescri.ao intercorrente\b|\bsuspens(ao|o) do (feito|processo) por (1|um) ano\b' },
    @{ Sev = 'MEDIA'; Rotulo = 'Suspensao / sobrestam.';  Padrao = '\bsuspens(ao|o|a)\b|\bsobrestad|\bsobrestamento\b' },
    @{ Sev = 'MEDIA'; Rotulo = 'Conclusos / vista';       Padrao = '\bconclus(o|os|ao)\b|\bvista dos autos\b|\bremessa ao mp\b|\bde-se vista\b' },
    @{ Sev = 'MEDIA'; Rotulo = 'Diligencia frustrada';    Padrao = '\bnegativ(o|a)\b|\bnao localizad|\bmudou-se\b|\bfrustrad|\bsem cumprimento\b|\bendereco incorreto\b|\bnao encontrad' },
    @{ Sev = 'MEDIA'; Rotulo = 'Emenda / regularizacao';  Padrao = '\bemende\b|\bemenda\b|\bsanar\b|\bregularize\b|\bsob pena de indeferimento\b|\bart\.? ?76 do cpc\b' },
    @{ Sev = 'MEDIA'; Rotulo = 'Recuperacao / falencia';  Padrao = '\brecupera.ao judicial\b|\bfal.ncia\b|\bjuizo universal\b' },
    @{ Sev = 'MEDIA'; Rotulo = 'Tema / IRDR / repetit.';  Padrao = '\btema \d+\b|\birdr\b|\brepercussao geral\b|\brepetitivo\b|\bsumula vinculante\b' },
    @{ Sev = 'MEDIA'; Rotulo = 'Migracao / apenso';       Padrao = '\bprocesso migrado\b|\bautos em apartado\b|\bautos dependentes\b|\bapenso\b|\bredistribui' }
)

$MESES = @{
    'janeiro' = 1; 'fevereiro' = 2; 'marco' = 3; 'abril' = 4; 'maio' = 5; 'junho' = 6;
    'julho' = 7; 'agosto' = 8; 'setembro' = 9; 'outubro' = 10; 'novembro' = 11; 'dezembro' = 12
}

# ----------------------------------------------------------------------------
# Motor
# ----------------------------------------------------------------------------

function Invoke-Mapa {
    param([string]$arquivo)

    $fonte = Get-Fonte $arquivo
    $linhas = Get-Linhas $fonte
    $total = $linhas.Count

    $saida = New-Object System.Text.StringBuilder
    function Add($t) { [void]$saida.AppendLine([string]$t) }

    # ---------------- passe unico ----------------
    # Comeca em 1, e nao em 0: o pdf2md.ps1 nao emite marcador para a primeira pagina
    # (o primeiro que aparece e "[p. 2]"). Comecando em 0, a pagina 1 nunca era contada
    # como coberta e saia SEMPRE na lista de "sem camada de texto" - falso positivo que
    # ja foi copiado para dentro de uma ficha, afirmando nao lida a pagina de onde a
    # propria ficha tirara o numero, a classe e a qualificacao das partes.
    $pagina = 1
    $cnjs = @{}
    $capa = [ordered]@{}
    $partes = New-Object System.Collections.ArrayList
    $pecas = New-Object System.Collections.ArrayList
    $datas = New-Object System.Collections.ArrayList
    $prazos = New-Object System.Collections.ArrayList
    $alertas = New-Object System.Collections.ArrayList
    $assin = New-Object System.Collections.ArrayList
    $idxLinhas = New-Object System.Collections.ArrayList
    $formulas = New-Object System.Collections.ArrayList
    $urlDatas = New-Object System.Collections.ArrayList
    $valores = @{}
    $oabs = @{}
    $repetidas = @{}
    $paginasComTexto = @{}
    $sistema = New-Object System.Collections.ArrayList
    $dataExtrato = $null
    $linhaIndice = 0
    $linhaSumario = 0
    $acentos = 0
    $totalChars = 0

    if (-not $Cru) {
        foreach ($l in $linhas) {
            $k = (Get-Trecho $l 90)
            if ($k.Length -lt 20) { continue }
            if ($repetidas.ContainsKey($k)) { $repetidas[$k]++ } else { $repetidas[$k] = 1 }
        }
    }

    for ($i = 0; $i -lt $total; $i++) {
        $orig = $linhas[$i]
        if ([string]::IsNullOrWhiteSpace($orig)) { continue }
        $nl = $i + 1
        if ($orig -match '\[p\.\s*(\d+)\]') { $pagina = [int]$Matches[1] }

        $a = (ConvertTo-Ascii $orig).ToLowerInvariant()
        $trecho = Get-Trecho $orig $Contexto
        $carimbo = $false
        if (-not $Cru) {
            $k = (Get-Trecho $orig 90)
            if ($repetidas.ContainsKey($k) -and $repetidas[$k] -ge 5) { $carimbo = $true }
        }

        # cobertura e sanidade da conversao
        $totalChars += $orig.Length
        # Letra fora do ASCII = letra acentuada. Sem literal acentuado no codigo-fonte,
        # que quebraria se o .ps1 fosse lido como ANSI.
        $acentos += ([regex]::Matches($orig, '\p{L}')).Count - ([regex]::Matches($orig, '[a-zA-Z]')).Count
        # Pagina so conta como coberta se tiver linha de CONTEUDO. Nao sao conteudo:
        # o carimbo repetido, a URL de validacao, a foliacao e o numero do documento -
        # e sao exatamente eles que sobram numa pagina de imagem. Contar essa pagina
        # como lida esconde onde esta a prova.
        # Tira o que e boilerplate de sistema e ve se sobra texto de verdade.
        $limpo = $a -replace 'https?://\S+', '' `
                    -replace 'numero do (processo|documento)\s*:?\s*[\d\.\-/]*', '' `
                    -replace 'fls?\.?\s*:?\s*\d+', '' `
                    -replace 'pag(ina)?\.?\s*\d+([/ ]\d+)?', '' `
                    -replace 'instancia\s*=?\s*\d*', ''
        $limpo = $limpo -replace '[^a-z]', ''
        if (-not $carimbo -and $limpo.Length -ge 12 -and
            $orig -notmatch '^\s*\[p\.' -and $orig -notmatch '^\s*<!--') {
            $paginasComTexto[$pagina] = $true
        }

        # relogio embutido na URL de validacao do PJe-JT: AAMMDDHHMMSS nos 12 primeiros
        # digitos. E o unico jeito de datar peca que nao traz rodape de assinatura.
        foreach ($m in [regex]::Matches($orig, 'validacao/(\d{12})')) {
            $s = $m.Groups[1].Value
            $dt = New-Data ([int]$s.Substring(4, 2)) ([int]$s.Substring(2, 2)) (2000 + [int]$s.Substring(0, 2))
            if ($dt) {
                [void]$urlDatas.Add([pscustomobject]@{
                    Data = $dt
                    Hora = ('{0}:{1}:{2}' -f $s.Substring(6, 2), $s.Substring(8, 2), $s.Substring(10, 2))
                    Pagina = $pagina; Linha = $nl })
            }
        }

        # --- sistema ---
        if ($nl -le 60) {
            if ($a -match 'processo judicial eletronico|\bpje\b') {
                $marca = if ($a -match 'justica do trabalho|tribunal regional do trabalho') { 'PJe-JT (Justica do Trabalho)' } else { 'PJe' }
                if ($sistema -notcontains $marca) { [void]$sistema.Add($marca) }
            }
            if ($a -match '\be-?proc\b') { if ($sistema -notcontains 'eproc') { [void]$sistema.Add('eproc') } }
            if ($a -match 'tribunal de justica do estado de sao paulo|\besaj\b') { if ($sistema -notcontains 'eSAJ (TJSP)') { [void]$sistema.Add('eSAJ (TJSP)') } }
            if ($a -match 'projudi') { if ($sistema -notcontains 'Projudi') { [void]$sistema.Add('Projudi') } }
            if ($null -eq $dataExtrato -and $orig -match '^\s*(\d{2})/(\d{2})/(\d{4})\s*$') {
                $dataExtrato = New-Data ([int]$Matches[1]) ([int]$Matches[2]) ([int]$Matches[3])
            }
        }
        if ($a -match 'pje\.trt|pje\dg?\.|pjekz') {
            $marca = if ($a -match 'pje\.trt') { 'PJe-JT (Justica do Trabalho)' } else { 'PJe' }
            if ($sistema -notcontains $marca) { [void]$sistema.Add($marca) }
        }
        if ($a -match 'pastadigital|assinado digitalmente por.*tribunal de justica do estado de sao paulo') {
            if ($sistema -notcontains 'eSAJ (TJSP)') { [void]$sistema.Add('eSAJ (TJSP)') }
        }

        # --- indice oficial ---
        if ($linhaIndice -eq 0 -and $a -match 'documentos?\s+id\.?\s+data|^\s*#*\s*documentos\s*$|id\.?\s+data da\s+documento|data da\s+id\.\s+documento') { $linhaIndice = $nl }
        if ($linhaSumario -eq 0 -and $a -match '^\s*#*\s*sumario\s*$|para acessar o sumario') { $linhaSumario = $nl }

        # Linhas de indice: PJe usa Id numerico de 9-10 digitos; PJe-JT usa hash de 7 hex.
        # A captura do nome do documento e LAZY e para no proximo lancamento: o extrato
        # imprime varios lancamentos na mesma linha, e um limite fixo de caracteres
        # engolia o lancamento seguinte - fazendo sumir do indice justamente os IDs da
        # prova (extrato de FGTS, ficha de registro) e o ultimo despacho dos autos.
        foreach ($m in [regex]::Matches($orig, '(?<!\d)(\d{9,10})\s+(\d{2}/\d{2}/\d{4})(?:\s+(\d{2}:\d{2}))?\s+(.*?)(?=(?:(?<!\d)\d{9,10}\s+\d{2}/\d{2}/\d{4})|$)')) {
            $nome = Format-Celula $m.Groups[4].Value
            if ($nome.Length -ge 2) {
                [void]$idxLinhas.Add([pscustomobject]@{
                    Id = $m.Groups[1].Value; Data = $m.Groups[2].Value; Resto = $nome; Linha = $nl })
            }
        }
        foreach ($m in [regex]::Matches($orig, '(?<![0-9a-fA-F])([0-9a-f]{7})\s+(\d{2}/\d{2}/\d{4})\s+(\d{2}:\d{2})\s+(.*?)(?=(?:(?<![0-9a-fA-F])[0-9a-f]{7}\s+\d{2}/\d{2}/\d{4})|$)')) {
            $nome = Format-Celula $m.Groups[4].Value
            if ($nome.Length -ge 2) {
                [void]$idxLinhas.Add([pscustomobject]@{
                    Id = $m.Groups[1].Value; Data = $m.Groups[2].Value; Resto = $nome; Linha = $nl })
            }
        }

        # --- fronteiras de peca: assinatura eletronica ---
        if ($orig -match 'Assinado eletronicamente por:\s*(.+?)\s*-\s*(\d{2}/\d{2}/\d{4})\s+(\d{2}:\d{2}(?::\d{2})?)') {
            [void]$assin.Add([pscustomobject]@{
                Assinante = (Format-Celula $Matches[1]); Data = $Matches[2]; Hora = $Matches[3]
                Id = ''; Pagina = $pagina; Linha = $nl })
        }
        elseif ($orig -match 'assinado eletronicamente por\s+(.+?),\s*em\s*(\d{2}/\d{2}/\d{4}),?\s*[a\u00e0]s\s*(\d{2}:\d{2}(?::\d{2})?)\s*-\s*([0-9a-fA-F]{6,10})') {
            [void]$assin.Add([pscustomobject]@{
                Assinante = (Format-Celula $Matches[1]); Data = $Matches[2]; Hora = $Matches[3]
                Id = $Matches[4]; Pagina = $pagina; Linha = $nl })
        }
        elseif ($orig -match 'assinado digitalmente por\s+(.+?),.*?protocolado em\s*(\d{2}/\d{2}/\d{4})\s*[a\u00e0]s\s*(\d{2}:\d{2})') {
            [void]$assin.Add([pscustomobject]@{
                Assinante = (Format-Celula $Matches[1]); Data = $Matches[2]; Hora = $Matches[3]
                Id = ''; Pagina = $pagina; Linha = $nl })
        }

        # --- numero CNJ ---
        foreach ($m in [regex]::Matches($orig, '(?<![\d-])\d{7}[-\.]?\d{2}[\.\s]?\d{4}[\.\s]?\d[\.\s]?\d{2}[\.\s]?\d{4}(?!\d)')) {
            $d = ($m.Value -replace '\D', '')
            if ($d.Length -ne 20) { continue }
            if (-not $cnjs.ContainsKey($d)) {
                $cnjs[$d] = [pscustomobject]@{ Digitos = $d; Ocorrencias = 0; PrimeiraLinha = $nl; Valido = (Test-NumeroCNJ $d) }
            }
            $cnjs[$d].Ocorrencias++
        }

        # --- capa ---
        if ($nl -le 200) {
            foreach ($c in $CAMPOS_CAPA) {
                if (-not $capa.Contains($c.Rotulo)) {
                    $mm = [regex]::Match($a, $c.Padrao)
                    if ($mm.Success) {
                        $v = Format-Celula $mm.Groups[1].Value
                        if ($v.Length -ge 2 -and $v.Length -le 220) { $capa[$c.Rotulo] = $v }
                    }
                }
            }
            # Casa na linha ORIGINAL, com IgnoreCase: o nome da parte tem de sair como
            # esta impresso. Sair em caixa baixa convidava a preencher a ficha do lado
            # errado, que e o defeito numero um do controle de qualidade.
            # O valor termina na virgula, no proximo rotulo de polo, ou no fim da linha.
            # Exigindo so o proximo rotulo, o polo passivo do eSAJ nunca era capturado:
            # a linha "Requerido: FULANO, brasileiro, ... Valor da acao: R$ ..." tem outro
            # dois-pontos no meio, e o padrao morria antes de chegar la.
            foreach ($m in [regex]::Matches($orig, "\b($ROTULOS_PARTE)\s*:\s*([^:,\r\n]{3,90}?)(?=\s*,|\s+(?:$ROTULOS_PARTE)\s*:|\s*$)",
                    [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)) {
                $p = ('{0}: {1}' -f $m.Groups[1].Value.ToUpperInvariant(), (Format-Celula $m.Groups[2].Value))
                if ($partes -notcontains $p) { [void]$partes.Add($p) }
            }
            foreach ($m in [regex]::Matches($orig, '([A-Z][A-Za-z\u00C0-\u00FF\.\'' ]{4,70}?)\s*\((EXEQUENTE|EXECUTADO|EXECUTADA|AUTOR|AUTORA|REU|R[EÉ]|REQUERENTE|REQUERIDO|REQUERIDA|IMPETRANTE|IMPETRADO|RECLAMANTE|RECLAMADO|RECLAMADA|AGRAVANTE|AGRAVADO|APELANTE|APELADO)\)')) {
                # "Partes Advogados" e cabecalho de quadro, nao parte do nome.
                $nome = (Format-Celula $m.Groups[1].Value) -replace '^(?i)partes\s+advogados\s*', ''
                $p = ('{0}: {1}' -f $m.Groups[2].Value, $nome)
                if ($partes -notcontains $p) { [void]$partes.Add($p) }
            }
        }

        # --- indice de pecas por titulo ---
        # Tres filtros, todos aprendidos em uso real:
        #  (a) a palavra-chave tem de estar no COMECO da linha e a linha tem de ser
        #      curta - senao trecho de corpo de carta de citacao virava "acordo";
        #  (b) linha de negacao nao vira constricao: "sem restricao" numa tela RENAJUD
        #      e ausencia de constricao, e rotula-la de constricao inverte o fato;
        #  (c) marca d'agua ("SEM VALOR DE CERTIDAO") nao e certidao - eram 38 delas
        #      numa ficha da JUCESP, falseando a composicao dos autos.
        $ehTitulo = ($orig -match '^\s*#{1,6}\s') -or
                    ($orig -match '^\s*[A-Z\u00C0-\u00DC0-9\s\.\-\/\(\)\u00ba\u00aa]{6,90}\s*$') -or
                    ($a -match '^\s*(evento|mov(imento)?|id\.?|seq\.?|doc\.?|fls?\.|f\.)\s*[:n\u00ba]?\s*\d')
        $ruido = ($a -match 'sem valor de certid|sem restri|nada consta|nada a constar|nao consta restri|marca d.agua')
        if ($ehTitulo -and -not $carimbo -and -not $ruido -and $orig.Trim().Length -le 110) {
            $cabeca = $a.Substring(0, [Math]::Min(70, $a.Length))
            foreach ($p in $CATALOGO_PECAS) {
                if ($cabeca -match $p.Padrao) {
                    [void]$pecas.Add([pscustomobject]@{ Pagina = $pagina; Linha = $nl; Peca = $p.Rotulo; Trecho = $trecho })
                    break
                }
            }
        }

        # --- formulas de abertura e de dispositivo ---
        if (-not $carimbo) {
            foreach ($f in $CATALOGO_FORMULAS) {
                $mf = [regex]::Match($a, $f.Padrao)
                if ($mf.Success) {
                    [void]$formulas.Add([pscustomobject]@{
                        Pagina = $pagina; Linha = $nl; Rotulo = $f.Rotulo
                        Trecho = (Get-TrechoCentrado $orig $mf.Index $a.Length $Contexto) })
                    break
                }
            }
        }

        # --- datas ---
        if (-not $carimbo) {
            foreach ($m in [regex]::Matches($orig, '\b(\d{1,2})/(\d{1,2})/(\d{4})\b')) {
                $dt = New-Data ([int]$m.Groups[1].Value) ([int]$m.Groups[2].Value) ([int]$m.Groups[3].Value)
                if ($dt) { [void]$datas.Add([pscustomobject]@{ Data = $dt; Pagina = $pagina; Linha = $nl; Trecho = $trecho }) }
            }
            foreach ($m in [regex]::Matches($a, '\b(\d{1,2})\s+de\s+([a-z]+)\s+de\s+(\d{4})\b')) {
                $mes = $MESES[$m.Groups[2].Value]
                if ($mes) {
                    $dt = New-Data ([int]$m.Groups[1].Value) $mes ([int]$m.Groups[3].Value)
                    if ($dt) { [void]$datas.Add([pscustomobject]@{ Data = $dt; Pagina = $pagina; Linha = $nl; Trecho = $trecho }) }
                }
            }
        }

        # --- prazos ---
        foreach ($m in [regex]::Matches($a, '(no\s+)?prazo\s+(comum\s+|sucessivo\s+|improrrogavel\s+|em\s+dobro\s+|legal\s+)?de\s+\d{1,3}\s*(\([a-z\s]+\)\s*)?(dias?|horas?|meses)(\s+uteis)?|\b\d{1,3}\s*\([a-z\s]+\)\s*dias?\s+(uteis\s+)?(para|a\s+contar|apos|sob\s+pena)|\bprazo\s*:\s*\d{1,3}\s*dias?')) {
            [void]$prazos.Add([pscustomobject]@{ Pagina = $pagina; Linha = $nl; Expressao = (Format-Celula $m.Value); Trecho = $trecho })
        }

        # --- alertas ---
        if (-not $carimbo) {
            foreach ($al in $CATALOGO_ALERTAS) {
                $ma = [regex]::Match($a, $al.Padrao)
                if ($ma.Success) {
                    [void]$alertas.Add([pscustomobject]@{
                        Sev = $al.Sev; Rotulo = $al.Rotulo; Pagina = $pagina; Linha = $nl
                        Trecho = (Get-TrechoCentrado $orig $ma.Index $a.Length $Contexto) })
                }
            }
        }

        # --- valores e OAB ---
        foreach ($m in [regex]::Matches($orig, 'R\$\s?[\d\.]{1,15},\d{2}')) {
            $v = $m.Value -replace '\s', ''
            if ($valores.ContainsKey($v)) { $valores[$v]++ } else { $valores[$v] = 1 }
        }
        foreach ($m in [regex]::Matches($orig, 'OAB\s*[/\-]?\s*([A-Z]{2})\s*n?[.\u00ba\s]*([\d\.]{3,9})')) {
            $k = ('OAB/{0} {1}' -f $m.Groups[1].Value, ($m.Groups[2].Value -replace '\.', ''))
            if ($oabs.ContainsKey($k)) { $oabs[$k]++ } else { $oabs[$k] = 1 }
        }
    }

    # ---------------- relatorio ----------------
    Add ('# Mapa dos autos - ' + [System.IO.Path]::GetFileName($arquivo))
    Add ''
    Add ('Fonte lida: `{0}`  |  {1} linhas  |  {2} paginas detectadas' -f $fonte, $total, $pagina)
    if ($sistema.Count -gt 0) { Add ('Sistema: **{0}**' -f ($sistema -join ' / ')) }
    else { Add 'Sistema: nao identificado pelo cabecalho.' }
    Add ''

    # --- 0. atualidade -------------------------------------------------------
    # Quatro ancoras independentes, porque nenhuma existe em todos os sistemas: o
    # eSAJ nao tem data de geracao nem carimbo de assinatura apos a conversao; o
    # PJe-JT tem pecas recentes SEM rodape de assinatura, cuja unica data esta nos
    # 12 primeiros digitos da URL de validacao. Usar so uma ancora ja errou por 48
    # dias num caso e falhou inteiramente em outro.
    Add '## 0. O extrato esta atual?'
    Add ''

    function Get-DataBR { param([string]$s) $p = $s -split '/'; if ($p.Count -eq 3) { return (New-Data ([int]$p[0]) ([int]$p[1]) ([int]$p[2])) }; return $null }

    $ancoras = New-Object System.Collections.ArrayList

    if ($urlDatas.Count -gt 0) {
        $u = $urlDatas | Sort-Object Data | Select-Object -Last 1
        [void]$ancoras.Add([pscustomobject]@{ Nome = 'URL de validacao (relogio do PJe-JT)'; D = $u.Data
            Detalhe = ('{0} {1}, p. {2}, linha {3}' -f $u.Data.ToString('dd/MM/yyyy'), $u.Hora, $u.Pagina, $u.Linha) })
    }
    if ($idxLinhas.Count -gt 0) {
        $comD = @($idxLinhas | ForEach-Object { $d = Get-DataBR $_.Data; if ($d) { [pscustomobject]@{ D = $d; R = $_ } } } | Where-Object { $_ })
        if ($comD.Count -gt 0) {
            $i = $comD | Sort-Object D | Select-Object -Last 1
            [void]$ancoras.Add([pscustomobject]@{ Nome = 'Ultima linha do indice oficial'; D = $i.D
                Detalhe = ('{0} - Id {1} - {2}' -f $i.R.Data, $i.R.Id, $i.R.Resto) })
        }
    }
    $ultAssin = $null
    if ($assin.Count -gt 0) {
        $comD = @($assin | ForEach-Object { $d = Get-DataBR $_.Data; if ($d) { [pscustomobject]@{ D = $d; R = $_ } } } | Where-Object { $_ })
        if ($comD.Count -gt 0) {
            $ultAssin = $comD | Sort-Object D | Select-Object -Last 1
            [void]$ancoras.Add([pscustomobject]@{ Nome = 'Ultima assinatura eletronica'; D = $ultAssin.D
                Detalhe = ('{0} {1}, por {2} (p. {3}, linha {4})' -f $ultAssin.R.Data, $ultAssin.R.Hora, $ultAssin.R.Assinante, $ultAssin.R.Pagina, $ultAssin.R.Linha) })
        }
    }

    $inferida = $null
    if ($ancoras.Count -eq 0) {
        $passadas = @($datas | Where-Object { $_.Data -le $Hoje } | Sort-Object Data)
        if ($passadas.Count -gt 0) {
            $inferida = $passadas[$passadas.Count - 1]
            [void]$ancoras.Add([pscustomobject]@{ Nome = 'Data mais recente do texto (INFERIDA)'; D = $inferida.Data
                Detalhe = ('{0}, p. {1}, linha {2} - {3}' -f $inferida.Data.ToString('dd/MM/yyyy'), $inferida.Pagina, $inferida.Linha, $inferida.Trecho) })
        }
    }

    if ($dataExtrato) { Add ('- **Extrato gerado em {0}** (data impressa pelo sistema).' -f $dataExtrato.ToString('dd/MM/yyyy')) }

    if ($ancoras.Count -gt 0) {
        Add ''
        Add '| ancora da ultima atividade | data | onde |'
        Add '|---|---|---|'
        foreach ($an in ($ancoras | Sort-Object D -Descending)) {
            Add ('| {0} | **{1}** | {2} |' -f $an.Nome, $an.D.ToString('dd/MM/yyyy'), (Format-Celula $an.Detalhe))
        }
        Add ''
        $topo = ($ancoras | Sort-Object D | Select-Object -Last 1)
        if ($ancoras.Count -gt 1) {
            $base = ($ancoras | Sort-Object D | Select-Object -First 1)
            if ($topo.D -gt $base.D) {
                Add ('> As ancoras divergem em {0} dia(s). Vale a MAIS RECENTE ({1}): as demais nao cobrem pecas que entraram sem aquele marcador. Divergencia grande tambem pode significar que o arquivo esta truncado.' -f `
                    [int]($topo.D - $base.D).TotalDays, $topo.D.ToString('dd/MM/yyyy'))
                Add ''
            }
        }
        $gap = [int]($Hoje - $topo.D).TotalDays
        Add ('- Ultima atividade retratada: **{0}**. Hoje e {1}. O arquivo tem **{2} dia(s)**.' -f `
            $topo.D.ToString('dd/MM/yyyy'), $Hoje.ToString('dd/MM/yyyy'), $gap)
        if ($inferida) {
            Add '- **A data acima e inferida do texto**, nao de um marcador do sistema. Neste arquivo nao ha data de geracao, indice, assinatura eletronica nem URL de validacao: a atualidade NAO pode ser afirmada com base nele.'
        }
        Add ''
        if ($gap -ge 30) {
            Add ('> **ATENCAO - EXTRATO VENCIDO.** Ha {0} dias entre o ultimo ato retratado neste arquivo e hoje. Tudo o que ocorreu nesse intervalo esta invisivel aqui. NAO afirme fase atual, prazo em curso nem "ultimo movimento" com base so neste PDF: baixe extrato novo ou consulte o andamento no sistema do tribunal antes de concluir.' -f $gap)
        }
        else { Add '> Janela aceitavel, mas confirme o andamento no sistema antes de cravar prazo.' }
    }
    else { Add '- Nao foi possivel datar o arquivo por nenhuma das quatro ancoras. Trate-o como desatualizado ate consultar o sistema.' }
    Add ''

    # --- 0.1 cobertura e sanidade da conversao -------------------------------
    Add '## 0.1 O que o arquivo NAO mostra'
    Add ''
    if ($pagina -gt 0) {
        $mudas = @(1..$pagina | Where-Object { -not $paginasComTexto.ContainsKey($_) })
        if ($mudas.Count -eq 0) {
            Add ('- Todas as {0} paginas produziram texto.' -f $pagina)
        }
        else {
            # Comprime em faixas: "16-22, 28-41, 48".
            $faixas = New-Object System.Collections.ArrayList
            $ini = $mudas[0]; $ant = $mudas[0]
            for ($k = 1; $k -lt $mudas.Count; $k++) {
                if ($mudas[$k] -ne $ant + 1) {
                    [void]$faixas.Add($(if ($ini -eq $ant) { "$ini" } else { "$ini-$ant" }))
                    $ini = $mudas[$k]
                }
                $ant = $mudas[$k]
            }
            [void]$faixas.Add($(if ($ini -eq $ant) { "$ini" } else { "$ini-$ant" }))
            Add ('- **{0} de {1} paginas nao produziram texto:** {2}' -f $mudas.Count, $pagina, ($faixas -join ', '))
            Add ''
            Add '> Sao documentos digitalizados sem OCR, e o mapa nao diz NADA sobre o conteudo delas. Costumam ser exatamente a prova - extrato de FGTS, ficha de registro, ASO, laudo, termo de declaracoes, foto de album policial. Liste-as como nao lidas na entrega e abra o PDF original ou peca ao cliente. Nunca conclua "nao ha X nos autos" sem antes cobrir estas paginas.'
        }
    }
    else { Add '- O arquivo nao tem marcadores de pagina `[p. N]`; a cobertura por pagina nao pode ser apurada.' }
    Add ''
    if ($totalChars -gt 2000) {
        $pct = [math]::Round(100.0 * $acentos / $totalChars, 2)
        if ($pct -lt 1.0) {
            Add ('- **ACENTUACAO PERDIDA NA CONVERSAO: apenas {0}% dos caracteres sao acentuados.**' -f $pct)
            Add ''
            Add '> Texto juridico em portugues fica entre 2% e 3%. Abaixo de 1% a fonte do PDF nao traz `/ToUnicode` confiavel e os acentos viraram outro glifo (`sintese` sai `s?ntese`, `Alvaro` sai `?lvaro`). Consequencia pratica: **nome proprio, razao social e endereco copiados daqui vao errados para a peca.** Confira toda transcricao contra o PDF antes de usar.'
        }
        else { Add ('- Acentuacao integra ({0}% dos caracteres) - a conversao preservou os glifos.' -f $pct) }
    }
    Add ''

    # --- 1. identificacao ---------------------------------------------------
    Add '## 1. Identificacao'
    Add ''
    if ($cnjs.Count -eq 0) {
        Add '- Nenhum numero CNJ localizado: autos sem numeracao no texto, ou PDF sem camada de texto.'
    }
    else {
        Add '| Numero | Ocorrencias | 1a linha | DV |'
        Add '|---|---:|---:|---|'
        foreach ($c in ($cnjs.Values | Sort-Object -Property Ocorrencias -Descending)) {
            $dv = if ($c.Valido) { 'ok' } else { '**INVALIDO**' }
            Add ('| {0} | {1} | {2} | {3} |' -f (Format-CNJ $c.Digitos), $c.Ocorrencias, $c.PrimeiraLinha, $dv)
        }
        if ($cnjs.Count -gt 1) {
            Add ''
            Add ('> Ha {0} numeros distintos. Decida qual e o principal antes de analisar: os demais podem ser apenso, recurso, precatoria, execucao em apartado, numero antigo do mesmo feito - ou peca de OUTRO processo colada por engano.' -f $cnjs.Count)
        }
        $invalidos = @($cnjs.Values | Where-Object { -not $_.Valido })
        if ($invalidos.Count -gt 0) {
            Add ''
            Add ('> {0} numero(s) com digito verificador invalido. Ou houve erro de digitacao na peca, ou o OCR corrompeu o numero. Confira no sistema antes de copiar para qualquer lugar.' -f $invalidos.Count)
        }
    }
    Add ''
    if ($capa.Count -gt 0) {
        Add '**Campos da capa** (como impressos, sem correcao):'
        Add ''
        Add '| campo | valor |'
        Add '|---|---|'
        foreach ($k in $capa.Keys) { Add ('| {0} | {1} |' -f $k, (Format-Celula $capa[$k])) }
        Add ''
    }
    if ($partes.Count -gt 0) {
        Add ('**Partes e procuradores localizados:** ' + (($partes | Select-Object -First 24) -join ' &middot; '))
        Add ''
        Add '> Polo em branco, ou parte sem advogado ao lado, e informacao - nao e lacuna do extrato. Registre.'
        Add ''
    }

    # --- 2. indice oficial --------------------------------------------------
    Add '## 2. Indice oficial do sistema'
    Add ''
    if ($linhaIndice -gt 0) { Add ('- Tabela "Documentos / Id. / Data da Assinatura" comeca na **linha {0}**.' -f $linhaIndice) }
    if ($linhaSumario -gt 0) { Add ('- Marcador de SUMARIO na **linha {0}**. No PJe-JT o sumario fica na ULTIMA folha - va ao fim do arquivo.' -f $linhaSumario) }
    if ($linhaIndice -eq 0 -and $linhaSumario -eq 0) {
        Add '- Nenhum indice impresso. E o caso do eSAJ e das pastas digitais: a espinha e a foliacao `fls. N` e a ordem cronologica de juntada. Use a secao 3 (fronteiras de peca) como indice substituto.'
    }
    Add ''
    if ($idxLinhas.Count -gt 0) {
        Add ('**{0} lancamento(s) reconhecido(s)** no formato `<Id> <data> <documento>`:' -f $idxLinhas.Count)
        Add ''
        Add '| Id | data | documento / tipo | linha |'
        Add '|---|---|---|---:|'
        $n = 0
        foreach ($r in $idxLinhas) {
            if ($n -ge $MaxEventos) { Add ('| ... | ... | *(+{0} omitidos)* | |' -f ($idxLinhas.Count - $n)); break }
            Add ('| {0} | {1} | {2} | {3} |' -f $r.Id, $r.Data, $r.Resto, $r.Linha)
            $n++
        }
        Add ''
        Add '> O indice do PJe imprime a coluna da HORA quebrada na linha vizinha: a hora que aparece junto de um Id pode ser do lancamento anterior. E o indice e um indice, nao um inventario - peca protocolada com visibilidade restrita (defesa antes da conciliacao, por exemplo) existe nos autos e NAO aparece aqui. Confira sempre contra a secao 3.'
    }
    Add ''

    # --- 3. fronteiras de peca ----------------------------------------------
    Add '## 3. Fronteiras de peca (assinaturas eletronicas)'
    Add ''
    if ($assin.Count -eq 0) {
        Add '- Nenhum carimbo de assinatura reconhecido. Sem ele, a separacao entre uma peca e a seguinte so se faz pelo titulo - o que e menos confiavel.'
    }
    else {
        $blocos = New-Object System.Collections.ArrayList
        $atual = $null
        foreach ($s in $assin) {
            $chave = '{0}|{1}|{2}|{3}' -f $s.Assinante, $s.Data, $s.Hora, $s.Id
            if ($null -eq $atual -or $atual.Chave -ne $chave) {
                if ($atual) { [void]$blocos.Add($atual) }
                $atual = [pscustomobject]@{
                    Chave = $chave; Assinante = $s.Assinante; Data = $s.Data; Hora = $s.Hora; Id = $s.Id
                    PagIni = $s.Pagina; PagFim = $s.Pagina; LinIni = $s.Linha; LinFim = $s.Linha; Folhas = 1 }
            }
            else {
                $atual.PagFim = $s.Pagina; $atual.LinFim = $s.Linha; $atual.Folhas++
            }
        }
        if ($atual) { [void]$blocos.Add($atual) }

        $temId = @($blocos | Where-Object { $_.Id }).Count -gt 0
        $cobertas = @($blocos | ForEach-Object { $_.PagIni..$_.PagFim } | Sort-Object -Unique).Count

        Add ('**{0} bloco(s) de assinatura** = candidatos a peca autonoma. O carimbo do rodape, e nao o titulo, e o que diz onde uma peca termina e outra comeca.' -f $blocos.Count)
        Add ''
        if ($temId) {
            Add '| # | assinante | data/hora | Id | paginas | linhas | folhas |'
            Add '|---:|---|---|---|---|---|---:|'
        }
        else {
            Add '| # | assinante | data/hora | paginas | linhas | folhas |'
            Add '|---:|---|---|---|---|---:|'
        }
        $n = 0
        foreach ($b in $blocos) {
            $n++
            if ($n -gt $MaxEventos) { Add ('| ... | *(+{0} blocos omitidos)* | | | | |' -f ($blocos.Count - $MaxEventos)); break }
            if ($temId) {
                Add ('| {0} | {1} | {2} {3} | {4} | {5}-{6} | {7}-{8} | {9} |' -f `
                    $n, $b.Assinante, $b.Data, $b.Hora, $b.Id, $b.PagIni, $b.PagFim, $b.LinIni, $b.LinFim, $b.Folhas)
            }
            else {
                Add ('| {0} | {1} | {2} {3} | {4}-{5} | {6}-{7} | {8} |' -f `
                    $n, $b.Assinante, $b.Data, $b.Hora, $b.PagIni, $b.PagFim, $b.LinIni, $b.LinFim, $b.Folhas)
            }
        }
        Add ''
        if (-not $temId) {
            Add '> Este sistema nao repete o Id no rodape - so o nome e a data. A amarracao assinatura -> Id tem de ser feita contra a secao 2, casando data e paginas.'
            Add ''
        }
        if ($pagina -gt 0 -and $cobertas -lt $pagina) {
            Add ('> **COBERTURA PARCIAL: {0} de {1} paginas tem carimbo de assinatura.** As demais nao sao lacuna do arquivo - sao pecas que este sistema nao carimba (anexo, prova documental, peca protocolada por outro meio). Para essas, a secao 3 NAO serve de indice, e o "ultimo movimento" apurado so por ela pode estar desatualizado. Confira contra a secao 2.' -f $cobertas, $pagina)
            Add ''
        }
        Add '> Assinante servidor ou magistrado = ato do juizo (intimacao, despacho, decisao, sentenca, certidao): e nele que mora o prazo. Assinante advogado = peca de parte: nela mora a tese, nunca o prazo.'
        Add ''
        Add '> A data do carimbo e a data da ASSINATURA, nao a data do ato retratado nem a da juntada. Documento assinado em janeiro e juntado em marco aparece aqui com a data de janeiro.'
    }
    Add ''

    # --- 4. indice de pecas por titulo --------------------------------------
    Add '## 4. Pecas reconhecidas por titulo'
    Add ''
    if ($pecas.Count -eq 0) {
        Add '- Nenhum titulo de peca reconhecido. Confira se o .md preservou os titulos (o pdf2md marca com `#`) e se o PDF tem camada de texto.'
    }
    else {
        $resumo = $pecas | Group-Object Peca | Sort-Object Count -Descending
        Add ('**Quantas de cada:** ' + (($resumo | ForEach-Object { '{0} ({1})' -f $_.Name, $_.Count }) -join ' &middot; '))
        Add ''
        Add '| pag | linha | peca | titulo localizado |'
        Add '|---:|---:|---|---|'
        $n = 0
        foreach ($p in $pecas) {
            if ($n -ge $MaxEventos) { Add ('| ... | ... | ... | *(+{0} omitidas - use -MaxEventos)* |' -f ($pecas.Count - $n)); break }
            Add ('| {0} | {1} | {2} | {3} |' -f $p.Pagina, $p.Linha, $p.Peca, (Format-Celula $p.Trecho))
            $n++
        }
    }
    Add ''
    Add '> **Rotulo e palpite, nao classificacao.** O reconhecimento e por palavra no comeco da linha: uma linha pode ser rotulada errado, e uma peca sem titulo NAO aparece aqui de jeito nenhum. Nunca conclua "nao ha sentenca nos autos" a partir desta tabela - confira a secao 4.1 e abra a linha.'
    Add ''

    # --- 4.1 formulas -------------------------------------------------------
    Add '### 4.1 Pecas reconhecidas por formula'
    Add ''
    if ($formulas.Count -eq 0) {
        Add '- Nenhuma formula de abertura ou de dispositivo localizada.'
    }
    else {
        $resF = $formulas | Group-Object Rotulo | Sort-Object Count -Descending
        Add ('**Quantas de cada:** ' + (($resF | ForEach-Object { '{0} ({1})' -f $_.Name, $_.Count }) -join ' &middot; '))
        Add ''
        Add '| pag | linha | o que e | trecho |'
        Add '|---:|---:|---|---|'
        $n = 0
        foreach ($f in $formulas) {
            if ($n -ge $MaxEventos) { Add ('| ... | ... | ... | *(+{0} omitidas)* |' -f ($formulas.Count - $n)); break }
            Add ('| {0} | {1} | {2} | {3} |' -f $f.Pagina, $f.Linha, $f.Rotulo, (Format-Celula $f.Trecho))
            $n++
        }
        Add ''
        Add '> Esta tabela apanha a peca que a de cima perde: a denuncia que so tem enderecamento, e a sentenca do JEC, que vive dentro do termo de audiencia e nunca aparece como peca autonoma. `Dispositivo de sentenca` e `Acordao` sao os dois achados mais valiosos do mapa inteiro.'
    }
    Add ''

    # --- 5. linha do tempo --------------------------------------------------
    Add '## 5. Linha do tempo'
    Add ''
    if ($datas.Count -eq 0) { Add '- Nenhuma data localizada.' }
    else {
        $ord = $datas | Sort-Object Data
        Add ('Intervalo coberto: **{0}** a **{1}** ({2} datas).' -f `
            $ord[0].Data.ToString('dd/MM/yyyy'), $ord[$ord.Count-1].Data.ToString('dd/MM/yyyy'), $datas.Count)
        $futuras = @($datas | Where-Object { $_.Data -gt $Hoje })
        if ($futuras.Count -gt 0) {
            Add ''
            Add ('**{0} data(s) no futuro** - candidatas a audiencia, sessao ou vencimento designado:' -f $futuras.Count)
            Add ''
            Add '| data | pag | linha | trecho |'
            Add '|---|---:|---:|---|'
            foreach ($d in ($futuras | Sort-Object Data | Select-Object -First 20)) {
                Add ('| {0} | {1} | {2} | {3} |' -f $d.Data.ToString('dd/MM/yyyy'), $d.Pagina, $d.Linha, (Format-Celula $d.Trecho))
            }
        }
        Add ''
        Add '### 5.1 As 15 datas passadas mais recentes'
        Add ''
        Add '| data | pag | linha | trecho |'
        Add '|---|---:|---:|---|'
        foreach ($d in (@($ord | Where-Object { $_.Data -le $Hoje }) | Select-Object -Last 15 | Sort-Object Data -Descending)) {
            Add ('| {0} | {1} | {2} | {3} |' -f $d.Data.ToString('dd/MM/yyyy'), $d.Pagina, $d.Linha, (Format-Celula $d.Trecho))
        }
        Add ''
        Add '> A data mais recente do TEXTO nao e o ultimo movimento. Pode ser data de emissao do PDF, de assinatura, de vencimento de titulo ou de nascimento de parte. O ultimo movimento se apura na secao 3, nao aqui.'
        Add ''
        if ($Cronologia) {
            Add '### 5.2 Todas as datas, na ordem em que aparecem no arquivo'
            Add ''
            Add '> **Isto NAO e a cronologia do processo.** E a ordem das paginas do PDF, que nao coincide com a ordem dos fatos, e a lista mistura ato processual com data de nascimento, vencimento de titulo, ata de assembleia e termo inicial de indice. Nao copie para a ficha: a cronologia se reconstroi a partir da secao 2 e da secao 3.'
            Add ''
            Add '| data | pag | linha | trecho |'
            Add '|---|---:|---:|---|'
            $n = 0
            foreach ($d in ($datas | Sort-Object Linha)) {
                if ($n -ge $MaxEventos) { Add ('| ... | ... | ... | *(+{0} datas omitidas)* |' -f ($datas.Count - $n)); break }
                Add ('| {0} | {1} | {2} | {3} |' -f $d.Data.ToString('dd/MM/yyyy'), $d.Pagina, $d.Linha, (Format-Celula $d.Trecho))
                $n++
            }
        }
        else {
            Add ('### 5.2 Demais datas — suprimidas' )
            Add ''
            Add ('Ha {0} datas no arquivo. A lista completa sai fora de ordem cronologica (segue a ordem das paginas) e mistura ato processual com data de nascimento, vencimento e ata de assembleia — em autos grandes ela ocupa metade do mapa e nao se usa. Rode com `-Cronologia` se quiser mesmo.' -f $datas.Count)
        }
    }
    Add ''

    # --- 6. prazos ----------------------------------------------------------
    Add '## 6. Prazos mencionados no texto'
    Add ''
    if ($prazos.Count -eq 0) { Add '- Nenhuma expressao de prazo localizada.' }
    else {
        Add '| pag | linha | expressao | trecho |'
        Add '|---:|---:|---|---|'
        $n = 0
        foreach ($p in $prazos) {
            if ($n -ge $MaxEventos) { Add ('| ... | ... | ... | *(+{0} omitidos)* |' -f ($prazos.Count - $n)); break }
            Add ('| {0} | {1} | `{2}` | {3} |' -f $p.Pagina, $p.Linha, $p.Expressao, (Format-Celula $p.Trecho))
            $n++
        }
    }
    Add ''
    Add '> O script localiza a EXPRESSAO de prazo. Ele nao conta prazo e nao sabe o dies a quo. Dia util, suspensao, feriado local, prazo em dobro, intimacao pessoal e data de disponibilizacao no DJe dependem de conferencia humana no sistema do tribunal. O extrato de autos quase nunca traz a data da publicacao.'
    Add ''

    # --- 7. alertas ---------------------------------------------------------
    Add '## 7. Alertas'
    Add ''
    if ($alertas.Count -eq 0) { Add '- Nenhum alerta.' }
    else {
        foreach ($sev in @('ALTA', 'MEDIA')) {
            $doNivel = @($alertas | Where-Object { $_.Sev -eq $sev })
            if ($doNivel.Count -eq 0) { continue }
            Add ('### {0} - {1} ocorrencia(s)' -f $sev, $doNivel.Count)
            Add ''
            foreach ($g in ($doNivel | Group-Object Rotulo | Sort-Object Count -Descending)) {
                $primeiras = @($g.Group | Select-Object -First 4)
                Add ('- **{0}** ({1}x) - em {2}' -f $g.Name, $g.Count,
                    (($primeiras | ForEach-Object { 'p.{0}/l.{1}' -f $_.Pagina, $_.Linha }) -join ', '))
                Add ('    > {0}' -f $primeiras[0].Trecho)
            }
            Add ''
        }
        Add '> Alerta e pista, nao conclusao. "Prescricao" pode ser a tese da defesa e nao o reconhecimento dela; "revelia" pode estar na advertencia da notificacao e nao no decreto. Abra a linha antes de escrever qualquer coisa.'
    }
    Add ''

    # --- 8. valores e procuradores -----------------------------------------
    Add '## 8. Valores e procuradores'
    Add ''
    if ($valores.Count -gt 0) {
        $topo = $valores.GetEnumerator() | Sort-Object Value -Descending | Select-Object -First 12
        Add ('**Valores mais repetidos:** ' + (($topo | ForEach-Object { '{0} ({1}x)' -f $_.Key, $_.Value }) -join ' &middot; '))
    }
    else { Add '**Valores:** nenhum localizado.' }
    Add ''
    if ($oabs.Count -gt 0) {
        $to = $oabs.GetEnumerator() | Sort-Object Value -Descending | Select-Object -First 20
        Add ('**OAB citadas:** ' + (($to | ForEach-Object { '{0} ({1}x)' -f $_.Key, $_.Value }) -join ' &middot; '))
        Add ''
        Add '> Duas inscricoes proximas para o mesmo nome (ex.: 125.510 e 128.510) sao erro de digitacao, nao duas pessoas. Confira antes de reproduzir.'
    }
    else { Add '**OAB:** nenhuma localizada.' }
    Add ''

    # --- 9. proximo passo ---------------------------------------------------
    Add '## 9. Proximo passo'
    Add ''
    Add 'O mapa nao substitui a leitura. Abra por faixa de linha, nesta ordem:'
    Add ''
    Add '1. O indice oficial (secao 2) ou as fronteiras de peca (secao 3) - para escolher o que ler.'
    Add '2. O ultimo ato de JUIZO (secao 3, assinante servidor ou magistrado) - integral. E ele que fixa a fase e o prazo.'
    Add '3. A peca que abriu o feito (inicial, denuncia, CDA, termo de ajuizamento) - integral.'
    Add '4. A defesa (contestacao, embargos, resposta a acusacao) - integral, se existir.'
    Add '5. Toda linha listada nos alertas ALTA.'
    Add '6. As paginas que o mapa NAO cobriu: pagina sem texto e documento digitalizado sem OCR, e costuma ser a prova.'
    Add ''
    Add '```'
    Add ('sed -n ''<inicio>,<fim>p'' "{0}"' -f $fonte)
    Add '```'

    return $saida.ToString()
}

# ----------------------------------------------------------------------------

$tudo = New-Object System.Text.StringBuilder
foreach ($p in $Path) {
    if (-not (Test-Path -LiteralPath $p)) { Write-Warning "Arquivo nao encontrado: $p"; continue }
    Write-Host ("Mapeando {0}" -f [System.IO.Path]::GetFileName($p)) -ForegroundColor Cyan
    [void]$tudo.AppendLine((Invoke-Mapa $p))
    [void]$tudo.AppendLine('')
    [void]$tudo.AppendLine('---')
    [void]$tudo.AppendLine('')
}

if ($Out) {
    $dir = Split-Path -Parent $Out
    if ($dir -and -not (Test-Path -LiteralPath $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
    $tudo.ToString() | Out-File -LiteralPath $Out -Encoding utf8
    Write-Host ("Mapa gravado em {0}" -f $Out) -ForegroundColor Green
}
else {
    Write-Output $tudo.ToString()
}
