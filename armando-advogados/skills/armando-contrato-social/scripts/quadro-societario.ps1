#Requires -Version 5.1
<#
.SYNOPSIS
    Fecha, confere e redige o quadro societario de uma sociedade limitada.

.DESCRIPTION
    Recebe capital social, valor nominal da quota e a lista de socios (por
    numero de quotas OU por percentual) e devolve:

      1. um diagnostico com os erros que reprovam o instrumento na Junta
         Comercial (quotas que nao fecham, capital indivisivel pelo valor
         nominal, percentual que nao totaliza 100%, integralizacao parcial
         sem prazo);
      2. a tabela do quadro societario pronta para colar;
      3. a clausula do capital social no padrao do escritorio, com todos os
         valores por extenso.

    O extenso e gerado por algoritmo, nao copiado do precedente. Esse e o
    ponto: o acervo do escritorio tem extenso errado em instrumento ja
    arquivado (a XXII Alteracao da Distribuidora de Gas Correa registra
    "O aumento de R$ 350.000,00 (quinhentos mil reais)").

.PARAMETER Arquivo
    Caminho de um .json com o quadro. Ver exemplo-quadro.json.

.PARAMETER Rapido
    Alternativa ao .json para conferencia de bolso. Formato:
      "NOME:55; OUTRO NOME:45"            -> por percentual
      "NOME:36300q; OUTRO NOME:29700q"    -> por quotas (sufixo q)
    Exige -Capital. -ValorQuota assume R$ 1,00 se omitido.

.PARAMETER Capital
    Capital social total, em reais. Sobrepoe o valor do .json.

.PARAMETER ValorQuota
    Valor nominal de cada quota. Padrao: 1,00.

.PARAMETER RazaoSocial
    Nome empresarial, usado no cabecalho da saida.

.PARAMETER Clausula
    Numero/rotulo da clausula do capital na minuta. Padrao: "[N]".

.PARAMETER Saida
    Grava o resultado em arquivo .md em vez de so imprimir.

.PARAMETER UmMil
    Escreve "um mil" em vez de "mil" (uso corrente nos instrumentos da casa:
    "no valor de R$ 1.000,00 (um mil reais)").

.PARAMETER Json
    Emite o resultado como JSON, para consumo por outro script.

.EXAMPLE
    .\quadro-societario.ps1 exemplo-quadro.json

.EXAMPLE
    .\quadro-societario.ps1 -Rapido "HENRIQUE ROCHA ARMANDO:55; FELIPE C. CHADUD JORGE:25; SER MAIS CRIATIVO HOLDING LTDA:10; FC SOLUCOES EMPRESARIAIS LTDA:10" -Capital 66000

.NOTES
    Este arquivo precisa estar gravado em UTF-8 COM BOM. O Windows
    PowerShell 5.1 le .ps1 sem BOM como ANSI e corrompe os acentos do
    extenso ("tres" vira "trÃªs" na minuta).
#>
[CmdletBinding()]
param(
    [Parameter(Position = 0)][string]$Arquivo,
    [string]$Rapido,
    [decimal]$Capital = 0,
    [decimal]$ValorQuota = 0,
    [string]$RazaoSocial,
    [string]$Clausula = '[N]',
    [string]$Saida,
    [switch]$UmMil,
    [switch]$Json
)

$ErrorActionPreference = 'Stop'
try { [Console]::OutputEncoding = New-Object System.Text.UTF8Encoding($false) } catch { }
$ptBR = [Globalization.CultureInfo]::GetCultureInfo('pt-BR')

# ---------------------------------------------------------------- extenso ---

