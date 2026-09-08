# Variáveis do modelo de contestação trabalhista
### Armando Advogados — extraído de 64 contestações do Drive (57 trabalhistas, 6 cíveis, 1 sem número de autos)

---

## 1. Como o corpus foi lido

As 64 peças foram baixadas do Drive, descompactadas localmente e convertidas em texto (2,1 MB). A análise abaixo percorre o texto integral de todas elas, não uma amostra.

Classificação pelo número dos autos que consta do cabeçalho:

| Ramo | Peças | Foros identificados |
|---|---|---|
| Trabalhista | 57 | TRT-10 (Palmas 0801/0802, Gurupi 0821), TRT-8 (Parauapebas 0114/0130), TRT-11 (Boa Vista 0052), TRT-16 (MA 0008/0011), TRT-17 (Vitória 0006/0013), TRT-18 (Goiânia 0015/0131) |
| Cível | 6 | TJTO (Palmas 2729, Novo Acordo 2728, Porto Nacional 2731) |
| Sem número de autos | 1 | `Contestação - Andreza` |

---

## 2. Variáveis de cabeçalho

| Variável | Valores no acervo | Observação |
|---|---|---|
| `{{JUIZO_ORDINAL}}` | 1ª, 2ª, 3ª, 6ª, 13ª, 15ª — ou vazio | Gurupi, Luziânia e Bacabal são vara única: sai sem ordinal |
| `{{CIDADE_VARA}}` | Palmas (42), Gurupi (3), Parauapebas (3), Vitória (3), Boa Vista (2), Goiânia, Luziânia, Balsas, Bacabal | |
| `{{UF_VARA}}` | TO, PA, ES, RR, GO, MA | |
| `{{NUM_PROCESSO}}` | formato `NNNNNNN-DD.AAAA.5.RR.OOOO` | |
| `{{RECLAMANTE_NOME}}` | — | caixa alta |
| `{{RECLAMADA_RAZAO}}` | — | acrescentar `E OUTROS` no litisconsórcio |

**Fórmula do endereçamento.** A dominante é `AO DOUTO JUÍZO DA {{JUIZO_ORDINAL}} VARA DO TRABALHO DE {{CIDADE_VARA}}/{{UF_VARA}}.`, em 26 peças. Convivem no acervo outras 8 variantes (`AO JUÍZO DA…`, `… DE PALMAS - TOCANTINS`, `… DE PALMAS - TO`), sem critério aparente. O modelo fixa a forma dominante.

---

## 3. Variáveis do preâmbulo

| Variável | Valores no acervo |
|---|---|
| `{{RECLAMADA_RAZAO}}` | — |
| `{{RECLAMADA_CNPJ}}` | presente em 11 peças; ausente nas demais |
| `{{RECLAMADA_ENDERECO}}` | presente em 9 peças |
| `{{CONCORDANCIA_QUALIFICADA}}` | `qualificada` (30) · `qualificado` (4) · `qualificadas` (6) · `qualificados` (4) |
| `{{CONCORDANCIA_ADVOGADO}}` | `seu advogado` (dominante) · `seus advogados abaixo subscritos` (6) |

**Fórmula dominante, em 27 peças:**

> `{{RECLAMADA_RAZAO}}`, já devidamente **{{CONCORDANCIA_QUALIFICADA}}** nos autos do processo em epígrafe, por intermédio de **{{CONCORDANCIA_ADVOGADO}}** (procuração anexa), vem à presença de Vossa Excelência, nos moldes do artigo 847 da CLT, oferecer **CONTESTAÇÃO** aos termos da Reclamação Trabalhista movida por `{{RECLAMANTE_NOME}}`, o que passa a fazer pelas razões e fundamentos jurídicos a seguir expostos.

Variante para IDPJ, em 3 peças: troca `nos moldes do artigo 847 da CLT` por `nos moldes do artigo 135 do CPC e em cumprimento ao Despacho de ID …`.

---

## 4. Variáveis de fato

**Frase-molde do acervo:**

> O Reclamante ingressou com a presente Reclamação Trabalhista, alegando que foi **{{ADMITIDO_A}}** em `{{DATA_ADMISSAO}}`, para exercer a função de `{{FUNCAO}}`, percebendo como remuneração a importância mensal de R$ `{{SALARIO_NUM}}` (`{{SALARIO_EXTENSO}}`).

| Variável | Notas |
|---|---|
| `{{DATA_ADMISSAO}}` | — |
| `{{ADMITIDO_A}}` | concordar com o gênero do reclamante — ver defeito nº 5 |
| `{{FUNCAO}}` | motorista, eletricista, pedreiro, farmacêutica, vendedora, analista de licitação, operador de pá carregadeira, cotador de preços, contadora, operador de prensa de enfardamento… |
| `{{SALARIO_NUM}}` / `{{SALARIO_EXTENSO}}` | **conferir um contra o outro** — ver defeito nº 9 |
| `{{REMUNERACAO_VARIAVEL}}` | média de comissões e prêmios, quando houver |
| `{{JORNADA_CONTRATUAL}}` / `{{INTERVALO}}` | só quando houver pedido de jornada |
| `{{DATA_RESCISAO}}` | — |
| `{{MODALIDADE_RESCISAO}}` | dispensa sem justa causa · pedido de demissão · rescisão indireta pleiteada · justa causa · abandono de emprego · término de contrato de experiência |
| `{{ROL_PEDIDOS_INICIAL}}` | é o que define quais módulos do item 5 ficam ligados |
| `{{VALOR_CAUSA_NUM}}` / `{{VALOR_CAUSA_EXTENSO}}` | — |
| `{{RENDA_DECLARADA}}` | para a impugnação à gratuidade |
| `{{TETO_40PCT_RGPS}}` | 40% do teto do RGPS — atualizar pela portaria vigente; o acervo traz R$ 3.002,99 |

---

## 6. Variáveis do fecho e da assinatura

| Variável | Valores |
|---|---|
| `{{CIDADE_FECHO}}` | Palmas/TO em 47 peças — o escritório assina da sede, ainda que a vara seja de outro estado |
| `{{DATA_FECHO}}` | `data e hora certificadas pelo sistema` (45) · data por extenso (8) |
| `{{ADVOGADOS}}` | conjunto variável, ver quadro |

**Quadro de advogados apurado** (nº de peças em que o registro aparece):

| Advogado | OAB no acervo | Peças |
|---|---|---|
| Henrique Rocha Armando | OAB/TO 10.167 | 70 |
| Sandro Henrique Armando | OAB/TO 11.459-A · **OAB/SP 128.510 (ver controle-de-qualidade item 4)** | 59 |
| Lucas Almeida Monteiro | OAB/DF 70.224 | 19 |
| Maiane Lukarine S. do Carmo | OAB/TO 11.661 | 18 |
| Bruno Otávio Pereira Alves | OAB/TO 4.893 | 11 |
| Quintiliana Janis Cardoso Marques | OAB/TO 9.272 | 3 |
| Raquel Xavier Mendes | OAB/DF 70.204 | 2 |
| Gabriela Neitzke · Jennifer Letícia V. da Cunha · Luciana de Jesus | OAB/TO 9.088 · 12.080 · 13.702-B | 1 cada |

Honorários pedidos: **15% em 80 ocorrências**, sem uma única exceção no acervo.

---

