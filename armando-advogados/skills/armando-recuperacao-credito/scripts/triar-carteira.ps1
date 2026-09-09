<#
.SYNOPSIS
  Triagem de carteira de inadimplentes — Armando Advogados.

.DESCRIPTION
  Automatiza os filtros 1 e 3 da skill armando-recuperacao-credito sobre uma
  planilha de inadimplencia: prescricao por vencimento, coerencia do valor
  atualizado, classificacao da via cabivel e status sugerido.

  Nao substitui a conferencia documental. O filtro 2 (documento habil) depende
  de olhar o PDF e ver se ha canhoto assinado — nenhum script faz isso.
  E o veredito de prescricao e' provisorio: cabe procurar interrupcao
  (art. 202, VI, do CC — pagamento parcial, protesto, reconhecimento escrito)
  antes de descartar credito.

.PARAMETER Path
  Caminho do .csv da carteira. Aceita separador ';' ou ','.
  Colunas reconhecidas (o nome pode variar; a busca e' por palavra-chave):
    devedor | vencimento | principal | atualizado | titulo | nf | assinado

.PARAMETER DataBase
  Data de referencia da triagem. Padrao: hoje.

.PARAMETER Csv
  Caminho para gravar o resultado em CSV, no formato de colunas da casa.

.EXAMPLE
  .\triar-carteira.ps1 -Path "C:\Users\muril\Downloads\carteira.csv"

.EXAMPLE
  .\triar-carteira.ps1 -Path ".\carteira.csv" -Csv ".\triagem-saida.csv"
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, Position = 0)][string]$Path,
    [datetime]$DataBase = (Get-Date),
    [string]$Csv
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'lib-peca.ps1')

if (-not (Test-Path -LiteralPath $Path)) {
    throw "Arquivo nao encontrado: $Path"
}

# ------------------------------------------------------------ leitura do CSV
$primeira = (Get-Content -LiteralPath $Path -TotalCount 1 -Encoding UTF8)
$delim = if (($primeira -split ';').Count -gt ($primeira -split ',').Count) { ';' } else { ',' }
$linhas = @(Import-Csv -LiteralPath $Path -Delimiter $delim -Encoding UTF8)

if ($linhas.Count -eq 0) { throw 'Planilha vazia ou sem cabecalho.' }

$colunas = $linhas[0].PSObject.Properties.Name

function Find-Coluna {
    param([string[]]$Chaves)
    foreach ($chave in $Chaves) {
        $hit = $colunas | Where-Object { $_ -and ($_ -replace '[^A-Za-z]', '') -match "(?i)$chave" } | Select-Object -First 1
        if ($hit) { return $hit }
    }
    return $null
}

$cDevedor    = Find-Coluna @('devedor', 'cliente', 'nome', 'razao')
$cVencimento = Find-Coluna @('vencimento', 'venc', 'datavenc', 'ano')
$cPrincipal  = Find-Coluna @('principal', 'valorprincipal', 'nominal', 'valor')
$cAtualizado = Find-Coluna @('atualizado', 'comjuros', 'juros')
$cTitulo     = Find-Coluna @('titulo', 'especie', 'documento', 'doc')
$cNf         = Find-Coluna @('possuinf', 'nf', 'notafiscal')
$cAssinado   = Find-Coluna @('assinado', 'canhoto', 'docsassinados')

$achados = @()

if (-not $cDevedor)    { $achados += New-Achado -Severidade 'ALTA'  -Categoria 'Planilha' -Mensagem 'Coluna de devedor nao identificada' }
if (-not $cVencimento) { $achados += New-Achado -Severidade 'ALTA'  -Categoria 'Planilha' -Mensagem 'Coluna de vencimento nao identificada — sem ela nao ha calculo de prescricao' }
if (-not $cPrincipal)  { $achados += New-Achado -Severidade 'MEDIA' -Categoria 'Planilha' -Mensagem 'Coluna de valor principal nao identificada' }
if (-not $cAssinado)   { $achados += New-Achado -Severidade 'MEDIA' -Categoria 'Planilha' -Mensagem 'Coluna de documento assinado (canhoto) ausente — o filtro 2 fica inteiramente manual' }

if (-not $cDevedor -or -not $cVencimento) {
    $codigo = Write-Relatorio -Achados $achados -Titulo 'Triagem de carteira'
    exit $codigo
}

