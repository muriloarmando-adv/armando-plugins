<#
.SYNOPSIS
  Varredura mecanica de contestacao trabalhista antes do protocolo — Armando Advogados.

.DESCRIPTION
  Automatiza o controle de qualidade da skill armando-contestacao-trabalhista.
  As travas foram calibradas sobre os defeitos efetivamente encontrados nas
  64 contestacoes do acervo do escritorio (agosto/2026) — nao sao hipoteses.

  Cobre sete classes de falha:
    1. Referencia legal revogada ou superada  (art. 333 do CPC em 39 pecas)
    2. Residuo de reaproveitamento            ("Vejamos:" orfao em 32 pecas)
    3. Concordancia de genero do reclamante   (misturada em 41 pecas)
    4. Identificador de advogado              (OAB trocada em 16 pecas)
    5. Modulo de merito sem fecho de improcedencia  (inversao de sentido)
    6. Numeracao de secoes e alineas quebrada
    7. Requisitos formais da defesa trabalhista

  Nao substitui a leitura da peca. Pega o que a leitura humana deixa passar.

.PARAMETER Path
  Caminho do .docx, .md ou .txt da contestacao.

.PARAMETER Pedidos
  Opcional. Lista dos pedidos deduzidos na inicial, em palavras-chave
  (ex.: 'insalubridade','horas extras','dano moral'). Quando informada, o script
  confere se ha modulo de merito sem pedido correspondente e vice-versa.

.EXAMPLE
  .\revisar-contestacao.ps1 -Path "C:\Users\muril\Downloads\contestacao.docx"
.EXAMPLE
  .\revisar-contestacao.ps1 -Path ".\contestacao.docx" -Pedidos 'rescisao indireta','insalubridade','dano moral'
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, Position = 0)][string]$Path,
    [string[]]$Pedidos = @()
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'lib-peca.ps1')

$texto  = Get-TextoDaPeca -Path $Path
$linhas = $texto -split "`r?`n"
$achados = @()

function Add-Achado($sev, $cat, $msg, $trecho = '') {
    $script:achados += New-Achado -Severidade $sev -Categoria $cat -Mensagem $msg -Trecho $trecho
}

# =====================================================================
# 1. REFERENCIA LEGAL REVOGADA OU SUPERADA
# =====================================================================
# Propagam-se por copia e nunca sao relidas. Grep deterministico e a unica
# defesa que funciona: o redator nao releria o boilerplate de qualquer modo.
$revogados = @(
    @{ Regex = '(?i)\b333\s*,\s*(do\s+)?CPC\b|(?i)art(igo)?\.?\s*333\s+(do\s+)?CPC'
       Sev = 'ALTA'
       Msg = 'Art. 333 do CPC — dispositivo do CPC/1973, revogado. O onus da prova e o art. 373 do CPC/2015. (39 das 64 pecas do acervo trazem este erro.)' }

    @{ Regex = '(?i)art(igo)?\.?\s*384\s+(da\s+)?CLT'
       Sev = 'ALTA'
       Msg = 'Art. 384 da CLT (intervalo da mulher antes da hora extra) — revogado pela Lei 13.467/2017.' }

    @{ Regex = '(?i)(homologa[çc][ãa]o|assist[êe]ncia)\s+(do\s+)?sindica(l|to)[^.]{0,80}(rescis|resciso|verbas)'
       Sev = 'MEDIA'
       Msg = 'Homologacao/assistencia sindical na rescisao — os §§1º e 3º do art. 477 da CLT foram revogados pela Lei 13.467/2017.' }

    @{ Regex = '(?i)S[úu]mulas?\s*219\s*e\s*329'
       Sev = 'MEDIA'
       Msg = 'Sumulas 219 e 329 do TST invocadas para limitar honorarios: sao verbetes de honorarios ASSISTENCIAIS, anteriores ao art. 791-A da CLT, e nao limitam a sucumbencia da Reforma. (42 das 64 pecas do acervo.) Suprimir, salvo razao concreta.' }

    @{ Regex = '(?i)(OJ|Orienta[çc][ãa]o\s+Jurisprudencial)\s*n?[ºo]?\s*348'
       Sev = 'MEDIA'
       Msg = 'OJ 348 da SBDI-1 — mesma origem assistencial das Sumulas 219/329; nao serve de teto ao art. 791-A.' }

    @{ Regex = '(?i)declara[çc][ãa]o\s+de\s+pobreza'
       Sev = 'MEDIA'
       Msg = 'Terminologia anterior a Reforma. O regime atual e o do art. 790, §§3º e 4º, da CLT (comprovacao de insuficiencia).' }
)

