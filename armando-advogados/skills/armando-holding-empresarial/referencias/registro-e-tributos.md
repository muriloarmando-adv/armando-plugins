# Registro e efeitos tributários

Grau de confirmação. **[DREI]** indica texto conferido no Anexo IV da IN DREI 81/2020 vigente (gov.br/drei, alterado pelas INs DREI 55/2021, 88/2022, 112/2022 e 1/2024; outubro de 2026). **[LEI]** indica dispositivo legal estável. **[CONFERIR]** indica ponto não confirmado em fonte primária: verifique antes de afirmar ao cliente.

---

## 1. As três rotas de registro

| Rota | Como | Quando usar | Campo no `.json` |
|---|---|---|---|
| **Conjunta** (padrão) | contrato da holding (2º Ato) e alterações das investidas (1º Atos) protocolados **juntos**; as investidas mencionam a holding "em constituição" | todas as sociedades na mesma UF | `"rota": "conjunta"` |
| **Posterior** (redação literal do modelo) | registra-se a holding; os sócios "se comprometem a apresentar o ato de alteração das empresas compartilhadoras no prazo de 30 dias" | quando a Junta não vincular os processos, ou investida de outra UF | `"rota": "posterior"` |
| **Em dois tempos** (precedente Fourmaq) | holding constituída com capital mínimo em dinheiro; depois, aumento de capital integralizado com as quotas (art. 1.081) | quando o cliente quer a holding registrada antes, ou há investidas em várias UFs | gerar a constituição com `dinheiro` e tratar o aumento como alteração da holding |

**Por que a conjunta é o padrão.** O Manual exige que o 2º Ato indique o 1º e que os processos da mesma UF tramitem juntos [DREI 4.3.5, b, e Nota I]. A rota posterior registra um capital "totalmente integralizado" com quotas que, perante a sociedade e terceiros, ainda não foram transferidas (art. 1.057, parágrafo único) [LEI]. Funciona na prática de algumas Juntas, mas a afirmação é inexata até o 1º Ato ser averbado.

**JUCETINS.** Não há roteiro próprio publicado para vincular os processos [CONFERIR]. Antes do primeiro protocolo, confirme pelo atendimento da Junta (portal Simplifica Tocantins) como vincular e se a holding em constituição pode figurar como interveniente.

## 2. Roteiro depois da assinatura

1. **Viabilidade** do nome e do endereço da holding no integrador estadual (REDESIM).
2. **Protocolo** em até **30 dias** da assinatura. Dentro do prazo, os efeitos retroagem à data do ato; fora dele, contam do deferimento (Lei 8.934/1994, art. 36) [LEI].
3. **Visto de advogado** no contrato da holding. A holding não é ME/EPP (LC 123, art. 3º, § 4º, VII), e por isso não se aplica a dispensa do art. 1º, § 2º, da Lei 8.906/1994 [LEI].
4. Deferidos os atos:
   - **DBE** para inscrever a holding no CNPJ;
   - atualização do **QSA de cada investida** com o CNPJ da holding;
   - **desenquadramento** de ME/EPP das investidas que eram, e comunicação ao Simples;
   - bancos, procurações e contratos com cláusula de mudança de controle.
5. **DIRPF do ano seguinte, de cada sócio.** Baixa das quotas da investida e lançamento das quotas da holding **pelo mesmo valor**, se a conferência foi pelo custo (Lei 9.249/1995, art. 23, § 1º) [LEI].
6. **Guarde no Drive**, na pasta do cliente, o contrato da holding e cada alteração com a chancela da Junta. A próxima alteração de cada investida vai precisar do número da série.

## 3. Valor de conferência das quotas

O valor atribuído às quotas na cláusula do capital é **escolha**, e tem dois limites:

- **Para cima: ganho de capital.** A pessoa física pode transferir as quotas pelo valor da declaração de bens ou pelo valor de mercado. A diferença a maior é tributável como ganho de capital (Lei 9.249/1995, art. 23, *caput* e § 2º; alíquotas de 15% a 22,5% do art. 21 da Lei 8.981/1995) [LEI]. O modelo usa o valor nominal, que costuma coincidir com o custo na DIRPF. Confira.
- **Para cima também: estimação.** Quotas avaliadas acima do patrimônio real da investida expõem **todos** os sócios da holding, solidariamente, por 5 anos do registro (CC, art. 1.055, § 1º) [LEI]. O gerador compara com o patrimônio líquido, se informado.
- **Laudo:** não exigido pela Junta [DREI 4.3.4, Nota I, a]. Recomendável quando o valor diverge do nominal ou do custo.

Quando todos os valores coincidem com o custo na DIRPF, o gerador inclui no contrato o parágrafo do art. 23 da Lei 9.249/1995.

## 4. Simples Nacional e ME/EPP

- **Investida** com sócia pessoa jurídica deixa de ter tratamento de ME/EPP (LC 123/2006, art. 3º, § 4º, I) [DREI, transcrição no Manual].
- **Holding** que participa do capital de outra pessoa jurídica também não pode (art. 3º, § 4º, VII) [LEI].
- Corolário: nenhuma das duas pode usar a deliberação majoritária sem reunião da LC 123 (art. 70). Daí a correção da cláusula 33 do modelo.

## 5. Dividendos depois da Lei 15.270/2025 [CONFERIR — fonte secundária]

Vigência desde 1º/1/2026, segundo o que se publicou; o texto oficial não foi lido nesta pesquisa:

- **IRRF de 10%** sobre lucros e dividendos pagos por uma mesma pessoa jurídica a uma mesma pessoa física acima de **R$ 50 mil no mês**;
- **tributação mínima anual** para renda acima de R$ 600 mil;
- **transição** para lucros apurados até 2025 com distribuição aprovada até 31/12/2025;
- **contencioso** em curso: liminares e sentença contra a retenção.

Efeito provável na holding, a confirmar com tributarista:

- o dividendo da investida para a holding (de PJ para PJ) segue isento (Lei 9.249/1995, art. 10) e fora da retenção;
- a retenção recai quando a holding distribui aos sócios;
- concentrar várias investidas numa só fonte pagadora pode antecipar retenção mensal, sem mudar o ajuste anual.

**Não prometa economia tributária no contrato nem na entrega.** Remeta ao estudo comparativo PF × holding do NPPS (item 9 da lista de skills), quando existir.

## 6. Não é fusão nem ato de concentração

- **Fusão / incorporação.** Não há extinção de sociedade nem sucessão, então nada de protocolo, justificação ou quórum de operação societária (CC, arts. 1.116 a 1.122) [LEI].
- **CADE.** Se os mesmos sócios que controlam as investidas as transferem para uma holding própria, não muda o grupo de controle: é reorganização intragrupo. Só pense em notificação se algum grupo envolvido tiver faturamento de R$ 750 milhões e outro de R$ 75 milhões (Lei 12.529/2011, art. 88) [LEI; tratamento intragrupo: CONFERIR na Resolução CADE 33/2022].

## 7. Quóruns após a Lei 14.451/2022 [DREI, tabela do item 3.2]

| Matéria | Quórum legal |
|---|---|
| Modificação do contrato, incorporação, fusão, dissolução, recuperação judicial, designação/destituição/remuneração de administrador sócio | mais da metade do capital (art. 1.076, II) |
| Administrador **não sócio** | 2/3 dos sócios com capital não integralizado; mais da metade do capital com capital integralizado (art. 1.061) |
| Contas, distribuição de lucros (inclusive desproporcional), liquidantes | maioria dos presentes (art. 1.076, III) |
| Dispensa de reunião | decisão escrita de **todos** os sócios (art. 1.072, § 3º) |
| Exclusão por justa causa | mais da metade do capital, se o contrato a prever (art. 1.085) |

Quórum contratual mais alto prevalece.
