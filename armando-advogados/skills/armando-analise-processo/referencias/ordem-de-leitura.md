# Ordem de leitura — os sete passes

Sempre a mesma ordem, em qualquer ramo e em qualquer sistema. Cada passe fecha uma pergunta e libera o seguinte. Quem começa pela inicial trabalha duas vezes.

---

## Passe 1 — O arquivo está atual?

**Pergunta:** de quando é este retrato dos autos, e quanto tempo ele não cobre?

A regra das quatro âncoras está na **seção 3 do `SKILL.md`** e o `mapear-autos.ps1` faz a conta. Aqui só o que fazer com o resultado:

**Saída:** uma frase. *"Extrato gerado em 09/11/2025; última atividade em 16/10/2025; hoje é 27/08/2026 — 315 dias de tramitação não retratados."*

Acima de ~30 dias, a entrega **abre** com esse aviso e nenhuma afirmação de fase ou de prazo sai sem consulta ao sistema.

**Por que primeiro:** porque muda o que você pode afirmar em todo o resto. Não adianta descobrir no fim.

---

## Passe 2 — Capa, partes e quem tem advogado

**Pergunta:** que processo é este e quem está nele?

Extraia, na ordem: número CNJ · classe · órgão julgador (e relator, se 2º grau) · data de distribuição/autuação · valor da causa · assuntos · sigilo · gratuidade · liminar pedida.

**O que quase ninguém lê e é o mais informativo:** o **quadro de partes com os advogados ao lado**. Parte sem advogado é uma das seguintes: revel, ainda não citada, litigando em *jus postulandi* (comum no JEC e na Justiça do Trabalho), ou com habilitação protocolada e ainda não processada. Cada hipótese muda a análise inteira. Em uma execução fiscal do acervo, a ausência de advogado ao lado da executada era o dado central: nunca houve defesa técnica em dois anos e meio.

**A pergunta inversa, e igualmente urgente: o escritório está habilitado?** Quando o cliente chega com o processo já em curso, a parte costuma ter advogado constituído — outro. Disso dependem duas coisas imediatas: **se recebemos intimação** (não recebendo, o prazo corre sem que saibamos) e **se temos acesso integral** (em feito sigiloso, o acesso depende de deliberação do juízo). Registre no cabeçalho da ficha e, não estando habilitados, a habilitação é a primeira linha do `PRÓXIMO PASSO`.

**Valor da causa: o da capa pode estar velho.** A capa traz o valor da distribuição. Emenda, retificação e conversão de fase mudam esse valor sem que a capa acompanhe — há caso no acervo em que a capa diz R$ 1.000,00 e o valor retificado na fase de conhecimento é R$ 62.430,00, com custas complementares recolhidas. Registre **os dois**, dizendo qual é o da capa.

**Armadilhas de capa:**

- Em classes cautelares e criminais os campos `Valor da causa` e `Pedido de liminar` vêm zerados e negativos mesmo quando o objeto inteiro do feito é uma liminar já deferida. São inservíveis nessas classes.
- Polo `SIGILOSO` não significa investigado não identificado — os nomes costumam estar no corpo.
- A capa é gerada no instante da extração e pode não refletir peça protocolada horas antes.
- **A classe da capa é a classe de hoje**, e ela muda no meio da vida do processo. Mandado de segurança vira cumprimento de sentença, com **inversão de polos**: o impetrante de 2003 é o executado de 2024. Quem abre uma peça antiga isolada erra de lado.
- No PJe-JT a capa **não traz o órgão julgador nem a audiência** — estão na certidão/recibo de distribuição, algumas folhas adiante.
- No PJe híbrido, `Última distribuição` pode ser **posterior** ao último documento juntado: é redistribuição administrativa, não movimento processual.

---

## Passe 3 — O índice oficial

**Pergunta:** o que existe nos autos, de que tipo, em que datas?

O índice dá a cronologia inteira numa tela e evita ler o resto. Onde ele fica muda por sistema (ver `mapa-por-sistema.md`): capa no PJe, **última folha** no PJe-JT, e **não existe** no eSAJ.

Leia o índice **de baixo para cima**. A peça mais recente é a última linha.

**O que anotar do índice:**

1. A última linha — candidata a último movimento.
2. Todo documento de tipo decisório (Sentença, Decisão, Despacho, Acórdão).
3. Todo documento de comunicação (Intimação, Notificação, Citação, Mandado, Edital, A.R., Ecarta) — são eles que abrem prazo.
4. Buracos: intervalos longos sem lançamento, e tipos que deveriam existir e não existem.

**Armadilha central:** o índice é um índice, **não um inventário**. Peça com visibilidade restrita não aparece — no PJe-JT a contestação protocolada antes da frustração da conciliação (art. 22 da Res. CSJT 185/2017) some do sumário embora esteja fisicamente nos autos. **Sempre confira o índice contra as fronteiras de peça do mapa.** Concluir revelia onde há defesa é o pior erro possível.

Segunda armadilha: no extrato do PJe a coluna da **hora** quebra para a linha vizinha, de modo que a hora impressa junto de um ID pode ser do lançamento anterior. Para datar com precisão, use a URL de validação — no PJe-JT os 12 primeiros dígitos são `AAMMDDHHMMSS`.