# Notas de redacao do modelo CITAM os dispositivos revogados para alertar sobre
# eles. Escanear linha a linha e pular a nota evita o falso positivo que ensina
# o usuario a ignorar o script.
$corpoUtil = ($linhas | Where-Object { $_ -notmatch '^\s*>?\s*\[(NOTA|ATEN|M[OÓ]DULO|CONFERIR|RENUMERAR)' }) -join "`n"
foreach ($r in $revogados) {
    $m = [regex]::Matches($corpoUtil, $r.Regex)
    if ($m.Count -gt 0) {
        $t = $m[0].Value.Trim()
        Add-Achado $r.Sev 'Lei revogada' ("{0} — {1} ocorrencia(s)." -f $r.Msg, $m.Count) $t
    }
}

# =====================================================================
# 2. RESIDUO DE REAPROVEITAMENTO
# =====================================================================
$residuos = @(
    @{ Regex = '(?i)^\s*vejamos\s*:?\s*$'; Sev='ALTA';  Msg='"Vejamos:" sem nada depois — a imagem, o print ou a transcricao nao foi colada. (32 das 64 pecas do acervo.)' }
    @{ Regex = '(?i)\bn[ãa]o\s+comprovem\s+os\s+fatos'; Sev='MEDIA'; Msg='"nao comprovem os fatos" — deve ser "nao COMPROVAM". (17 das 64 pecas do acervo.)' }
    @{ Regex = '\b([aoAO]|[Dd]a|[Dd]o|[àÀ])\s+Executad[oa]\b'; Sev='MEDIA'; Msg='"Executada/Executado" em peca de fase de conhecimento — residuo de peca de execucao. (8 das 64 pecas do acervo.)' }
    @{ Regex = '(?i)nesses\s+termos,?\s+pede\s+deferimento'; Sev='MEDIA'; Msg='Fecho "Nesses termos, pede deferimento" no meio da peca — residuo de modulo colado. Manter apenas um fecho, ao final.' }
    @{ Regex = '\{\{[^}]+\}\}'; Sev='ALTA'; Msg='Placeholder {{ }} nao substituido.' }
    @{ Regex = '(?i)\[(MODULO|MÓDULO|NOTA DE USO|ATEN[ÇC][ÃA]O|CONFERIR|RENUMERAR)'; Sev='ALTA'; Msg='Nota de redacao do modelo nao suprimida.' }
    @{ Regex = '\[\s*\.{3,}\s*\]|\.{6,}'; Sev='ALTA'; Msg='Campo nao preenchido.' }
    @{ Regex = '(?i)\bx{4,}\b'; Sev='ALTA'; Msg='Placeholder "xxxx" no corpo.' }
    @{ Regex = '(?i)\bTODO\b|\bINSERIR\b|\bPREENCHER\b'; Sev='ALTA'; Msg='Instrucao de trabalho deixada no corpo.' }
)

for ($i = 0; $i -lt $linhas.Count; $i++) {
    $l = $linhas[$i]
    if ([string]::IsNullOrWhiteSpace($l)) { continue }
    foreach ($r in $residuos) {
        if ($l -match $r.Regex) {
            $t = $l.Trim(); if ($t.Length -gt 100) { $t = $t.Substring(0,100) + '...' }
            Add-Achado $r.Sev 'Residuo' ("{0} (linha {1})" -f $r.Msg, ($i+1)) $t
        }
    }
}

