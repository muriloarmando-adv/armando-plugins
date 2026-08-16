# Catálogo de cláusulas de garantia

Redações-base para a página dispositiva. **São modelos, não formulário**: adapte rótulos das partes, numeração, prazos e valores ao instrumento concreto, e confira se o contrato já não trata do ponto em outro dispositivo — cláusula duplicada cria a antinomia que estamos tentando eliminar.

Cada verbete traz o **vício** que a cláusula corrige, a **redação** e a **fallback** (posição de recuo, para quando a contraparte resistir).

---

## 1. Divergência entre cláusulas ou entre contrato e anexo

**Vício.** O objeto, o valor ou a especificação constam de forma diversa em dois pontos do instrumento, ou divergem entre o corpo do contrato e a proposta comercial que o integra. Abre litígio interpretativo e permite ao adverso sustentar a versão que lhe convier.

**Redação (aditivo retificador).**

> As Partes retificam, de comum acordo, a Cláusula [X] deste Contrato, que passa a vigorar com a seguinte redação: "[redação corrigida]". Ficam expressamente ratificadas as demais disposições contratuais, prevalecendo, em caso de divergência entre o corpo deste Contrato e qualquer de seus anexos, a redação [do Contrato / do Anexo [n]], nesta ordem.

**Cláusula de prevalência, quando ausente.**

> Em caso de divergência entre as disposições deste Contrato e as de seus Anexos, prevalecerão, nesta ordem: (i) os Termos Aditivos, do mais recente ao mais antigo; (ii) o corpo deste Contrato; e (iii) a Proposta Comercial e demais Anexos. A ordem estabelecida neste item não se aplica a especificações técnicas e a preços unitários, quanto aos quais prevalecerá a Proposta Comercial aprovada pela CONTRATANTE.

**Fallback.** Ata de reunião ou e-mail de confirmação recíproca fixando a interpretação — inferior ao aditivo, mas serve de prova.

---

## 2. Encargos moratórios excessivos

**Vício.** Juros convencionais muito acima do padrão civil, cumulados com multa alta e índice de correção volátil. Além do custo direto, expõe o contrato a revisão judicial e enfraquece a exigibilidade do conjunto.

**Redação.**

> O atraso no pagamento de qualquer quantia devida por força deste Contrato sujeitará a Parte inadimplente a multa moratória de 2% (dois por cento) sobre o valor em atraso, juros de mora de 1% (um por cento) ao mês, calculados pro rata die, e correção monetária pelo IPCA, todos incidentes desde a data do vencimento até a data do efetivo pagamento.

**Fundamento a invocar.** Art. 406 do Código Civil; função social do contrato (art. 421) e boa-fé objetiva (art. 422); vedação ao enriquecimento sem causa (art. 884) e lesão (art. 157). Para precedente nominado, acione o agente `jurisprudencia` — não cite julgado de memória.

**Fallback.** Manter o percentual pactuado, mas (i) trocar IGP-M por IPCA, (ii) fixar carência de 5 dias úteis antes da incidência, e (iii) suprimir a cumulação de multa e juros sobre a mesma parcela no mesmo período.

---

## 3. Responsabilidade ilimitada e transferência integral do risco

**Vício.** O instrumento imputa ao cliente responsabilidade integral e irrestrita pela guarda e integridade do bem, estendida a danos indiretos, morais, "tempo parado" e "perda de faturamento", sem qualquer contrapartida quanto ao estado de conservação do bem entregue. É a cláusula de responsabilidade ilimitada — obrigação de contorno indeterminado.

**Redação.**

> **[X].1** Cada Parte responderá pelos danos que der causa, na exata proporção de sua culpa, apurada nos termos deste Contrato e da legislação aplicável.
>
> **[X].2** A responsabilidade total e agregada de cada Parte, por todo e qualquer dano decorrente deste Contrato, fica limitada ao valor total do Contrato, ressalvadas as hipóteses de dolo, fraude e danos a terceiros.
>
> **[X].3** Nenhuma das Partes responderá perante a outra por lucros cessantes, perda de faturamento, perda de oportunidade de negócio, danos indiretos ou danos morais, ainda que previsíveis.
>
> **[X].4** A CONTRATANTE não responde por vícios ocultos, defeitos de fabricação, desgaste natural, fadiga de material, falha de manutenção preventiva ou qualquer condição preexistente do equipamento, cuja apuração e reparação incumbem exclusivamente à CONTRATADA.

