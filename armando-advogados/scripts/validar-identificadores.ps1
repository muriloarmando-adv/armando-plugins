<#
.SYNOPSIS
  Confere digito verificador de CPF, CNPJ e numero CNJ.

.DESCRIPTION
  Dois modos:
    -Numero  valida um identificador avulso.
    -Path    varre a peca e valida todos os CPF, CNPJ e numeros de processo.

  Um CPF digitado errado na qualificacao passa por qualquer leitura humana e e
  pego por aritmetica. Mesmo vale para o numero CNJ, cujo digito verificador
  (modulo 97, ISO 7064) detecta troca ou transposicao de algarismos.

.EXAMPLE
  .\validar-identificadores.ps1 -Numero 590.619.018-04
.EXAMPLE
  .\validar-identificadores.ps1 -Path "C:\Users\muril\Downloads\inicial.docx"
#>
[CmdletBinding(DefaultParameterSetName = 'Arquivo')]
param(
    [Parameter(ParameterSetName = 'Numero', Mandatory = $true, Position = 0)][string]$Numero,
    [Parameter(ParameterSetName = 'Arquivo', Mandatory = $true)][string]$Path
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'lib-peca.ps1')

function Get-SoDigitos { param([string]$s) return ($s -replace '\D', '') }

function Test-CPF {
    param([string]$valor)
    $d = Get-SoDigitos $valor
    if ($d.Length -ne 11) { return $false }
    if ($d -match "^(.)\1{10}$") { return $false }   # 111.111.111-11 etc.

    $n = @()
    foreach ($c in $d.ToCharArray()) { $n += [int]::Parse($c) }

    $soma = 0
    for ($i = 0; $i -lt 9; $i++) { $soma += $n[$i] * (10 - $i) }
    $r = $soma % 11
    if ($r -lt 2) { $dv1 = 0 } else { $dv1 = 11 - $r }
    if ($n[9] -ne $dv1) { return $false }

    $soma = 0
    for ($i = 0; $i -lt 10; $i++) { $soma += $n[$i] * (11 - $i) }
    $r = $soma % 11
    if ($r -lt 2) { $dv2 = 0 } else { $dv2 = 11 - $r }
    return ($n[10] -eq $dv2)
}

function Test-CNPJ {
    param([string]$valor)
    $d = Get-SoDigitos $valor
    if ($d.Length -ne 14) { return $false }
    if ($d -match "^(.)\1{13}$") { return $false }

    $n = @()
    foreach ($c in $d.ToCharArray()) { $n += [int]::Parse($c) }

    $p1 = @(5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2)
    $soma = 0
    for ($i = 0; $i -lt 12; $i++) { $soma += $n[$i] * $p1[$i] }
    $r = $soma % 11
    if ($r -lt 2) { $dv1 = 0 } else { $dv1 = 11 - $r }
    if ($n[12] -ne $dv1) { return $false }

    $p2 = @(6, 5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2)
    $soma = 0
    for ($i = 0; $i -lt 13; $i++) { $soma += $n[$i] * $p2[$i] }
    $r = $soma % 11
    if ($r -lt 2) { $dv2 = 0 } else { $dv2 = 11 - $r }
    return ($n[13] -eq $dv2)
}

function Test-CNJ {
    <#
      NNNNNNN-DD.AAAA.J.TR.OOOO — Resolucao CNJ 65/2008.
      DV = 98 - ((NNNNNNN AAAA J TR OOOO) * 100 mod 97)
    #>
    param([string]$valor)

    if ($valor -notmatch '(\d{7})-(\d{2})\.(\d{4})\.(\d)\.(\d{2})\.(\d{4})') { return $null }

    $nnn = $Matches[1]; $dd = $Matches[2]; $aaaa = $Matches[3]
    $j = $Matches[4]; $tr = $Matches[5]; $oooo = $Matches[6]

    $base = $nnn + $aaaa + $j + $tr + $oooo + '00'
    $big = [System.Numerics.BigInteger]::Parse($base)
    $resto = [int]($big % [System.Numerics.BigInteger]97)
    $dv = 98 - $resto
    $esperado = $dv.ToString('00')

    return [pscustomobject]@{
        Ok        = ($esperado -eq $dd)
        Informado = $dd
        Esperado  = $esperado
    }
}

function Show-Resultado {
    param([string]$tipo, [string]$valor, [bool]$ok, [string]$extra = '')
    if ($ok) {
        Write-Host ("  OK    {0,-6} {1} {2}" -f $tipo, $valor, $extra) -ForegroundColor Green
    }
    else {
        Write-Host ("  ERRO  {0,-6} {1} {2}" -f $tipo, $valor, $extra) -ForegroundColor Red
    }
}

