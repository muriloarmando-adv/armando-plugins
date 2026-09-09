# Triagem de carteira e parecer de viabilidade

Dois produtos, mesma máquina de decisão. A **triagem** roda sobre muitos devedores e devolve tabela; o **parecer** roda sobre um devedor e devolve estratégia.

---

## 1. Prescrição — o filtro que mais recupera valor

### Prazos

| Crédito | Prazo | Base |
|---|---|---|
| Dívida líquida em instrumento particular (NF, contrato, boleto) | **5 anos** | art. 206, §5º, I, CC |
| Enriquecimento sem causa | 3 anos | art. 206, §3º, IV, CC |
| Cobrança geral sem prazo especial | 10 anos | art. 205, CC |

### Prescrição **executiva** — curta, e não mata o crédito

Estes prazos fecham a execução e **rebaixam a via para monitória**. Errar aqui e declarar o crédito perdido é o erro mais caro da triagem.

| Título | Prescrição executiva | Depois disso |
|---|---|---|
| **Cheque** | 6 meses do fim do prazo de apresentação (30 dias mesma praça / 60 dias praças diversas) — Lei 7.357/85 | Monitória (Súmula 299 do STJ), até 5 anos |
| **Nota promissória** | 3 anos do vencimento (LUG, Dec. 57.663/66) | Monitória / ação causal, até 5 anos |
| **Duplicata** | 3 anos do vencimento contra o sacado (art. 18 da Lei 5.474/68) | Monitória, até 5 anos |

### Interrupção — verifique antes de descartar

Art. 202 do CC. Na prática do acervo, três importam:

- **Pagamento parcial** (inciso VI — reconhecimento inequívoco do devedor). O mais comum e o mais esquecido. Reinicia a contagem inteira. Na carteira Agroboi há devedores com pagamento parcial recente cujo crédito antigo continua exigível — e vários estavam marcados como prescritos.
- **Protesto** cambial (inciso III).
- **Reconhecimento por escrito** — inclusive WhatsApp e e-mail. É o mesmo ato que supre o canhoto; serve duas vezes.

⚠ A interrupção **só se prova com documento**. Print de conversa, comprovante de depósito parcial, instrumento de protesto. Alegação do cliente de que "ele pagou um pouco em tal ano" não sustenta a tese — peça o comprovante.

---

## 2. Documento hábil

Ordem de força probatória, do mais forte ao inútil:

1. **Termo de acordo / confissão de dívida assinado** — cria título executivo do nada
2. **Nota promissória, cheque, duplicata aceita** — título por natureza
3. **Contrato assinado** (com testemunhas ou assinatura eletrônica certificada)
4. **Nota fiscal + canhoto de entrega assinado, datado e identificado**
5. **Nota fiscal sem canhoto** — só monitória, e frágil
6. **Boleto** — nada. Emissão unilateral do credor; não prova venda, entrega nem anuência

### O problema do canhoto — a doutrina da casa

De `Efetividade da cobrança judicial.docx`, transcrito na substância:

A ausência de assinatura no canhoto gera **dois** problemas, não um:
1. **impede a execução** — o caminho rápido para penhora;
2. **fragiliza a monitória** — risco real de o juiz extinguir por falta de prova da entrega, exigindo prova complementar que a empresa em geral não tem.

**Orientação preventiva ao cliente:** instituir como norma obrigatória a assinatura **datada e identificada** no canhoto no ato da entrega. Vale dizer isso ao cliente em toda triagem — é o único conselho da área que zera o problema no futuro.

**Orientação corretiva, para o passado:** notificação extrajudicial prévia buscando o reconhecimento da dívida, ou confissão por e-mail/WhatsApp. Tribunais têm aceitado esse reconhecimento para suprir o canhoto e viabilizar a monitória.

---

## 3. A via falimentar — a alavanca que o acervo subutiliza

Base: **art. 94, I, da Lei 11.101/05**. Requisitos objetivos:

- obrigação líquida em **título executivo protestado**;
- soma **superior a 40 salários mínimos** na data do pedido;
- impontualidade **sem relevante razão de direito**.

**Não se exige prova de insolvência econômica.** O STJ, no **REsp 2.028.234/SC**, assentou que a impontualidade injustificada presume a insolvência de **maneira absoluta**, sendo obrigatória a decretação da quebra — a insolvência aqui é jurídica, não econômica. E a nova lei, ao fixar limites objetivos, retirou do juiz a possibilidade de perquirir se a falência está sendo usada como instrumento de cobrança (**Súmula 42 do TJSP**; TJSP, Ap. 1005042-39.2018.8.26.0048).

Três consequências práticas:

