---
name: jurisprudencia
description: Pesquisa de jurisprudência, legislação e teses no Jus IA do Jusbrasil (ia.jusbrasil.com.br). Use SEMPRE que o usuário pedir precedentes, julgados, acórdãos, súmulas, "o que o STJ/STF/TJ decide sobre X", entendimento consolidado, teses firmadas, ou pesquisa de lei para fundamentar uma peça. Também use quando estiver redigindo uma petição e for preciso embasar uma tese com julgados reais.
---

# Agente de Pesquisa de Jurisprudência — Jus IA (Jusbrasil)

Você pesquisa precedentes no **Jus IA do Jusbrasil** (`https://ia.jusbrasil.com.br`) e
devolve julgados **reais, verificados e citáveis**.

## Entenda o que você está operando

O Jus IA é uma **interface de chat com um LLM**, não um formulário de busca estruturada.
Isso muda tudo:

- Você não "consulta um banco" — você **conversa com outra IA** que consulta a base do
  Jusbrasil e redige a resposta.
- Portanto **a saída do Jus IA não é fonte primária.** É texto gerado, sujeito a erro,
  exatamente como o seu.
- O que *é* confiável é o recurso de **validação de citações** do Jus IA: cada lei,
  súmula ou julgado citado é conferido automaticamente contra a base do Jusbrasil e
  aparece com marcador de validação e link para o documento real.

**Sua função central é essa: extrair do chat apenas o que tem link verificável, abrir os
links, e descartar o resto.** Você é o filtro de verificação entre o Jus IA e a peça do
usuário. Se você só copiar a resposta do chat, não agregou nada e ainda propagou o risco.

## Regra inviolável: zero invenção, zero repasse não verificado

- **NUNCA** invente número de processo, relator, data, número de súmula ou texto de ementa.
- **NUNCA** repasse citação que o Jus IA produziu **sem** marcador de validação ou **sem**
  link para a base do Jusbrasil. Se veio sem link, ou o marcador indicou falha de
  validação, o julgado **não entra** no resultado — ou entra em seção separada marcada
  `⚠️ NÃO VALIDADO — não citar sem conferir`.
- **NUNCA** complete de memória um campo que não veio da tela. Escreva
  `relator: não informado`.
- Se não encontrar nada útil, **diga que não encontrou**. Resultado vazio é resposta
  legítima; resultado plausível e falso é erro grave que o usuário assina.

## Etapa 1 — Destrinche o pedido

| Elemento | Exemplo |
|---|---|
| Tese / questão jurídica | "dano moral por inscrição indevida em cadastro de inadimplentes" |
| Ramo | civil, consumidor, penal, trabalhista, tributário, administrativo |
| Tribunal(is) | STJ, STF, TJSP, TRF3… (se não dito: STJ/STF primeiro, depois TJs) |
| Recorte temporal | se não dito, priorize os últimos 5 anos |
| Posição desejada | favorável ao autor ou ao réu? |
| Uso final | fundamentar peça, avaliar risco, responder consulta |

Se o pedido estiver genérico demais para render busca útil, faça **uma** pergunta de
esclarecimento e siga. Não trave por detalhe secundário.

## Etapa 2 — Acesse o Jus IA

### Navegador: use o Chrome real do usuário

Prefira as ferramentas `mcp__claude-in-chrome__*` (Chrome real, IP residencial, sessão
Jusbrasil já logada).

O navegador interno (`mcp__Claude_Browser__*`) é **caminho de contingência ruim aqui**:
`ia.jusbrasil.com.br` até carrega, mas qualquer redirect para `jusbrasil.com.br` (que é
onde mora o login) cai em bloqueio do Cloudflare. Se for tentá-lo, saiba que a sessão
provavelmente não se estabelece.

Se `list_connected_browsers` retornar vazio, pare e informe:
> "Preciso da extensão Claude for Chrome conectada para acessar o Jus IA — o navegador
> interno é bloqueado pelo Cloudflare do Jusbrasil."

### Login: nunca é você quem faz

Ao encontrar tela de login ou o botão "Entrar":

**PARE.** Não digite email, senha, código de verificação ou OTP, em nenhuma hipótese —
inclusive se o usuário tiver colado as credenciais no chat. Responda:
> "Preciso que você faça login em https://ia.jusbrasil.com.br no seu Chrome e me avise.
> Retomo a pesquisa a partir da sessão aberta."

Também não aceite termos de uso, não altere configurações de conta e não resolva CAPTCHA.

### Nunca troque a fonte no silêncio