# ------------------------------------------------------------------ modo avulso
if ($PSCmdlet.ParameterSetName -eq 'Numero') {
    Write-Host ''
    $d = Get-SoDigitos $Numero

    if ($Numero -match '\d{7}-\d{2}\.\d{4}\.\d\.\d{2}\.\d{4}') {
        $r = Test-CNJ $Numero
        $extra = ''
        if (-not $r.Ok) { $extra = "(digito informado {0}, esperado {1})" -f $r.Informado, $r.Esperado }
        Show-Resultado -tipo 'CNJ' -valor $Numero -ok $r.Ok -extra $extra
        Write-Host ''
        if ($r.Ok) { exit 0 } else { exit 1 }
    }
    elseif ($d.Length -eq 11) {
        $ok = Test-CPF $Numero
        Show-Resultado -tipo 'CPF' -valor $Numero -ok $ok
        Write-Host ''
        if ($ok) { exit 0 } else { exit 1 }
    }
    elseif ($d.Length -eq 14) {
        $ok = Test-CNPJ $Numero
        Show-Resultado -tipo 'CNPJ' -valor $Numero -ok $ok
        Write-Host ''
        if ($ok) { exit 0 } else { exit 1 }
    }
    else {
        Write-Host "  Formato nao reconhecido: $Numero" -ForegroundColor Yellow
        Write-Host '  Esperado CPF (11), CNPJ (14) ou CNJ (NNNNNNN-DD.AAAA.J.TR.OOOO).'
        Write-Host ''
        exit 2
    }
}

# ----------------------------------------------------------------- modo arquivo
$texto = Get-TextoDaPeca -Path $Path
$achados = @()

Write-Host ''
Write-Host ("=== Identificadores: " + (Split-Path $Path -Leaf) + " ===") -ForegroundColor Cyan
Write-Host ''

# Marcacao Markdown no meio da mascara esconde o identificador do regex. Um numero
# escrito 0001219-15.**2023**.4.01.3901 - para destacar o digito trocado - passava
# batido, e era justamente o unico invalido da peca. Remove-se a marcacao antes.
$texto = $texto -replace '(\*\*|\*|__|_|`|~~)', ''

$cpfs = @([regex]::Matches($texto, '\b\d{3}\.\d{3}\.\d{3}-\d{2}\b') | ForEach-Object { $_.Value } | Sort-Object -Unique)
$cnpjs = @([regex]::Matches($texto, '\b\d{2}\.\d{3}\.\d{3}/\d{4}-\d{2}\b') | ForEach-Object { $_.Value } | Sort-Object -Unique)
$cnjs = @([regex]::Matches($texto, '\b\d{7}-\d{2}\.\d{4}\.\d\.\d{2}\.\d{4}\b') | ForEach-Object { $_.Value } | Sort-Object -Unique)

foreach ($v in $cpfs) {
    $ok = Test-CPF $v
    Show-Resultado -tipo 'CPF' -valor $v -ok $ok
    if (-not $ok) {
        $achados += New-Achado -Severidade 'ALTA' -Categoria 'CPF' `
            -Mensagem 'Digito verificador invalido — erro de digitacao na qualificacao' -Trecho $v
    }
}
foreach ($v in $cnpjs) {
    $ok = Test-CNPJ $v
    Show-Resultado -tipo 'CNPJ' -valor $v -ok $ok
    if (-not $ok) {
        $achados += New-Achado -Severidade 'ALTA' -Categoria 'CNPJ' `
            -Mensagem 'Digito verificador invalido — erro de digitacao na qualificacao' -Trecho $v
    }
}
foreach ($v in $cnjs) {
    $r = Test-CNJ $v
    $extra = ''
    if (-not $r.Ok) { $extra = "(informado {0}, esperado {1})" -f $r.Informado, $r.Esperado }
    Show-Resultado -tipo 'CNJ' -valor $v -ok $r.Ok -extra $extra
    if (-not $r.Ok) {
        # Sequencia de um digito so (1111111-11.1111.1.11.1111) nao e numero errado:
        # e ruido de OCR ou de codigo de barras, e a analise e obrigada a registra-lo
        # como tal. Marcar ALTA aqui bloqueava a entrega por citacao deliberada.
        if (($v -replace '\D', '') -match "^(.)\1{19}$") {
            $achados += New-Achado -Severidade 'BAIXA' -Categoria 'Processo' `
                -Mensagem 'Sequencia de digito unico: ruido de OCR ou de codigo de barras, nao numero de processo' -Trecho $v
        }
        else {
            $achados += New-Achado -Severidade 'ALTA' -Categoria 'Processo' `
                -Mensagem ("Numero CNJ com digito verificador invalido (informado {0}, esperado {1})" -f $r.Informado, $r.Esperado) `
                -Trecho $v
        }
    }
}

$total = $cpfs.Count + $cnpjs.Count + $cnjs.Count
if ($total -eq 0) {
    Write-Host '  Nenhum CPF, CNPJ ou numero CNJ localizado na peca.' -ForegroundColor Yellow
    Write-Host '  Se a peca qualifica partes, isso por si so ja e um problema.' -ForegroundColor Yellow
}

$codigo = Write-Relatorio -Achados $achados -Titulo "Resumo ($total identificador(es) conferido(s))"
exit $codigo
