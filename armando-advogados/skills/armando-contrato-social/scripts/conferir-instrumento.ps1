#Requires -Version 5.1
<#
.SYNOPSIS
    Confere um instrumento societario antes do arquivamento. E a trava.

.DESCRIPTION
    Le um .docx, .txt ou .md e roda 21 verificacoes automaticas contra os
    defeitos que EXISTEM nos instrumentos do acervo do escritorio — varios
    deles ja arquivados na Junta.

    Nao substitui a leitura de referencias/controle-de-qualidade.md. Pega o
    que e mecanico: remissao quebrada, numeracao que regride, extenso que
    nao bate com o algarismo, base legal revogada, competencia atribuida a
    quem nao a tem, placeholder esquecido.

    Severidades:
      ERRO     defeito objetivo; corrija antes de entregar (codigo de saida 1)
      ALERTA   provavel defeito; confira e decida conscientemente
      CONFERIR ponto que exige confirmacao humana (foro, CNAE, datas)

.PARAMETER Caminho
    Instrumento a conferir (.docx, .txt, .md). Para PDF, converta antes com
    a skill armando-pdf-markdown.

.PARAMETER Saida
    Grava o relatorio em .md em vez de imprimir.

.PARAMETER Json
    Emite as constatacoes como JSON.

.PARAMETER SoErros
    Mostra apenas severidade ERRO.

.EXAMPLE
    .\conferir-instrumento.ps1 "7a Alteracao Contratual.docx"

.EXAMPLE
    .\conferir-instrumento.ps1 minuta.md -SoErros

.NOTES
    Gravar em UTF-8 COM BOM (PS 5.1 le .ps1 sem BOM como ANSI).
#>
[CmdletBinding()]
param(
    [Parameter(Position = 0, Mandatory = $true)][string]$Caminho,
    [string]$Saida,
    [switch]$Json,
    [switch]$SoErros
)

$ErrorActionPreference = 'Stop'
try { [Console]::OutputEncoding = New-Object System.Text.UTF8Encoding($false) } catch { }
. (Join-Path $PSScriptRoot 'lib-extenso.ps1')

# ------------------------------------------------------------------ leitura ---

function Get-TextoDocx {
    param([string]$Path)
    Add-Type -AssemblyName System.IO.Compression.FileSystem | Out-Null
    $zip = [IO.Compression.ZipFile]::OpenRead($Path)
    try {
        $e = $zip.Entries | Where-Object { $_.FullName -eq 'word/document.xml' }
        if (-not $e) { throw "docx sem word/document.xml: $Path" }
        $sr = New-Object IO.StreamReader($e.Open(), [Text.Encoding]::UTF8)
        try { $xml = $sr.ReadToEnd() } finally { $sr.Dispose() }
    } finally { $zip.Dispose() }

    $xml = $xml -replace '<w:tab[^>]*/>', "`t"
    $xml = $xml -replace '<w:br[^>]*/>', "`n"
    $xml = $xml -replace '</w:p>', "`n"
    $xml = $xml -replace '<[^>]+>', ''
    $xml = $xml -replace '&lt;', '<' -replace '&gt;', '>' -replace '&quot;', '"' -replace '&apos;', "'" -replace '&amp;', '&'
    return $xml
}

if (-not (Test-Path -LiteralPath $Caminho)) { throw "Arquivo nao encontrado: $Caminho" }
$ext = [IO.Path]::GetExtension($Caminho).ToLowerInvariant()
if ($ext -eq '.pdf') { throw 'PDF nao e lido direto. Converta antes com a skill armando-pdf-markdown e passe o .md.' }
if ($ext -eq '.docx') { $texto = Get-TextoDocx (Resolve-Path -LiteralPath $Caminho) }
else { $texto = [IO.File]::ReadAllText((Resolve-Path -LiteralPath $Caminho), [Text.Encoding]::UTF8) }

$linhas = $texto -split "`r?`n"
$plano  = ($linhas -join ' ')

# Tipo do instrumento. Sem isso o script cobra de um acordo de socios coisas
# que so o registro na Junta exige (desimpedimento, CNAE).
$cabeca = ($linhas | Select-Object -First 40) -join ' '
$tipo = 'contrato'
if     ($cabeca -match '(?i)ACORDO\s+DE\s+(S[ÓO]CIOS|QUOTISTAS|ACIONISTAS)') { $tipo = 'acordo' }
elseif ($cabeca -match '(?i)ATA\s+DE\s+(REUNI[ÃA]O|ASSEMBLEIA)')             { $tipo = 'ata' }

