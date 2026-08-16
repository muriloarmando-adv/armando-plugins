---
name: armando-naji-tarefa
description: >
  Formata e prepara tarefas para lançamento no sistema de gestão de tarefas NAJI do escritório
  Armando Advogados, seguindo o template oficial de card (ESFERA, CLIENTE, PRAZO INTERNO, PRAZO
  FATAL, TIPO DE TAREFA, DEMANDA, LINK PASTA, GRUPO DE AÇÃO, NUCLEO, ADV RESPONSÁVEL, COORDENADOR,
  PRIORIDADE). Use esta skill SEMPRE que o usuário pedir para "criar uma tarefa", "preparar uma
  tarefa", "lançar atividade", "lançar demanda", "abrir card NAJI", "montar tarefa para a Sarah"
  (ou outro colega), transcrever tarefas de bilhete/lembrete manuscrito, ou delegar internamente
  qualquer análise processual/extrajudicial — mesmo que o usuário não mencione "NAJI" ou "card"
  explicitamente. Inclui fluxo obrigatório de apuração prévia (memória + Google Drive) para
  preencher CLIENTE, LINK PASTA e DEMANDA com precisão, sem jamais inventar número de autos,
  artigo de lei ou jurisprudência. Substitui a skill `naji-tarefa`.
---

# Skill: Tarefa NAJI — Armando Advogados

Gera cards de tarefa no padrão interno do escritório para lançamento no sistema NAJI, com
apuração prévia dos fatos (nunca preenchendo campos por presunção quando é possível confirmar).

---

## Template oficial do card (ordem fixa — não alterar)

```
ESFERA: ( ) EXTRAJUDICIAL ( ) JUDICIAL

CLIENTE:

PRAZO INTERNO: ___   Horário: ___

PRAZO FATAL:

TIPO DE TAREFA:

DEMANDA: ___

LINK PASTA: ___

GRUPO DE AÇÃO:

NUCLEO: NAJI

ADV RESPONSÁVEL:

COORDENADOR:

PRIORIDADE: ( ) Importante ( ) Urgente ( ) Futura ( ) Recorrente ( ) Privada
```

Não existe campo "RESPONSÁVEL PELO ENVIO" neste template oficial — não incluir.

---

## Defaults fixos do escritório

- **NUCLEO:** sempre `NAJI`
- **ADV RESPONSÁVEL:** o advogado que está abrindo a tarefa, salvo indicação expressa em
  contrário. Se não der para inferir quem é, perguntar antes de fechar o card — nunca chutar
- **TIPO DE TAREFA:** default `Análise Processual`; ajustar o qualificador conforme o pedido do
  usuário (ex.: "análise complexa" → `Análise Processual (Complexa)`; "atendimento" →
  `Atendimento ao Cliente`)
- **PRAZO INTERNO:** um dia após a abertura da tarefa, às `14:00`
- **PRAZO FATAL:** dois dias após a abertura da tarefa
  — usar esses defaults SALVO quando houver prazo processual real e identificável (recursal,
  audiência, decisão com prazo fatal), caso em que o prazo real prevalece e deve ser destacado
- **COORDENADOR:** em branco por padrão

### Resolução obrigatória de datas

`D+1` e `D+2` são **regra interna de cálculo, não texto de card**. Converta sempre, a partir da
data corrente da conversa, e escreva no card **apenas a data de calendário**, no formato
`dd/mm/aaaa`.

**Nunca escrever `D+1`, `D+2` ou qualquer notação relativa dentro do card** — nem sozinha, nem
entre parênteses ao lado da data, nem como prefixo. Quem recebe o card lê data, não fórmula.

Exemplo, para uma tarefa aberta em 30/07/2026 (quinta-feira):

```
PRAZO INTERNO: 31/07/2026   Horário: 14:00

PRAZO FATAL: 01/08/2026
```

Errado — não fazer:

```
PRAZO INTERNO: D+1 (31/07/2026)   ← notação relativa no card
PRAZO FATAL: D+2                  ← sem data efetiva
```

Se a data resultante cair em sábado, domingo ou feriado forense, sinalizar isso ao final da
resposta (não corrigir por conta própria) e sugerir o próximo dia útil como alternativa, deixando
a decisão para o advogado responsável. Essa sinalização vai **fora do card**, no texto de
acompanhamento.

---

## Fluxo de apuração prévia (fazer ANTES de preencher o card)

Nunca presumir CLIENTE, LINK PASTA ou os elementos da DEMANDA quando eles puderem ser
confirmados. Ordem de apuração:

