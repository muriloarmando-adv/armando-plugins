# djen.ps1 - Consulta o Diario de Justica Eletronico Nacional (DJEN/CNJ) e gera um
# digest em markdown para o agente `diario-justica` do escritorio Armando Advogados.
#
# API publica: https://comunicaapi.pje.jus.br/api/v1/comunicacao
#   parametros uteis: siglaTribunal, numeroOab + ufOab, nomeAdvogado, numeroProcesso,
#   orgaoId, texto, dataDisponibilizacaoInicio, dataDisponibilizacaoFim, pagina, itensPorPagina
#
# ATENCAO: a API aplica rate limit (HTTP 429). O script ja serializa e espera entre
# as chamadas; nao reduza o -IntervaloMs sem necessidade.
#
# Uso:
#   .\djen.ps1                                   # ontem+hoje, escritorio + panorama penal STJ
#   .\djen.ps1 -Modo escritorio
#   .\djen.ps1 -Modo stjpenal -PaginasPanorama 5
#   .\djen.ps1 -DataInicio 2026-08-10 -DataFim 2026-08-14 -Saida C:\tmp\djen.md

[CmdletBinding()]
param(
  [ValidateSet("escritorio", "stjpenal", "informativo", "ambos")]
  [string]$Modo = "ambos",
  [string]$DataInicio,
  [string]$DataFim,
  [string]$Config,
  [string]$Saida,
  [int]$PaginasPanorama = 3,
  [int]$IntervaloMs = 1800,
  [int]$MaxCaracteresTexto = 1500
)

$ErrorActionPreference = "Stop"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
try { Add-Type -AssemblyName System.Web -ErrorAction Stop } catch {}

$API = "https://comunicaapi.pje.jus.br/api/v1/comunicacao"
$ORGAO_STJ_PENAL = 59632   # SPF Coordenadoria de Processamento de Feitos de Direito Penal

# --- datas -------------------------------------------------------------------
$hoje = Get-Date
if (-not $DataInicio) { $DataInicio = $hoje.AddDays(-1).ToString("yyyy-MM-dd") }
if (-not $DataFim)    { $DataFim    = $hoje.ToString("yyyy-MM-dd") }

# --- config ------------------------------------------------------------------
if (-not $Config) { $Config = Join-Path $PSScriptRoot "djen-advogados.json" }
if (-not (Test-Path $Config)) { throw "Config nao encontrada: $Config" }
$cfg = Get-Content $Config -Raw -Encoding UTF8 | ConvertFrom-Json
$advogados = $cfg.advogados
$tribunais = $cfg.tribunais
if (-not $tribunais) { $tribunais = @("TJTO", "STJ") }

if (-not $Saida) {
  $dir = Join-Path $env:USERPROFILE "Documents\DJEN"
  if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
  $Saida = Join-Path $dir ("djen-" + $hoje.ToString("yyyy-MM-dd") + ".md")
}

# --- helpers -----------------------------------------------------------------
function Invoke-Djen {
  param([hashtable]$Q)
  $pares = @()
  foreach ($k in $Q.Keys) { $pares += ("{0}={1}" -f $k, [uri]::EscapeDataString([string]$Q[$k])) }
  $url = $API + "?" + ($pares -join "&")
  for ($tentativa = 1; $tentativa -le 5; $tentativa++) {
    try {
      $r = Invoke-RestMethod -Uri $url -TimeoutSec 180 -Headers @{ "Accept" = "application/json" }
      Start-Sleep -Milliseconds $IntervaloMs
      return $r
    } catch {
      $codigo = ""
      if ($_.Exception.Response) { $codigo = [int]$_.Exception.Response.StatusCode }
      $espera = [Math]::Min(60, 5 * [Math]::Pow(2, $tentativa - 1))
      Write-Warning ("DJEN falhou (tentativa {0}/5, HTTP {1}). Aguardando {2}s. URL: {3}" -f $tentativa, $codigo, $espera, $url)
      Start-Sleep -Seconds $espera
    }
  }
  Write-Warning ("DJEN INDISPONIVEL apos 5 tentativas: {0}" -f $url)
  return $null
}

function ConvertTo-Texto {
  param([string]$Html)
  if (-not $Html) { return "" }
  $t = $Html -replace '(?is)<(script|style)[^>]*>.*?</\1>', ' '
  $t = $t -replace '(?i)</(p|div|tr|section|br|h[1-6])>', "`n"
  $t = $t -replace '(?i)<br\s*/?>', "`n"
  $t = $t -replace '<[^>]+>', ' '
  try { $t = [System.Web.HttpUtility]::HtmlDecode($t) } catch {}
  $t = $t -replace '[ \t\u00a0]+', ' '
  $t = $t -replace '(\r?\n\s*){2,}', "`n"
  return $t.Trim()
}