**Fallback.** Se o adverso recusar o teto do item X.2, aceitar teto mais alto (2x o valor do contrato) mas **jamais** abrir mão do X.3 e do X.4 — são os que impedem a conta aberta.

---

## 4. Ausência de garantia de entrega em condições adequadas

**Vício.** O contrato responsabiliza o cliente pela integridade do bem, mas não obriga a contraparte a entregá-lo apto, certificado e documentado. Assimetria flagrante: à contraparte, liberdade; ao cliente, responsabilidade irrestrita.

**Redação.**

> A CONTRATADA garante que o equipamento será entregue em plenas condições operacionais e de segurança, acompanhado da documentação técnica pertinente, dos certificados de inspeção e ensaio exigidos pela normatização aplicável e do comprovante de manutenção preventiva em dia. A entrega será precedida de vistoria conjunta, reduzida a termo assinado por ambas as Partes, com registro fotográfico do estado do bem, documento que servirá de parâmetro exclusivo para a apuração de eventuais danos ao término da locação.

**Por que o termo de vistoria importa.** Sem ele, toda avaria preexistente é imputável ao cliente por presunção prática. É a cláusula de melhor relação custo-benefício desta lista.

---

## 5. Garantia de desempenho, SLA e indisponibilidade

**Vício.** Nenhum nível mínimo de disponibilidade, nenhuma penalidade para a contraparte por falha técnica, nenhum prazo de substituição — enquanto o cliente responde por tudo.

**Redação.**

> **[X].1** A CONTRATADA obriga-se a manter o equipamento em condições de operação durante todo o período contratado, respondendo pela manutenção preventiva e corretiva.
>
> **[X].2** Verificada falha técnica que impeça a operação, a CONTRATADA disporá de [4 (quatro)] horas para o restabelecimento e de [24 (vinte e quatro)] horas para a substituição do equipamento por outro de especificação igual ou superior, sem custo adicional para a CONTRATANTE.
>
> **[X].3** As paralisações decorrentes de falha técnica superiores a [4 (quatro)] horas contínuas ensejarão desconto proporcional na diária, calculado pro rata, sem prejuízo da recomposição dos custos comprovadamente incorridos pela CONTRATANTE em razão da paralisação.
>
> **[X].4** Excedido o prazo do item [X].2 sem restabelecimento ou substituição, fica facultado à CONTRATANTE rescindir o Contrato sem incidência de multa e sem prejuízo da restituição dos valores pagos por serviços não prestados.

**Fallback.** Suprimir o item X.3 e manter apenas o desconto pro rata sem recomposição de custos.

---

## 6. Aceitação tácita e prazo exíguo de impugnação

**Vício.** Silêncio convertido em anuência ao valor cobrado, em prazo curto demais para a estrutura administrativa do cliente. O silêncio como manifestação de vontade é excepcional (art. 111 do Código Civil).

**Redação.**

> A CONTRATANTE disporá de 5 (cinco) dias úteis, contados do recebimento do relatório de medição, para manifestar-se por escrito. A ausência de manifestação nesse prazo autorizará a emissão da fatura com base nos dados da medição, mas **não implicará, em hipótese alguma, renúncia ao direito de impugnação posterior**, administrativa ou judicial, de valores cobrados em desacordo com este Contrato, tampouco convalidará erro aritmético, de lançamento, de duplicidade ou de aplicação de preço unitário.

**Complemento — revisão pós-pagamento simétrica.** Se o contrato permite à contraparte revisar a medição após o pagamento, a faculdade tem de ser recíproca e limitada:

> A aprovação, expressa ou tácita, do demonstrativo de medição e o correspondente pagamento não impedirão que qualquer das Partes, no prazo de 30 (trinta) dias subsequentes ao pagamento, identificando erro aritmético, de lançamento ou de duplicidade, demonstrado documentalmente, manifeste-se por escrito e de forma fundamentada à outra. A impugnação fundamentada suspenderá a retenção da parcela controvertida. Somente o valor incontroverso ou definitivamente apurado poderá ser retido ou compensado nos pagamentos subsequentes.