# ------------------------------------------------------------------ parsers
function ConvertTo-Valor {
    param([string]$Texto)
    if ([string]::IsNullOrWhiteSpace($Texto)) { return $null }
    $t = ($Texto -replace '(?i)r\$', '').Trim()
    $t = $t -replace '[^\d,.\-]', ''
    if ($t -eq '' -or $t -eq '-') { return $null }
    # Ultimo separador manda: se for virgula, formato BR; se ponto, formato US.
    $ultVirg = $t.LastIndexOf(',')
    $ultPont = $t.LastIndexOf('.')
    if ($ultVirg -gt $ultPont) { $t = ($t -replace '\.', '') -replace ',', '.' }
    else                       { $t = $t -replace ',', '' }
    $valor = 0.0
    if ([double]::TryParse($t, [Globalization.NumberStyles]::Float,
            [Globalization.CultureInfo]::InvariantCulture, [ref]$valor)) { return $valor }
    return $null
}

function ConvertTo-Vencimento {
    param([string]$Texto)
    if ([string]::IsNullOrWhiteSpace($Texto)) { return $null }
    $t = $Texto.Trim()
    # Ano isolado: assume 31/12, o cenario mais favoravel ao credor.
    if ($t -match '^\s*(19|20)\d{2}\s*$') { return [datetime]::new([int]$t, 12, 31) }
    $formatos = @('dd/MM/yyyy', 'd/M/yyyy', 'MM/dd/yyyy', 'M/d/yyyy', 'yyyy-MM-dd', 'dd-MM-yyyy')
    $dt = [datetime]::MinValue
    foreach ($f in $formatos) {
        if ([datetime]::TryParseExact($t, $f, [Globalization.CultureInfo]::InvariantCulture,
                [Globalization.DateTimeStyles]::None, [ref]$dt)) { return $dt }
    }
    if ([datetime]::TryParse($t, [Globalization.CultureInfo]::GetCultureInfo('pt-BR'),
            [Globalization.DateTimeStyles]::None, [ref]$dt)) { return $dt }
    return $null
}

function Get-Via {
    <#
      Filtro 3: a especie do titulo define a via. Considera tambem a prescricao
      EXECUTIVA curta das cambiais — que nao mata o credito, rebaixa a via
      (cheque 6 meses; NP e duplicata 3 anos).
    #>
    param([string]$Titulo, [string]$TemNf, [string]$Assinado, [datetime]$Vencimento, [datetime]$DataBase)

    $t = "$Titulo".ToLowerInvariant()
    $assinadoSim = "$Assinado" -match '(?i)^\s*(s|sim|x|true|1)'
    $nfSim       = "$TemNf"    -match '(?i)^\s*(s|sim|x|true|1)'
    $temVenc     = $Vencimento -ne [datetime]::MinValue

    if ($t -match 'acordo|confiss') { return 'Execucao (art. 784, III + 4o)' }
    if ($t -match 'honorar')        { return 'Execucao (art. 784, XII + art. 24 EAOAB)' }

    if ($t -match 'cheque') {
        # Lei 7.357/85: 6 meses do fim do prazo de apresentacao (usa-se 30 dias).
        if ($temVenc -and $Vencimento.AddDays(30).AddMonths(6) -lt $DataBase) {
            return 'Monitoria (art. 700) — cheque prescrito, Sum. 299/531 STJ'
        }
        return 'Execucao (art. 784, I) — conferir prazo de apresentacao'
    }
    if ($t -match 'promiss') {
        # LUG: 3 anos do vencimento.
        if ($temVenc -and $Vencimento.AddYears(3) -lt $DataBase) {
            return 'Monitoria (art. 700) — NP com execucao prescrita (3 anos)'
        }
        return 'Execucao (art. 784, I)'
    }
    if ($t -match 'duplicata') {
        # Art. 18 da Lei 5.474/68: 3 anos contra o sacado.
        if ($temVenc -and $Vencimento.AddYears(3) -lt $DataBase) {
            return 'Monitoria (art. 700) — duplicata com execucao prescrita (3 anos)'
        }
        return 'Execucao (art. 784, I) — se aceita'
    }
    if ($t -match 'contrato') {
        if ($assinadoSim) { return 'Execucao (art. 784, III)' }
        return 'Monitoria (art. 700) — contrato sem testemunhas'
    }
    # O titulo declarado manda sobre a coluna "Possui NF?": no acervo ha linhas
    # marcadas NF=SIM cuja pasta so tem boleto.
    if ($t -match 'boleto') { return 'Nenhuma — so boleto. Notificar e protestar' }
    if ($t -match 'nota fiscal|^nf$|fatura' -or ($t -eq '' -and $nfSim)) {
        if ($assinadoSim) { return 'Monitoria (art. 700) — NF com canhoto' }
        return 'Monitoria fragil — notificar antes para suprir canhoto'
    }
    return 'Indefinida — apurar especie do titulo'
}