---

## Passe 4 — O último ato de juízo, integral

**Pergunta:** qual é a fase, o que está decidido, e que prazo está aberto contra quem?

Este é o passe que economiza mais trabalho, e por isso vem **antes** da inicial.

Ache o último documento assinado por **magistrado ou servidor** (não por advogado) e leia-o inteiro. Dele saem:

- a fase real do processo;
- o comando vigente — e leia o **dispositivo**, não o relatório. Num acervo criminal, o relatório da decisão menciona busca em três endereços de duas pessoas jurídicas; o dispositivo autoriza a diligência **exclusivamente na residência de uma pessoa física**. Quem lê só o relatório afirma o que não aconteceu;
- o prazo aberto, o destinatário e a cominação;
- **o que foi deferido e ainda não cumprido** — e de que lado joga. Estando o cliente no polo ativo, é a alavanca mais barata do caso. Estando no passivo, é o **risco iminente**: SISBAJUD, RENAJUD, penhora e ofícios já autorizados disparam sem nova decisão, a qualquer momento. A mesma linha dos autos, lida do outro lado, inverte de sentido — diga de qual lado você a está lendo;
- **contradição entre o ato do juízo e o que os autos certificam.** Existe, e não é raro: um despacho do acervo declara cumprido um mandado que uma certidão de oficial de justiça, no mesmo processo, certifica como **não** cumprido. Isso não é silêncio dos autos nem ausência de peça — é vício, e vale como tese própria quando prejudica o cliente. Confronte sempre o que o despacho afirma dos autos com o que os autos mostram.

Depois dele, procure a **certidão de intimação** que o segue. É ali, e não na decisão, que estão o meio (`Sistema`, carta, edital, DJe) e o prazo. Sem essa certidão, o prazo não começou a correr.

**Se o último ato for de mero expediente** (dirigido à secretaria), não há prazo contra as partes: o pendente é ato do juízo. Diga isso — e diga há quanto tempo.

---

## Passe 5 — A peça inaugural, integral

**Pergunta:** o que se pede, com que fundamento, e o que o adversário precisa provar?

Inicial, reclamação trabalhista, denúncia, CDA, termo de ajuizamento — conforme o caso.

Extraia: causa de pedir com datas · rol de pedidos **com os valores de cada um** · valor da causa e como foi calculado · documentos que a instruem · o que ficou apenas alegado.

**A tabela vale mais que o texto.** Nas trabalhistas, a "tabela de verbas" ao fim da inicial fixa o objeto e o rito melhor do que a narrativa. Nas execuções, a memória de cálculo — e é nela, não na CDA, que estão as datas do processo administrativo que fundam qualquer tese de prescrição.

**Cotejo obrigatório:** os pedidos deduzidos no texto contra os assuntos efetivamente **cadastrados** no sistema. A divergência entre os dois revela pedido não cadastrado (e vice-versa) e às vezes denuncia resíduo de formulário — uma inicial do acervo lista contatos de uma "2ª Reclamada" que não existe no polo passivo.

---

## Passe 6 — Defesa e réplica

**Pergunta:** o que virou controvérsia e o que já é incontroverso?

Leia a contestação/embargos/resposta à acusação inteira, e a réplica se houver.

Monte a coluna dupla: **o que o autor afirma × o que o réu opõe**, item a item. O que ninguém contesta sai do caminho — é o maior ganho de tempo da análise.

Anote também:

- preliminares e prejudiciais, que decidem antes do mérito;
- teses em cascata: qual é a principal e qual é a subsidiária;
- **contradição interna dentro da própria defesa** — existe, e precisa ser administrada antes da audiência, não descoberta nela;
- prova que cada lado anunciou que vai produzir.

**Se não há defesa**, verifique por quê antes de escrever "revel": prazo ainda aberto, citação não perfectibilizada, peça com visibilidade restrita, ou revelia mesmo.

---

## Passe 7 — Prova, dinheiro e constrição

**Pergunta:** o que está provado, quanto se discute e o que já foi apreendido?

- **Laudo e perícia:** leia a conclusão por extenso, inclusive quando é contra o cliente. E confira se a perícia foi efetivamente realizada — há sentença que defere adicional pericial dispensando a perícia, e isso é matéria de recurso.
- **Cálculo:** confira a aritmética. Erros de soma passaram tanto nas fichas quanto nas peças do acervo. Todo valor com data-base.
- **Constrição:** penhora, SISBAJUD, RENAJUD, INFOJUD, arresto, indisponibilidade, leilão. Leia o **resultado**, não o título do documento: no formulário de marcar "X" o que vale é o quadrado marcado, e "SISBAJUD" pode ser bloqueio, desbloqueio de valor irrisório ou negativo.
- **Documentos digitalizados sem OCR:** liste-os um a um como não lidos. São, com frequência, a prova nuclear.

---

## Fechamento — as três perguntas de saída

Antes de escrever, responda em voz alta:

1. **Onde está o processo agora?** Uma frase, com o ato e a data.
2. **O que vence primeiro?** Um prazo, uma audiência, uma providência interna — com o gatilho e a ressalva de conferência.
3. **O que eu não consegui apurar, e por quê?** Se a lista estiver vazia, você não olhou direito.
