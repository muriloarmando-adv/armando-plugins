---
name: armando-recuperacao-credito
description: Conduz o ciclo de recuperação de crédito do escritório Armando Advogados — triagem da carteira de inadimplentes pelos três filtros da casa (prescrição, documento hábil, espécie do título), parecer de viabilidade com escolha da via, notificação extrajudicial de débito, termo de acordo e confissão de dívida, e as iniciais de ação monitória e de execução de título extrajudicial. Use SEMPRE que o usuário pedir para "cobrar esse cliente", "triar a carteira", "planilha de inadimplência", "notificar o devedor", "vale a pena cobrar", "isso já prescreveu?", "fazer a monitória", "executar o título", "acordo de dívida", "confissão de dívida", "protestar o título", "pedido de falência por dívida", "recuperação de crédito" — mesmo sem nomear a área. Para contestação, use `armando-contestacao-trabalhista`; para inicial de outra matéria, `armando-peticao-inicial`.
---

# Recuperação de Crédito — Padrão Armando Advogados

Padrão extraído do acervo de recuperação de crédito do Drive em setembro de 2026: as carteiras **AGROBOI/Pereira & Magalhães, MEGGA, CALCÁRIO MILENIUM, TAIS MUNIZ, CONSTRUTORA M21, GRUPO CORREA e SANCHES**, mais a carteira de honorários do próprio escritório (**PRIME HOLDING, 63 MOTORS, L B PARTICIPAÇÃO, HM CIRÚRGICA, FOURMAQ**).

Duas fontes governam esta skill acima dos modelos de peça:

- **`Efetividade da cobrança judicial.docx`** — a nota doutrinária da casa sobre o canhoto da nota fiscal. É regra de decisão, não modelo.
- **`Acompanhamento de Cobrança.xlsx`** (carteira Agroboi) — a triagem de ~120 devedores, R$ 310.942,97 de principal.

E o dado dessa planilha define a prioridade desta skill inteira: **mais de 70 dos ~120 devedores foram descartados por prescrição.** A área não perde crédito por insolvência do devedor — perde por demora na triagem. Por isso a triagem vem antes de qualquer redação, sempre, inclusive quando o usuário já pediu a peça pronta.

---

## 1. Apuração prévia obrigatória

Não redija nem opine sem estas respostas. Pergunte em bloco, de uma vez:

1. **Quem é o credor** e em que qualidade — cliente da casa ou o próprio escritório cobrando honorários. Muda o tom, a alçada e quem assina.
2. **Qual o documento que lastreia o crédito** — e o arquivo, não a descrição dele. Nota fiscal, boleto, nota promissória, cheque, duplicata, contrato, termo de acordo. **Boleto sozinho não é documento de crédito**; ver §2.
3. **Há canhoto de entrega assinado?** Pergunta decisiva, e a que mais se esquece. Ver `referencias/triagem.md`.
4. **Data de cada vencimento.** Sem isso não há cálculo de prescrição, e sem prescrição não há triagem.
5. **Quanto já foi pago**, se houve pagamento parcial. O acervo abate pagamentos parciais do nominal antes de atualizar — e pagamento parcial interrompe a prescrição (art. 202, VI, do CC), o que pode ressuscitar crédito aparentemente morto.
6. **Houve cobrança extrajudicial?** Prints de WhatsApp, e-mail, carta. No acervo isso é prova de reconhecimento de dívida, não apenas histórico.
7. **O título foi protestado?** Data e cartório. Governa a via falimentar e a constituição em mora.
8. **Qual o domicílio do devedor** — define a comarca (art. 46 do CPC), salvo foro de eleição em contrato ou acordo.

**Nunca invente** número de nota fiscal, chave de NF-e, CPF/CNPJ, data de vencimento, valor, número de cheque, agência, conta, comarca ou número de OAB. Campo não apurado entra como `[......]` e a pendência vai listada ao final da entrega.

**Nunca invente jurisprudência.** `referencias/precedentes.md` traz a biblioteca colhida das próprias peças da casa. Para tese sem julgado ali, acione o agente `jurisprudencia` (Jus IA). Nunca fabrique ementa, número de recurso ou relator.

---

## 2. A trava que precede tudo: os três filtros

Rode nesta ordem. Cada filtro que reprova **encerra a análise daquele crédito** — não passe ao seguinte procurando um jeito de salvar a peça.

### Filtro 1 — Prescrição

Dívida líquida constante de instrumento particular prescreve em **5 anos** (art. 206, §5º, I, do CC). Conte de cada vencimento, individualmente, e não do vencimento mais recente da carteira.

Antes de declarar prescrito, verifique as causas de interrupção do art. 202 do CC — em especial **pagamento parcial** (inciso VI, reconhecimento inequívoco pelo devedor) e **protesto**. Na carteira Agroboi há devedores com pagamento parcial recente cujo crédito antigo continua exigível.