**Ponto de ruptura.** A frase "somente o valor incontroverso ou definitivamente apurado poderá ser retido" é o núcleo. Sem ela, a retenção unilateral por mera alegação permanece possível, e o resto da cláusula é ornamento.

---

## 7. Retenções cautelares sem teto nem prazo

**Vício.** Faculdade de reter valores controvertidos sem limite percentual, sem prazo de apuração e sem custo financeiro — a contraparte financia-se com o dinheiro do cliente.

**Redação.**

> **[X].1** As retenções cautelares de valores controvertidos ficam limitadas, em cada medição, a 20% (vinte por cento) do respectivo valor líquido, salvo prejuízo já quantificado e demonstrado documentalmente.
>
> **[X].2** A apuração observará o prazo máximo de 60 (sessenta) dias. Encerrado o prazo sem quantificação fundamentada do valor, a parcela retida será imediatamente liberada, com os acréscimos do item [X].3.
>
> **[X].3** Os valores retidos, glosados ou compensados que venham a ser liberados ou restituídos, por se revelar indevida a retenção, serão acrescidos de correção monetária pelo IPCA e juros de 1% (um por cento) ao mês, incidentes desde a data da retenção até a efetiva liberação.

**Atenção na negociação.** A contraparte tende a aceitar o teto e o prazo, e depois (i) alargar o rol de exceções ao teto e (ii) tornar o prazo suspensível "enquanto depender de autoridade externa". Se as hipóteses excepcionadas de maior incidência prática forem justamente as que envolvem órgãos externos, a suspensão vira regra. Exija, no mínimo, dever de informar a existência e o andamento da apuração.

**Sobre os juros.** Se o adverso impuser carência ("juros só se não pago em 10 dias úteis após a definição"), é concessão módica e aceitável — desde que a **correção monetária continue correndo desde a data da retenção**. Esse é o ponto que não se cede.

---

## 8. Rescisão, cancelamento e adiamento

**Vício.** Multa aplicada indistintamente ao cancelamento motivado e ao imotivado; retenção de valores pagos por serviços não prestados; aviso prévio desproporcional à duração do contrato.

**Redação.**

> **[X].1** A CONTRATANTE poderá cancelar ou adiar a atividade mediante comunicação escrita com antecedência mínima de 10 (dez) dias corridos da data prevista para o início da mobilização.
>
> **[X].2** O cancelamento comunicado fora do prazo do item [X].1 sujeitará a CONTRATANTE a multa de [10%] sobre o valor total do Contrato.
>
> **[X].3** A multa prevista no item [X].2 **não será devida** quando o cancelamento ou adiamento decorrer de caso fortuito, força maior, determinação de autoridade pública ou fato imputável à CONTRATADA, inclusive indisponibilidade do equipamento, atraso na mobilização ou ausência da documentação técnica exigida.
>
> **[X].4** Em qualquer hipótese de cancelamento, serão restituídos à CONTRATANTE, no prazo de 10 (dez) dias, os valores pagos por serviços não prestados, inclusive mobilização e desmobilização não executadas, sem prejuízo da multa eventualmente devida.

**Fallback.** Ceder no percentual da multa (item X.2) para preservar X.3 e X.4. A distinção entre motivado e imotivado vale mais que o percentual.

---

## 9. Carência e aviso prévio na rescisão imotivada

**Vício.** Contrato de fornecimento continuado que exige investimento em mobilização (frota, equipamento, pessoal) e admite denúncia imotivada a qualquer tempo. O investimento não amortiza.

**Redação.**

> A [PARTE] poderá rescindir imotivadamente este Contrato, total ou parcialmente, a qualquer tempo, mediante comunicação escrita à outra Parte com antecedência mínima de 180 (cento e oitenta) dias, facultada a rescisão imotivada somente após decorridos 18 (dezoito) meses do início efetivo das entregas.

**Por que esta é a cláusula mais valiosa em contrato de fornecimento.** Carência somada a aviso prévio dá horizonte mínimo de 24 meses de operação — lastro temporal para amortização de frota e equipamento. É a alternativa que costuma ser aceita quando a indenização do investimento não amortizado é rejeitada. Uma vez obtida, não reabrir.

**Complemento — isenção de multa na denúncia regular.**