# ------------------------------------------------------------------ triagem
$resultado = @()
$semData = 0

foreach ($linha in $linhas) {
    $devedor = "$($linha.$cDevedor)".Trim()
    if ([string]::IsNullOrWhiteSpace($devedor)) { continue }

    $venc       = ConvertTo-Vencimento "$($linha.$cVencimento)"
    $principal  = if ($cPrincipal)  { ConvertTo-Valor "$($linha.$cPrincipal)" }  else { $null }
    $atualizado = if ($cAtualizado) { ConvertTo-Valor "$($linha.$cAtualizado)" } else { $null }
    $titulo     = if ($cTitulo)     { "$($linha.$cTitulo)" }   else { '' }
    $temNf      = if ($cNf)         { "$($linha.$cNf)" }       else { '' }
    $assinado   = if ($cAssinado)   { "$($linha.$cAssinado)" } else { '' }

    $vencParaVia = if ($null -eq $venc) { [datetime]::MinValue } else { $venc }
    $via = Get-Via -Titulo $titulo -TemNf $temNf -Assinado $assinado `
                   -Vencimento $vencParaVia -DataBase $DataBase

    if ($null -eq $venc) {
        $semData++
        $resultado += [pscustomobject]@{
            Devedor = $devedor; Vencimento = ''; MesesRestantes = ''
            Principal = $principal; Atualizado = $atualizado
            Status = 'Triagem'; Via = $via
            Observacao = 'Vencimento nao interpretado — prescricao nao calculada'
        }
        continue
    }

    $limite = $venc.AddYears(5)
    $mesesRestantes = [math]::Floor(($limite - $DataBase).TotalDays / 30.44)

    if ($limite -lt $DataBase) {
        $status = 'Prescrito'
        $obs = ('Prescrito em {0:dd/MM/yyyy}, ha {1} mes(es) — conferir interrupcao (art. 202, VI, do CC) antes de descartar' -f $limite, [math]::Abs($mesesRestantes))
    }
    elseif ($mesesRestantes -le 12) {
        $status = 'Ajuizar'
        $obs = ('URGENTE: prescreve em {0} mes(es), em {1:dd/MM/yyyy}' -f $mesesRestantes, $limite)
    }
    elseif ($via -match 'Nenhuma|fragil|Indefinida') {
        $status = if ($via -match 'Indefinida') { 'Triagem' } else { 'Notificar' }
        $obs = 'Prazo em curso, falta documento habil'
    }
    else {
        $status = 'Ajuizar'
        $obs = ('Prazo em curso — prescreve em {0:dd/MM/yyyy}' -f $limite)
    }

    if ($null -ne $principal -and $null -ne $atualizado -and $atualizado -lt $principal) {
        $achados += New-Achado -Severidade 'ALTA' -Categoria 'Dado corrompido' `
            -Mensagem ('{0}: valor atualizado menor que o principal — atualizacao nao reduz divida' -f $devedor) `
            -Trecho ('principal {0:N2} / atualizado {1:N2}' -f $principal, $atualizado)
        $obs += ' | ATUALIZADO < PRINCIPAL: refazer calculo'
    }

    $resultado += [pscustomobject]@{
        Devedor = $devedor; Vencimento = $venc.ToString('dd/MM/yyyy')
        MesesRestantes = $mesesRestantes
        Principal = $principal; Atualizado = $atualizado
        Status = $status; Via = $via; Observacao = $obs
    }
}

if ($resultado.Count -eq 0) { throw 'Nenhuma linha com devedor identificavel.' }

# ------------------------------------------------------------------- relato
$fmt = 'N2'
Write-Host ''
Write-Host '=== Triagem de carteira ===' -ForegroundColor Cyan
Write-Host ("Arquivo: {0}" -f (Split-Path $Path -Leaf))
Write-Host ("Data-base: {0:dd/MM/yyyy}   Registros: {1}" -f $DataBase, $resultado.Count)

# Out-String forca a renderizacao aqui: sem ele o Format-Table sai depois dos
# agregados, porque o pipeline de formatacao e' preguicoso.
$tabela = $resultado |
    Select-Object Devedor, Vencimento,
        @{ n = 'Meses'; e = { if ($_.MesesRestantes -eq '') { '' } elseif ($_.MesesRestantes -lt 0) { 'VENCIDO' } else { $_.MesesRestantes } } },
        @{ n = 'Principal';  e = { if ($null -ne $_.Principal)  { $_.Principal.ToString($fmt) }  else { '' } } },
        @{ n = 'Atualizado'; e = { if ($null -ne $_.Atualizado) { $_.Atualizado.ToString($fmt) } else { '' } } },
        Status, Via |
    Format-Table -AutoSize -Wrap | Out-String -Width 200
Write-Host $tabela

# ---------------------------------------------------------------- agregados
$somaP = ($resultado | Where-Object { $null -ne $_.Principal } | Measure-Object Principal -Sum).Sum
$prescritos = @($resultado | Where-Object { $_.Status -eq 'Prescrito' })
$somaPresc = ($prescritos | Where-Object { $null -ne $_.Principal } | Measure-Object Principal -Sum).Sum
if (-not $somaP) { $somaP = 0 }
if (-not $somaPresc) { $somaPresc = 0 }

Write-Host '--- Agregados ---' -ForegroundColor Cyan
foreach ($s in @('Ajuizar', 'Notificar', 'Triagem', 'Prescrito')) {
    $grupo = @($resultado | Where-Object { $_.Status -eq $s })
    if ($grupo.Count -eq 0) { continue }
    $soma = ($grupo | Where-Object { $null -ne $_.Principal } | Measure-Object Principal -Sum).Sum
    if (-not $soma) { $soma = 0 }
    Write-Host ("  {0,-10} {1,4} devedor(es)   R$ {2,14}" -f $s, $grupo.Count, $soma.ToString($fmt))
}
Write-Host ("  {0,-10} {1,4}                R$ {2,14}" -f 'TOTAL', $resultado.Count, $somaP.ToString($fmt))

if ($somaP -gt 0 -and $somaPresc -gt 0) {
    $pct = [math]::Round(100 * $somaPresc / $somaP, 1)
    Write-Host ''
    Write-Host ("PRESCRITO: R$ {0} — {1}% do principal da carteira." -f $somaPresc.ToString($fmt), $pct) -ForegroundColor Red
}

$urgentes = @($resultado | Where-Object { $_.MesesRestantes -is [double] -and $_.MesesRestantes -ge 0 -and $_.MesesRestantes -le 12 })
if ($urgentes.Count -gt 0) {
    $achados += New-Achado -Severidade 'ALTA' -Categoria 'Prescricao iminente' `
        -Mensagem ('{0} devedor(es) prescrevem em 12 meses ou menos — priorizar' -f $urgentes.Count) `
        -Trecho (($urgentes | Select-Object -First 8 | ForEach-Object { $_.Devedor }) -join '; ')
}
if ($semData -gt 0) {
    $achados += New-Achado -Severidade 'MEDIA' -Categoria 'Planilha' `
        -Mensagem ('{0} linha(s) com vencimento nao interpretado — prescricao nao calculada' -f $semData)
}
$indef = @($resultado | Where-Object { $_.Via -match 'Indefinida' }).Count
if ($indef -gt 0) {
    $achados += New-Achado -Severidade 'MEDIA' -Categoria 'Filtro 3' `
        -Mensagem ('{0} linha(s) sem especie de titulo declarada — via indefinida' -f $indef)
}

if ($Csv) {
    $resultado | Export-Csv -LiteralPath $Csv -Delimiter ';' -NoTypeInformation -Encoding UTF8
    Write-Host ''
    Write-Host ("Resultado gravado em: {0}" -f $Csv) -ForegroundColor Green
}

$codigo = Write-Relatorio -Achados $achados -Titulo 'Achados da triagem'
Write-Host 'Lembrete: o filtro 2 (canhoto assinado) exige olhar o documento — nenhum script cobre.' -ForegroundColor DarkGray
Write-Host 'Antes de aceitar "Prescrito", procure pagamento parcial, protesto ou reconhecimento escrito.' -ForegroundColor DarkGray
Write-Host ''
exit $codigo