$Uni      = @('', 'um', 'dois', 'três', 'quatro', 'cinco', 'seis', 'sete', 'oito', 'nove')
$Adolesc  = @('dez', 'onze', 'doze', 'treze', 'quatorze', 'quinze', 'dezesseis', 'dezessete', 'dezoito', 'dezenove')
$Dezenas  = @('', '', 'vinte', 'trinta', 'quarenta', 'cinquenta', 'sessenta', 'setenta', 'oitenta', 'noventa')
$Centenas = @('', 'cento', 'duzentos', 'trezentos', 'quatrocentos', 'quinhentos', 'seiscentos', 'setecentos', 'oitocentos', 'novecentos')
$Escalas  = @(
    @{ Sing = '';         Plur = '' },
    @{ Sing = 'mil';      Plur = 'mil' },
    @{ Sing = 'milhão';   Plur = 'milhões' },
    @{ Sing = 'bilhão';   Plur = 'bilhões' },
    @{ Sing = 'trilhão';  Plur = 'trilhões' }
)

function Convert-GrupoExtenso {
    param([int]$N)
    if ($N -eq 0)   { return '' }
    if ($N -eq 100) { return 'cem' }
    $c = [int][math]::Floor($N / 100)
    $r = $N % 100
    $partes = @()
    if ($c -gt 0) { $partes += $Centenas[$c] }
    if ($r -gt 0) {
        if ($r -lt 10) {
            $partes += $Uni[$r]
        } elseif ($r -lt 20) {
            $partes += $Adolesc[$r - 10]
        } else {
            $d = [int][math]::Floor($r / 10)
            $u = $r % 10
            if ($u -gt 0) { $partes += ($Dezenas[$d] + ' e ' + $Uni[$u]) }
            else          { $partes += $Dezenas[$d] }
        }
    }
    return ($partes -join ' e ')
}

function Convert-InteiroExtenso {
    param([long]$N)
    if ($N -lt 0)  { return 'menos ' + (Convert-InteiroExtenso ([math]::Abs($N))) }
    if ($N -eq 0)  { return 'zero' }

    $vals = @()
    $resto = $N
    while ($resto -gt 0) {
        $vals += [int]($resto % 1000)
        $resto = [long][math]::Floor($resto / 1000)
    }
    if ($vals.Count -gt $Escalas.Count) { throw "Valor fora da faixa suportada pelo extenso: $N" }

    $partes = @()
    for ($i = $vals.Count - 1; $i -ge 0; $i--) {
        $v = $vals[$i]
        if ($v -eq 0) { continue }
        $txt = Convert-GrupoExtenso $v
        if ($i -eq 1) {
            if ($v -eq 1) { if ($UmMil) { $txt = 'um mil' } else { $txt = 'mil' } }
            else          { $txt = "$txt mil" }
        } elseif ($i -ge 2) {
            if ($v -eq 1) { $txt = 'um ' + $Escalas[$i].Sing }
            else          { $txt = $txt + ' ' + $Escalas[$i].Plur }
        }
        $partes += ,@($txt, $v)
    }

    $saida = $partes[0][0]
    for ($k = 1; $k -lt $partes.Count; $k++) {
        $v = $partes[$k][1]
        $ultimo = ($k -eq $partes.Count - 1)
        if ($ultimo -and ($v -lt 100 -or ($v % 100) -eq 0)) { $saida = "$saida e "  + $partes[$k][0] }
        else                                                { $saida = "$saida, " + $partes[$k][0] }
    }
    return $saida
}

function Convert-ReaisExtenso {
    param([decimal]$V)
    $neg = $V -lt 0
    $V = [math]::Abs($V)
    $inteiro = [long][math]::Truncate($V)
    $cent = [int][math]::Round(($V - $inteiro) * 100, 0)
    if ($cent -eq 100) { $inteiro++; $cent = 0 }

    $p = @()
    if ($inteiro -gt 0 -or $cent -eq 0) {
        $u = 'reais'; if ($inteiro -eq 1) { $u = 'real' }
        $p += (Convert-InteiroExtenso $inteiro) + " $u"
    }
    if ($cent -gt 0) {
        $u = 'centavos'; if ($cent -eq 1) { $u = 'centavo' }
        $p += (Convert-InteiroExtenso $cent) + " $u"
    }
    $r = $p -join ' e '
    if ($neg) { $r = "menos $r" }
    return $r
}