Prazos que fogem da regra dos 5 anos estão em `referencias/triagem.md` — cheque, nota promissória e duplicata têm prescrição executiva própria, muito mais curta, **e o vencimento dela não mata o crédito: rebaixa a via**.

### Filtro 2 — Documento hábil

**Boleto não prova nada.** É instrumento de cobrança emitido unilateralmente pelo credor; não prova a venda, a entrega, nem a anuência do devedor. Na planilha Agroboi, a observação mais frequente entre os créditos não prescritos é exatamente *"na pasta tem apenas boleto"*.

Nota fiscal **sem canhoto assinado** fecha a execução e fragiliza a monitória — há risco real de extinção por falta de prova da entrega. A correção da casa, escrita na nota doutrinária, é **notificar antes** para obter reconhecimento da dívida (ou confissão por WhatsApp/e-mail), que supre o canhoto e viabiliza a monitória.

### Filtro 3 — Espécie do título define a via

| Documento disponível | Via | Fundamento |
|---|---|---|
| Nota promissória, cheque no prazo, duplicata aceita | **Execução** | art. 784, I, CPC |
| Contrato assinado (2 testemunhas ou assinatura eletrônica) | **Execução** | art. 784, III |
| Termo de acordo / confissão de dívida | **Execução** | art. 784, III + §4º |
| Contrato de honorários advocatícios | **Execução** | art. 784, XII + art. 24 da Lei 8.906/94 |
| Nota fiscal **com** canhoto assinado | **Monitória** | art. 700 |
| Cheque prescrito | **Monitória** | Súmulas 299 e 531 do STJ |
| Contrato sem testemunhas, sem contexto probatório | **Monitória** | art. 700 |
| Só boleto, ou NF sem canhoto | **Notificação + protesto** primeiro | — |
| Título protestado > 40 salários mínimos | Avalie **falência** | art. 94, I, Lei 11.101/05 |

A última linha é a que mais se perde. Quando a dívida protestada supera 40 salários mínimos, o **pedido de falência** costuma recuperar mais rápido que a execução, porque a devedora precisa do **depósito elisivo** — valor integral, com juros e sucumbência — para evitar a quebra. Credores podem somar títulos em litisconsórcio para atingir o patamar (art. 94, §1º). Desenvolvido em `referencias/triagem.md`.

O script `triar-carteira.ps1` roda os filtros 1 e 3 sobre a planilha inteira e devolve o diagnóstico por devedor. **Rode-o antes de opinar sobre carteira com mais de um devedor.**

---

## 3. A escada de cobrança

O acervo segue esta ordem, e cada degrau produz prova para o próximo:

```
1. cobrança amigável pelo cliente        → prints viram prova de reconhecimento
2. cálculo atualizado do débito          → sem isso não há valor certo em nenhum degrau
3. NOTIFICAÇÃO EXTRAJUDICIAL (3 dias úteis)  → constitui em mora; supre o canhoto
4. protesto                              → mora + requisito da via falimentar
5. TERMO DE ACORDO / CONFISSÃO DE DÍVIDA → cria título executivo onde não havia
6. ajuizamento: MONITÓRIA ou EXECUÇÃO    → conforme o filtro 3
7. penhora SISBAJUD / RENAJUD / bens
```

O degrau 5 é o mais subestimado: transforma nota fiscal sem canhoto — que não executava e monitoriava mal — em título executivo do art. 784, III. Quando há qualquer chance de acordo, ele vale mais que a peça judicial.

Não pule o degrau 3 por pressa. Notificação é barata, constitui em mora, e no acervo é o que produz o reconhecimento que sustenta a monitória.

---

## 4. Os cinco produtos

Escolha um e diga qual está fazendo. Cada arquivo traz o esqueleto por extenso.

| Produto | Quando | Referência |
|---|---|---|
| **TRIAGEM DE CARTEIRA** | planilha de inadimplência, "vale a pena cobrar", "o que já prescreveu" | `referencias/triagem.md` |
| **PARECER DE VIABILIDADE** | um devedor, dívida relevante, escolha de via ou estratégia | `referencias/triagem.md` |
| **NOTIFICAÇÃO EXTRAJUDICIAL** | primeiro ato formal; ou para suprir canhoto | `referencias/notificacao.md` |
| **ACORDO / CONFISSÃO DE DÍVIDA** | devedor aceita pagar; criar título executivo | `referencias/acordo.md` |
| **INICIAL** — monitória ou execução | esgotado o extrajudicial | `referencias/monitoria.md`, `referencias/execucao.md` |

