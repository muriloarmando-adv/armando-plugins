---
name: armando-timbrado
description: Gera documentos jurídicos em .docx no papel timbrado do escritório Armando Advogados, com a formatação da casa — Book Antiqua 12, entrelinha 1,5, **espaçamento de 8 pt entre parágrafos**, justificado e recuo de primeira linha de 1,5 cm. Use SEMPRE que o usuário pedir para redigir, criar ou gerar qualquer peça ou documento jurídico em Word — petição inicial, contestação, recurso, memorial, parecer, requerimento, ofício, habeas corpus, mandado de segurança, agravo, apelação, embargos, memorando de análise contratual, minuta de contrato — mesmo que não mencione "papel timbrado" ou "Armando Advogados". Substitui a skill `armando-peticao`, da qual difere apenas pelo espaçamento de 8 pt entre parágrafos.
---

# Petição e documentos no timbrado — Armando Advogados

Gera documentos jurídicos prontos para uso com o papel timbrado oficial do escritório,
aplicando automaticamente todas as formatações exigidas.

> **Diferença em relação à `armando-peticao`:** esta versão acrescenta **espaçamento de
> 8 pt depois de cada parágrafo** (`w:after="160"`). Todo o restante é idêntico. Use esta;
> a outra fica como histórico.

---

## Formatação Padrão

| Elemento         | Valor                          |
|-----------------|-------------------------------|
| Fonte           | Book Antiqua                  |
| Tamanho         | 12pt (24 half-points)         |
| Entrelinha      | 1,5 linhas (`line="360"`)     |
| **Espaçamento entre parágrafos** | **8 pt depois (`w:after="160"`)** |
| Alinhamento     | Justificado (`jc val="both"`) |
| 1ª linha        | 1,5 cm = 851 DXA              |
| Página          | A4 (11906 × 16838 DXA)        |
| Margens (DXA)   | top=1985, bottom=834, left=1260, right=1416 |

**Conversão:** `w:after` e `w:before` são expressos em vigésimos de ponto. Logo,
**8 pt = 160**. Não confundir com DXA (twips), usado em recuo e margem.

---

## Fluxo de Trabalho

### 1. Copiar o template

O template é o `assets/template_peticao.docx` **desta própria skill**. Localize o diretório da skill
antes de copiar — ele muda conforme a instalação (`/mnt/skills/user/armando-timbrado/` quando é skill
pessoal na nuvem; algo como `.../plugins/armando-advogados/skills/armando-timbrado/` quando vem pelo
plugin do escritório).

```bash
TIMBRADO=$(find / -name template_peticao.docx -path '*armando-timbrado*' 2>/dev/null | head -1)
cp "$TIMBRADO" /home/claude/peticao_output.docx
```

### 2. Descompactar

```bash
python /mnt/skills/public/docx/scripts/office/unpack.py /home/claude/peticao_output.docx /home/claude/peticao_unpacked/
```

### 3. Substituir o conteúdo do body

Editar `peticao_unpacked/word/document.xml` — substituir o `<w:body>` inteiro, preservando
o `<w:sectPr>` original (que contém as referências ao header/footer e margens de página).

**Estrutura do body:**

```xml
<w:body>
  <!-- PARÁGRAFOS DA PETIÇÃO AQUI -->
  <w:sectPr>
    <!-- MANTER O sectPr ORIGINAL DO TEMPLATE — NÃO ALTERAR -->
  </w:sectPr>
</w:body>
```

### 4. Estrutura de parágrafo padrão

Todo parágrafo de corpo da petição deve usar:

```xml
<w:p>
  <w:pPr>
    <w:spacing w:line="360" w:lineRule="auto" w:before="0" w:after="160"/>
    <w:ind w:left="0" w:right="0" w:firstLine="851"/>
    <w:jc w:val="both"/>
  </w:pPr>
  <w:r>
    <w:rPr>
      <w:rFonts w:ascii="Book Antiqua" w:hAnsi="Book Antiqua" w:cs="Book Antiqua" w:eastAsia="Book Antiqua"/>
      <w:sz w:val="24"/>
      <w:szCs w:val="24"/>
    </w:rPr>
    <w:t xml:space="preserve">Texto do parágrafo aqui.</w:t>
  </w:r>
</w:p>
```

### 5. Títulos e cabeçalhos da petição

Para títulos centralizados em negrito (ex.: "EXCELENTÍSSIMO SENHOR JUIZ", tipo da ação):