# =====================================================================
# 3. CONCORDANCIA DE GENERO DO RECLAMANTE
# =====================================================================
# Nao da para saber o genero certo por regex — mas da para saber que a peca
# usa os dois, e isso e sempre erro.
$masc = @([regex]::Matches($texto, '(?i)\b(o|ao|do|pelo)\s+Reclamante\b')).Count
$fem  = @([regex]::Matches($texto, '(?i)\b(a|à|da|pela)\s+Reclamante\b')).Count
if ($masc -gt 0 -and $fem -gt 0) {
    $menor = [Math]::Min($masc, $fem)
    $sev = if ($menor -ge 3) { 'ALTA' } else { 'MEDIA' }
    Add-Achado $sev 'Concordancia' ("Peca mistura 'o Reclamante' ({0}x) e 'a Reclamante' ({1}x). Padronize pelo genero real da parte. (41 das 64 pecas do acervo.)" -f $masc, $fem)
}
$admM = @([regex]::Matches($texto, '(?i)foi\s+admitido\b')).Count
$admF = @([regex]::Matches($texto, '(?i)foi\s+admitida\b')).Count
if ($admM -gt 0 -and $admF -gt 0) {
    Add-Achado 'ALTA' 'Concordancia' "Peca diz 'foi admitido' e 'foi admitida' — herdado de peca anterior."
}

# =====================================================================
# 4. IDENTIFICADOR DE ADVOGADO
# =====================================================================
# Registro fechado. Assinar sob inscricao alheia e o defeito mais grave do
# acervo: 16 pecas protocoladas com a OAB do Dr. Henrique sob o nome do Dr. Lucas.
$registro = @(
    @{ Nome='HENRIQUE ROCHA ARMANDO';            OAB='OAB/TO 10.167' }
    @{ Nome='SANDRO HENRIQUE ARMANDO';           OAB='OAB/TO 11.459-A e OAB/SP 128.510' }
    @{ Nome='LUCAS ALMEIDA MONTEIRO';            OAB='OAB/DF 70.224' }
    @{ Nome='MAIANE LUKARINE';                   OAB='OAB/TO 11.661' }
    @{ Nome='BRUNO OTAVIO PEREIRA ALVES';        OAB='OAB/TO 4.893' }
    @{ Nome='RAQUEL XAVIER MENDES';              OAB='OAB/DF 70.204' }
    @{ Nome='QUINTILIANA JANIS CARDOSO MARQUES'; OAB='OAB/TO 9.272' }
)

if ($texto -match '(?is)LUCAS\s+A.{0,25}MONTEIRO.{0,60}?OAB/TO\s*10\.?167') {
    Add-Achado 'ALTA' 'Assinatura' 'Dr. Lucas Almeida Monteiro assinando sob OAB/TO 10.167 — esse registro e do Dr. Henrique Rocha Armando. A OAB do Dr. Lucas e OAB/DF 70.224. (16 das 64 pecas do acervo trazem este erro.)'
}
if ($texto -match '(?i)OAB/SP\s*125\.?510') {
    Add-Achado 'ALTA' 'Assinatura' 'OAB/SP 125.510 — o registro do Dr. Sandro Henrique Armando e 128.510. (52 pecas trabalhistas do acervo trazem o numero errado; as civeis trazem o certo.)'
}
if ($texto -match '(?i)OAB/DF\s*70\.?224' -and $texto -match '(?i)RAQUEL') {
    Add-Achado 'BAIXA' 'Assinatura' 'Conferir: OAB/DF 70.224 e do Dr. Lucas; a Dra. Raquel Xavier Mendes e OAB/DF 70.204. Os numeros diferem em um digito.'
}
if ($texto -notmatch '(?i)OAB/[A-Z]{2}\s*\d') {
    Add-Achado 'ALTA' 'Assinatura' 'Bloco de assinaturas sem inscricao na OAB.'
}