1. **Memória** — verificar se já existe registro sobre o cliente/matéria; ler o(s) arquivo(s)
   relevante(s) antes de redigir qualquer coisa.
2. **Google Drive (se houver arquivo referenciado)** — usar `get_file_metadata` subindo por
   `parentId` até localizar a pasta-raiz do cliente. Isso define CLIENTE e LINK PASTA com
   precisão — não supor o cliente pelo nome mencionado na conversa se o arquivo estiver
   fisicamente em pasta de outro cliente (operações compartilhadas, ex. Operação Hygea, guardam
   material de vários investigados na pasta de um único cliente).
3. **Busca por conteúdo** (`search_files` com `fullText contains`) — localizar número de
   processo/autos, datas, termos de apreensão, portarias etc. concretos para compor a DEMANDA.
4. **Nunca inventar** número de CNJ, artigo de lei ou julgado. Se não for possível confirmar,
   preencher com `[A CONFIRMAR]` e sinalizar expressamente ao advogado responsável ao final da resposta —
   nunca deixar uma lacuna sem destaque.

---

## Regras de preenchimento por campo

- **ESFERA:** marcar conforme a natureza do procedimento (judicial vs. extrajudicial).
- **CLIENTE:** o cliente formalmente constituído no escritório; se a tarefa envolve terceiro
  vinculado a um cliente (familiar, ex-cônjuge, sócio etc.), indicar ambos e sinalizar a questão
  de legitimidade/procuração no checklist final.
- **PRAZO INTERNO / PRAZO FATAL:** somente a data de calendário, `dd/mm/aaaa`. Ver a regra de
  resolução de datas acima.
- **DEMANDA:** sempre no infinitivo, no formato:
  `Realizar [ação] ... nos autos nº [CNJ] ([partes]), [natureza], [detalhe específico].`
- **LINK PASTA:** apenas a URL (`viewUrl`) real e clicável da pasta no Drive, obtida via
  `get_file_metadata`/`search_files` — sem caminho textual (breadcrumb), sem nome de pasta,
  apenas o link. Se a tarefa referenciar mais de uma pasta relevante (ex.: pasta do cliente
  formal + pasta onde o arquivo-fonte fisicamente está), incluir os dois links, um por linha,
  identificando cada um em poucas palavras.
- **GRUPO DE AÇÃO:** categoria de classificação do procedimento (ex.: `Judicial Criminal`,
  `Judicial Cível`, `Extrajudicial Cível`) — nunca um nome descritivo do caso.
- **PRIORIDADE:** escolher com base em urgência real (prazo fatal próximo, risco de perecimento
  de direito); na dúvida, marcar `Importante` e sinalizar que pode ser elevado a `Urgente`.

---

## Formato de entrega

Sempre entregar o card completo em bloco de código (para facilitar cópia), respeitando a ordem
de campos do template — nunca reordenar ou omitir campos, mesmo os que ficarem em branco.

Antes de enviar, conferir sempre estes dois pontos (erros recorrentes a evitar):
1. **LINK PASTA contém apenas a URL real do Drive** — nunca o caminho textual (breadcrumb).
2. **PRAZO INTERNO e PRAZO FATAL trazem apenas a data de calendário** — nenhuma ocorrência de
   `D+`, "amanhã", "depois de amanhã" ou notação relativa equivalente dentro do card.

## Checklist final (sinalizar sempre que aplicável, com vênia)

Antes de dar a tarefa por pronta, verificar e apontar ao usuário:

- **Representação/procuração** — se a tarefa envolve pessoa não formalmente cliente, indicar que
  a peça final não poderá ser subscrita em seu nome sem instrumento de mandato.
- **Identidade dos autos** — se o arquivo-fonte estiver em pasta de cliente diverso do
  interessado direto, confirmar se realmente se trata da mesma matéria antes de finalizar.
- **Viabilidade técnica** — arquivos de Drive acima de ~10 MB não são baixáveis pela integração
  disponível; sinalizar necessidade de fracionamento ou busca por página no visualizador.

## Registro de acompanhamento

O texto que acompanha o card (fora dele) deve ser redigido em registro jurídico elaborado —
pedindo vênia, com jargão técnico e fundamentação em doutrina/jurisprudência apenas quando
efetivamente verificável, nunca inventada. Consultar a skill `nabor-bulhoes-style` quando o
acompanhamento exigir maior desenvolvimento argumentativo.
