<#
.SYNOPSIS
  Valor por extenso em portugues e conferencia dos pares "R$ X (extenso)" da peca.

.DESCRIPTION
  Dois modos:
    -Valor  gera o extenso de um valor.
    -Path   varre a peca e confere se cada "R$ 13.173,13 (treze mil...)" bate.

  O padrao do escritorio exige algarismo seguido do extenso entre parenteses em
  todo valor. Este script pega o extenso que sobrou de uma versao anterior do
  calculo — o erro mais provavel ao reaproveitar peca.

.EXAMPLE
  .\extenso.ps1 -Valor 13173.13
.EXAMPLE
  .\extenso.ps1 -Path "C:\Users\muril\Downloads\inicial.docx"
#>
[CmdletBinding(DefaultParameterSetName = 'Valor')]
param(
    [Parameter(ParameterSetName = 'Valor', Mandatory = $true, Position = 0)][decimal]$Valor,
    [Parameter(ParameterSetName = 'Arquivo', Mandatory = $true)][string]$Path,
    [Parameter(ParameterSetName = 'Valor')][switch]$SemMoeda
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'lib-peca.ps1')

$UNI = @('', 'um', 'dois', 'tres', 'quatro', 'cinco', 'seis', 'sete', 'oito', 'nove',
         'dez', 'onze', 'doze', 'treze', 'quatorze', 'quinze', 'dezesseis', 'dezessete',
         'dezoito', 'dezenove')
$DEZ = @('', '', 'vinte', 'trinta', 'quarenta', 'cinquenta', 'sessenta', 'setenta', 'oitenta', 'noventa')
$CEN = @('', 'cento', 'duzentos', 'trezentos', 'quatrocentos', 'quinhentos', 'seiscentos',
         'setecentos', 'oitocentos', 'novecentos')

function ConvertTo-ExtensoGrupo {
    <# 1 a 999 por extenso. #>
    param([int]$n)

    if ($n -eq 0) { return '' }
    if ($n -eq 100) { return 'cem' }

    $partes = @()
    $c = [math]::Floor($n / 100)
    $resto = $n % 100

    if ($c -gt 0) { $partes += $CEN[$c] }

    if ($resto -gt 0) {
        if ($resto -lt 20) {
            $partes += $UNI[$resto]
        }
        else {
            $d = [math]::Floor($resto / 10)
            $u = $resto % 10
            if ($u -eq 0) { $partes += $DEZ[$d] }
            else { $partes += ($DEZ[$d] + ' e ' + $UNI[$u]) }
        }
    }
    return ($partes -join ' e ')
}

function ConvertTo-ExtensoInteiro {
    <# 0 a 999.999.999.999 por extenso, sem moeda. #>
    param([long]$n)

    if ($n -eq 0) { return 'zero' }

    $escalas = @(
        @{ Valor = 1000000000L; Sing = 'bilhao';  Plur = 'bilhoes' },
        @{ Valor = 1000000L;    Sing = 'milhao';  Plur = 'milhoes' },
        @{ Valor = 1000L;       Sing = 'mil';     Plur = 'mil' }
    )

    $blocos = @()
    $rest = $n

    foreach ($e in $escalas) {
        $q = [long][math]::Floor($rest / $e.Valor)
        if ($q -gt 0) {
            $txt = ConvertTo-ExtensoGrupo -n ([int]$q)
            if ($e.Sing -eq 'mil') {
                if ($q -eq 1) { $blocos += 'mil' } else { $blocos += ($txt + ' mil') }
            }
            else {
                if ($q -eq 1) { $blocos += ('um ' + $e.Sing) } else { $blocos += ($txt + ' ' + $e.Plur) }
            }
            $rest = $rest % $e.Valor
        }
    }

    if ($rest -gt 0) { $blocos += (ConvertTo-ExtensoGrupo -n ([int]$rest)) }

    # Regra do "e": liga o ultimo bloco quando ele e menor que 100 ou centena redonda.
    if ($blocos.Count -eq 1) { return $blocos[0] }

    $ultimo = $rest
    $cabeca = $blocos[0..($blocos.Count - 2)] -join ', '
    if ($ultimo -gt 0 -and ($ultimo -lt 100 -or ($ultimo % 100) -eq 0)) {
        return ($cabeca + ' e ' + $blocos[-1])
    }
    return ($cabeca + ', ' + $blocos[-1]) -replace ',\s*$', ''
}

function ConvertTo-Extenso {
    <# Valor monetario por extenso, no formato do escritorio. #>
    param([decimal]$v, [switch]$Puro)

    $neg = $v -lt 0
    if ($neg) { $v = -$v }

    $inteiro = [long][math]::Truncate($v)
    $cent = [int][math]::Round(($v - $inteiro) * 100, 0)
    if ($cent -eq 100) { $inteiro++; $cent = 0 }

    if ($Puro) { return (ConvertTo-ExtensoInteiro -n $inteiro) }

    $partes = @()
    if ($inteiro -gt 0 -or $cent -eq 0) {
        $moeda = 'reais'
        if ($inteiro -eq 1) { $moeda = 'real' }
        $partes += ((ConvertTo-ExtensoInteiro -n $inteiro) + ' ' + $moeda)
    }
    if ($cent -gt 0) {
        $c = 'centavos'
        if ($cent -eq 1) { $c = 'centavo' }
        $partes += ((ConvertTo-ExtensoInteiro -n $cent) + ' ' + $c)
    }

    $txt = $partes -join ' e '
    if ($neg) { $txt = 'menos ' + $txt }
    return $txt
}

