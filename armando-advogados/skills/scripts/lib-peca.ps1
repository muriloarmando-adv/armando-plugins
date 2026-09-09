# lib-peca.ps1 — funcoes comuns aos scripts de revisao de peca.
# Carregado por revisar-inicial.ps1, extenso.ps1 e validar-identificadores.ps1.
# Windows PowerShell 5.1.

function Get-TextoDaPeca {
    <#
      Le .docx, .md, .txt ou .htm e devolve o texto corrido.
      No .docx, cada </w:p> vira quebra de linha, para preservar paragrafos.
    #>
    param([Parameter(Mandatory = $true)][string]$Path)

    if (-not (Test-Path -LiteralPath $Path)) {
        throw "Arquivo nao encontrado: $Path"
    }

    $ext = [System.IO.Path]::GetExtension($Path).ToLowerInvariant()

    if ($ext -eq '.docx') {
        Add-Type -AssemblyName System.IO.Compression.FileSystem -ErrorAction Stop
        $full = (Resolve-Path -LiteralPath $Path).ProviderPath
        $zip = [System.IO.Compression.ZipFile]::OpenRead($full)
        try {
            $entry = $zip.Entries | Where-Object { $_.FullName -eq 'word/document.xml' }
            if ($null -eq $entry) { throw "docx sem word/document.xml: $Path" }
            $reader = New-Object System.IO.StreamReader($entry.Open(), [System.Text.Encoding]::UTF8)
            try { $xml = $reader.ReadToEnd() } finally { $reader.Dispose() }
        }
        finally { $zip.Dispose() }

        $xml = $xml -replace '</w:p>', "`n"
        $xml = $xml -replace '<w:br[^>]*/>', "`n"
        $xml = $xml -replace '<w:tab[^>]*/>', "`t"
        $txt = $xml -replace '<[^>]+>', ''
        $txt = $txt -replace '&amp;', '&' -replace '&lt;', '<' -replace '&gt;', '>' -replace '&quot;', '"' -replace '&apos;', "'"
        return $txt
    }

    return (Get-Content -LiteralPath $Path -Raw -Encoding UTF8)
}

function New-Achado {
    <#
      Constroi um achado padronizado. Severidade: ALTA, MEDIA, BAIXA.
    #>
    param(
        [string]$Severidade,
        [string]$Categoria,
        [string]$Mensagem,
        [string]$Trecho = ''
    )
    [pscustomobject]@{
        Severidade = $Severidade
        Categoria  = $Categoria
        Mensagem   = $Mensagem
        Trecho     = $Trecho
    }
}

function Write-Relatorio {
    <#
      Imprime os achados agrupados por severidade e devolve o codigo de saida
      sugerido: 1 se houver ALTA, 0 nos demais casos.
    #>
    param(
        [Parameter(Mandatory = $true)][AllowEmptyCollection()][array]$Achados,
        [string]$Titulo = 'Revisao'
    )

    Write-Host ''
    Write-Host "=== $Titulo ===" -ForegroundColor Cyan

    if ($Achados.Count -eq 0) {
        Write-Host 'Nenhum problema encontrado.' -ForegroundColor Green
        Write-Host ''
        return 0
    }

    $ordem = @{ 'ALTA' = 0; 'MEDIA' = 1; 'BAIXA' = 2 }
    $cores = @{ 'ALTA' = 'Red'; 'MEDIA' = 'Yellow'; 'BAIXA' = 'DarkGray' }

    foreach ($sev in @('ALTA', 'MEDIA', 'BAIXA')) {
        $doNivel = @($Achados | Where-Object { $_.Severidade -eq $sev })
        if ($doNivel.Count -eq 0) { continue }

        Write-Host ''
        Write-Host "[$sev] $($doNivel.Count) achado(s)" -ForegroundColor $cores[$sev]
        foreach ($a in $doNivel) {
            Write-Host ("  - {0}: {1}" -f $a.Categoria, $a.Mensagem)
            if ($a.Trecho) {
                Write-Host ("      > {0}" -f $a.Trecho) -ForegroundColor DarkGray
            }
        }
    }

    $altas = @($Achados | Where-Object { $_.Severidade -eq 'ALTA' }).Count
    Write-Host ''
    if ($altas -gt 0) {
        Write-Host "NAO PROTOCOLAR: $altas item(ns) de severidade ALTA." -ForegroundColor Red
        Write-Host ''
        return 1
    }
    Write-Host 'Sem impeditivo de severidade ALTA. Confira os demais itens.' -ForegroundColor Yellow
    Write-Host ''
    return 0
}

function Get-DistanciaEdicao {
    <# Levenshtein. Usado para achar identificadores quase iguais. #>
    param([string]$a, [string]$b)

    if ($a -eq $b) { return 0 }
    if ($a.Length -eq 0) { return $b.Length }
    if ($b.Length -eq 0) { return $a.Length }

    $m = New-Object 'int[,]' ($a.Length + 1), ($b.Length + 1)
    for ($i = 0; $i -le $a.Length; $i++) { $m[$i, 0] = $i }
    for ($j = 0; $j -le $b.Length; $j++) { $m[0, $j] = $j }

    for ($i = 1; $i -le $a.Length; $i++) {
        for ($j = 1; $j -le $b.Length; $j++) {
            if ($a[$i - 1] -eq $b[$j - 1]) { $custo = 0 } else { $custo = 1 }
            $del = $m[($i - 1), $j] + 1
            $ins = $m[$i, ($j - 1)] + 1
            $sub = $m[($i - 1), ($j - 1)] + $custo
            $min = $del
            if ($ins -lt $min) { $min = $ins }
            if ($sub -lt $min) { $min = $sub }
            $m[$i, $j] = $min
        }
    }
    return $m[$a.Length, $b.Length]
}
