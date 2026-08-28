---
name: armando-pdf-markdown
description: Converte PDF em Markdown enxuto antes de ler — remonta os parágrafos, marca os títulos e remove cabeçalho, rodapé e carimbo de assinatura repetidos em toda página, gastando uma fração dos tokens de ler o PDF direto. Use SEMPRE que precisar LER o conteúdo de um PDF (processo do PJe/eSAJ, petição, contrato, acórdão, laudo, contrato social) — inclusive quando o usuário só disser "analisa esse processo", "resume esse acórdão", "o que diz esse contrato", "lê esse PDF pra mim", "dá uma olhada nesse arquivo" — e também quando pedir explicitamente "converter PDF", "transformar PDF em markdown", "extrair o texto do PDF", "passar esse PDF pra .md", "gastar menos token com esse arquivo".
---

# PDF → Markdown

Ler o PDF direto gasta muito token e, em máquina Windows sem Python, nem funciona (o `Read`
nativo falha com "pdftoppm is not installed" e abrir pelo Word via COM trava). Converta primeiro.

**Escolha o motor pelo ambiente:**

| Ambiente | Motor |
|---|---|
| Claude Code em Windows | `scripts/pdf2md.ps1` (PowerShell, sem dependência) |
| Claude na nuvem, Cowork, Linux, Mac | `scripts/pdf2md.py` (Python + `pdfplumber`) |

Os dois produzem o mesmo formato de saída e aceitam as mesmas opções.

## Como rodar em Windows (Claude Code)

Localize o script e converta (uma linha só):

```powershell
$exe = @("$env:CLAUDE_PLUGIN_ROOT\skills\armando-pdf-markdown\scripts\pdf2md.ps1", "$env:USERPROFILE\.claude\skills\armando-pdf-markdown\scripts\pdf2md.ps1", "$env:USERPROFILE\.claude\tools\pdf2md.ps1") | Where-Object { $_ -and (Test-Path $_) } | Select-Object -First 1
powershell -NoProfile -ExecutionPolicy Bypass -File $exe "C:\caminho\processo.pdf" -Out "C:\caminho\processo.md"
```

Sem `-Out`, grava o `.md` ao lado do PDF. Aceita vários arquivos e pastas de uma vez:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File $exe "C:\pasta\do\processo" -Out "C:\saida"
```

## Como rodar na nuvem / Cowork / Linux / Mac

```bash
PDF2MD=$(ls "$CLAUDE_PLUGIN_ROOT/skills/armando-pdf-markdown/scripts/pdf2md.py" \
            "$HOME/.claude/skills/armando-pdf-markdown/scripts/pdf2md.py" 2>/dev/null | head -1)
python3 "$PDF2MD" processo.pdf --out processo.md
```

Se `pdfplumber` não estiver instalado, instale (`pip install pdfplumber`). Sem ele o script cai
para `pypdf`, que não devolve a posição do texto — a remontagem de parágrafo e a remoção de
carimbo saem bem piores, e o script avisa quando isso acontece. As opções são as mesmas, com dois
hífens: `--manter-repetidos`, `--sem-marcas-de-pagina`, `--linhas`.

> A versão PowerShell foi testada em PDF do PJe/TRF1, eSAJ/TJSP, Word, Google Docs e livro de 98
> páginas. **A versão Python ainda não teve uma execução real** — na primeira vez que usá-la,
> confira a saída contra o PDF antes de confiar. Se sair torta, rode com `--linhas` e reporte.

Depois é só `Read` no `.md`.

**Não converta o mesmo PDF duas vezes**: se já existe um `.md` ao lado, com data posterior à do
PDF, leia esse.

## Opções

| PowerShell | Python | Para que |
|---|---|---|
| `-ManterRepetidos` | `--manter-repetidos` | Não remover cabeçalho/rodapé/carimbo repetidos. Use quando o carimbo importar (conferir assinatura digital, id de documento do PJe). |
| `-SemMarcasDePagina` | `--sem-marcas-de-pagina` | Sai sem as marcas `[p. 12]`. Só use se o documento não for ser citado por página. |
| `-Linhas` | `--linhas` | Gera também um `.linhas.tsv` com página, posição, tamanho e negrito de cada linha crua. Use para diagnosticar saída torta. |
| `-Abrir` | — | Abre o `.md` ao terminar. |

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

## Para o usuário converter sozinho, sem abrir o Claude

`scripts/PDF para Markdown.cmd` — duplo clique abre o seletor de arquivos, ou arraste PDFs (ou uma
pasta) para cima dele. Também dá para instalar no menu **Enviar para** do Windows:

```powershell
$w = New-Object -ComObject WScript.Shell
$lnk = $w.CreateShortcut((Join-Path ([Environment]::GetFolderPath('ApplicationData')) 'Microsoft\Windows\SendTo\PDF para Markdown.lnk'))
$lnk.TargetPath = "<caminho>\scripts\PDF para Markdown.cmd"; $lnk.IconLocation = 'shell32.dll,70'; $lnk.Save()
```
