# Modelos de entrega

Quatro produtos. A ficha é a espinha; os outros três se montam a partir dela. Na dúvida, entregue a ficha.

| Produto | Leitor | Registro | Fecha em |
|---|---|---|---|
| FICHA RESUMO DO PROCESSO | escritório, pasta | 3ª pessoa, técnico médio | observações e pendências |
| RESUMO PARA O CLIENTE | leigo com decisão na mão | 1ª pessoa do plural, sem lei nem latim | o que precisa ser feito |
| PARECER ESTRATÉGICO | quem decide a tese | 3ª pessoa, técnico alto | recomendação nominada |
| TRIAGEM DE PRAZO | quem vai protocolar | telegráfico | o que fazer e até quando |

---

## 1. FICHA RESUMO DO PROCESSO

O formato mais usado da casa. No acervo aparece com dois títulos — `FICHA RESUMO PROCESSO` e `RESUMO RECLAMAÇÃO TRABALHISTA` — para o mesmo documento; use **`FICHA RESUMO DO PROCESSO`** e, sendo trabalhista, acrescente a linha de espécie logo abaixo.

As seis rubricas centrais são invariáveis no acervo. **Não as reescreva.**

```
FICHA RESUMO DO PROCESSO
[RECLAMAÇÃO TRABALHISTA | AÇÃO DE COBRANÇA | EXECUÇÃO FISCAL | …]

CLIENTE:                       ← de que lado atuamos. Campo que falta em TODAS as fichas do acervo.
ESCRITÓRIO HABILITADO?         ← sim / não / não confirmado. Em feito sob sigilo, protocolar
                                 procuração NÃO habilita: o acesso depende de deliberação do
                                 juízo. Sem despacho, a resposta é "não confirmado", e a
                                 habilitação é a primeira linha do próximo passo.
PROCESSO:                      ← número CNJ com máscara, sempre
CLASSE / RITO:
VARA / ÓRGÃO:                  ← por extenso, com a cidade
[RELATOR:]                     ← 2º grau
[PROCESSOS RELACIONADOS:]      ← apensos, recursos, execução em apartado, precatória
AUTOR / RECLAMANTE:
RÉU / RECLAMADA(S):            ← na ordem do polo, separadas por ponto-e-vírgula
VALOR DA CAUSA:                ← R$ 0.000,00, com a data-base entre parênteses
DISTRIBUÍDO EM:
FASE ATUAL:                    ← uma frase
PRÓXIMO ATO / PRAZO:           ← o gatilho, o quanto e a ressalva de conferência
AUDIÊNCIA:                     ← data, hora e modalidade
LINK DA PASTA:
ANALISTA:                      ← o nome de uma pessoa. Não sabendo, `não apurado` —
                                 nunca o nome da skill ou do fluxo.
ANÁLISE FECHADA EM:            ← data de corte da consulta aos autos. Obrigatório.
COBERTURA DO ARQUIVO:          ← o que a capa DECLARA existir contra o que o arquivo
                                 CONTÉM, em volumes, apensos e faixa de folhas.
                                 Obrigatório. Ex.: `capa declara 1 volume e 12 apensos;
                                 este arquivo traz 1 volume (fls. 1-830) e 1 apenso
                                 (fls. 1-32) — 11 apensos não estão aqui`.

RESUMO DOS FATOS

   [A versão do adversário, sempre atribuída. Abre pela admissão/contratação,
    função e remuneração ou pelo negócio de origem, e segue com o rol do que
    a parte diz não ter recebido ou não ter sido cumprido.]

PRINCIPAIS TESES JURÍDICAS

   Do Reclamante / Autor:
   - […]

   Das Reclamadas / Do Réu:
   - […]

O QUE ACONTECEU NO PROCESSO ATÉ AGORA

   dd/mm/aaaa — Rubrica curta terminada em ponto. [1 a 4 frases: o que foi
                decidido E a consequência processual.]
   …

DOCUMENTAÇÃO NECESSÁRIA PARA DEFESA (digitalizada)

   - […]                       ← adaptado ao caso. Ver a advertência abaixo.

PERGUNTAS PARA O CLIENTE

   - […]?                      ← interrogativas diretas, fechadas por interrogação

OBSERVAÇÕES

   [Complexidade, natureza da prova, onde está o risco, condição processual
    das partes (jus postulandi, corré já com advogado), o que a análise não
    conseguiu apurar.]

PENDÊNCIAS

   - […]                       ← todo `não apurado`, documento citado e não juntado,
                                 página sem OCR, pergunta ao cliente sem resposta

RISCOS

   - […]                       ← onde a tese é forte, onde é vulnerável, o que o
                                 adversário tem de melhor, e o custo da via quando
                                 ele chega perto do proveito

PRÓXIMO PASSO

   1. […]                      ← o que fazer, QUEM faz, ATÉ QUANDO. Providência sem
                                 responsável e sem data não é próximo passo.
```

