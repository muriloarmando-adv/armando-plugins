# Controle de qualidade

Passe a minuta por este crivo **antes de entregar**. É a mesma varredura que a skill `armando-analise-contrato` aplicaria se o instrumento viesse da outra parte.

Os itens marcados com ⚠ correspondem a defeitos que **existem em instrumentos do próprio acervo do escritório** — inclusive arquivados. São os que mais se propagam, porque cada minuta nova nasce de um precedente.

---

## A. Aritmética do capital — rode o script

```bash
powershell -NoProfile -ExecutionPolicy Bypass -File "scripts/quadro-societario.ps1" dados.json
```

- [ ] A soma das quotas dos sócios é igual ao total do capital dividido pelo valor nominal.
- [ ] O capital é divisível pelo valor nominal da quota (não há quota fracionária).
- [ ] Os percentuais somam 100%, e cada um bate com a razão quotas/total.
- [ ] Os valores em reais de cada sócio batem com quotas × valor nominal.
- [ ] Se o capital não está totalmente integralizado: há prazo e modo de realização (art. 997, IV).
- [ ] ⚠ **Todo valor e toda quantidade têm extenso, e o extenso está certo.** A XXII Alteração da Distribuidora de Gás Correa registra *"O aumento de R$ 350.000,00 (quinhentos mil reais)"* — errado, arquivado, e replicável por copiar-e-colar. O script gera o extenso; não o digite à mão.
- [ ] ⚠ Parênteses fechados: o mesmo instrumento traz *"R$ 150.000,00 cento e cinquenta mil reais)"*.
- [ ] A tabela do capital aparece com os mesmos números **em todos os lugares** onde é repetida (corpo da alteração e consolidação).

## B. Identidade das pessoas

- [ ] ⚠ **A grafia do nome de cada sócio é idêntica** no preâmbulo, na tabela do capital, no corpo das cláusulas e no bloco de assinaturas. O precedente da Distribuidora de Gás qualifica "ITELVINO CORREA **NETTO**" e assina "ITELVINO CORREA **NETO**".
- [ ] Qualificação de PF completa: nome, nacionalidade, naturalidade, data de nascimento, estado civil **e regime de bens se casado**, profissão, CPF, RG com órgão expedidor, endereço com CEP.
- [ ] Qualificação de PJ completa: denominação, CNPJ, sede, NIRE — **e o representante que assina, qualificado como pessoa física**.
- [ ] Nenhum CPF, CNPJ, NIRE, RG, CEP, data de arquivamento ou CNAE foi inventado. O que não foi apurado está como `[......]` e consta da lista de pendências.
- [ ] Se há cônjuges no quadro: o regime de bens não é comunhão universal nem separação obrigatória (art. 977).
- [ ] Concordância de gênero e número nas cláusulas personalizadas. ⚠ A Megga escreve *"O Administrador declara [...] de que não está **impedida**"*.

## C. Numeração e remissões

- [ ] ⚠ **Toda cláusula tem número.** A consolidação da Lawletter perdeu a numeração — e a alteração seguinte remete a "Cláusulas 13ª, 34ª, 36ª, 37ª, 55ª e 64ª", que não existem no texto consolidado. É o defeito mais grave do acervo.
- [ ] A numeração é contínua e sem saltos, do início ao fim do instrumento.
- [ ] ⚠ **Toda remissão interna aponta para dispositivo existente.** A Megga remete três vezes ao *"Capítulo XV de dissolução e liquidação de quotas"* num instrumento que não tem capítulos — o dispositivo correto era a Cláusula Nona. A remissão veio do modelo de origem e ninguém conferiu.
- [ ] As remissões são por número, nunca por descrição ("na forma do Capítulo XV", não "conforme acima").
- [ ] Um único sistema de subdivisão por cláusula: ou parágrafos, ou itens decimais — não os dois. ⚠ A Megga mistura `1.1` com `Parágrafo primeiro` na mesma cláusula.
- [ ] Uma única arquitetura no documento: ou capítulos romanos, ou cláusulas ordinais. ⚠ A Lawletter rotula dezenove blocos como `CAPÍTULO` e o último como `CLÁUSULA XX - DO FORO`.
- [ ] O ordinal da alteração continua a série da empresa e mantém o formato usado nas anteriores.

## D. Coerência interna — antinomias