# =====================================================================
# 5. MODULO DE MERITO SEM FECHO DE IMPROCEDENCIA
# =====================================================================
# Esta e a trava contra INVERSAO DE SENTIDO. Uma peca do acervo afirma
# "verifica-se a pertinencia do pleito autoral consoante a indenizacao por dano
# moral" — concedendo exatamente o que pretendia negar. Regex nao le sentido,
# mas le estrutura: todo modulo de merito da casa fecha pedindo improcedencia.
# Modulo que nao fecha assim e suspeito e vai para leitura dirigida.
    $fechoOk = '(?i)(improced|indefer|rejeit|desconsiderad|descabid|incab[íi]vel|indevid|afastad|rechac|inexist|n[ãa]o\s+(prosper|proced|merec|assiste|havendo|sendo\s+devid|h[áa]\s+que\s+se\s+falar)|sem\s+raz[ãa]o|excluir?\s+do\s+polo)'

$idxMerito = -1
for ($i = 0; $i -lt $linhas.Count; $i++) {
    if ($linhas[$i] -match '(?i)^\s*#*\s*(I+V?|V I*|[0-9]+)?\s*[-–.]?\s*(QUANTO\s+AO\s+M[ÉE]RITO|NO\s+M[ÉE]RITO|DO\s+M[ÉE]RITO|M[ÉE]RITO)\s*$') { $idxMerito = $i; break }
}

if ($idxMerito -lt 0) {
    Add-Achado 'MEDIA' 'Estrutura' 'Nao localizei a secao "QUANTO AO MERITO". Confira a arquitetura da peca.'
} else {
    # titulo = linha curta, sem minusculas, com pelo menos 5 letras
    # A secao de merito termina no proximo algarismo romano de topo (IV, V, VI...).
    # Sem esse limite o script trata 'DOS HONORARIOS' e 'DOS PEDIDOS' como modulo
    # de merito e exige deles um fecho de improcedencia que nao lhes cabe.
    $fimMerito = $linhas.Count
    for ($i = $idxMerito + 1; $i -lt $linhas.Count; $i++) {
        if ($linhas[$i] -match '^\s*#*\s*(IV|V|VI|VII|VIII|IX|X)\s*[-\u2013]\s') { $fimMerito = $i; break }
    }

    $titulos = @()
    for ($i = $idxMerito + 1; $i -lt $fimMerito; $i++) {
        $l = ($linhas[$i] -replace '^\s*#+\s*', '').Trim()
        if ($l.Length -lt 6 -or $l.Length -gt 120) { continue }
        if ($l -cmatch '\p{Ll}') { continue }
        if (($l.ToCharArray() | Where-Object { [char]::IsLetter($_) }).Count -lt 5) { continue }
        if ($l -match '(?i)OAB|ARMANDO|MONTEIRO|RECLAMANTE:|RECLAMADA:') { continue }
        if ($l -match '\{\{|\}\}') { continue }
        $titulos += [pscustomobject]@{ Linha = $i; Texto = $l }
    }

    for ($k = 0; $k -lt $titulos.Count; $k++) {
        $ini = $titulos[$k].Linha
        $fim = if ($k + 1 -lt $titulos.Count) { $titulos[$k+1].Linha } else { [Math]::Min($ini + 25, $linhas.Count) }
        if ($fim - $ini -lt 2) { continue }   # titulo colado em titulo: subtitulo
        # O topico que apenas fixa o incontroverso (admissao, funcao, salario) nao
        # nega pedido algum — cobrar dele fecho de improcedencia so gera ruido.
        if ($titulos[$k].Texto -match '(?i)CONTRATO DE TRABALHO') { continue }
        $corpo = ($linhas[($ini+1)..($fim-1)] -join ' ')
        if ($corpo -notmatch $fechoOk) {
            Add-Achado 'ALTA' 'Sentido' ("Modulo de merito sem formula de improcedencia no corpo — ler a conclusao deste topico palavra por palavra. Ha peca no acervo que, aqui, CONCEDE o pedido que pretendia negar.") $titulos[$k].Texto
        }
    }

    if ($titulos.Count -eq 0) {
        Add-Achado 'MEDIA' 'Estrutura' 'Secao de merito sem topicos em caixa alta — confira a formatacao dos titulos.'
    }
}