# Heuristica de triagem criminal (ASCII-only de proposito: o '.' cobre acentos).
$reCrimClasse = '(?i)CRIMINAL|PENAL|HABEAS|INQU.RITO|REVIS.O CRIMINAL|AGRAVO EM EXECU|EMBARGOS INFRINGENTES E DE NULIDADE|PRIS.O|BUSCA E APREENS|INTERCEPTA'
$reCrimOrgao  = '(?i)CRIMINAL|PENAL|J.RI|EXECU..ES PENAIS|QUINTA TURMA|SEXTA TURMA|TERCEIRA SE'

function Test-Criminal {
  param($Item)
  $classe = [string]$Item.nomeClasse
  $orgao  = [string]$Item.nomeOrgao
  if ($classe -match $reCrimClasse) { return $true }
  if ($orgao  -match $reCrimOrgao)  { return $true }
  return $false
}

function Get-Relator {
  param([string]$Texto)
  $m = [regex]::Match($Texto, '(?i)RELATOR.{0,3}:\s*(MINISTR.{1,60}?)(?:\s+[A-Z]{5,}\s*:|\r|\n|$)')
  if ($m.Success) { return $m.Groups[1].Value.Trim() }
  $m = [regex]::Match($Texto, '(?i)RELATOR.{0,3}:\s*(DES.{1,60}?)(?:\s+[A-Z]{5,}\s*:|\r|\n|$)')
  if ($m.Success) { return $m.Groups[1].Value.Trim() }
  return ""
}

function Get-Todas-Paginas {
  param([hashtable]$Q, [int]$MaxPaginas = 20)
  $itens = @()
  for ($p = 1; $p -le $MaxPaginas; $p++) {
    $Q["pagina"] = $p
    $r = Invoke-Djen -Q $Q
    if (-not $r) { break }
    if (-not $r.items -or $r.items.Count -eq 0) { break }
    $itens += $r.items
    if ($r.items.Count -lt [int]$Q["itensPorPagina"]) { break }
  }
  return , $itens
}

function Get-InformativoPenal {
  # Baixa o Informativo de Jurisprudencia do STJ (edicao corrente, semanal) e
  # devolve so as secoes de Direito Penal / Processual Penal.
  $url = "https://processo.stj.jus.br/jurisprudencia/externo/informativo/"
  try {
    $wc = New-Object System.Net.WebClient
    $bytes = $wc.DownloadData($url)
  } catch {
    Write-Warning ("Informativo do STJ indisponivel: " + $_.Exception.Message)
    return $null
  }
  $cabecalho = [System.Text.Encoding]::ASCII.GetString($bytes, 0, [Math]::Min(3000, $bytes.Length))
  $enc = [System.Text.Encoding]::UTF8
  if ($cabecalho -match '(?i)charset\s*=\s*"?(iso-8859-1|windows-1252)') {
    $enc = [System.Text.Encoding]::GetEncoding("iso-8859-1")
  }
  $html = $enc.GetString($bytes)
  $texto = ConvertTo-Texto $html

  $edicao = ""
  $m = [regex]::Match($texto, '(?i)Informativo de Jurisprud.ncia n.?\s*(\d+)\s*-\s*([0-9]{1,2} de [a-z]+ de [0-9]{4})')
  if ($m.Success) { $edicao = "n. " + $m.Groups[1].Value + " - " + $m.Groups[2].Value }

  # "DIREITO " seguido so de caixa alta: "nao minuscula e nao digito" cobre as
  # acentuadas sem gravar byte nao-ASCII aqui (o PS 5.1 le este arquivo como ANSI).
  $marcadores = [regex]::Matches($texto, '(?m)DIREITO [^a-z0-9\r\n]{2,60}')
  $blocos = @()
  for ($i = 0; $i -lt $marcadores.Count; $i++) {
    $titulo = $marcadores[$i].Value.Trim()
    if ($titulo -notmatch '(?i)PENAL') { continue }
    $ini = $marcadores[$i].Index
    $fim = $texto.Length
    if ($i + 1 -lt $marcadores.Count) { $fim = $marcadores[$i + 1].Index }
    $trecho = $texto.Substring($ini, $fim - $ini).Trim()
    if ($trecho.Length -lt 120) { continue }
    if ($trecho.Length -gt 6000) { $trecho = $trecho.Substring(0, 6000) + " [...]" }
    $blocos += $trecho
  }
  return [pscustomobject]@{ edicao = $edicao; blocos = $blocos; url = $url }
}

# --- bloco 1: publicacoes do escritorio --------------------------------------
$porId = @{}
$falhas = @()