function Format-Real   { param([decimal]$V) return $V.ToString('N2', $ptBR) }
function Format-Inteiro{ param([long]$V)    return $V.ToString('N0', $ptBR) }

function Format-Percentual {
    param([decimal]$P)
    $arred = [math]::Round($P, 4)
    if ($arred -eq [math]::Truncate($arred)) { return ([long]$arred).ToString('N0', $ptBR) }
    return $arred.ToString('0.####', $ptBR)
}

# ------------------------------------------------------------------ entrada ---

$erros  = New-Object System.Collections.ArrayList
$avisos = New-Object System.Collections.ArrayList

# Aceita "33,3333" (pt-BR) e "33.3333" (invariante). Com os dois separadores,
# o ponto e milhar e a virgula e decimal: "1.234,56".
function ConvertTo-Decimal {
    param([string]$S)
    $S = $S.Trim()
    if ($S -match '\.' -and $S -match ',') { $S = ($S -replace '\.', '') -replace ',', '.' }
    elseif ($S -match ',')                 { $S = $S -replace ',', '.' }
    return [decimal]::Parse($S, [Globalization.NumberStyles]::Float, [Globalization.CultureInfo]::InvariantCulture)
}

$dados = $null
if ($Rapido) {
    $socios = @()
    foreach ($item in ($Rapido -split ';')) {
        $item = $item.Trim()
        if (-not $item) { continue }
        $i = $item.LastIndexOf(':')
        if ($i -lt 1) { throw "Item invalido em -Rapido: '$item'. Use NOME:55 ou NOME:36300q" }
        $nome = $item.Substring(0, $i).Trim()
        $val  = $item.Substring($i + 1).Trim()
        if ($val -match '^(?<n>[\d\.,]+)\s*q$') {
            $socios += [pscustomobject]@{ nome = $nome; quotas = [long](($Matches['n'] -replace '\.', '') -replace ',', '') }
        } else {
            $socios += [pscustomobject]@{ nome = $nome; percentual = (ConvertTo-Decimal ($val -replace '%', '')) }
        }
    }
    $dados = [pscustomobject]@{ socios = $socios }
} elseif ($Arquivo) {
    if (-not (Test-Path -LiteralPath $Arquivo)) { throw "Arquivo nao encontrado: $Arquivo" }
    $dados = [IO.File]::ReadAllText((Resolve-Path -LiteralPath $Arquivo), [Text.Encoding]::UTF8) | ConvertFrom-Json
} else {
    throw 'Informe um .json (posicional) ou -Rapido "NOME:55; OUTRO:45" -Capital <valor>.'
}

function Get-Campo {
    param($Obj, [string]$Nome)
    if ($null -eq $Obj) { return $null }
    $p = $Obj.PSObject.Properties[$Nome]
    if ($p) { return $p.Value }
    return $null
}

if (-not $RazaoSocial) { $RazaoSocial = [string](Get-Campo $dados 'razaoSocial') }
$cnpj = [string](Get-Campo $dados 'cnpj')
if ($Capital    -le 0) { $v = Get-Campo $dados 'capital';    if ($null -ne $v) { $Capital    = [decimal]$v } }
if ($ValorQuota -le 0) { $v = Get-Campo $dados 'valorQuota'; if ($null -ne $v) { $ValorQuota = [decimal]$v } }
if ($ValorQuota -le 0) { $ValorQuota = 1 }
$prazoInteg = [string](Get-Campo $dados 'prazoIntegralizacao')

$listaSocios = @(Get-Campo $dados 'socios')
if ($listaSocios.Count -eq 0) { throw 'Nenhum socio informado.' }
if ($Capital -le 0) { throw 'Capital social nao informado (use -Capital ou o campo "capital" do .json).' }

# ------------------------------------------------------------------ calculo ---