Peça em `.docx` sai pela `armando-timbrado`. Inicial obedece também à formatação da `armando-peticao-inicial` — endereçamento, preâmbulo em parágrafo único terminado em "propor a presente [AÇÃO]", seções em algarismo romano, valor da causa fundamentado.

---

## 5. Controle de qualidade

```
& "<scripts>\triar-carteira.ps1"           -Path "<planilha.csv>"
& "<scripts>\revisar-inicial.ps1"          -Path "<peça>"
& "<scripts>\extenso.ps1"                  -Path "<peça>"
& "<scripts>\validar-identificadores.ps1"  -Path "<peça>"
```

> A pasta dos scripts: quando esta skill carrega, o prompt informa o **diretório-base** dela. Tente, nesta ordem, `<base>/scripts` e `<base>/../../scripts` — esta skill leva os scripts **dentro** dela, então o primeiro caminho resolve; no plugin instalado há também a cópia da raiz. Saindo vazio nos dois, **pare e diga que não localizou os scripts**.
>
> Em máquina que nunca rodou script da casa, o PowerShell pode recusar por política de execução. Rode uma vez, na sessão: `Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass`.

Saída com código `1` quando há achado ALTA. **Achado ALTA é impedimento de protocolo.**

A leitura dirigida que nenhum script substitui está em `referencias/controle-de-qualidade.md`. Passe por ela.

---

## 6. Os quatro defeitos herdados do acervo — não os repita

Estes vêm de peças reais da casa e se propagam por cópia. Todos os quatro estão em mais de uma peça, o que é a assinatura de boilerplate contaminado.

1. **Monitória fundamentada em artigo de execução.** As duas monitórias do acervo dizem *"com fundamento nos artigos 700 e seguintes, bem como nos artigos 778 e seguintes do CPC"*. O art. 778 é de execução e não tem o que fazer em monitória. **Em monitória, cite só o art. 700 e seguintes.**

2. **Execução invocando o art. 44 do Código Civil.** Duas execuções abrem os fundamentos com *"os artigos 783 e 784 do Código de Processo Civil e o art. 44 do Código Civil preveem"*. O art. 44 do CC arrola as pessoas jurídicas de direito privado — nada a ver com título executivo. **Suprima.**

3. **Gênero e número do réu errados.** A monitória contra Francisco de Assis Solino pede citação "à **Requerida**"; a execução contra a Granmix pede que "**paguem**" no singular do sujeito. São resíduos da peça de origem. Confira réu por réu, pedido por pedido.

4. **Praça da assinatura divergindo do juízo.** A execução endereçada à Comarca de Miranorte está assinada em "Palmas/TO". A praça acompanha a comarca do endereçamento.

E um defeito de planilha, não de peça: na carteira Agroboi a coluna "Valor Com Juros" traz, em vários devedores, valor **menor** que o principal — Cleyber (4.478,60 → 1.075,31), Jason (4.270,70 → 3.025,51). Atualização não reduz dívida. Ao receber planilha do cliente, **confira essa coluna antes de usar qualquer número**; se o atualizado for menor que o nominal, o dado está corrompido e o cálculo precisa ser refeito.

---

## 7. Teses de risco — saiba onde o padrão da casa é discutível

1. **Honorários contratuais somados ao valor exequendo.** A execução do Granmix inclui 20% de honorários contratuais no montante e abre seção para sustentá-los (arts. 389, 395 e 404 do CC). É tese defensável e há julgado do TJTO, mas **é contestada** — parte da jurisprudência recusa a cumulação com a sucumbência na mesma execução. Sustente, mas não apresente ao cliente como líquido e certo, e mantenha o pedido de reconhecimento em separado, como o modelo faz.

2. **Mitigação da exigência de duas testemunhas.** O acervo executa instrumento assinado eletronicamente sem testemunhas, com apoio no REsp 1.495.920/DF e em julgados do TJTO e do TJ-MG. Funciona quando **há contexto probatório farto** (WhatsApp, cobranças, reconhecimento). Sem esse contexto, a tese fica exposta — e aí a monitória é a via mais segura, ainda que mais lenta.

3. **Multa compensatória de 10% cumulada com moratória de 2%.** O modelo de acordo da casa prevê as duas, mais juros de mora de 1% e compensatórios de 1%. A cumulação é atacável por excesso. Ao usar em contrato de consumo, revise; entre empresas o risco é menor.

4. **Insolvência civil pelo art. 748 do CPC/1973.** O parecer da Fourmaq a invoca como "falência da pessoa física". A aplicabilidade residual existe, mas é controvertida e varia por tribunal. **Confirme antes de prometer ao cliente.**

Antes de repetir qualquer súmula ou precedente do acervo, **confira a vigência**. Foi por cópia não conferida que o art. 778 chegou às duas monitórias.