# ------------------------------------------------------------ constatacoes ---

$achados = New-Object System.Collections.ArrayList

function Add-Achado {
    param([string]$Sev, [string]$Regra, [string]$Texto, [int]$Linha = 0, [string]$Trecho = '')
    [void]$achados.Add([pscustomobject]@{
        Severidade = $Sev
        Regra      = $Regra
        Texto      = $Texto
        Linha      = $Linha
        Trecho     = ($Trecho -replace '\s+', ' ').Trim()
    })
}

function Test-Padrao {
    param([string]$Regex, [string]$Sev, [string]$Regra, [string]$Texto, [int]$Max = 6)
    $n = 0
    for ($i = 0; $i -lt $linhas.Count; $i++) {
        if ($linhas[$i] -match $Regex) {
            $n++
            if ($n -le $Max) {
                $t = $linhas[$i]
                if ($t.Length -gt 190) { $t = $t.Substring(0, 190) + '...' }
                Add-Achado $Sev $Regra $Texto ($i + 1) $t
            }
        }
    }
}

# 1. Placeholders esquecidos --------------------------------------------------
Test-Padrao '\[\s*-?\s*INSERIR\s*-?\s*\]|\[\s*-?\s*Inserir\s*-?\s*\]|\[\.{2,}\]|\bXPTO\b|\[SÓCIO \d\]|\[NOME\]|\[\.\.\.\]' `
    'ERRO' 'placeholder' 'Placeholder nao preenchido. Nenhum campo pode ir para a Junta como marcador.'

# 2. art. 2.031 do CC como base da consolidacao -------------------------------
Test-Padrao 'art(igo)?\.?\s*2\.?031' `
    'ERRO' 'base-legal' 'Art. 2.031 do Codigo Civil invocado. Ele trata do prazo de adaptacao das sociedades anteriores ao CC/2002, exaurido ha duas decadas — nao e fundamento de consolidacao. Achado do parecer do escritorio sobre a 7a Alteracao Biomassa Chaparini.'

# 3. EIRELI -------------------------------------------------------------------
Test-Padrao '\bEIRELI\b' `
    'ALERTA' 'eireli' 'Mencao a EIRELI. O tipo foi extinto e convertido em sociedade limitada unipessoal pela Lei 14.382/2022.'

# 4. Quorum de 3/4 anterior a Lei 14.451/2022 ---------------------------------
Test-Padrao '(3/4|tr[êe]s quartos).{0,140}(modifica[çc][ãa]o do contrato|altera[çc][ãa]o contratual|incorpora[çc][ãa]o|fus[ãa]o|dissolu[çc][ãa]o)|(modifica[çc][ãa]o do contrato|altera[çc][ãa]o contratual).{0,140}(3/4|tr[êe]s quartos)' `
    'CONFERIR' 'quorum-14451' 'Quorum de 3/4 associado a alteracao contratual ou operacao societaria. Desde a Lei 14.451/2022 o quorum LEGAL e mais da metade do capital (art. 1.076). Eleva-lo e licito, mas tem de ser escolha consciente — nao heranca de modelo antigo.'

# 5-7. Competencia dos socios atribuida a administradores ---------------------
Test-Padrao 'delibera[çc][õo]es\s+sociais\s+ser[ãa]o\s+tomadas\s+p(or|elos)\s+.{0,40}administrador' `
    'ERRO' 'competencia' 'Deliberacoes sociais atribuidas aos ADMINISTRADORES. As materias do art. 1.071 (alteracao contratual, operacoes societarias, contas, exclusao, lucros) sao privativas dos SOCIOS — a clausula e nula nessa parte. Defeito real da consolidacao V Power Energia Solar.'
Test-Padrao 'dissolvida\s+pela\s+delibera[çc][ãa]o\s+dos\s+administradores|liquida[çc][ãa]o.{0,60}delibera[çc][ãa]o\s+dos\s+administradores' `
    'ERRO' 'competencia' 'Dissolucao deliberada por administradores. E materia de socios (arts. 1.071, VI, e 1.076).'
