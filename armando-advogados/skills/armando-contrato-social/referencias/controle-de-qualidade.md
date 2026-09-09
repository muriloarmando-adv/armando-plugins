# Controle de qualidade

Passe a minuta por este crivo **antes de entregar**. É a mesma varredura que a skill `armando-analise-contrato` aplicaria se o instrumento viesse da outra parte.

Os itens marcados com ⚠ correspondem a defeitos que **existem em instrumentos do próprio acervo do escritório** — inclusive arquivados. São os que mais se propagam, porque cada minuta nova nasce de um precedente.

---

## 0. Trava automática — rode antes de qualquer leitura

```bash
powershell -NoProfile -ExecutionPolicy Bypass -File "scripts/conferir-instrumento.ps1" "minuta.docx"
```

Aceita `.docx`, `.md` e `.txt`. Para PDF, converta antes com `armando-pdf-markdown`. Sai com código 1 se houver ERRO — **instrumento com ERRO não sai do escritório**.

O script reconhece se o documento é contrato social, acordo de sócios ou ata, e não cobra de um o que só o outro exige. Ele confere, mecanicamente:

| Regra | O que pega |
|---|---|
| `placeholder` | `[-INSERIR-]`, `[......]`, `XPTO`, `[SÓCIO 1]` esquecidos |
| `base-legal` | art. 2.031 do CC invocado como fundamento da consolidação |
| `eireli` | menção a EIRELI, tipo extinto pela Lei 14.382/2022 |
| `quorum-14451` | quórum de 3/4 herdado de modelo anterior à Lei 14.451/2022 |
| `competencia` | deliberação social, dissolução ou exclusão atribuídas a administradores |
| `anuencia-tacita` | silêncio tratado como anuência |
| `tempo-verbal` | "passará a ser" dentro da consolidação |
| `capital-contraditorio` | "totalmente integralizado" convivendo com cronograma futuro |
| `remissao` | remissão a Cláusula, Capítulo ou item que não existe no instrumento |
| `numeracao` | sequência que regride (11.8 → 10.9), item repetido, cláusula sem cabeçalho |
| `extenso` | extenso que não bate com o algarismo, em valores e em quantidades |
| `grafia-nome` | duas grafias próximas do mesmo nome (NETTO/NETO, ROMANELLI/ROMANELI) |
| `foro` | mais de um foro eleito; foro convivendo com arbitragem; foro a confirmar |
| `desimpedimento` | ausência da declaração do art. 1.011, § 1º |
| `liquidacao` | partilha do passivo em vez do acervo remanescente |
| `regencia` | "as regras que, no Código Civil, regem a Sociedade Anônima" |
| `cnae` | objeto social sem código CNAE |
| `bens` | integralização em bens sem o art. 1.055, § 1º |
| `prazo` | balanço anual com prazo de entrega em 31/12 |

**O script não substitui esta lista.** Ele pega o mecânico; o que exige juízo — antinomia entre cláusulas, quórum desenhado contra o cliente, critério de haveres, alçada em face do ativo real — continua sendo leitura humana.

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
- [ ] **Varredura final do documento inteiro** pelo `scripts/extenso.ps1` do plugin, modo `-Path`: confere todo par `R$ X (extenso)` da peça, inclusive os valores que não vieram do quadro societário (preço de cessão, alçada do administrador, parcelas de haveres).
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

## H. Competência, base legal e vícios materiais

Bloco acrescido em 08/09/2026, a partir da leitura da consolidação V Power Energia Solar e do parecer do escritório sobre a 7ª Alteração Biomassa Chaparini.

- [ ] ⚠ **Matéria de sócio não é atribuída a administrador.** A consolidação da V Power diz *"As deliberações sociais serão tomadas por todos os administradores não sócios"* e lista, em seguida, modificação do contrato, incorporação, fusão, cisão, dissolução, exclusão de sócia, aprovação de contas e distribuição de lucros. Tudo isso é privativo dos **sócios** (arts. 1.071 e 1.076) — a cláusula é nula nessa parte. O mesmo instrumento faz a sociedade ser *"dissolvida pela deliberação dos administradores"* e reconhece *"aos administradores o direito de promoverem a exclusão de sócia"*.
- [ ] ⚠ **A base legal da consolidação não é o art. 2.031 do Código Civil.** Aquele dispositivo trata do prazo de adaptação das sociedades anteriores ao CC/2002, exaurido há duas décadas. É o achado nº 2 do parecer Biomassa Chaparini, e o erro mais frequente em minuta de contador.
- [ ] ⚠ **Capital "totalmente integralizado" não convive com cronograma futuro.** A V Power fixa aportes até 31/12/2025 e 31/12/2030 na Cláusula V e abre a Cláusula VII com *"O capital social, em já estando totalmente integralizado, pode ser aumentado"*. Uma das duas é falsa.
- [ ] **O objeto social e os CNAE correspondem à atividade real.** Método do parecer Biomassa: leia a **lista de bens integralizados** e a **denominação** como prova do negócio. Se o bem de maior valor é um picador florestal e o objeto só tem CNAE de serraria, o objeto está errado, não o ativo.
- [ ] **A alçada da administração cobre o ativo que a sociedade realmente tem.** Trava só para bem imóvel, numa sociedade cujo patrimônio é frota e maquinário, não protege nada.
- [ ] **Integralização em bens traz laudo e a cláusula do art. 1.055, § 1º** (solidariedade pela exata estimação por 5 anos) — sobretudo com bens antigos, cujo valor de mercado é contestável.
- [ ] **Prazo cumprível.** A V Power obriga o administrador a entregar *"o balanço anual até 31 de dezembro de cada ano"*, sendo o exercício encerrado em 31 de dezembro.
- [ ] ⚠ **Ao corrigir uma remissão, releia o dispositivo inteiro.** A 2ª Alteração da V Power reescreveu a Cláusula 9.11 só para acertar o número do item a que ela remetia — e manteve intacta a nulidade de atribuir as deliberações sociais aos administradores. Consertar a moldura não endireita o quadro.
- [ ] **Foro conferido, não herdado.** A `Minuta - Acordo de Sócios - Completo` da casa carrega *"foro da Cidade de Recife/PE"*, num escritório de Palmas/TO.

## Regra de ouro

> Reaproveite a **estrutura** dos precedentes. Não reaproveite os **defeitos**.

Todo item marcado com ⚠ chegou ao acervo por cópia de um modelo anterior que ninguém releu. A minuta que sai desta skill é a oportunidade de interromper a cadeia.