- [ ] ⚠ **Cessão de quotas.** A regra geral e o procedimento não se contradizem. A Lawletter diz *"Será vedada a cessão ou transferência de quotas sociais a terceiros, seja a que título for"* e, na cláusula seguinte, disciplina como ofertá-las. A Distribuidora de Gás exige "aprovação da coletividade social" numa cláusula e admite cessão a estranho "se não houver oposição de mais de um quarto do capital" na seguinte.
- [ ] ⚠ **Administração.** Se há exigência de assinatura conjunta para atos relevantes, não pode haver outra cláusula autorizando assinatura isolada para empréstimos e alienação de imóveis. A Lawletter tem as duas.
- [ ] ⚠ **Exclusão por incapacidade.** Ou é judicial (art. 1.030), ou é automática — não as duas. A Megga afirma as duas em cláusulas consecutivas.
- [ ] **Quóruns.** O capítulo de quórum, o de administração, o de exclusão e o de dissolução dizem o mesmo número para a mesma matéria.
- [ ] ⚠ **Quórum da deliberação por documento escrito** não é um número fixo menor que o exigido para as matérias unânimes. A Lawletter fixa 75% para o documento escrito e unanimidade para cinco matérias — o documento escrito, como redigido, aprovaria o que exige unanimidade.
- [ ] **Apuração de haveres.** O critério, o prazo de carência, o número de parcelas e o índice de correção aparecem uma única vez, ou repetidos com os mesmos números.
- [ ] ⚠ **Partilha na liquidação.** O que se distribui entre os sócios é o **acervo remanescente**, não o passivo. A Megga escreve *"uma vez dissolvido, o **passivo** será distribuído entre os sócios na exata proporção de suas quotas"* — o que contradiz a limitação de responsabilidade do próprio contrato.
- [ ] **Foro e arbitragem** não coexistem. Se há cláusula compromissória, não há cláusula de eleição de foro.
- [ ] ⚠ **Foro com redação única.** A Megga usa "com exclusão expressa de qualquer outro" no corpo e "por mais privilegiado que os outros sejam" na consolidação do mesmo instrumento.

## E. Alteração × consolidação

- [ ] ⚠ **O texto consolidado reproduz literalmente o texto aprovado no corpo da alteração** — palavra por palavra, inclusive pontuação.
- [ ] ⚠ **Tempo verbal:** o corpo consuma o ato ("o capital **é elevado**"), a consolidação descreve o estado ("o capital **é** de"). Nada de "passará a ser" na consolidação. A Megga diz "passa a ser" no corpo e "passará a ser" na consolidação.
- [ ] Cada cláusula da alteração faz **uma** operação, anunciada por altera-se / inclui-se / suprime-se.
- [ ] A redação nova está transcrita por extenso e entre aspas — nunca "conforme acordado".
- [ ] Há cláusula de manutenção das demais disposições e cláusula de consolidação.
- [ ] A qualificação dos sócios aparece nas duas partes do instrumento, idêntica.
- [ ] Local, data e assinaturas aparecem **uma única vez**, ao final.
- [ ] Se houve supressão ou inserção, a renumeração foi feita e as remissões foram varridas de novo.

## F. Conteúdo mínimo e escolhas de risco

- [ ] As oito indicações do art. 997 estão presentes (ver `quoruns-e-registro.md`, seção 2).
- [ ] Declaração de desimpedimento do administrador, com o texto do art. 1.011, § 1º, **no instrumento em que ele é nomeado**.
- [ ] Objeto social descrito de forma precisa, com CNAE.
- [ ] ⚠ **Silêncio na preferência = recusa**, não anuência. A Megga estipula o contrário (*"O silêncio dos demais sócios importará em anuência com a venda das quotas"*) — quem não lê a notificação perde a sociedade para um terceiro.
- [ ] Se há exclusão extrajudicial pretendida, a cláusula do art. 1.085 está no contrato — sem ela, só resta a via judicial.
- [ ] Critério de apuração de haveres definido (sem ele, aplica-se o art. 606 do CPC, em regra o critério mais caro para quem fica).
- [ ] Parcelamento de haveres tem índice de correção e juros.
- [ ] ⚠ **Regência supletiva** enunciada corretamente: ou silêncio (normas da sociedade simples), ou cláusula expressa pela Lei 6.404/1976. A Megga escreve que, persistindo a omissão, *"usam-se as regras que, no Código Civil, regem a Sociedade Anônima"* — o Código Civil não disciplina sociedade anônima.
- [ ] Não concorrência, se houver, tem limite de tempo, de território e de objeto.
- [ ] Prazo de duração indeterminado (ou, se determinado, o cliente foi avisado de que isso afasta a retirada imotivada do art. 1.029).
- [ ] Quóruns conferidos contra o quadro societário real, e não copiados do precedente. Ver `quoruns-e-registro.md`, seção 1.

## G. Forma e entrega

- [ ] Sem "outrossim", "destarte" ou latinismo. Registro seco.
- [ ] Valores, prazos e percentuais sempre em algarismo seguido de extenso entre parênteses.
- [ ] Prazos qualificados: dias **corridos** ou **úteis**, com termo inicial expresso.
- [ ] Rubricas de capítulo em caixa alta, precedidas de DA/DO/DAS/DOS.
- [ ] Bloco de assinaturas com rótulo correto sob cada nome, e o rótulo "Administrador" batendo com o Capítulo VII.
- [ ] Bloco de visto de advogado — ou anotação da dispensa por ME/EPP.
- [ ] `.docx` no timbrado da casa (`armando-timbrado`).
- [ ] A entrega lista: **pendências** (`[......]`), **escolhas de risco** (quóruns, critério de haveres, anuência tácita, distribuição desproporcional) e **providências de registro** (prazo de 30 dias, visto, documentos a coletar).

---

## Regra de ouro

> Reaproveite a **estrutura** dos precedentes. Não reaproveite os **defeitos**.

Todo item marcado com ⚠ chegou ao acervo por cópia de um modelo anterior que ninguém releu. A minuta que sai desta skill é a oportunidade de interromper a cadeia.