if ($Modo -eq "escritorio" -or $Modo -eq "ambos") {
  foreach ($adv in $advogados) {
    foreach ($trib in $tribunais) {
      Write-Host ("Consultando {0} - OAB {1} {2} ..." -f $trib, $adv.uf, $adv.oab)
      $q = @{
        siglaTribunal              = $trib
        numeroOab                  = $adv.oab
        ufOab                      = $adv.uf
        dataDisponibilizacaoInicio = $DataInicio
        dataDisponibilizacaoFim    = $DataFim
        itensPorPagina             = 50
      }
      $itens = Get-Todas-Paginas -Q $q
      if ($null -eq $itens) { $falhas += ("{0}/OAB {1} {2}" -f $trib, $adv.uf, $adv.oab); continue }
      foreach ($it in $itens) {
        $id = [string]$it.id
        if (-not $porId.ContainsKey($id)) {
          $texto = ConvertTo-Texto ([string]$it.texto)
          $porId[$id] = [pscustomobject]@{
            id        = $id
            tribunal  = [string]$it.siglaTribunal
            data      = [string]$it.data_disponibilizacao
            orgao     = [string]$it.nomeOrgao
            classe    = [string]$it.nomeClasse
            tipo      = [string]$it.tipoComunicacao
            tipoDoc   = [string]$it.tipoDocumento
            processo  = [string]$it.numeroprocessocommascara
            link      = [string]$it.link
            relator   = Get-Relator $texto
            criminal  = (Test-Criminal $it)
            texto     = $texto
            advogados = New-Object System.Collections.ArrayList
            partes    = (($it.destinatarios | ForEach-Object { "{0} ({1})" -f $_.nome, $_.polo }) -join "; ")
          }
        }
        $rotulo = "{0} (OAB {1} {2})" -f $adv.nome, $adv.uf, $adv.oab
        if (-not $porId[$id].advogados.Contains($rotulo)) { [void]$porId[$id].advogados.Add($rotulo) }
      }
    }
  }
}

$pubs = @($porId.Values | Sort-Object tribunal, data, orgao)

# --- bloco 2: panorama criminal do STJ ---------------------------------------
$panorama = @()
$panoramaTotal = 0
if ($Modo -eq "stjpenal" -or $Modo -eq "ambos") {
  Write-Host "Consultando panorama criminal do STJ (orgao penal) ..."
  $q = @{
    siglaTribunal              = "STJ"
    orgaoId                    = $ORGAO_STJ_PENAL
    dataDisponibilizacaoInicio = $DataInicio
    dataDisponibilizacaoFim    = $DataFim
    itensPorPagina             = 50
  }
  $q["pagina"] = 1
  $primeira = Invoke-Djen -Q $q
  if ($primeira) {
    $panoramaTotal = [int]$primeira.count
    $panorama += $primeira.items
    for ($p = 2; $p -le $PaginasPanorama; $p++) {
      $q["pagina"] = $p
      $r = Invoke-Djen -Q $q
      if (-not $r -or -not $r.items) { break }
      $panorama += $r.items
    }
  } else {
    $falhas += "STJ/panorama penal"
  }
}

# --- relatorio ---------------------------------------------------------------
$sb = New-Object System.Text.StringBuilder
function Add-Linha { param([string]$s) [void]$sb.AppendLine($s) }

Add-Linha ("# DJEN - coleta bruta " + $DataInicio + " a " + $DataFim)
Add-Linha ("Gerado em " + $hoje.ToString("dd/MM/yyyy HH:mm") + " | fonte: comunicaapi.pje.jus.br (DJEN/CNJ)")
if ($falhas.Count -gt 0) {
  Add-Linha ""
  Add-Linha ("> **CONSULTAS QUE FALHARAM (cobertura incompleta):** " + ($falhas -join ", "))
}
Add-Linha ""

