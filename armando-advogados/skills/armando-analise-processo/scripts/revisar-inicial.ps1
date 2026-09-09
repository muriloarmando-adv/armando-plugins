<#
.SYNOPSIS
  Varredura mecanica de peca antes do protocolo — Armando Advogados.

.DESCRIPTION
  Automatiza os itens 1 e 2 do controle de qualidade da skill armando-peticao-inicial:
  residuo de trabalho deixado no corpo, identificadores divergentes entre ocorrencias,
  numeracao de secoes quebrada, marca de grifo sem grifo e ausencia de valor da causa.

  Nao substitui a leitura da peca. Pega o que a leitura humana deixa passar.

.PARAMETER Path
  Caminho do .docx, .md ou .txt da peca.

.EXAMPLE
  .\revisar-inicial.ps1 -Path "C:\Users\muril\Downloads\inicial.docx"
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, Position = 0)][string]$Path
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'lib-peca.ps1')

$texto = Get-TextoDaPeca -Path $Path
$linhas = $texto -split "`r?`n"
$achados = @()

# ---------------------------------------------------------------- 1. Residuo
# Padroes efetivamente encontrados no acervo do escritorio.
$residuos = @(
    @{ Regex = 'x{4,}';                                      Msg = 'Placeholder "xxxx" no corpo (ja foi protocolado no lugar do valor da causa)' }
    @{ Regex = 'PROCURAR\s+UMA\s+JURISPRUD';                 Msg = 'Marcacao de pesquisa pendente deixada no corpo' }
    @{ Regex = '^\s*MinutaIA\s*$';                           Msg = 'Cabecalho "MinutaIA" na primeira linha' }
    @{ Regex = '\[\s*\.{3,}\s*\]';                           Msg = 'Campo [......] nao preenchido' }
    @{ Regex = '\.{6,}';                                     Msg = 'Sequencia de pontos — qualificacao ou campo incompleto' }
    @{ Regex = '\bDocs?\.\s*\d+\s*a\s*XX\b';                 Msg = 'Rol de documentos com "a XX" nao fechado' }
    @{ Regex = '^\s*PRINT\s*$';                              Msg = 'Marcador PRINT onde deveria haver imagem' }
    @{ Regex = '\bTODO\b|\bTO-?DO:';                         Msg = 'Marcador TODO' }
    @{ Regex = '\bLOREM IPSUM\b';                            Msg = 'Texto de preenchimento' }
    @{ Regex = '\bINSERIR\b|\bPREENCHER\b|\bCONFERIR\b\s*$'; Msg = 'Instrucao de trabalho no corpo' }
    @{ Regex = '\[A CONFIRMAR\]';                            Msg = 'Campo marcado como a confirmar' }
)