```xml
<w:p>
  <w:pPr>
    <w:spacing w:line="360" w:lineRule="auto" w:before="0" w:after="160"/>
    <w:ind w:left="0" w:right="0" w:firstLine="0"/>
    <w:jc w:val="center"/>
  </w:pPr>
  <w:r>
    <w:rPr>
      <w:rFonts w:ascii="Book Antiqua" w:hAnsi="Book Antiqua" w:cs="Book Antiqua" w:eastAsia="Book Antiqua"/>
      <w:b/>
      <w:sz w:val="24"/>
      <w:szCs w:val="24"/>
    </w:rPr>
    <w:t>TÍTULO AQUI</w:t>
  </w:r>
</w:p>
```

### 6. Parágrafos sem recuo de primeira linha

Para parágrafos que não devem ter recuo (ex.: qualificação das partes, rodapé narrativo):

```xml
<w:ind w:left="0" w:right="0" w:firstLine="0"/>
```

### 7. Parágrafo de fecho/local e data (alinhado à direita)

```xml
<w:pPr>
  <w:spacing w:line="360" w:lineRule="auto" w:before="0" w:after="160"/>
  <w:ind w:left="0" w:right="0" w:firstLine="0"/>
  <w:jc w:val="right"/>
</w:pPr>
```

### 8. Linhas em branco

Com o espaçamento de 8 pt ativo, o parágrafo vazio de separação passa a ser
**dispensável na maioria dos casos** — o respiro entre blocos já vem do `w:after`.
Use parágrafo vazio apenas onde se quiser salto visual maior (antes do bloco de
assinatura, por exemplo), e nesse caso zere o espaçamento dele para não somar duas
vezes:

```xml
<w:spacing w:line="360" w:lineRule="auto" w:before="0" w:after="0"/>
```

### 9. Empacotar

```bash
python /mnt/skills/public/docx/scripts/office/pack.py /home/claude/peticao_unpacked/ /home/claude/peticao_final.docx --original /home/claude/peticao_output.docx
```

### 10. Validar e entregar

```bash
python /mnt/skills/public/docx/scripts/office/validate.py /home/claude/peticao_final.docx
cp /home/claude/peticao_final.docx /mnt/user-data/outputs/peticao_final.docx
```

---

## Regras Críticas

- **NUNCA alterar o `<w:sectPr>`** do template — ele contém as referências ao papel timbrado (header/footer) e as margens corretas da página.
- **SEMPRE usar Book Antiqua** — não substituir por Arial, Times New Roman ou qualquer outra fonte.
- **`w:sz val="24"`** corresponde a 12pt (o valor em half-points).
- **`w:line="360"`** com `lineRule="auto"` = entrelinha 1,5.
- **`w:after="160"`** = 8 pt de espaçamento depois do parágrafo. **Aplicar em todos os
  parágrafos de corpo e de título**, exceto nos parágrafos vazios de separação.
- **`w:firstLine="851"`** = 1,5 cm (1 cm = ~567 DXA).
- **`w:jc val="both"`** = texto justificado.
- Títulos sem recuo de primeira linha usam `w:firstLine="0"`.
- Nunca usar `\n` — cada parágrafo é um `<w:p>` separado.
- Usar `xml:space="preserve"` em `<w:t>` quando o texto tiver espaços no início ou fim.

---

## Estrutura Típica de Petição

1. **Endereçamento** — centralizado, negrito, sem recuo (ex.: "EXCELENTÍSSIMO SENHOR DOUTOR JUIZ...")
2. **Qualificação do requerente** — com recuo de primeira linha, justificado
3. **Dos Fatos** — título centralizado + parágrafos com recuo
4. **Do Direito** — título centralizado + parágrafos com recuo
5. **Do Pedido** — título centralizado + parágrafos com recuo
6. **Fecho** — "Nestes termos, pede deferimento." (justificado, com recuo)
7. **Local e data** — alinhado à direita, sem recuo
8. **Assinatura** — centralizado

---

## Notas de Formatação Jurídica Brasileira

- Petições judiciais: parágrafo de abertura sem recuo; demais com recuo de 1ª linha.
- Recursos: manter mesma formatação, adicionar cabeçalho com número do processo.
- Pareceres, memorandos de análise contratual e minutas de contrato: usar a mesma
  formatação padrão desta skill.

---

## Ambiente de execução

O fluxo acima pressupõe ambiente com **Python** e os scripts de `docx` em
`/mnt/skills/public/docx/scripts/office/` — é o caso do Claude na nuvem e do Cowork.

**Em máquina Windows local não há Python.** Nesse ambiente, use a skill `docx`
disponível na sessão, ou manipule o `.docx` como arquivo ZIP: descompactar, editar
`word/document.xml` preservando o `sectPr`, recompactar. O template em
`assets/template_peticao.docx` é o mesmo nos dois casos.