**As três últimas rubricas são obrigatórias e vão sempre por extenso**, cada uma com seu título. Amontoá-las em `OBSERVAÇÕES` foi o defeito que mais derrubou a nota nos testes: sem elas a ficha descreve o processo e não diz o que fazer com ele — que é a única coisa que ela existe para dizer.

**`COBERTURA DO ARQUIVO` é obrigatória na mesma medida.** Ela responde *quanto dos autos eu tenho na mão* — e num caso real foi a informação mais importante da entrega inteira: a capa dizia **1 volume e 12 apensos**, e o arquivo tinha **1 volume e 1 apenso**. Sem esse campo, a ficha descreve com segurança um processo que só conhece pela oitava parte, e todo `não há nos autos` que ela escreve é falso.

Escreva os dois lados, sempre nesta ordem — o que a capa declara, o que o arquivo contém —, em volumes, apensos e faixa de folhas. Não conferindo o número, `não apurado`, e a diferença vai para `PENDÊNCIAS`. Quem apura os blocos é a seção 0.2 do mapa (reinício de foliação = apenso novo); onde não há carimbo de folha, diga isso em vez de estimar.

**Quando um dos polos ainda não falou.** É o normal em pasta que entra antes da primeira peça: o bloco de teses da outra parte seria vazio. Mantenha a rubrica e rotule o bloco — `nenhuma tese foi deduzida nos autos; as linhas abaixo são construção desta análise`. A utilidade inteira da ficha para o escritório está aí, e o rótulo impede que a construção seja lida como alegação existente.

**Quando não houve contato com o cliente.** Abra `PERGUNTAS PARA O CLIENTE` com uma nota — *nenhuma destas foi respondida ainda* — e repita a lista em `PENDÊNCIAS`. É o caso mais frequente, não a exceção.

**Enunciar parâmetro legal não é transcrever lei.** A ficha não transcreve dispositivo nem ementa. Mas **pode e deve** enunciar o parâmetro de que a peça vai precisar — a faixa de escalonamento do art. 130 da CLT em que as faltas apuradas caem, o teto da multa, o divisor aplicável. Sem isso a ficha entrega a contagem e deixa a conta para quem escreve a peça, que é justamente o retrabalho que ela existe para evitar.

**Cálculo derivado é permitido, e vem rotulado.** "Não invente valor" e "diga quanto o cliente deve hoje" não colidem: o valor projetado — multa e honorários do art. 523, atualização, saldo — entra com a etiqueta `projeção desta análise, não valor fixado nos autos`, seguida da fórmula. O que não se admite é o número aparecer como se estivesse nos autos.

**Variações legítimas do acervo:**

- Processo longo: subdivida a cronologia por fase — `Fase de conhecimento, 1º grau (2022-2023)` · `Fase recursal (2024-2025)` · `Cumprimento de sentença (fase atual)`. A marcação `(fase atual)` cola no título da fase corrente.
- Disputa que virou aritmética: acrescente `RESUMO DOS VALORES EM DISPUTA`, tabela `Item | Valor`, seguida de um parágrafo que **delimita o que a tabela não cobre**. Inclua quando os valores estão **em disputa entre as partes** ou já liquidados — não quando são apenas o rol de pedidos da inicial, que já vive em `PRINCIPAIS TESES JURÍDICAS`. Na tabela os valores ficam em algarismo; o extenso vai na prosa.
- Prognóstico: o par `Chance de ganho:` / `Proveito econômico:` vai **no cabeçalho**, não no fim. Quantificado e com a alavanca que o produz.
- Depois de reunião com o cliente: bloco `ANOTAÇÕES`, com a resposta colhida transcrita em CAIXA ALTA.

**Advertência sobre o checklist de documentos.** No acervo a lista trabalhista padrão (contracheques, TRCT, extrato FGTS, registro de ponto, advertências) foi colada **sem adaptação** num caso de acidente de trabalho de prestador de serviço, em que a discussão era responsabilidade civil do tomador. Colar checklist é o defeito mais comum da ficha. Adapte item a item — e o erro fossilizado "Ficha de registro **da** funcionário", que aparece idêntico em duas fichas, prova que ninguém releu.

**Fórmulas literais da casa**, para reaproveitar:

- `A Reclamante afirma que foi admitida em 24/06/2025, para exercer a função de Recepcionista Jr., percebendo como última remuneração o valor de R$ 1.841,00`
- `Sustenta que:`
- `O Reclamante requer:`
- `A reclamação foi ajuizada em [data].`
- `Foi designada audiência inaugural telepresencial para o dia [data], às [hora].`
- `A tentativa conciliatória restou infrutífera.`
- `Realizada por videoconferência no CEJUSC, resultou infrutífera, abrindo-se o prazo de 15 dias para contestação.`
- `O Autor ingressou via Jus Postulandi (sem advogado).`
- `Cliente revel no processo.`
- `Conclusão do perito no laudo:`
- `Sentença desfavorável:`
- `O processo encontra-se na fase de cumprimento de sentença, restrita, por ora, à obrigação de pagar quantia certa.`
- `Não há nos autos prova de cumprimento: nenhuma certidão de cadastramento, extrato, resultado ou intimação.`
- `A notificação está dúbia, devendo ser realizado balcão virtual para verificar se é a audiência UNA ou inicial.`
- `Registrou-se apenas um incidente sem relação com o mérito.`
- `O principal risco do processo está relacionado à comprovação documental da rescisão.`

---

## 2. RESUMO PARA O CLIENTE

Leitor leigo com uma decisão de negócio na mão. **Não é a análise jurídica** — é a resposta a quatro perguntas, nesta ordem.

```
RESUMO PARA O CLIENTE
[Linha de objeto em negrito: o problema concreto, nomeado]

Prezado(a) [NOME DO CLIENTE],

[Uma frase dizendo o que é este documento e o que ele vai responder.]

O que está acontecendo
   [A origem, contada como história. Termo técnico traduzido na primeira aparição.]

O que isso significa [para o imóvel / para a empresa / para o senhor]
   [O fato jurídico traduzido em número e proporção.]

O que isso muda [para a compra / para o pagamento / para o acordo]
   [O efeito prático de hoje, dito sem eufemismo, com a causa do travamento.]

O que precisa ser feito
   [A providência, onde ela corre, quem a faz, e por que não é preciso mais do que isso.]

Resumindo
   Hoje: …
   Motivo: …
   Solução: …
   Depois disso: …

Ficamos à disposição para qualquer dúvida.

[Cidade]/[UF], [data por extenso].
[Nome do advogado] — OAB/[UF] [número]
```

**Regras do formato:** primeira pessoa do plural do escritório (`Preparamos`, `Vamos precisar pedir`, `avisaremos vocês`); sem artigo de lei, sem jurisprudência, sem latim; sigla sempre traduzida na estreia; percentual sempre glosado (`1,85% do imóvel — pouco menos de 2 em cada 100`); frases curtas, parágrafos de 2 a 4 linhas; **franqueza máxima**, inclusive sobre o que é desfavorável; tranquilização ancorada em fato, nunca em adjetivo (`não é necessário abrir uma ação nova`).

**Precisão que o modelo do acervo perdeu e você não pode perder:** *venda* e *registro* não são a mesma coisa; *ordem judicial* não é *pedido*. Simplificar não é trocar o regime do ato. E nomeie o cliente e o número dos autos — o resumo do acervo não traz nenhum dos dois, e é irrastreável fora da pasta.

---

## 3. PARECER ESTRATÉGICO

Quando já existe uma tese a testar, ou uma peça a escrever.

```
PARECER TÉCNICO-JURÍDICO
[Título: o tipo + a tese + o caso entre parênteses]

Data: …            Assunto: …
Cliente: …         Adversa: …
Autos: …           ← todos os processos conexos, com classe, número e vara
Estratégia definida: …   ← a tese em UMA frase, antes de qualquer narrativa
Prazo: …           ← a data fatal da peça a que o parecer serve

I — O CASO
II — A MARCHA PROCESSUAL              ← cronologia por evento/ID, com o estado de cumprimento de cada um
III — O OBSTÁCULO                      ← o que foi indeferido, e com quais fundamentos
IV — A ESTRATÉGIA
    IV.1 — [um subitem para cada fundamento do indeferimento a desarmar]
    IV.n — Se for negado outra vez     ← o plano B
V — FOCO DA PEÇA                       ← o que ela ataca e o que deliberadamente NÃO discute
VI — O QUE NÃO CONFUNDIR               ← requisitos que não se misturam
VII — RISCO REMANESCENTE               ← o que continua exposto mesmo dando certo, com a mitigação
```

**As rubricas de conclusão da casa**, em negrito, sempre **depois** do fato e da prova, nunca antes:

- **`Análise Estratégica:`** — sobe do caso concreto para a leitura de conjuntura: o que o adversário está tentando fazer, e por que isso o enfraquece.
- **`Desconstrução Técnica:`** — ataca a narrativa adversária usando os números dela. *(No acervo aparece grafado "Deconstrução". É erro: escreva `Desconstrução`.)*
- **`O Fato Crucial:`** — reservado à **prova negativa**, ao dado que não existe no acervo. *"Em toda a extensão dos relatórios do COAF não existe qualquer menção ao nome de [X]. Esta omissão não é meramente circunstancial; ela é absoluta."*
- **`O "So What?":`** — traduz fato + prova em consequência jurídica. É a rubrica mais característica da casa.
- **`Recomendação Estratégica:`** — última linha, com verbo deôntico e o provimento **nomeado**: *"A defesa deve articular … como fundamento precípuo para a rejeição da denúncia ou absolvição sumária."*

