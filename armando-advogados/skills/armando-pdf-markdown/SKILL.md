---
name: armando-pdf-markdown
description: Converte PDF em Markdown enxuto antes de ler — remonta os parágrafos, marca os títulos e remove cabeçalho, rodapé e carimbo de assinatura repetidos em toda página, gastando uma fração dos tokens de ler o PDF direto. Use SEMPRE que precisar LER o conteúdo de um PDF nesta máquina (processo do PJe/eSAJ, petição, contrato, acórdão, laudo, contrato social) — inclusive quando o usuário só disser "analisa esse processo", "resume esse acórdão", "o que diz esse contrato", "lê esse PDF pra mim", "dá uma olhada nesse arquivo" — e também quando pedir explicitamente "converter PDF", "transformar PDF em markdown", "extrair o texto do PDF", "passar esse PDF pra .md", "gastar menos token com esse arquivo".
---

# PDF → Markdown

Esta máquina **não abre PDF direto**: o `Read` nativo falha ("pdftoppm is not installed"),
não há Python nem poppler, e abrir PDF pelo Word via COM trava. O caminho é converter primeiro.

## Como rodar

Localize o script e converta (uma linha só):

```powershell
$exe = @("$env:CLAUDE_PLUGIN_ROOT\skills\armando-pdf-markdown\scripts\pdf2md.ps1", "$env:USERPROFILE\.claude\skills\armando-pdf-markdown\scripts\pdf2md.ps1", "$env:USERPROFILE\.claude\tools\pdf2md.ps1") | Where-Object { $_ -and (Test-Path $_) } | Select-Object -First 1
powershell -NoProfile -ExecutionPolicy Bypass -File $exe "C:\caminho\processo.pdf" -Out "C:\caminho\processo.md"
```

Sem `-Out`, grava o `.md` ao lado do PDF. Aceita vários arquivos e pastas de uma vez:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File $exe "C:\pasta\do\processo" -Out "C:\saida"
```

Depois é só `Read` no `.md`.

**Não converta o mesmo PDF duas vezes**: se já existe um `.md` ao lado, com data posterior à do
PDF, leia esse.

## Opções

| Flag | Para que |
|---|---|
| `-ManterRepetidos` | Não remover cabeçalho/rodapé/carimbo repetidos. Use quando o carimbo importar (conferir assinatura digital, id de documento do PJe). |
| `-SemMarcasDePagina` | Sai sem as marcas `[p. 12]`. Só use se o documento não for ser citado por página. |
| `-Linhas` | Gera também um `.linhas.tsv` com página, posição, tamanho e negrito de cada linha crua. Use para diagnosticar saída torta. |
| `-Abrir` | Abre o `.md` ao terminar. |

## O que a saída tem

- Parágrafos remontados (a linha justificada do PDF vira parágrafo corrido).
- Títulos em `#`/`##`/`###`, detectados por tamanho de fonte, negrito e caixa alta.
- Marcas `[p. 12]` para citar a folha certa.
- Primeira linha em comentário HTML com o nome do arquivo, o número de páginas e quantas
  linhas de carimbo foram removidas.

## Limites — leia antes de confiar na saída

- **Não faz OCR.** PDF digitalizado sai vazio. O script avisa
  ("quase não há texto por página — PDF provavelmente digitalizado"). Nesse caso, diga isso ao
  usuário em vez de analisar o pouco que saiu: o `.md` terá só o carimbo da margem.
- **Tabela vira texto corrido**, sem grade. Serve para ler, não para conferir coluna por coluna.
- Página de rosto do PJe e índice de documentos saem como texto solto — é tabela.
- Se o PDF tiver camada de OCR ruim (processo antigo digitalizado), a saída herda o erro do OCR.
  Palavra truncada ou sem sentido no `.md` provavelmente já estava assim no PDF; confira o
  original antes de citar trecho literal em peça.
- **Nunca cite trecho literal, número de processo, valor ou data lidos aqui sem conferir no
  PDF original** se o texto for para uma peça.

## Quando o carimbo importa

A remoção de repetidos casa o carimbo pelos 60 primeiros caracteres, porque nome do signatário e
código de conferência mudam a cada página. Isso apaga a linha inteira do eSAJ/TJSP
("Este documento é cópia do original, assinado digitalmente por…"). Se a tarefa for justamente
conferir quem assinou ou o código de autenticação, rode com `-ManterRepetidos`.

## Fora do Claude Code (Claude na nuvem / Cowork)

O script é PowerShell e só roda em máquina Windows com Claude Code. No ambiente da nuvem, use a
skill pública `pdf` (que tem Python e poppler) e depois aplique o mesmo cuidado a mão: junte as
linhas quebradas em parágrafo e apague a linha de carimbo que se repete em toda página, que é
onde o token vai embora.

## Para o usuário converter sozinho, sem abrir o Claude

`scripts/PDF para Markdown.cmd` — duplo clique abre o seletor de arquivos, ou arraste PDFs (ou uma
pasta) para cima dele. Também dá para instalar no menu **Enviar para** do Windows:

```powershell
$w = New-Object -ComObject WScript.Shell
$lnk = $w.CreateShortcut((Join-Path ([Environment]::GetFolderPath('ApplicationData')) 'Microsoft\Windows\SendTo\PDF para Markdown.lnk'))
$lnk.TargetPath = "<caminho>\scripts\PDF para Markdown.cmd"; $lnk.IconLocation = 'shell32.dll,70'; $lnk.Save()
```