> A multa não será aplicável ao término normal da vigência, à rescisão imotivada promovida por **qualquer das Partes** na forma dos Itens [X] e [Y], ao encerramento por comum acordo, ao caso fortuito ou força maior regularmente reconhecido, ou ao encerramento decorrente de fato comprovadamente imputável exclusivamente à [CONTRAPARTE].

A expressão **"qualquer das Partes"** é o ponto. Isenção que só alcança a denúncia do adverso permite-lhe sustentar que o exercício regular da nossa denúncia atrai a multa compensatória — tese frágil, mas cuja simples arguição já impõe ao cliente o ônus de litigar sobre a cifra.

---

## 10. Simetria das multas compensatórias

**Vício.** Percentuais iguais incidentes sobre bases diferentes. Simetria aparente, assimetria substancial.

**Diagnóstico antes da redação.** Calcule as duas multas em reais. Se a razão entre elas não for 1:1, o percentual não é o problema — a base é.

**Redação.**

> A rescisão por culpa de qualquer das Partes sujeitará a Parte culpada ao pagamento de multa compensatória equivalente a [10%] do valor correspondente a [6 (seis)] meses de fornecimento, calculado com base no volume mensal ordinário e nos preços unitários vigentes na data da rescisão. A multa será exigível somente após a efetiva rescisão e não será cumulada com outra multa compensatória incidente sobre o mesmo fato gerador.

**Regra de negociação.** Condicionar qualquer elevação percentual à equiparação das bases — ambas em doze meses, ou ambas em seis. Elevação uniforme sobre bases desiguais dobra a exposição do cliente e preserva integralmente a disparidade.

**Teto x piso.** Verifique se a multa é teto para um lado e piso para o outro. Se o contrato diz que a multa contra o cliente não afasta indenização suplementar, mas a multa contra o adverso "constitui a única verba devida", a simetria numérica encobre regimes opostos. Denuncie isso por extenso.

---

## 11. Rol aberto de exceções e cláusula de encerramento

**Vício.** Rol de hipóteses de não incidência encerrado por inciso genérico do tipo "qualquer outra hipótese prevista neste Contrato que autorize suspensão, retenção ou não recebimento". Como o instrumento costuma conferir à contraparte diversas faculdades autônomas de suspensão, cada uma delas passa a ser, por remissão, hipótese excludente — e permite reconstruir *ex post* quase qualquer inadimplemento como exceção.

**Redação.**

> As hipóteses previstas neste item são **taxativas**, vedada interpretação extensiva ou analógica, e não alcançam o exercício, pela [CONTRAPARTE], de faculdades de suspensão, reprogramação ou retenção previstas em outros dispositivos deste Contrato.

**Como negociar.** Duas frentes: suprimir o inciso de encerramento **ou** converter o rol em taxativo com a cláusula de fechamento acima. A segunda é mais fácil de obter. Sem uma das duas, qualquer percentual de compensação acordado permanece condicionado a rol aberto — e a negociação sobre o percentual torna-se acadêmica. **Priorize este ponto sobre o valor.**

---

## 12. Piso de materialidade para rescisão por culpa

**Vício.** Qualquer déficit ou falha, ainda que marginal, autoriza em tese a rescisão por culpa.

**Redação.**

> Para os fins deste item, o déficit de fornecimento somente caracterizará causa de rescisão quando superior a 15% (quinze por cento) do Volume Mensal Programado em 2 (dois) meses-calendário consecutivos, ressalvadas as hipóteses de rescisão imediata dos Itens [X] e [Y].

**Cuidado formal.** Parágrafo único inserido por aditivo costuma sair com numeração automática errada, duplicando a rubrica de outro item. Confira a rubrica antes da assinatura e, se estiver errada, peça a correção como mera revisão redacional.

---

## 13. Comunicação prévia de reajuste e memória de cálculo

**Vício.** Reajuste aplicado sem demonstração da base, ou com prazo de contestação inútil.

**Redação.**

> A Parte interessada comunicará à outra, por escrito e com antecedência mínima de 48 (quarenta e oito) horas úteis da emissão da primeira Nota Fiscal alcançada pela alteração, a memória de cálculo do reajuste, acompanhada do levantamento oficial que a fundamenta. A ausência de impugnação fundamentada nesse prazo autorizará o faturamento pelo preço atualizado, para mais ou para menos, na forma desta Cláusula.

