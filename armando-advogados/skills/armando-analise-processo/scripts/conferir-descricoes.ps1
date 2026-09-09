<#
.SYNOPSIS
  Confere o limite de 1024 caracteres do campo `description` de cada SKILL.md.

.DESCRIPTION
  A description e o unico texto que o modelo le para decidir se a skill entra.
  Passando de 1024 caracteres, a skill e recusada no carregamento - e o sintoma
  e ela simplesmente nao existir, sem mensagem de erro.

  Mede em CARACTERES e em BYTES UTF-8, e cobra o limite pelo maior dos dois:
  nao esta documentado qual deles o validador conta, e em portugues a diferenca
  chega a 40 por causa dos acentos. Duas skills da casa ja estouraram sem que
  ninguem percebesse.

  Codigo de saida 1 quando alguma estoura.

.PARAMETER Path
  Pasta de skills. Padrao: a pasta `skills` ao lado deste script.

.PARAMETER Limite
  Padrao 1024.

.PARAMETER Margem
  Avisa (sem reprovar) quando faltar menos que isto para o limite. Padrao 60.

.EXAMPLE
  .\conferir-descricoes.ps1
#>
[CmdletBinding()]
param(
    [string]$Path,
    [int]$Limite = 1024,
    [int]$Margem = 60
)

$ErrorActionPreference = 'Stop'

if (-not $Path) { $Path = Join-Path $PSScriptRoot '..\skills' }
if (-not (Test-Path -LiteralPath $Path)) { throw "Pasta de skills nao encontrada: $Path" }

$estouros = 0
$apertadas = 0

Write-Host ''
Write-Host '=== description de cada SKILL.md ===' -ForegroundColor Cyan
Write-Host ''

foreach ($d in (Get-ChildItem -LiteralPath $Path -Directory | Sort-Object Name)) {
    $f = Join-Path $d.FullName 'SKILL.md'
    if (-not (Test-Path -LiteralPath $f)) { continue }

    $txt = Get-Content -LiteralPath $f -Raw -Encoding UTF8

    # Aceita a forma de uma linha e a forma dobrada (`description: >`).
    if ($txt -notmatch '(?ms)^description:[ ]*(.*?)\r?\n(?=[a-zA-Z_-]+:|---)') {
        Write-Host ("  ?     {0,-28} sem campo description" -f $d.Name) -ForegroundColor Yellow
        continue
    }

    $desc = ($Matches[1] -replace '^>\s*', '' -replace '\r?\n\s+', ' ').Trim()
    $chars = $desc.Length
    $bytes = [System.Text.Encoding]::UTF8.GetByteCount($desc)
    $pior = [Math]::Max($chars, $bytes)

    if ($pior -gt $Limite) {
        $estouros++
        Write-Host ("  ERRO  {0,-28} chars={1,5}  bytes={2,5}  ESTOURA em {3}" -f `
            $d.Name, $chars, $bytes, ($pior - $Limite)) -ForegroundColor Red
    }
    elseif (($Limite - $pior) -lt $Margem) {
        $apertadas++
        Write-Host ("  ~     {0,-28} chars={1,5}  bytes={2,5}  folga de so {3}" -f `
            $d.Name, $chars, $bytes, ($Limite - $pior)) -ForegroundColor Yellow
    }
    else {
        Write-Host ("  OK    {0,-28} chars={1,5}  bytes={2,5}" -f $d.Name, $chars, $bytes) -ForegroundColor DarkGray
    }
}

Write-Host ''
if ($estouros -gt 0) {
    Write-Host ("NAO PUBLICAR: {0} skill(s) com description acima de {1}." -f $estouros, $Limite) -ForegroundColor Red
    Write-Host 'Corte gatilho repetido e a lista de secoes; preserve o "Use SEMPRE que".' -ForegroundColor Red
    Write-Host ''
    exit 1
}
if ($apertadas -gt 0) {
    Write-Host ("{0} skill(s) com pouca folga - a proxima frase acrescentada estoura." -f $apertadas) -ForegroundColor Yellow
}
Write-Host 'Todas dentro do limite.' -ForegroundColor Green
Write-Host ''
exit 0