function ConvertTo-Comparavel {
    <# Normaliza para comparar: minusculas, sem acento, sem pontuacao, espaco unico. #>
    param([string]$s)
    if ($null -eq $s) { return '' }
    $t = $s.ToLowerInvariant()
    $t = $t.Normalize([System.Text.NormalizationForm]::FormD)
    $sb = New-Object System.Text.StringBuilder
    foreach ($ch in $t.ToCharArray()) {
        if ([System.Globalization.CharUnicodeInfo]::GetUnicodeCategory($ch) -ne [System.Globalization.UnicodeCategory]::NonSpacingMark) {
            [void]$sb.Append($ch)
        }
    }
    $t = $sb.ToString()
    $t = $t -replace '[^a-z0-9 ]', ' '
    $t = $t -replace '\s+', ' '

    # Variantes igualmente corretas, para nao gerar falso positivo:
    $t = $t -replace '\bum mil\b', 'mil'          # "um mil duzentos" == "mil duzentos"
    $t = $t -replace '\bcatorze\b', 'quatorze'
    $t = $t -replace '\bseiscentas\b', 'seiscentos'
    $t = $t -replace '\bduzentas\b', 'duzentos'
    $t = $t -replace '\btrezentas\b', 'trezentos'
    $t = $t -replace '\bquatrocentas\b', 'quatrocentos'
    $t = $t -replace '\bquinhentas\b', 'quinhentos'
    $t = $t -replace '\bsetecentas\b', 'setecentos'
    $t = $t -replace '\boitocentas\b', 'oitocentos'
    $t = $t -replace '\bnovecentas\b', 'novecentos'
    $t = $t -replace '\bduas\b', 'dois'
    $t = $t -replace '\buma\b', 'um'

    return $t.Trim()
}

# ------------------------------------------------------------------ modo Valor
if ($PSCmdlet.ParameterSetName -eq 'Valor') {
    $ext = ConvertTo-Extenso -v $Valor -Puro:$SemMoeda
    if ($SemMoeda) {
        Write-Host $ext
    }
    else {
        $fmt = $Valor.ToString('N2', [System.Globalization.CultureInfo]::GetCultureInfo('pt-BR'))
        Write-Host ("R$ {0} ({1})" -f $fmt, $ext)
    }
    exit 0
}

# --------------------------------------------------------------- modo Arquivo
$texto = Get-TextoDaPeca -Path $Path
$achados = @()

# Pares "R$ 1.234,56 (extenso)" — o extenso pode atravessar quebra de linha.
$plano = $texto -replace '\s+', ' '
$rx = [regex]'R\$\s*([\d\.]+,\d{2}|\d+)\s*\(([^\)]{3,220})\)'
$pares = $rx.Matches($plano)

$conferidos = 0
foreach ($m in $pares) {
    $numTxt = $m.Groups[1].Value
    $extTxt = $m.Groups[2].Value

    # Ignora parenteses que nao sao extenso (ex.: "R$ 100,00 (doc. 5)").
    if ($extTxt -notmatch '(?i)(real|reais|centavo|mil|milh|bilh|zero|um|dois|tres|tr[eê]s)') { continue }

    $limpo = $numTxt -replace '\.', '' -replace ',', '.'
    [decimal]$v = 0
    # Cultura invariante: em pt-BR o ponto seria lido como separador de milhar.
    $okParse = [decimal]::TryParse(
        $limpo,
        [System.Globalization.NumberStyles]::Float,
        [System.Globalization.CultureInfo]::InvariantCulture,
        [ref]$v)
    if (-not $okParse) { continue }
    $conferidos++

    $esperado = ConvertTo-Extenso -v $v
    $a = ConvertTo-Comparavel $esperado
    $b = ConvertTo-Comparavel $extTxt

    if ($a -ne $b) {
        # Tolera ausencia da conjuncao "e" e virgulas de separacao.
        $a2 = ($a -replace '\be\b', '') -replace '\s+', ' '
        $b2 = ($b -replace '\be\b', '') -replace '\s+', ' '
        if ($a2.Trim() -ne $b2.Trim()) {
            $achados += New-Achado -Severidade 'ALTA' -Categoria 'Extenso' `
                -Mensagem ("R$ {0} nao confere com o extenso escrito" -f $numTxt) `
                -Trecho ("escrito:  {0}`n      > esperado: {1}" -f $extTxt.Trim(), $esperado)
        }
    }
}

# Valores sem extenso nenhum.
# O (?![\d,]) evita casar o pedaco "R$ 983,03" de um valor malformado "R$ 983,032,00".
$soltos = [regex]::Matches($plano, 'R\$\s*[\d\.]+,\d{2}(?![\d,])(?!\s*\()')
if ($soltos.Count -gt 0) {
    $lista = @($soltos | ForEach-Object { $_.Value } | Sort-Object -Unique)
    $achados += New-Achado -Severidade 'MEDIA' -Categoria 'Extenso' `
        -Mensagem ("{0} valor(es) sem extenso entre parenteses — o padrao da casa exige" -f $lista.Count) `
        -Trecho ($lista -join '   ')
}

# Formato numerico errado: R$ 983,032,00
$malformados = [regex]::Matches($plano, 'R\$\s*\d+,\d{3},\d{2}')
foreach ($mm in $malformados) {
    $achados += New-Achado -Severidade 'ALTA' -Categoria 'Formato' `
        -Mensagem 'Valor com virgula no lugar do separador de milhar' -Trecho $mm.Value
}

$titulo = "Extenso: " + (Split-Path $Path -Leaf) + " ($conferidos par(es) conferido(s))"
$codigo = Write-Relatorio -Achados $achados -Titulo $titulo
exit $codigo