**Nota.** Redija em termos bilaterais ("a Parte interessada"). O dispositivo aproveita ao cliente tanto na variação positiva quanto na negativa, e a bilateralidade reduz drasticamente a resistência do adverso.

---

## 14. Suspensão do fornecimento por inadimplemento

**Vício.** Direito de suspender neutralizado por exigência genérica de "inexistência de qualquer glosa, retenção ou discussão de boa-fé sobre o valor" — basta formalizar divergência sobre qualquer parcela para bloquear a suspensão.

**Redação.**

> A suspensão somente poderá ser exercida após notificação formal e decurso do prazo de [X] dias sem regularização, e **limitar-se-á proporcionalmente à parcela vencida, líquida e incontroversa, não sendo obstada por glosa, retenção ou divergência que recaia sobre parcela diversa daquela que fundamenta a suspensão**.

---

## 15. Seguro e dispensa de regresso

**Vício.** O cliente é obrigado a contratar seguro amplo com cláusula de dispensa de regresso em favor da contraparte — o que, na prática, faz o cliente segurar o patrimônio alheio e renunciar à ação regressiva contra quem deu causa ao sinistro.

**Redação.**

> A obrigação de contratação de seguro prevista no item [X] não abrange os danos decorrentes de vício, defeito, desgaste, falha de manutenção ou operação inadequada imputáveis à CONTRATADA ou a seus prepostos, hipóteses em que fica **preservado o direito de regresso** da CONTRATANTE e da seguradora. A cláusula de dispensa de regresso limita-se aos sinistros decorrentes de fato imputável à CONTRATANTE.

---

## 16. Responsabilidade trabalhista e previdenciária

**Vício.** O contrato declara que a contraparte responde por reclamações trabalhistas, mas não cria mecanismo que torne a declaração eficaz.

**Redação.**

> A CONTRATADA responde exclusivamente pelos vínculos, encargos e obrigações trabalhistas, previdenciárias e securitárias de seus empregados e prepostos, obrigando-se a: (i) requerer sua exclusão do polo passivo e assumir a defesa de qualquer reclamação ajuizada em face da CONTRATANTE, no prazo de 5 (cinco) dias úteis contado da respectiva ciência; (ii) reembolsar integralmente à CONTRATANTE, no prazo de 10 (dez) dias, todo valor por esta despendido a esse título, inclusive custas, depósitos recursais e honorários; e (iii) apresentar mensalmente, como condição de exigibilidade do pagamento, as guias de recolhimento e a documentação comprobatória da regularidade trabalhista e previdenciária.

**O que faz a diferença.** A alínea (iii). Sem condicionar o pagamento à comprovação, as alíneas (i) e (ii) só valem contra empresa solvente.

---

## 17. Foro de eleição

**Vício.** Foro na sede do adverso, com renúncia expressa a qualquer outro. Impõe ao cliente o ônus logístico e financeiro de litigar longe da própria base operacional — e o ônus recai justamente sobre quem, na maioria das vezes, será autor.

**Redação.**

> Fica eleito o foro da Comarca de [comarca da sede ou da operação do cliente], para dirimir as controvérsias decorrentes deste Contrato.

**Fallback, em ordem.** (i) Foro da comarca do cliente; (ii) foro do local de execução do contrato; (iii) comarca equidistante ou de maior estrutura judiciária regional; (iv) manutenção do foro do adverso **com supressão da renúncia expressa a outro foro** — o que preserva a discussão sobre competência.

---

## Ordem de prioridade sugerida

Quando não houver instrução do cliente em contrário, esta é a ordem que costuma render mais na mesa:

1. **Rol aberto de exceções** (verbete 11) — sem ele, a negociação sobre valores é acadêmica.
2. **Limitação de responsabilidade** (verbete 3) — maior exposição em cifra absoluta.
3. **Carência e aviso prévio** (verbete 9) — em contrato de fornecimento com investimento em mobilização.
4. **Antinomias e dispositivos inexequíveis** — direito instituído por uma cláusula e neutralizado por outra.
5. **Simetria de multas** (verbete 10).
6. **Prazos de impugnação e retenções** (verbetes 6 e 7).
7. **Garantias técnicas e SLA** (verbetes 4 e 5).
8. **Foro** (verbete 17).
9. **Defeitos formais e uniformização de valores divergentes** (verbete 1) — por último, como moeda de fechamento.
