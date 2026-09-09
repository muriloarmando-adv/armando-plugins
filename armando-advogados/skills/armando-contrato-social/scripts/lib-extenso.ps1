<#
.SYNOPSIS
  Valor e quantidade por extenso em portugues. Biblioteca compartilhada.

.DESCRIPTION
  Usada por quadro-societario.ps1 (gera o extenso) e por
  conferir-instrumento.ps1 (confere o extenso ja escrito na minuta).

  Motivo de existir: o acervo do escritorio tem instrumento ARQUIVADO com
  extenso errado — a XXII Alteracao da Distribuidora de Gas Correa registra
  "O aumento de R$ 350.000,00 (quinhentos mil reais)".

  Este arquivo precisa estar gravado em UTF-8 COM BOM: o Windows PowerShell
  5.1 le .ps1 sem BOM como ANSI e corrompe "tres"/"milhoes" na minuta.
#>

$script:ExtUni      = @('', 'um', 'dois', 'três', 'quatro', 'cinco', 'seis', 'sete', 'oito', 'nove')
$script:ExtAdolesc  = @('dez', 'onze', 'doze', 'treze', 'quatorze', 'quinze', 'dezesseis', 'dezessete', 'dezoito', 'dezenove')
$script:ExtDezenas  = @('', '', 'vinte', 'trinta', 'quarenta', 'cinquenta', 'sessenta', 'setenta', 'oitenta', 'noventa')
$script:ExtCentenas = @('', 'cento', 'duzentos', 'trezentos', 'quatrocentos', 'quinhentos', 'seiscentos', 'setecentos', 'oitocentos', 'novecentos')
$script:ExtEscalas  = @(
    @{ Sing = '';        Plur = '' },
    @{ Sing = 'mil';     Plur = 'mil' },
    @{ Sing = 'milhão';  Plur = 'milhões' },
    @{ Sing = 'bilhão';  Plur = 'bilhões' },
    @{ Sing = 'trilhão'; Plur = 'trilhões' }
)

function Convert-GrupoExtenso {
    <# 1 a 999 por extenso. #>
    param([int]$N)
    if ($N -eq 0)   { return '' }
    if ($N -eq 100) { return 'cem' }
    $c = [int][math]::Floor($N / 100)
    $r = $N % 100
    $partes = @()
    if ($c -gt 0) { $partes += $script:ExtCentenas[$c] }
    if ($r -gt 0) {
        if ($r -lt 10) {
            $partes += $script:ExtUni[$r]
        } elseif ($r -lt 20) {
            $partes += $script:ExtAdolesc[$r - 10]
        } else {
            $d = [int][math]::Floor($r / 10)
            $u = $r % 10
            if ($u -gt 0) { $partes += ($script:ExtDezenas[$d] + ' e ' + $script:ExtUni[$u]) }
            else          { $partes += $script:ExtDezenas[$d] }
        }
    }
    return ($partes -join ' e ')
}

function Convert-InteiroExtenso {
    <#
      Inteiro por extenso. -UmMil escreve "um mil" (uso corrente nos
      instrumentos da casa: "R$ 1.000,00 (um mil reais)").
    #>
    param([long]$N, [switch]$UmMil)
    if ($N -lt 0) { return 'menos ' + (Convert-InteiroExtenso ([math]::Abs($N)) -UmMil:$UmMil) }
    if ($N -eq 0) { return 'zero' }

    $vals = @()
    $resto = $N
    while ($resto -gt 0) {
        $vals += [int]($resto % 1000)
        $resto = [long][math]::Floor($resto / 1000)
    }
    if ($vals.Count -gt $script:ExtEscalas.Count) { throw "Valor fora da faixa suportada pelo extenso: $N" }

    $partes = @()
    for ($i = $vals.Count - 1; $i -ge 0; $i--) {
        $v = $vals[$i]
        if ($v -eq 0) { continue }
        $txt = Convert-GrupoExtenso $v
        if ($i -eq 1) {
            if ($v -eq 1) { if ($UmMil) { $txt = 'um mil' } else { $txt = 'mil' } }
            else          { $txt = "$txt mil" }
        } elseif ($i -ge 2) {
            if ($v -eq 1) { $txt = 'um ' + $script:ExtEscalas[$i].Sing }
            else          { $txt = $txt + ' ' + $script:ExtEscalas[$i].Plur }
        }
        $partes += ,@($txt, $v)
    }

    # Ultimo grupo entra com " e " se for menor que 100 ou centena redonda;
    # os intermediarios entram com ", ". Da "tres milhoes, trezentos e
    # sessenta mil" e "um milhao e quinhentos mil".
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
    <# Valor em reais por extenso, com centavos. #>
    param([decimal]$V, [switch]$UmMil)
    $neg = $V -lt 0
    $V = [math]::Abs($V)
    $inteiro = [long][math]::Truncate($V)
    $cent = [int][math]::Round(($V - $inteiro) * 100, 0)
    if ($cent -eq 100) { $inteiro++; $cent = 0 }

    $p = @()
    if ($inteiro -gt 0 -or $cent -eq 0) {
        $u = 'reais'; if ($inteiro -eq 1) { $u = 'real' }
        $p += (Convert-InteiroExtenso $inteiro -UmMil:$UmMil) + " $u"
    }
    if ($cent -gt 0) {
        $u = 'centavos'; if ($cent -eq 1) { $u = 'centavo' }
        $p += (Convert-InteiroExtenso $cent) + " $u"
    }
    $r = $p -join ' e '
    if ($neg) { $r = "menos $r" }
    return $r
}

function ConvertTo-ChaveExtenso {
    <#
      Normaliza extenso para comparacao: minusculas, sem acento, sem
      pontuacao, colapsa "e"/","/espacos. Assim "tres milhoes, trezentos e
      sessenta mil" casa com "tres milhoes e trezentos e sessenta mil".
    #>
    param([string]$S)
    if (-not $S) { return '' }
    $s = $S.ToLowerInvariant()
    $s = $s.Normalize([Text.NormalizationForm]::FormD)
    $sb = New-Object System.Text.StringBuilder
    foreach ($ch in $s.ToCharArray()) {
        if ([Globalization.CharUnicodeInfo]::GetUnicodeCategory($ch) -ne [Globalization.UnicodeCategory]::NonSpacingMark) {
            [void]$sb.Append($ch)
        }
    }
    $s = $sb.ToString()
    $s = $s -replace '[^a-z0-9]+', ' '
    $s = ' ' + $s.Trim() + ' '
    $s = $s -replace ' e ', ' '
    $s = $s -replace '\s+', ' '
    return $s.Trim()
}