Test-Padrao 'administradores.{0,80}promover(em)?\s+a\s+exclus[ãa]o' `
    'ERRO' 'competencia' 'Exclusao de socio promovida por administradores. O art. 1.085 exige deliberacao de socios que representem mais da metade do capital.'

# 8. Silencio como anuencia ---------------------------------------------------
Test-Padrao 'sil[êe]ncio.{0,100}(anu[êe]ncia|anuir|concord[âa]ncia|aceita)' `
    'ALERTA' 'anuencia-tacita' 'Silencio tratado como anuencia. A regra da casa e a inversa: silencio e RECUSA. Como esta, quem nao le a notificacao perde a sociedade para um terceiro (defeito da XXVIII Alteracao Megga Distribuidora).'

# 9. Tempo verbal futuro na consolidacao --------------------------------------
if ($plano -match 'CONSOLIDA[ÇC][ÃA]O') {
    Test-Padrao 'passar[áa]\s+a\s+ser|passar[ãa]o\s+a\s+ser' `
        'ALERTA' 'tempo-verbal' 'Futuro na consolidacao. No corpo da alteracao o ato se consuma ("o capital E elevado"); na consolidacao o estado e presente ("o capital E de"). A XXVIII Alteracao Megga diz "passa a ser" no corpo e "passara a ser" na consolidacao.'
}

# 10. Capital integralizado x cronograma de integralizacao --------------------
if ($plano -match 'totalmente\s+integraliz' -and
    $plano -match '(ser[áa]|a ser|ser[ãa]o)\s+integralizad|integraliza[çc][ãa]o\s+se\s+dar[áa]|aportes\s+.{0,60}a\s+serem\s+realizados') {
    Add-Achado 'ERRO' 'capital-contraditorio' 'O instrumento afirma capital "totalmente integralizado" E, em outro ponto, estabelece cronograma futuro de integralizacao. Contradicao direta — defeito real da consolidacao V Power: a Clausula V parcela aportes ate 2030 e a Clausula VII diz "em ja estando totalmente integralizado".'
}

# 11. Remissoes internas quebradas --------------------------------------------
$ordExt = @{
    'PRIMEIRA' = 1; 'SEGUNDA' = 2; 'TERCEIRA' = 3; 'QUARTA' = 4; 'QUINTA' = 5
    'SEXTA' = 6; 'SÉTIMA' = 7; 'SETIMA' = 7; 'OITAVA' = 8; 'NONA' = 9
    'DÉCIMA' = 10; 'DECIMA' = 10
}
$defClaus = New-Object 'System.Collections.Generic.HashSet[string]'
$defCap   = New-Object 'System.Collections.Generic.HashSet[string]'
$defItem  = New-Object 'System.Collections.Generic.HashSet[string]'

foreach ($l in $linhas) {
    $t = $l.Trim()
    if ($t -match '(?i)^\**\s*CL[ÁA]USULA\s+(\d+)\s*[ªº]?') {
        [void]$defClaus.Add($Matches[1])
    } elseif ($t -match '(?i)^\**\s*CL[ÁA]USULA\s+([A-ZÁÉÍÓÚÂÊÔÃÕÇ]+)') {
        $k = $Matches[1].ToUpperInvariant()
        if ($ordExt.ContainsKey($k)) { [void]$defClaus.Add([string]$ordExt[$k]) }
    }
    if ($t -match '(?i)^\**\s*CAP[ÍI]TULO\s+([IVXLC]+)\b') { [void]$defCap.Add($Matches[1].ToUpperInvariant()) }
    if ($t -match '^\**\s*(\d+(?:\.\d+)+)\s*[\.\-)]')      { [void]$defItem.Add($Matches[1]) }
    if ($t -match '^\**\s*(\d+)\s*[\.\-)]\s')              { [void]$defItem.Add($Matches[1]) }
}

for ($i = 0; $i -lt $linhas.Count; $i++) {
    foreach ($m in [regex]::Matches($linhas[$i], '(?i)\bcl[áa]usula\s+(\d+)\s*[ªº]')) {
        $alvo = $m.Groups[1].Value
        if ($defClaus.Count -gt 0 -and -not $defClaus.Contains($alvo)) {
            Add-Achado 'ERRO' 'remissao' "Remissao a Clausula $alvo, que nao existe no instrumento. Defeito classico de minuta reaproveitada — a Minuta de Acordo de Socios da casa remete, dentro da Clausula 7a, a 'esta Clausula 6a'." ($i + 1) $linhas[$i]
        }
    }
    foreach ($m in [regex]::Matches($linhas[$i], '(?i)\bcap[íi]tulo\s+([IVXLC]+)\b')) {
        $alvo = $m.Groups[1].Value.ToUpperInvariant()
        # Sem o segundo ramo, o defeito da Megga escapa: aquele instrumento
        # remete ao "Capitulo XV" e nao tem capitulo nenhum, entao defCap
        # fica vazio e a checagem seria pulada justamente onde importa.
        if ($defCap.Count -eq 0 -or -not $defCap.Contains($alvo)) {
            Add-Achado 'ERRO' 'remissao' "Remissao ao Capitulo $alvo, que nao existe no instrumento. A XXVIII Alteracao Megga remete tres vezes a um 'Capitulo XV' inexistente." ($i + 1) $linhas[$i]
        }
    }
    foreach ($m in [regex]::Matches($linhas[$i], '(?i)\bitem\s+(\d+(?:\.\d+)+)')) {
        $alvo = $m.Groups[1].Value
        if ($defItem.Count -gt 0 -and -not $defItem.Contains($alvo)) {
            Add-Achado 'ALERTA' 'remissao' "Remissao ao item $alvo, que nao aparece numerado no instrumento." ($i + 1) $linhas[$i]
        }
    }
}

# 12. Numeracao decimal que regride ou repete ---------------------------------
$seq = @()
for ($i = 0; $i -lt $linhas.Count; $i++) {
    # (?!\d) impede que o subitem "2.4.1." case como se fosse o item "2.4".
    # Aceita "11.8. Texto", "1.1 - Texto" e "4.8 Texto". O (?!\d) impede que
    # o subitem "2.4.1." case como se fosse o item "2.4".
    if ($linhas[$i].Trim() -match '^\**\s*(\d+)\.(\d+)(?!\d)\s*[\.\-–)]?\s') {
        $seq += [pscustomobject]@{ Maior = [int]$Matches[1]; Menor = [int]$Matches[2]; Linha = $i + 1; Txt = $linhas[$i] }
    }
}
for ($k = 1; $k -lt $seq.Count; $k++) {
    $a = $seq[$k - 1]
    $b = $seq[$k]
    if ($b.Maior -lt $a.Maior -and ($a.Maior - $b.Maior) -le 3 -and $b.Menor -gt $a.Menor) {
        Add-Achado 'ERRO' 'numeracao' "Numeracao regride: $($a.Maior).$($a.Menor) seguido de $($b.Maior).$($b.Menor). A Minuta de Acordo de Socios da casa vai de 11.8 para 10.9 e volta para 11.10." $b.Linha $b.Txt
    }
    if ($b.Maior -eq $a.Maior -and $b.Menor -eq $a.Menor) {
        Add-Achado 'ALERTA' 'numeracao' "Item $($b.Maior).$($b.Menor) aparece duas vezes." $b.Linha $b.Txt
    }
}

# 13. Buraco na sequencia de clausulas ----------------------------------------
if ($defClaus.Count -gt 2) {
    $nums = @($defClaus | ForEach-Object { [int]$_ } | Sort-Object)
    $falt = @()
    for ($n = $nums[0]; $n -le $nums[-1]; $n++) { if ($nums -notcontains $n) { $falt += $n } }
    if ($falt.Count -gt 0) {
        Add-Achado 'ALERTA' 'numeracao' ("Sem cabecalho proprio: Clausula(s) " + ($falt -join ', ') + ". A consolidacao Lawletter perdeu a numeracao das clausulas e a alteracao seguinte remete a 'Clausula 45a', que nao existe mais no texto.")
    }
}

# 14. Extenso que nao bate com o algarismo ------------------------------------
$ptBR = [Globalization.CultureInfo]::GetCultureInfo('pt-BR')
for ($i = 0; $i -lt $linhas.Count; $i++) {
    foreach ($m in [regex]::Matches($linhas[$i], 'R\$\s*([\d]{1,3}(?:\.\d{3})*(?:,\d{2})?)\s*\(([^)]{3,120})\)')) {
        $numTxt = $m.Groups[1].Value
        $achouTxt = $m.Groups[2].Value
        if ($achouTxt -match '(?i)^\s*(extenso|valor|inserir|\.)') { continue }
        try { $val = [decimal]::Parse($numTxt, [Globalization.NumberStyles]::Number, $ptBR) } catch { continue }
        $espA = ConvertTo-ChaveExtenso (Convert-ReaisExtenso $val)
        $espB = ConvertTo-ChaveExtenso (Convert-ReaisExtenso $val -UmMil)
        $achou = ConvertTo-ChaveExtenso $achouTxt
        $achouSM = ($achou -replace '\s*(reais|real|centavos|centavo)$', '').Trim()
        $espSM   = ($espA  -replace '\s*(reais|real|centavos|centavo)$', '').Trim()
        if ($achou -ne $espA -and $achou -ne $espB -and $achouSM -ne $espSM) {
            Add-Achado 'ERRO' 'extenso' "Extenso nao bate com o algarismo. Escrito: R$ $numTxt ($achouTxt). Correto: $(Convert-ReaisExtenso $val). A XXII Alteracao da Distribuidora de Gas Correa foi arquivada com 'R$ 350.000,00 (quinhentos mil reais)'." ($i + 1) $m.Value
        }
    }
    foreach ($m in [regex]::Matches($linhas[$i], '(?<![\d,.])([\d]{1,3}(?:\.\d{3})*)\s*\(([^)]{3,110})\)\s*(quotas|cotas|dias|meses|anos|parcelas|presta[çc][õo]es)')) {
        $numTxt = $m.Groups[1].Value
        $achouTxt = $m.Groups[2].Value
        if ($achouTxt -match '(?i)^\s*(extenso|inserir|\.)') { continue }
        try { $val = [long]([decimal]::Parse($numTxt, [Globalization.NumberStyles]::Number, $ptBR)) } catch { continue }
        $espA = ConvertTo-ChaveExtenso (Convert-InteiroExtenso $val)
        $espB = ConvertTo-ChaveExtenso (Convert-InteiroExtenso $val -UmMil)
        $achou = ConvertTo-ChaveExtenso $achouTxt
        if ($achou -ne $espA -and $achou -ne $espB) {
            Add-Achado 'ERRO' 'extenso' "Extenso nao bate com o algarismo. Escrito: $numTxt ($achouTxt) $($m.Groups[3].Value). Correto: $(Convert-InteiroExtenso $val)." ($i + 1) $m.Value
        }
    }
}

# 15. Nomes proprios com grafia divergente ------------------------------------
function Get-Distancia {
    param([string]$A, [string]$B)
    $n = $A.Length
    $m = $B.Length
    if ($n -eq 0) { return $m }
    if ($m -eq 0) { return $n }
    $d = New-Object 'int[,]' ($n + 1), ($m + 1)
    for ($i = 0; $i -le $n; $i++) { $d[$i, 0] = $i }
    for ($j = 0; $j -le $m; $j++) { $d[0, $j] = $j }
    for ($i = 1; $i -le $n; $i++) {
        for ($j = 1; $j -le $m; $j++) {
            # PS 5.1 nao parseia $d[($i-1), $j] dentro de chamada de metodo:
            # le a virgula como construtor de array. Indices em variaveis.
            $im1 = $i - 1
            $jm1 = $j - 1
            $custo = 1
            if ($A[$im1] -eq $B[$jm1]) { $custo = 0 }
            $del = $d[$im1, $j] + 1
            $ins = $d[$i, $jm1] + 1
            $sub = $d[$im1, $jm1] + $custo
            $min = $del
            if ($ins -lt $min) { $min = $ins }
            if ($sub -lt $min) { $min = $sub }
            $d[$i, $j] = $min
        }
    }
    return $d[$n, $m]
}

$nomes = New-Object 'System.Collections.Generic.HashSet[string]'
foreach ($m in [regex]::Matches($plano, '\b([A-ZÁÉÍÓÚÂÊÔÃÕÇ]{3,}(?:\s+(?:D[AEO]S?|E)\s+|\s+)[A-ZÁÉÍÓÚÂÊÔÃÕÇ]{3,}(?:(?:\s+(?:D[AEO]S?|E)\s+|\s+)[A-ZÁÉÍÓÚÂÊÔÃÕÇ]{3,})*)\b')) {
    $n = ($m.Groups[1].Value -replace '\s+', ' ').Trim()
    if ($n -match '(?i)\b(LTDA|CNPJ|NIRE|JUNTA|COMERCIAL|C[ÓO]DIGO|CIVIL|CL[ÁA]USULA|CAP[ÍI]TULO|SOCIAL|CONTRATO|ALTERA[ÇC][ÃA]O|CONSOLIDA[ÇC][ÃA]O|TOTAL|S[ÓO]CIOS?|ADMINISTRADOR|PAR[ÁA]GRAFO|ANEXO|ESTADO|JUCETINS)\b') { continue }
    if (($n -split ' ').Count -lt 2) { continue }
    [void]$nomes.Add($n)
}
$arr = @($nomes)
for ($i = 0; $i -lt $arr.Count; $i++) {
    for ($j = $i + 1; $j -lt $arr.Count; $j++) {
        if ([math]::Abs($arr[$i].Length - $arr[$j].Length) -gt 2) { continue }
        $dist = Get-Distancia $arr[$i] $arr[$j]
        if ($dist -ge 1 -and $dist -le 2) {
            Add-Achado 'ALERTA' 'grafia-nome' "Duas grafias proximas do mesmo nome: '$($arr[$i])' e '$($arr[$j])'. A XXII Alteracao da Distribuidora de Gas qualifica 'ITELVINO CORREA NETTO' e assina 'ITELVINO CORREA NETO'; a Junta faz exigencia."
        }
    }
}

# 16. Foro ---------------------------------------------------------------------
$foros = New-Object 'System.Collections.Generic.HashSet[string]'
foreach ($m in [regex]::Matches($plano, '(?i)foro\s+d[ao]\s+(?:Comarca\s+d[eo]\s+|Cidade\s+d[eo]\s+)?([A-ZÁÉÍÓÚÂÊÔÃÕÇ][\p{L}\s\-]{2,40}?)\s*[\/,\.]')) {
    [void]$foros.Add(($m.Groups[1].Value -replace '\s+', ' ').Trim())
}
if ($foros.Count -gt 1) {
    Add-Achado 'ERRO' 'foro' ("Mais de um foro eleito no mesmo instrumento: " + (@($foros) -join ' | ') + ".")
} elseif ($foros.Count -eq 1) {
    Add-Achado 'CONFERIR' 'foro' ("Foro eleito: " + (@($foros)[0]) + ". Confirme que e a comarca pretendida — a Minuta de Acordo de Socios da casa carrega 'foro da Cidade de Recife/PE' herdado do modelo de origem.")
}
if ($plano -match '(?i)arbitrag' -and $plano -match '(?i)elegem\s+o\s+foro|fica\s+eleito\s+o\s+foro') {
    Add-Achado 'ALERTA' 'foro' 'Clausula compromissoria de arbitragem convivendo com eleicao de foro. Escolha uma.'
}

# 17. Declaracao de desimpedimento ---------------------------------------------
if ($tipo -eq 'contrato' -and
    $plano -match '(?i)administra[çc][ãa]o\s+d[ae]\s+sociedade|administrador' -and
    $plano -notmatch '(?i)(n[ãa]o\s+est[ãa]o?\s+impedid|declara.{0,80}impedid|impedid[oa]s?\s+de\s+exercer)') {
    Add-Achado 'ERRO' 'desimpedimento' 'Nao ha declaracao de desimpedimento do administrador (art. 1.011, par. 1o, do Codigo Civil). E condicao de arquivamento e a exigencia mais comum da Junta.'
}

# 18. Partilha do passivo -------------------------------------------------------
Test-Padrao 'passivo\s+ser[áa]\s+distribu[íi]do\s+entre\s+os\s+s[óo]cios' `
    'ERRO' 'liquidacao' 'Na liquidacao, o que se partilha e o ACERVO REMANESCENTE, nao o passivo. Como esta, a clausula contradiz a limitacao de responsabilidade do art. 1.052 (defeito da XXVIII Alteracao Megga).'

# 19. Regencia supletiva malformada --------------------------------------------
Test-Padrao 'C[óo]digo\s+Civil.{0,60}regem\s+a\s+Sociedade\s+An[ôo]nima' `
    'ERRO' 'regencia' 'O Codigo Civil nao disciplina sociedade anonima. A escolha do art. 1.053 e binaria: silencio (normas da sociedade simples) ou clausula expressa pela Lei 6.404/1976.'

# 20. Objeto social sem CNAE ----------------------------------------------------
if ($tipo -eq 'contrato' -and $plano -match '(?i)objeto\s+social' -and $plano -notmatch '\d{4}-\d/\d{2}|\d{2}\.\d{2}-\d-\d{2}') {
    Add-Achado 'ALERTA' 'cnae' 'Objeto social sem codigo CNAE. A Junta confere o objeto contra a viabilidade (Redesim/DBE), e CNAE incompativel com a atividade real gera risco fiscal e de emissao de nota — achado do parecer Biomassa Chaparini.'
}

# 21. Integralizacao em bens sem art. 1.055, par. 1o ---------------------------
if ($plano -match '(?i)integraliz.{0,200}(bens|ve[íi]culos?|im[óo]ve(l|is)|maquin[áa]rio|equipamento)' -and $plano -notmatch '1\.?055') {
    Add-Achado 'ALERTA' 'bens' 'Integralizacao em bens sem mencao ao art. 1.055, par. 1o (responsabilidade solidaria dos socios pela exata estimacao, por 5 anos) nem a laudo de avaliacao. O parecer Biomassa Chaparini recomenda a clausula expressa.'
}

# 22. Prazo impossivel ----------------------------------------------------------
Test-Padrao 'balan[çc]o\s+anual\s+at[ée]\s+31\s+de\s+dezembro' `
    'ALERTA' 'prazo' 'Balanco do exercicio encerrado em 31/12 com prazo de entrega ate 31/12: impossivel de cumprir (defeito da consolidacao V Power).'

# ------------------------------------------------------------------- saida ---

$ordem = @{ 'ERRO' = 0; 'ALERTA' = 1; 'CONFERIR' = 2 }
$lista = @($achados | Sort-Object @{ Expression = { $ordem[$_.Severidade] } }, Linha)
if ($SoErros) { $lista = @($lista | Where-Object { $_.Severidade -eq 'ERRO' }) }

$nErro = @($achados | Where-Object { $_.Severidade -eq 'ERRO' }).Count
$nAler = @($achados | Where-Object { $_.Severidade -eq 'ALERTA' }).Count
$nConf = @($achados | Where-Object { $_.Severidade -eq 'CONFERIR' }).Count

if ($Json) {
    $texto = [pscustomobject]@{
        arquivo   = (Resolve-Path -LiteralPath $Caminho).Path
        erros     = $nErro
        alertas   = $nAler
        conferir  = $nConf
        aprovado  = ($nErro -eq 0)
        achados   = $lista
    } | ConvertTo-Json -Depth 5
} else {
    $sb = New-Object System.Text.StringBuilder
    $nl = [Environment]::NewLine
    $add = { param([string]$T = '') [void]$sb.Append($T).Append($nl) }

    & $add "# Conferencia de instrumento societario"
    & $add ''
    & $add "**Arquivo:** $([IO.Path]::GetFileName($Caminho))"
    & $add ''
    & $add "**Linhas analisadas:** $($linhas.Count)"
    & $add ''
    & $add "**Resultado:** $nErro ERRO | $nAler ALERTA | $nConf CONFERIR"
    & $add ''

    if ($lista.Count -eq 0) {
        & $add 'Nenhuma constatacao mecanica. Isso NAO dispensa referencias/controle-de-qualidade.md — o script pega o que e automatico, nao o que exige juizo.'
    } else {
        $sevAtual = ''
        foreach ($a in $lista) {
            if ($a.Severidade -ne $sevAtual) {
                $sevAtual = $a.Severidade
                & $add ''
                & $add "## $sevAtual"
                & $add ''
            }
            $loc = ''
            if ($a.Linha -gt 0) { $loc = " _(linha $($a.Linha))_" }
            & $add "- **[$($a.Regra)]**$loc $($a.Texto)"
            if ($a.Trecho) { & $add "  > $($a.Trecho)" }
        }
    }
    & $add ''
    & $add '---'
    & $add 'Conferencia mecanica. O crivo completo esta em `referencias/controle-de-qualidade.md`.'
    $texto = $sb.ToString()
}

if ($Saida) {
    [IO.File]::WriteAllText($Saida, $texto, (New-Object System.Text.UTF8Encoding($false)))
    Write-Host "Gravado em $Saida"
} else {
    Write-Output $texto
}

if ($nErro -gt 0) { exit 1 }
exit 0