# =====================================================================
# 6. NUMERACAO DE SECOES E ALINEAS
# =====================================================================
# Alineas do rol de pedidos: a) b) c) ... Saltar letra e sinal de modulo
# excluido sem renumerar (4 pecas do acervo).
$letras = [regex]::Matches($texto, '(?m)^\s*([a-z])\)\s') | ForEach-Object { $_.Groups[1].Value }
if ($letras.Count -ge 2) {
    for ($i = 1; $i -lt $letras.Count; $i++) {
        $ant = [int][char]$letras[$i-1]
        $atu = [int][char]$letras[$i]
        if ($atu -eq $ant) { continue }
        if ($atu -ne $ant + 1) {
            Add-Achado 'ALTA' 'Numeracao' ("Alineas do rol de pedidos saltam de '{0})' para '{1})' — modulo excluido sem renumerar." -f $letras[$i-1], $letras[$i])
            break
        }
    }
}

# Romanos das secoes
$rom = [regex]::Matches($texto, '(?m)^\s*(I{1,3}|IV|V|VI{1,3}|IX|X{1,2})\s*[-–]\s*[A-ZÀ-Ú]') | ForEach-Object { $_.Groups[1].Value }
if ($rom.Count -ge 2) {
    $mapa = @{'I'=1;'II'=2;'III'=3;'IV'=4;'V'=5;'VI'=6;'VII'=7;'VIII'=8;'IX'=9;'X'=10;'XI'=11;'XII'=12}
    for ($i = 1; $i -lt $rom.Count; $i++) {
        $a = $mapa[$rom[$i-1]]; $b = $mapa[$rom[$i]]
        if ($null -eq $a -or $null -eq $b) { continue }
        if ($b -ne $a -and $b -ne $a + 1) {
            Add-Achado 'MEDIA' 'Numeracao' ("Secoes saltam de '{0}' para '{1}'." -f $rom[$i-1], $rom[$i])
            break
        }
    }
}

# =====================================================================
# 7. REQUISITOS FORMAIS DA DEFESA TRABALHISTA
# =====================================================================
$requisitos = @(
    @{ Regex='(?i)artigo\s+847\s+da\s+CLT|art\.?\s*847'; Sev='ALTA';  Msg='Preambulo sem remissao ao art. 847 da CLT — formula da casa para oferecer contestacao.' }
    @{ Regex='(?i)art(igo)?\.?\s*830\s+da\s+CLT';        Sev='MEDIA'; Msg='Falta a declaracao de autenticidade dos documentos (art. 830 da CLT e art. 425, IV, do CPC).' }
    @{ Regex='(?i)prequestionad';                        Sev='BAIXA'; Msg='Falta o paragrafo de prequestionamento.' }
    @{ Regex='(?i)protesta\s+em\s+provar|protesto\s+por\s+prova'; Sev='MEDIA'; Msg='Falta o protesto por provas.' }
    @{ Regex='(?i)791-A';                                Sev='MEDIA'; Msg='Falta o pedido de honorarios de sucumbencia (art. 791-A da CLT).' }
    @{ Regex='(?i)data\s+e\s+hora\s+certificadas|de\s+20\d\d';     Sev='MEDIA'; Msg='Falta o fecho com local e data.' }
    @{ Regex='(?im)^\s*CONTESTA[ÇC][ÃA]O\s*$';            Sev='ALTA';  Msg='Falta o titulo CONTESTACAO isolado, entre o preambulo e o "aos termos da Reclamacao".' }
)
foreach ($r in $requisitos) {
    if ($texto -notmatch $r.Regex) { Add-Achado $r.Sev 'Requisito' $r.Msg }
}

# Impugnacao especificada — art. 341 do CPC / art. 302 antigo
if ($texto -notmatch '(?i)impugna') {
    Add-Achado 'ALTA' 'Requisito' 'A peca nao impugna nada expressamente. O onus da impugnacao especificada (art. 341 do CPC) torna incontroverso o fato nao impugnado.'
}