$totalQuotasDec = $Capital / $ValorQuota
$totalQuotas = [long][math]::Round($totalQuotasDec, 0)
if ([math]::Abs($totalQuotasDec - $totalQuotas) -gt 0.0000001) {
    [void]$erros.Add("O capital de R$ $(Format-Real $Capital) nao e divisivel pelo valor nominal de R$ $(Format-Real $ValorQuota): resultaria em $($totalQuotasDec.ToString('0.####', $ptBR)) quotas. Quota fracionaria e vedada (art. 1.056 do Codigo Civil).")
    $totalQuotas = [long][math]::Floor($totalQuotasDec)
}

$linhas = @()
foreach ($s in $listaSocios) {
    $nome = [string](Get-Campo $s 'nome')
    if (-not $nome) { [void]$erros.Add('Ha socio sem nome na lista.'); $nome = '[......]' }

    $qRaw = Get-Campo $s 'quotas'
    $pRaw = Get-Campo $s 'percentual'
    $quotas = $null
    $pctDeclarado = $null

    if ($null -ne $pRaw) { $pctDeclarado = [decimal]$pRaw }

    if ($null -ne $qRaw) {
        $quotas = [long]$qRaw
    } elseif ($null -ne $pctDeclarado) {
        $qDec = $totalQuotas * $pctDeclarado / 100
        $quotas = [long][math]::Round($qDec, 0)
        if ([math]::Abs($qDec - $quotas) -gt 0.0000001) {
            [void]$erros.Add("$nome`: $(Format-Percentual $pctDeclarado)% de $(Format-Inteiro $totalQuotas) quotas da $($qDec.ToString('0.####', $ptBR)) quotas — nao e numero inteiro. Ajuste o capital, o valor nominal ou o percentual.")
        }
    } else {
        [void]$erros.Add("$nome`: informe 'quotas' ou 'percentual'.")
        $quotas = 0
    }

    if ($quotas -le 0) { [void]$avisos.Add("$nome`: participacao de $(Format-Inteiro $quotas) quotas. Socio sem quota nao integra o quadro societario.") }

    $integ = Get-Campo $s 'integralizado'
    $valorSocio = $quotas * $ValorQuota
    if ($null -eq $integ) { $integ = $valorSocio } else { $integ = [decimal]$integ }
    if ($integ -gt $valorSocio) {
        [void]$erros.Add("$nome`: integralizado (R$ $(Format-Real $integ)) maior que o subscrito (R$ $(Format-Real $valorSocio)).")
    }

    $pctReal = 0
    if ($totalQuotas -gt 0) { $pctReal = [decimal]$quotas * 100 / $totalQuotas }
    if ($null -ne $pctDeclarado -and [math]::Abs($pctReal - $pctDeclarado) -gt 0.0001) {
        [void]$avisos.Add("$nome`: percentual declarado $(Format-Percentual $pctDeclarado)% diverge do calculado $(Format-Percentual $pctReal)%. Prevaleceu o numero de quotas.")
    }

    $linhas += [pscustomobject]@{
        Nome          = $nome
        Quotas        = $quotas
        Percentual    = $pctReal
        Valor         = $valorSocio
        Integralizado = $integ
    }
}

$somaQuotas = 0L; foreach ($l in $linhas) { $somaQuotas += $l.Quotas }
$somaValor  = 0.0; foreach ($l in $linhas) { $somaValor  += $l.Valor }
$somaInteg  = 0.0; foreach ($l in $linhas) { $somaInteg  += $l.Integralizado }

if ($somaQuotas -ne $totalQuotas) {
    $dif = $somaQuotas - $totalQuotas
    $sinal = 'a mais'; if ($dif -lt 0) { $sinal = 'a menos' }
    [void]$erros.Add("As quotas dos socios somam $(Format-Inteiro $somaQuotas), mas o capital de R$ $(Format-Real $Capital) comporta $(Format-Inteiro $totalQuotas) quotas de R$ $(Format-Real $ValorQuota) — $(Format-Inteiro ([math]::Abs($dif))) quota(s) $sinal.")
}