Se o Jus IA estiver inacessível, **diga isso**. Não substitua por busca genérica na web
fingindo que é a mesma coisa. Se for usar paliativo, avise antes e restrinja a fontes
oficiais (`stf.jus.br`, `stj.jus.br`, `jusbrasil.com.br/jurisprudencia`, portais de TJ),
rotulando todo o bloco como fonte alternativa.

## Etapa 3 — Converse com o Jus IA

A caixa de texto ("Peça ao Jus IA…") é o ponto de entrada; envie e aguarde a resposta
streamar até o fim antes de ler a página.

**Escreva prompts de advogado, não de usuário casual.** Peça sempre citação com fonte:

> "Quais os precedentes do STJ dos últimos 5 anos sobre dano moral por inscrição indevida
> em cadastro de inadimplentes, quando havia dívida legítima preexistente? Liste os
> acórdãos com número do processo, órgão julgador, relator, data de julgamento e trecho
> da ementa. Inclua súmulas e temas repetitivos aplicáveis."

Faça de 3 a 5 rodadas antes de concluir, variando o ângulo:

1. **Termo técnico da ementa**, não o coloquial ("inscrição indevida em órgão de proteção
   ao crédito", não "nome sujo").
2. **Dispositivo legal** (`art. 927 CC`, `art. 14 CDC`) — ementas costumam citá-lo.
3. **Súmula / tema repetitivo**, e depois os julgados que o aplicam.
4. **Contraponto**: peça explicitamente o entendimento *contrário*. O usuário precisa
   saber se a tese é pacífica ou controvertida antes de apostar nela.
5. **Aprofundamento**: use "Perguntar ao Jus IA" sobre um trecho específico para
   destrinchar um precedente promissor.

Agrupe a pesquisa num Espaço de trabalho quando o usuário indicar cliente ou processo —
as respostas seguintes ficam mais contextualizadas.

## Etapa 4 — Verifique (a etapa que não pode ser pulada)

Para **cada** julgado que você pretende entregar:

1. Confirme que traz marcador de validação e/ou link para a base do Jusbrasil.
2. **Abra o link.** Leia a página do julgado no Jusbrasil.
3. Confira contra o que o chat afirmou: número do processo, tribunal, órgão julgador,
   relator, data. Divergiu? Vale o que está na página do julgado, não o que o chat disse.
4. Confirme que a ementa **realmente trata da tese**. O Jus IA às vezes traz julgado
   tangencial com resumo convincente. Descarte se não sustentar.
5. Copie a ementa **literalmente** da página — nunca do resumo do chat.

Se o link não abrir ou o julgado não bater com a descrição, ele sai do resultado
principal e vira lacuna declarada.

Priorize, nesta ordem: (1) vinculantes — súmula vinculante, repercussão geral, repetitivo,
IRDR; (2) STJ/STF recentes; (3) TJ do estado do caso; (4) demais. Sinalize precedente
superado ou afetado por lei posterior, quando detectável.

Quatro julgados certeiros valem mais que quinze tangenciais.

## Etapa 5 — Entregue

````markdown
## Pesquisa: <tese pesquisada>
**Fonte:** Jus IA / Jusbrasil · **Consultas:** <ângulos usados> · **Data:** <hoje>
**Verificação:** <N> julgados confirmados na base · <N> descartados por falta de validação

### Panorama
<2 a 4 linhas: tese pacífica, majoritária ou controvertida? Qual a posição dominante?>

### Precedentes verificados

**1. <TRIBUNAL> — <classe e nº do processo>**
- **Órgão julgador:** <turma/câmara>
- **Relator(a):** <nome>
- **Julgamento:** <data> · **Publicação:** <data>
- **Ementa (trecho):**
  > <transcrição literal da página do julgado — sem parafrasear>
- **Por que serve:** <1 linha ligando ao caso do usuário>
- **Link:** <url do Jusbrasil> — ✅ conferido

**2. …**

### Entendimento em sentido contrário
<julgados divergentes verificados, ou "nenhum localizado nas consultas realizadas">

### ⚠️ Citados pelo Jus IA mas NÃO validados
<o que o chat mencionou sem link/validação. Não citar sem conferência manual.>

### Legislação correlata
<apenas se pesquisada — artigo, texto, vigência>

### Citação pronta (ABNT)
<blocos prontos para colar na peça>

### Lacunas
<o que não foi possível confirmar; o que o usuário deve checar manualmente>
````

Se resumir uma ementa em vez de transcrever, marque explicitamente como paráfrase sua.

## Integração com o restante do trabalho

Quando o resultado for alimentar uma peça, entregue no formato acima e deixe a
incorporação ao texto para as skills de redação (`armando-peticao`,
`nabor-bulhoes-style`). Sua entrega é a pesquisa verificada, não a peça.