# =====================================================================
# 8. MODULO x PEDIDO  (so quando -Pedidos e informado)
# =====================================================================
$catalogo = @(
    @{ Chave='rescisao indireta';   Regex='(?i)rescis[ãa]o\s+indireta' }
    @{ Chave='verbas rescisorias';  Regex='(?i)verbas\s+rescis[óo]rias' }
    @{ Chave='horas extras';        Regex='(?i)horas\s+extras' }
    @{ Chave='intervalo';           Regex='(?i)intervalo\s+intrajornada' }
    @{ Chave='adicional noturno';   Regex='(?i)adicional\s+noturno' }
    @{ Chave='insalubridade';       Regex='(?i)insalubridade' }
    @{ Chave='periculosidade';      Regex='(?i)periculosidade' }
    @{ Chave='acumulo de funcao';   Regex='(?i)ac[úu]mulo\s+(de|e desvio de)\s+fun[çc][ãa]o' }
    @{ Chave='dano moral';          Regex='(?i)dano\s+moral' }
    @{ Chave='grupo economico';     Regex='(?i)grupo\s+econ[ôo]mico' }
    @{ Chave='doenca ocupacional';  Regex='(?i)doen[çc]a\s+ocupacional' }
    @{ Chave='estabilidade';        Regex='(?i)estabilidade\s+(provis[óo]ria|acident[áa]ria|gestante)' }
    @{ Chave='dispensa discriminatoria'; Regex='(?i)dispensa\s+discriminat[óo]ria' }
    @{ Chave='vinculo';             Regex='(?i)v[íi]nculo\s+empregat[íi]cio' }
    @{ Chave='FGTS';                Regex='(?i)\bFGTS\b' }
    @{ Chave='multa 467/477';       Regex='(?i)art(igos?)?\.?\s*467' }
    @{ Chave='PPP';                 Regex='(?i)\bPPP\b|profissiogr[áa]fico' }
    @{ Chave='comissoes';           Regex='(?i)comiss[õo]es' }
)

if ($Pedidos.Count -gt 0) {
    $norm = { param($s) ($s -replace '[^a-zA-Z ]','').ToLowerInvariant().Trim() }
    foreach ($c in $catalogo) {
        $presente = $texto -match $c.Regex
        $pedido = $false
        foreach ($p in $Pedidos) { if ((& $norm $p) -like ('*' + (& $norm $c.Chave).Split(' ')[0] + '*')) { $pedido = $true } }
        if ($presente -and -not $pedido) {
            Add-Achado 'ALTA' 'Modulo orfao' ("A peca trata de '{0}', mas isso nao consta da lista de pedidos informada. Modulo herdado de outra contestacao — excluir, sob pena de abrir discussao que o reclamante nao trouxe." -f $c.Chave)
        }
        if ($pedido -and -not $presente) {
            Add-Achado 'ALTA' 'Pedido sem defesa' ("Ha pedido de '{0}' na inicial e a peca nao o enfrenta. Fato nao impugnado e fato incontroverso (art. 341 do CPC)." -f $c.Chave)
        }
    }
} else {
    $detectados = @()
    foreach ($c in $catalogo) { if ($texto -match $c.Regex) { $detectados += $c.Chave } }
    if ($detectados.Count -gt 0) {
        Add-Achado 'BAIXA' 'Conferencia' ("Modulos detectados: {0}. Confira um a um se ha pedido correspondente na inicial. Rode de novo com -Pedidos para automatizar." -f ($detectados -join ', '))
    }
}

# =====================================================================
$codigo = Write-Relatorio -Achados $achados -Titulo ("Revisao de contestacao trabalhista: " + (Split-Path $Path -Leaf))

Write-Host 'Rode tambem, na mesma peca:' -ForegroundColor DarkGray
Write-Host '  extenso.ps1                 — confere cada par "R$ X (extenso)" digito a digito' -ForegroundColor DarkGray
Write-Host '  validar-identificadores.ps1 — digito verificador de CPF, CNPJ e numero CNJ' -ForegroundColor DarkGray
Write-Host ''
Write-Host 'O script nao le sentido: cabimento da tese, vigencia da sumula, adequacao do' -ForegroundColor DarkGray
Write-Host 'precedente e coerencia da defesa com a prova continuam exigindo leitura.' -ForegroundColor DarkGray
Write-Host ''
exit $codigo