for ($i = 0; $i -lt $linhas.Count; $i++) {
    $linha = $linhas[$i]
    if ([string]::IsNullOrWhiteSpace($linha)) { continue }
    foreach ($r in $residuos) {
        if ($linha -match $r.Regex) {
            $trecho = $linha.Trim()
            if ($trecho.Length -gt 110) { $trecho = $trecho.Substring(0, 110) + '...' }
            $achados += New-Achado -Severidade 'ALTA' -Categoria 'Residuo' `
                -Mensagem ("{0} (linha {1})" -f $r.Msg, ($i + 1)) -Trecho $trecho
        }
    }
}

# ------------------------------------------- 2. Identificadores quase iguais
# Numeros CNJ e codigos alfanumericos (auto de infracao, termo de embargo).
function Test-GrupoDivergente {
    param([string[]]$Itens, [string]$Rotulo, [int]$MaxDistancia)

    $unicos = @($Itens | Sort-Object -Unique)
    $saida = @()
    for ($i = 0; $i -lt $unicos.Count; $i++) {
        for ($j = $i + 1; $j -lt $unicos.Count; $j++) {
            $d = Get-DistanciaEdicao $unicos[$i] $unicos[$j]
            if ($d -ge 1 -and $d -le $MaxDistancia) {
                $saida += New-Achado -Severidade 'ALTA' -Categoria 'Identificador' `
                    -Mensagem ("{0} com grafias divergentes na mesma peca — provavel erro de digitacao" -f $Rotulo) `
                    -Trecho ("{0}   vs.   {1}" -f $unicos[$i], $unicos[$j])
            }
        }
    }
    return $saida
}

$cnj = @([regex]::Matches($texto, '\d{7}-\d{2}\.\d{4}\.\d\.\d{2}\.\d{4}') | ForEach-Object { $_.Value })
if ($cnj.Count -gt 1) {
    $achados += Test-GrupoDivergente -Itens $cnj -Rotulo 'Numero de processo' -MaxDistancia 2
}

# Codigos tipo OKHDP2LX / QWUND71C / EGRVP0NE: 6 a 10 caracteres, maiusculas com digito.
$codigos = @([regex]::Matches($texto, '\b(?=[A-Z0-9]{6,10}\b)(?=[A-Z0-9]*\d)(?=[A-Z0-9]*[A-Z])[A-Z0-9]{6,10}\b') |
    ForEach-Object { $_.Value })
$ignorar = @('SISBAJUD', 'RENAJUD', 'CPFMF', 'CNPJMF')
$codigos = @($codigos | Where-Object { $ignorar -notcontains $_ })
if ($codigos.Count -gt 1) {
    $achados += Test-GrupoDivergente -Itens $codigos -Rotulo 'Codigo (auto/termo/protocolo)' -MaxDistancia 1
}

# CPF e CNPJ divergentes
$cpfs = @([regex]::Matches($texto, '\b\d{3}\.\d{3}\.\d{3}-\d{2}\b') | ForEach-Object { $_.Value })
if ($cpfs.Count -gt 1) { $achados += Test-GrupoDivergente -Itens $cpfs -Rotulo 'CPF' -MaxDistancia 1 }
$cnpjs = @([regex]::Matches($texto, '\b\d{2}\.\d{3}\.\d{3}/\d{4}-\d{2}\b') | ForEach-Object { $_.Value })
if ($cnpjs.Count -gt 1) { $achados += Test-GrupoDivergente -Itens $cnpjs -Rotulo 'CNPJ' -MaxDistancia 1 }

# ------------------------------------------------- 3. Numeracao das secoes
$romanos = @{ 'I' = 1; 'II' = 2; 'III' = 3; 'IV' = 4; 'V' = 5; 'VI' = 6; 'VII' = 7; 'VIII' = 8;
              'IX' = 9; 'X' = 10; 'XI' = 11; 'XII' = 12; 'XIII' = 13; 'XIV' = 14; 'XV' = 15 }

$sequencia = @()
foreach ($linha in $linhas) {
    $t = $linha.Trim()
    if ($t -match '^(I{1,3}|IV|VI{0,3}|IX|XI{0,3}|XIV|XV)\s*[\.\-\u2013\u2014]\s*\S') {
        $r = $Matches[1]
        if ($romanos.ContainsKey($r)) { $sequencia += $romanos[$r] }
    }
}

if ($sequencia.Count -ge 2) {
    for ($i = 1; $i -lt $sequencia.Count; $i++) {
        $ant = $sequencia[$i - 1]
        $atu = $sequencia[$i]
        if ($atu -eq $ant) {
            $achados += New-Achado -Severidade 'MEDIA' -Categoria 'Numeracao' `
                -Mensagem ("Secao {0} aparece duas vezes seguidas" -f $atu)
        }
        elseif ($atu -ne ($ant + 1)) {
            $achados += New-Achado -Severidade 'MEDIA' -Categoria 'Numeracao' `
                -Mensagem ("Salto na numeracao de secoes: {0} seguida de {1}" -f $ant, $atu)
        }
    }
}

# ------------------------------------------------------ 4. Marca de grifo
$marcas = @([regex]::Matches($texto, '\((?:grifos?\s+(?:nossos?|meu|do\s+autor)|grifei|grifamos|destacou-se|destaquei)\)', 'IgnoreCase')).Count
if ($marcas -gt 0) {
    $achados += New-Achado -Severidade 'BAIXA' -Categoria 'Grifo' `
        -Mensagem ("{0} marca(s) de grifo na peca — confira se cada uma corresponde a destaque efetivo no trecho transcrito" -f $marcas)
}

# ------------------------------------------------- 5. Fechos obrigatorios
if ($texto -notmatch '(?i)(d[aá]-se\s+[aà]\s+causa|dar-se-[aá]\s+a\s+causa|atribui(?:-se)?\s+[aà]\s+causa|valor\s+da\s+causa)') {
    $achados += New-Achado -Severidade 'ALTA' -Categoria 'Requisito' `
        -Mensagem 'Valor da causa nao localizado (art. 319, V, do CPC)'
}
if ($texto -notmatch '(?i)(pede\s+deferimento|pedem\s+deferimento)') {
    $achados += New-Achado -Severidade 'MEDIA' -Categoria 'Requisito' `
        -Mensagem 'Fecho "pede deferimento" nao localizado'
}
if ($texto -notmatch '(?i)(em\s+s[ií]ntese,\s+os\s+fatos|s[aã]o\s+esses,\s+em\s+s[ií]ntese)') {
    $achados += New-Achado -Severidade 'BAIXA' -Categoria 'Padrao da casa' `
        -Mensagem 'Fecho da secao de fatos ausente ("Em sintese, os fatos.")'
}
if ($texto -notmatch '(?i)concilia[cç][aã]o') {
    $achados += New-Achado -Severidade 'MEDIA' -Categoria 'Requisito' `
        -Mensagem 'Opcao sobre audiencia de conciliacao nao declarada (art. 319, VII, do CPC)'
}
if ($texto -notmatch '(?i)(OAB/[A-Z]{2}\s*\d)') {
    $achados += New-Achado -Severidade 'ALTA' -Categoria 'Requisito' `
        -Mensagem 'Bloco de assinaturas sem inscricao na OAB'
}
if ($texto -match '(?i)OAB/SP\s*125\.?510') {
    $achados += New-Achado -Severidade 'ALTA' -Categoria 'Assinatura' `
        -Mensagem 'OAB/SP 125.510 — o correto para Sandro Henrique Armando e 128.510'
}

# -------------------------------------------------- 6. Forma inaudita altera
$parte = @([regex]::Matches($texto, '(?i)inaudita\s+altera\s+parte')).Count
$pars = @([regex]::Matches($texto, '(?i)inaudita\s+altera\s+pars')).Count
if ($parte -gt 0 -and $pars -gt 0) {
    $achados += New-Achado -Severidade 'BAIXA' -Categoria 'Forma' `
        -Mensagem ("Peca mistura 'inaudita altera parte' ({0}x) e 'inaudita altera pars' ({1}x) — padronize" -f $parte, $pars)
}

$codigo = Write-Relatorio -Achados $achados -Titulo ("Revisao mecanica: " + (Split-Path $Path -Leaf))
Write-Host 'Lembrete: ementa, tese e cabimento continuam exigindo leitura. Este script so cobre o mecanico.' -ForegroundColor DarkGray
Write-Host ''
exit $codigo
