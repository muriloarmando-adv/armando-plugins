<#
.SYNOPSIS
  Empacota uma skill em .zip aceito pelo painel de Habilidades — Armando Advogados.

.DESCRIPTION
  NAO use Compress-Archive para isto. No Windows PowerShell 5.1 ele grava os nomes
  das entradas com barra invertida ("skill\SKILL.md"), e o painel de Habilidades
  recusa o arquivo com "Zip file contains path with invalid characters".
  O formato ZIP exige barra normal.

  Este script monta o pacote entrada por entrada, com "/", incluindo as entradas
  de diretorio — do jeito que os zips que subiram sem erro estao montados.

.PARAMETER Path
  Pasta da skill (a que contem o SKILL.md).

.PARAMETER Destino
  Opcional. Caminho do .zip. Padrao: irmao da pasta, com o mesmo nome.

.EXAMPLE
  .\empacotar-skill.ps1 -Path "..\skills\armando-contestacao-trabalhista"
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, Position = 0)][string]$Path,
    [string]$Destino
)

$ErrorActionPreference = 'Stop'

$pasta = (Resolve-Path -LiteralPath $Path).ProviderPath.TrimEnd('\')
if (-not (Test-Path -LiteralPath (Join-Path $pasta 'SKILL.md'))) {
    throw "Nao encontrei SKILL.md em $pasta — nao parece ser uma pasta de skill."
}
$nome = Split-Path $pasta -Leaf
if (-not $Destino) { $Destino = Join-Path (Split-Path $pasta -Parent) ("$nome.zip") }
if (Test-Path -LiteralPath $Destino) { Remove-Item -LiteralPath $Destino -Force }

Add-Type -AssemblyName System.IO.Compression.FileSystem
Add-Type -AssemblyName System.IO.Compression

$raiz = (Split-Path $pasta -Parent).TrimEnd('\') + '\'
$fs = [System.IO.File]::Open($Destino, [System.IO.FileMode]::Create)
$zip = New-Object System.IO.Compression.ZipArchive($fs, [System.IO.Compression.ZipArchiveMode]::Create)

$nDir = 0; $nArq = 0
try {
    # entradas de diretorio, terminadas em "/"
    foreach ($d in @(Get-Item -LiteralPath $pasta) + @(Get-ChildItem -LiteralPath $pasta -Recurse -Directory)) {
        $rel = $d.FullName.Substring($raiz.Length).Replace('\', '/') + '/'
        [void]$zip.CreateEntry($rel)
        $nDir++
    }
    foreach ($f in Get-ChildItem -LiteralPath $pasta -Recurse -File) {
        $rel = $f.FullName.Substring($raiz.Length).Replace('\', '/')
        $e = $zip.CreateEntry($rel, [System.IO.Compression.CompressionLevel]::Optimal)
        $st = $e.Open()
        $bytes = [System.IO.File]::ReadAllBytes($f.FullName)
        $st.Write($bytes, 0, $bytes.Length)
        $st.Dispose()
        $nArq++
    }
}
finally { $zip.Dispose(); $fs.Dispose() }

# conferencia: nenhuma barra invertida, nenhum caractere fora do ASCII imprimivel
$a = [System.IO.Compression.ZipFile]::OpenRead($Destino)
$ruins = @($a.Entries | Where-Object { $_.FullName -match '\\' -or $_.FullName -match '[^\x20-\x7E]' })
$total = $a.Entries.Count
$primeira = $a.Entries[0].FullName
$a.Dispose()

if ($ruins.Count -gt 0) {
    Write-Host "FALHOU — entradas invalidas:" -ForegroundColor Red
    $ruins | ForEach-Object { Write-Host ("  " + $_.FullName) }
    exit 1
}

Write-Host ("OK  {0}" -f $Destino) -ForegroundColor Green
Write-Host ("    {0} diretorios, {1} arquivos, {2} entradas — 1a: {3}" -f $nDir, $nArq, $total, $primeira)
exit 0