if ($Modo -eq "escritorio" -or $Modo -eq "ambos") {
  $crim = @($pubs | Where-Object { $_.criminal })
  Add-Linha ("## Bloco 1 - Publicacoes do escritorio")
  Add-Linha ("Total: {0} | criminais: {1} | TJTO: {2} | STJ: {3}" -f $pubs.Count, $crim.Count,
    @($pubs | Where-Object { $_.tribunal -eq "TJTO" }).Count,
    @($pubs | Where-Object { $_.tribunal -eq "STJ" }).Count)
  Add-Linha ""
  if ($pubs.Count -eq 0) {
    Add-Linha "_Nenhuma publicacao no periodo._"
  }
  $i = 0
  foreach ($p in $pubs) {
    $i++
    $marca = ""
    if ($p.criminal) { $marca = " [CRIMINAL]" }
    Add-Linha ("### {0}. {1} - {2}{3}" -f $i, $p.tribunal, $p.processo, $marca)
    Add-Linha ("- **ID DJEN:** {0}" -f $p.id)
    Add-Linha ("- **Orgao:** {0}" -f $p.orgao)
    Add-Linha ("- **Classe:** {0} | **Tipo:** {1} {2}" -f $p.classe, $p.tipo, $p.tipoDoc)
    if ($p.relator) { Add-Linha ("- **Relator:** {0}" -f $p.relator) }
    Add-Linha ("- **Disponibilizado:** {0}" -f $p.data)
    Add-Linha ("- **Advogado(s) do escritorio:** {0}" -f ($p.advogados -join " | "))
    if ($p.partes) { Add-Linha ("- **Partes:** {0}" -f $p.partes) }
    if ($p.link)   { Add-Linha ("- **Integra:** {0}" -f $p.link) }
    $txt = $p.texto
    if ($txt.Length -gt $MaxCaracteresTexto) { $txt = $txt.Substring(0, $MaxCaracteresTexto) + " [...TEXTO TRUNCADO...]" }
    Add-Linha ""
    Add-Linha '~~~'
    Add-Linha $txt
    Add-Linha '~~~'
    Add-Linha ""
  }
}

if ($Modo -eq "stjpenal" -or $Modo -eq "ambos") {
  Add-Linha ""
  Add-Linha "## Bloco 2 - Panorama criminal do STJ (orgao de Direito Penal)"
  Add-Linha ("Publicacoes criminais do STJ no periodo: **{0}**. Amostra coletada: **{1}** (paginas 1-{2})." -f $panoramaTotal, $panorama.Count, $PaginasPanorama)
  Add-Linha "> A amostra NAO e o diario inteiro. Declare esse limite no relatorio final."
  Add-Linha ""
  if ($panorama.Count -gt 0) {
    Add-Linha "### Distribuicao por classe (amostra)"
    $panorama | Group-Object nomeClasse | Sort-Object Count -Descending | Select-Object -First 15 | ForEach-Object {
      Add-Linha ("- {0}: {1}" -f $_.Name, $_.Count)
    }
    Add-Linha ""
    Add-Linha "### Itens da amostra"
    $j = 0
    foreach ($it in $panorama) {
      $j++
      $texto = ConvertTo-Texto ([string]$it.texto)
      $rel = Get-Relator $texto
      Add-Linha ("**{0}. {1}** | {2} | rel. {3}" -f $j, $it.numeroprocessocommascara, $it.nomeClasse, $rel)
      $txt = $texto
      if ($txt.Length -gt 900) { $txt = $txt.Substring(0, 900) + " [...]" }
      Add-Linha ("> " + ($txt -replace "`n", " "))
      if ($it.link) { Add-Linha ("> Integra: " + $it.link) }
      Add-Linha ""
    }
  } else {
    Add-Linha "_Nada coletado._"
  }
}

$infEdicao = ""
if ($Modo -eq "informativo" -or $Modo -eq "ambos") {
  Write-Host "Consultando Informativo de Jurisprudencia do STJ ..."
  $inf = Get-InformativoPenal
  Add-Linha ""
  Add-Linha "## Bloco 3 - Informativo de Jurisprudencia do STJ (secoes penais)"
  if (-not $inf) {
    Add-Linha "_Fonte indisponivel na coleta de hoje._"
    $falhas += "STJ/Informativo"
  } else {
    $infEdicao = $inf.edicao
    Add-Linha ("Edicao corrente: **{0}** | fonte: {1}" -f $inf.edicao, $inf.url)
    Add-Linha "> O Informativo e SEMANAL. Se a edicao for a mesma do relatorio anterior, apenas registre isso e nao repita o conteudo."
    Add-Linha ""
    if ($inf.blocos.Count -eq 0) {
      Add-Linha "_Esta edicao nao traz secao de direito penal ou processual penal._"
    } else {
      foreach ($b in $inf.blocos) {
        Add-Linha ("> " + ($b -replace "`n", "`n> "))
        Add-Linha ""
      }
    }
  }
}

$sb.ToString() | Out-File -FilePath $Saida -Encoding utf8
Write-Host ""
Write-Host ("Digest gravado em: " + $Saida)
Write-Host ("Publicacoes do escritorio: {0} (criminais: {1}) | Panorama STJ penal: {2} de {3}" -f `
  $pubs.Count, @($pubs | Where-Object { $_.criminal }).Count, $panorama.Count, $panoramaTotal)
if ($falhas.Count -gt 0) { Write-Host ("FALHAS: " + ($falhas -join ", ")) }