# So faz sentido cobrar prazo de integralizacao se a aritmetica do capital ja
# fechou — senao o saldo "a integralizar" e apenas eco do erro anterior.
$capitalConsistente = ($somaQuotas -eq $totalQuotas -and $erros.Count -eq 0)
$aIntegralizar = $Capital - $somaInteg
if ($aIntegralizar -gt 0.004 -and $capitalConsistente) {
    if (-not $prazoInteg) {
        [void]$erros.Add("Ha R$ $(Format-Real $aIntegralizar) de capital subscrito e nao integralizado, mas o campo 'prazoIntegralizacao' esta vazio. O contrato precisa dizer o prazo e o modo de realizacao (art. 997, IV, do Codigo Civil).")
    } else {
        [void]$avisos.Add("Capital parcialmente integralizado: falta R$ $(Format-Real $aIntegralizar), com prazo ate $prazoInteg. Confira se a clausula de responsabilidade solidaria pela integralizacao (art. 1.052) esta no instrumento.")
    }
}

if ($linhas.Count -eq 1) {
    [void]$avisos.Add('Sociedade unipessoal. Confira: nome empresarial encerrado em "LTDA" (a sigla "SLU" nao e obrigatoria), dispensa das clausulas de cessao/preferencia/quorum entre socios, e as regras dos §§ 1o e 2o do art. 1.052 do Codigo Civil.')
}

$pjSemRep = @()
foreach ($s in $listaSocios) {
    $nome = [string](Get-Campo $s 'nome')
    $tipo = [string](Get-Campo $s 'tipo')
    $rep  = [string](Get-Campo $s 'representante')
    if ($rep -match '^\[\.*\]$') { $rep = '' }
    if (($tipo -eq 'PJ' -or $nome -match '(?i)\b(LTDA|S\.?A\.?|EIRELI|PARTICIPACOES|PARTICIPAÇÕES|HOLDING)\b') -and -not $rep) {
        $pjSemRep += $nome
    }
}
if ($pjSemRep.Count -gt 0) {
    [void]$avisos.Add("Socio(s) pessoa juridica sem representante indicado: $($pjSemRep -join '; '). A qualificacao de PJ exige denominacao, CNPJ, sede e o representante que assina.")
}

# ------------------------------------------------------------------- saida ---

$nl = [Environment]::NewLine
$sb = New-Object System.Text.StringBuilder

function Add-Linha { param([string]$T = '') [void]$sb.Append($T).Append($nl) }

$titulo = 'QUADRO SOCIETARIO'
if ($RazaoSocial) { $titulo = "$titulo — $RazaoSocial" }
Add-Linha "# $titulo"
if ($cnpj) { Add-Linha; Add-Linha "CNPJ $cnpj" }
Add-Linha

Add-Linha '## Diagnostico'
Add-Linha
if ($erros.Count -eq 0 -and $avisos.Count -eq 0) {
    Add-Linha 'OK — o quadro fecha. Quotas, percentuais e valores sao consistentes.'
} else {
    foreach ($e in $erros)  { Add-Linha "- ERRO: $e" }
    foreach ($a in $avisos) { Add-Linha "- AVISO: $a" }
}
Add-Linha

Add-Linha '## Tabela'
Add-Linha
Add-Linha '| SOCIO | QUOTAS | % | VALOR (R$) |'
Add-Linha '| :--- | ---: | ---: | ---: |'
foreach ($l in $linhas) {
    Add-Linha "| $($l.Nome) | $(Format-Inteiro $l.Quotas) | $(Format-Percentual $l.Percentual) | $(Format-Real $l.Valor) |"
}
$pctTotal = 0; if ($totalQuotas -gt 0) { $pctTotal = [decimal]$somaQuotas * 100 / $totalQuotas }
Add-Linha "| **TOTAL** | **$(Format-Inteiro $somaQuotas)** | **$(Format-Percentual $pctTotal)** | **$(Format-Real $somaValor)** |"
Add-Linha