Nunca termine em "Conclusão" seca: é sempre `Conclusão e Recomendações Estratégicas` ou `Conclusão e Prognóstico`.

**Recomendação em cadeia** (o formato que funcionou melhor no acervo): tese em uma frase → veículo legal nominado → obstáculo **quantificado** ("quanto falta") → providência com margem deliberada e o porquê da margem → alternativa se o cliente não quiser o custo → hierarquia do esforço → plano B → exposição residual com mitigação de custo zero.

**Frases da casa:**

- `Estratégia definida: complementar a garantia do juízo para obter o efeito suspensivo aos embargos, mantido em paralelo o agravo de instrumento contra a decisão do evento 96.`
- `Nunca apreciado.` · `A medida aguarda apenas cumprimento.` · `A premissa deixou de existir.` · `Aquele cenário terminou.`
- `O agravo não discute a dívida.`
- `Ponto a suprir: … Juntar essa prova contábil elimina o fundamento nos exatos termos em que foi formulado — é a providência de maior retorno e depende apenas da cliente.`
- `Sugestão: depositar R$ 9.000,00, com margem deliberada, e pedir, como cautela, que eventual insuficiência seja precedida de intimação para complementar — evita um terceiro indeferimento por questão meramente aritmética.`
- `Mitigação de custo zero: incluir, no mesmo pedido, requerimento de que não se autorize levantamento antes do trânsito em julgado dos embargos, ou mediante caução.`
- `Usar a nomenclatura de um no outro convida o julgador a aplicar o teste errado.`
- `Valores atualizados pelos índices oficiais do IBGE divulgados até julho de 2026. Conferir o inteiro teor dos julgados antes de transcrever em peça.`

**Vedação:** nenhum campo `Persona:` no cabeçalho. É instrução de prompt vazada para dentro do documento, e um parecer do acervo saiu assim — com `Persona`, e **sem** assinatura, OAB, local e destinatário.

**Se o parecer alimenta uma peça**, ele precisa entregar o que a peça vai citar: ver `por-ramo.md`, seção final.

---

## 4. TRIAGEM DE PRAZO

Intimação recém-publicada. Produto de meia página, para decidir hoje.

```
TRIAGEM — [CLIENTE] — [nº dos autos]

ATO:          [tipo, ID/evento/folha, data da assinatura]
PUBLICADO EM: [data — ou "não apurado: extrato não traz a publicação"]
O QUE DIZ:    [uma frase; se for decisão, o dispositivo, não o relatório]
PRAZO:        [N dias, art. …, contado de …] — CONFERIR NO SISTEMA
CABE:         [recurso/peça cabível, com dispositivo] · [tem efeito suspensivo? art. …]
RECOMENDAÇÃO: [recorrer / cumprir / peticionar / nada a fazer] — em uma linha
RISCO SE NADA FOR FEITO: [uma linha]
```

Encerra com o card da `armando-naji-tarefa`.

---

## Como o escritório escreve — comum aos quatro

- **Terceira pessoa** na descrição. Primeira do plural só quando se opina (`identificamos pontos que podem ser explorados na contestação`) e no resumo ao cliente, onde é a norma.
- **Verbo dicendi para a versão do adversário**, sem exceção: `afirma`, `aduz`, `sustenta`, `postula`, `pleiteia`, `alega`. E, quando a alegação é grave, futuro do pretérito: `teria determinado`.
- **Partes pelo papel processual**, maiúscula inicial, mantido em todas as ocorrências. Nome civil só no bloco de identificação. **O cliente nunca é "nosso cliente"** — é o nome ou a posição.
- **Tempo verbal:** pretérito perfeito para o que já foi praticado; presente para o estado do processo; futuro só em hipótese condicionada (`Caso o prazo transcorra sem pagamento…`).
- **Números por extenso entre parênteses:** `5 (cinco) dias`, `15 (quinze) dias úteis`, `R$ 13.173,13 (treze mil, cento e setenta e três reais e treze centavos)`.
- **Citação legal com dispositivo, inciso e diploma:** `art. 335, I, do CPC`; `art. 919, § 2º, do CPC`; `art. 483, "d", da CLT`.
- **Julgado com identificação completa:** `STJ, AgInt no AREsp nº 2.643.705/RJ, Rel. Min. João Otávio de Noronha, 4ª Turma, j. 25/08/2025`. Sempre pelo agente `jurisprudencia`.
- **Franqueza.** Frase curta e seca para o que está errado, faltando ou contra o cliente.
- **Delimite o alcance do próprio documento:** `até a última movimentação dos autos`, `até a última página disponível do processo`.