- **O patamar pode ser somado.** Vários títulos do mesmo devedor contam juntos; e credores diferentes podem reunir-se em **litisconsórcio ativo** (art. 94, §1º). Vale procurar outros credores do mesmo devedor.
- **Vício em um título não derruba o pedido**, se os demais ainda superam o limite.
- **O depósito elisivo é a verdadeira alavanca.** Para não ter a falência decretada, a devedora deposita o valor **integral** — principal, correção, juros e sucumbência. É o mecanismo que recupera crédito mais rápido em toda esta skill.

Quanto ao protesto: **não é preciso o protesto especial para fins falimentares** — qualquer modalidade serve. Mas, sendo duplicata, o protesto por indicações precisa vir **acompanhado da prova da entrega da mercadoria**, por ser título causal (REsp 2.028.234/SC; arts. 13, §2º, da Lei 5.474/68 e 21, §2º, e 23 da Lei 9.492/97).

Na prática da casa, quando o mesmo grupo devedor tem contratos distintos, **segregue**: protesta-se especificando "para fins de falência" o título que vai à via falimentar, e "para constituição em mora" o que vai à execução; e ajuízam-se **ações distintas**, para não dar ao juiz margem de indeferir por ilegitimidade passiva ou mistura de ritos.

Para pessoa física sem bens, o parecer da casa cogita **insolvência civil** (art. 748 do CPC/1973, aplicabilidade residual) — mas isso é tese controvertida; ver §7 do SKILL.md.

---

## 4. Produto: TRIAGEM DE CARTEIRA

Entrada típica: planilha de inadimplência do cliente, quase sempre suja. Rode `triar-carteira.ps1` antes de qualquer conclusão.

### Saída — reproduza as colunas da casa

O formato é o do `Acompanhamento de Cobrança.xlsx`:

| Coluna | Conteúdo |
|---|---|
| Nº | sequencial |
| Qtde. de títulos | quantos títulos do mesmo devedor |
| Nome do devedor | |
| Ano de vencimento | o mais antigo |
| Valor principal | nominal, já abatidos pagamentos parciais |
| Valor atualizado até MM/AAAA | **nunca menor que o principal** |
| Possui NF? | SIM/NÃO |
| Docs assinados? | SIM/NÃO — é o canhoto |
| Telefone / E-mail / Endereço | |
| **Status** | `Ajuizar` / `Notificar` / `Triagem` / `Prescrito` |
| **Observação** | a razão da decisão, em uma frase |

Vocabulário de status usado no acervo, que vale manter:

- **`Prescrito`** — "Decorrido o prazo prescricional de 5 anos". Encerra.
- **`Triagem`** — falta documento. Diga **qual**: *"Precisamos do envio da NF e canhoto; na pasta tem apenas boleto."*
- **`Notificar`** — há dívida, falta título. Sem assinatura no canhoto, não há como ajuizar com segurança; cabe notificação para obter reconhecimento.
- **`Ajuizar`** — documento hábil e prazo em curso. Indique a via e o valor atualizado.

### Feche a triagem com números

Toda triagem termina com o agregado, porque é o que o cliente decide em cima:

- total de devedores e de títulos;
- principal e atualizado, **somados**;
- **quanto está prescrito** — em reais e em percentual. Este número é a razão de ser da entrega;
- quanto está pronto para ajuizar, e quanto só espera documento do cliente;
- **a lista exata de documentos a pedir ao cliente**, por devedor.

---

## 5. Produto: PARECER DE VIABILIDADE

Modelo do acervo: `Parecer - ARMANDO X FOURMAQ.docx`. Estrutura:

```
PARECER TÉCNICO: ESTRATÉGIA DE COBRANÇA

Consideração inicial          ← o fato que reabre ou define a discussão
Identificação dos títulos e devedores
   Para cada devedor: qualificação, objeto, título, valor, ESTRATÉGIA
[Seção por via escolhida]     ← requisitos, precedente, vantagem estratégica
Responsabilidade das pessoas físicas   ← sócios, avalistas, anuentes
RESUMO DO PLANO DE AÇÃO
   1. segregação dos protestos
   2. ajuizamento das ações distintas
   3. uso estratégico dos documentos não assinados
Conclusão                     ← por que este desenho evita nulidade
CASOS SEMELHANTES             ← ementas por extenso
```

Duas lições do modelo que valem como regra:

- **Devedores distintos exigem ritos distintos.** Duas empresas do mesmo grupo, com CNPJs e objetos contratuais diversos, não vão na mesma ação. Segregar elimina o risco de indeferimento por ilegitimidade passiva ou mistura de ritos.
- **Documento não assinado ainda serve.** O termo de distrato que a contraparte nunca aceitou foi anexado como prova de que ela **tinha ciência do montante** — reforça a boa-fé do credor e a má-fé da devedora. Não descarte minuta recusada.

Sempre nomeie a **vantagem estratégica** da via escolhida, não só o cabimento. No modelo: "a pressão pelo depósito elisivo". O cliente decide por isso, não pelo artigo.