Add-Linha '## Clausula do capital social'
Add-Linha
Add-Linha "CLAUSULA $Clausula - DO CAPITAL SOCIAL"
Add-Linha
$capExt   = Convert-ReaisExtenso $Capital
$qtdExt   = Convert-InteiroExtenso $totalQuotas
$vqExt    = Convert-ReaisExtenso $ValorQuota
if ($aIntegralizar -gt 0.004) {
    $intExt  = Convert-ReaisExtenso $somaInteg
    $saldExt = Convert-ReaisExtenso $aIntegralizar
    $prazo = $prazoInteg; if (-not $prazo) { $prazo = '[......]' }
    Add-Linha "O capital social e de R$ $(Format-Real $Capital) ($capExt), dividido em $(Format-Inteiro $totalQuotas) ($qtdExt) quotas, no valor nominal de R$ $(Format-Real $ValorQuota) ($vqExt) cada, totalmente subscritas pelos socios e integralizadas em R$ $(Format-Real $somaInteg) ($intExt) em moeda corrente nacional, obrigando-se os socios a integralizar o saldo de R$ $(Format-Real $aIntegralizar) ($saldExt), em moeda corrente nacional, ate $prazo, assim distribuido:"
} else {
    Add-Linha "O capital social e de R$ $(Format-Real $Capital) ($capExt), dividido em $(Format-Inteiro $totalQuotas) ($qtdExt) quotas, no valor nominal de R$ $(Format-Real $ValorQuota) ($vqExt) cada, totalmente subscritas e integralizadas em moeda corrente nacional, assim distribuidas entre os socios:"
}
Add-Linha
Add-Linha '[inserir a tabela acima]'
Add-Linha
Add-Linha 'Paragrafo unico - A responsabilidade de cada socio e restrita ao valor de suas quotas, mas todos respondem solidariamente pela integralizacao do capital social (art. 1.052 do Codigo Civil).'
Add-Linha

Add-Linha '## Extenso conferido'
Add-Linha
Add-Linha "- Capital: R$ $(Format-Real $Capital) — **$capExt**"
Add-Linha "- Quotas: $(Format-Inteiro $totalQuotas) — **$qtdExt**"
Add-Linha "- Valor nominal: R$ $(Format-Real $ValorQuota) — **$vqExt**"
foreach ($l in $linhas) {
    Add-Linha "- $($l.Nome): $(Format-Inteiro $l.Quotas) ($(Convert-InteiroExtenso $l.Quotas)) quotas — R$ $(Format-Real $l.Valor) ($(Convert-ReaisExtenso $l.Valor))"
}

$texto = $sb.ToString()

if ($Json) {
    $obj = [pscustomobject]@{
        razaoSocial     = $RazaoSocial
        cnpj            = $cnpj
        capital         = $Capital
        capitalExtenso  = $capExt
        valorQuota      = $ValorQuota
        totalQuotas     = $totalQuotas
        quotasExtenso   = $qtdExt
        aIntegralizar   = $aIntegralizar
        socios          = @($linhas | ForEach-Object {
            [pscustomobject]@{
                nome          = $_.Nome
                quotas        = $_.Quotas
                quotasExtenso = (Convert-InteiroExtenso $_.Quotas)
                percentual    = [math]::Round($_.Percentual, 4)
                valor         = $_.Valor
                valorExtenso  = (Convert-ReaisExtenso $_.Valor)
                integralizado = $_.Integralizado
            }
        })
        erros           = @($erros)
        avisos          = @($avisos)
        fecha           = ($erros.Count -eq 0)
    }
    $texto = $obj | ConvertTo-Json -Depth 5
}

if ($Saida) {
    [IO.File]::WriteAllText($Saida, $texto, (New-Object System.Text.UTF8Encoding($false)))
    Write-Host "Gravado em $Saida"
} else {
    Write-Output $texto
}

if ($erros.Count -gt 0) { exit 1 }
exit 0
