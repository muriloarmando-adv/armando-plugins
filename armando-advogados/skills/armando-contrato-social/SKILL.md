---
name: armando-contrato-social
description: Redige, revisa e confere atos societários no padrão do escritório Armando Advogados — contrato social, alteração e consolidação, acordo de sócios, ata de reunião, transformação, holding, SPE, SCP, sociedade unipessoal e distrato — com quadro societário fechado por script, extenso por algoritmo, quóruns da Lei 14.451/2022 e trava automática de 21 verificações antes do arquivamento. Use SEMPRE que pedirem para "abrir empresa", "constituir sociedade", "fazer o contrato social", "alteração contratual", "consolidar o contrato", "aumento de capital", "entrada ou saída de sócio", "cessão de quotas", "trocar o administrador", "mudar sede ou objeto", "holding familiar", "montar a SPE", "acordo de sócios", "ata de reunião de sócios", "liquidar quotas do sócio falecido", "transformar em Ltda", "distrato", "encerrar a empresa" — e para ANALISAR minuta societária de terceiro ("revisar essa alteração", "o contador mandou a minuta", "conferir antes da Junta"). Contrato entre empresas: `armando-elaborar-contrato`.
---

# Atos Societários — Padrão Armando Advogados

Cobre **todo o ciclo societário da sociedade limitada**: constituir, alterar, consolidar, acordar entre sócios, deliberar em ata, transformar, corrigir o que foi arquivado com defeito e encerrar. Cobre também a **revisão de minuta de terceiro** antes do arquivamento — que é metade do trabalho societário da casa.

Padrão extraído de instrumentos reais do Drive: Lawletter Agência Digital, Megga Distribuidora, Distribuidora de Gás Correa, V Power Energia Solar, Clínica de Gastro de Palmas, Biomassa Chaparini e a minuta em branco de acordo de sócios da casa.

Contrato entre empresas é `armando-elaborar-contrato`. Estatuto de S.A. **não** é esta skill.

---

## 1. Escolha o produto

| O usuário quer | Leia |
|---|---|
| constituir sociedade limitada | `referencias/estrutura-e-preambulo.md` + `clausulas-por-capitulo.md` |
| alterar e consolidar contrato | `referencias/alteracao-e-consolidacao.md` |
| corrigir defeito já arquivado | `alteracao-e-consolidacao.md`, seção 7 |
| acordo de sócios ou de quotistas | `referencias/acordo-de-socios.md` |
| ata de reunião ou assembleia | `referencias/atas-e-deliberacoes.md` |
| liquidar quotas de sócio falecido | `atas-e-deliberacoes.md`, seção 2 |
| holding, SPE, SCP, SLU, transformação, cisão, distrato | `referencias/especies-e-operacoes.md` |
| revisar minuta de terceiro / dar parecer | `referencias/analise-de-instrumento.md` |
| quóruns, art. 997, registro na Junta | `referencias/quoruns-e-registro.md` |
| conferir antes de entregar | `referencias/controle-de-qualidade.md` |

## 2. Apuração prévia obrigatória

Não redija sem estas respostas. Pergunte em bloco:

1. **Constituição, alteração ou ata?** Se for alteração: **qual o número da série** e **cadê o último instrumento arquivado**. Sem ele não há como conferir numeração, redação vigente, NIRE nem quóruns.
2. **Quem são os sócios**, com qualificação completa — PF: nome, nacionalidade, naturalidade, nascimento, estado civil **e regime de bens se casado**, profissão, CPF, RG com órgão expedidor, endereço com CEP. PJ: denominação, CNPJ, sede, NIRE **e o representante que assina**.
3. **Capital social**: total, valor nominal da quota, distribuição (em quotas ou percentual), e se está integralizado — se não, em quê, em quanto tempo, de que forma.
4. **Objeto social** e os CNAE. Se a atividade depende de licença, diga qual.
5. **Quem administra**, isolada ou conjuntamente, e com que **alçada** — em face do ativo que a sociedade realmente tem.
6. **Sede** e **foro**.
7. **O que o cliente quer proteger.** É a pergunta que define quóruns, preferência, critério de haveres e exclusão extrajudicial. Sociedade 50/50 e sociedade 90/10 não levam o mesmo contrato.

Nunca invente CNPJ, CPF, NIRE, RG, CEP, CNAE ou data de arquivamento. Campo não apurado entra como `[......]` e sobe para a lista de pendências.

## 3. Precedentes no Drive

```
search_files: title contains '[nome da empresa]'
search_files: title contains 'ALTERAÇÃO CONTRATUAL'
search_files: title contains 'ACORDO DE SÓCIOS'
search_files: fullText contains 'SOCIEDADE EMPRESÁRIA LIMITADA' and mimeType != 'application/vnd.google-apps.folder'
```

**Lidos e destrinchados nas referências:**

| Instrumento | ID | O que ensina |
|---|---|---|
| Lawletter — 1ª Alteração e Consolidação | `1cw0tkOCxhSBx0sPpT02Mvczc1BpAAZd3` | arquitetura de 20 capítulos; DCF na apuração de haveres; consolidação que **perdeu a numeração** |
| Megga Distribuidora — XXVIII Alteração | `1jik66mG2jcxZNhRJd5AnXPZuafvomPkb` | cláusulas ordinais com itens decimais; filiais; remissão a capítulo inexistente |
| Distribuidora de Gás Correa — XXII Alteração | `1DlPyUJ0-3-3Pu8v_mlC4NcZ53RB_qWSZ` | alteração cláusula a cláusula; **extenso errado arquivado**; grafia divergente de nome |
| V Power Energia Solar — 2ª Alteração | `19Ozbwzg6bEj44FhPFud5KNATlqTC5rWU` | **alteração corretiva**; deliberação atribuída a administradores; capital contraditório |
| Clínica de Gastro — Ata de Reunião | `12yyqrwZUPI116WE8AHvM1Y4_e_mu_fWfhghsrs-yw-c` | ata em 8 seções; liquidação de quotas de falecido pelo Manual do DREI |
| Biomassa Chaparini — Análise da 7ª Alteração | `15WqH7ywCNar-gCbDeDEfhB5sq4qio5lk` | **o formato de parecer da casa** e cinco travas materiais |
| Minuta de Acordo de Sócios (modelo em branco) | `1QTpS4qMsuL1TRWjNqVezWIrXX5jSfZ_w` | 17 cláusulas com tag, drag, opção de compra — e **foro de Recife/PE** herdado |

Outros localizados (holdings, SPE, SCP, transformação, estatutos de S.A., séries longas de alteração) estão catalogados em `referencias/especies-e-operacoes.md`.

⚠ `SPE Caracol Ltda - Contrato Social.pdf` (`1RZ3ZsbG8G_zqHSQ_ma1l16U4OLduClgG`) é **digitalizado** — devolve só a folha de rosto da Junta. Não gaste leitura. Para PDF societário, use `armando-pdf-markdown`.

**Reaproveite a estrutura. Não reaproveite os defeitos** — `controle-de-qualidade.md` lista cada um deles, com o instrumento de origem.

## 4. Estrutura do contrato social

Detalhamento em `referencias/estrutura-e-preambulo.md`; texto literal das 79 cláusulas em `referencias/clausulas-por-capitulo.md`.

```
CONTRATO SOCIAL DE CONSTITUIÇÃO DA SOCIEDADE EMPRESÁRIA LIMITADA
[DENOMINAÇÃO] LTDA
[qualificação de cada sócio] + [fórmula de vinculação]

I DENOMINAÇÃO E SEDE            XI  CONSELHO FISCAL
II OBJETO E PRAZO               XII CONTABILIDADE E RESULTADOS
III CAPITAL E QUOTAS            XIII PRÓ-LABORE
IV CESSÃO DE QUOTAS             XIV INTERDIÇÃO E EXCLUSÃO JUDICIAL
V AUMENTO E REDUÇÃO             XV  FALECIMENTO, DIVÓRCIO E HAVERES
VI DEVERES SOCIAIS              XVI EXCLUSÃO EXTRAJUDICIAL E RETIRADA
VII ADMINISTRAÇÃO               XVII DISSOLUÇÃO E LIQUIDAÇÃO
VIII DELIBERAÇÕES               XVIII CONFIDENCIALIDADE
IX CONVOCAÇÃO E VOTO            XIX REGÊNCIA SUPLETIVA E CONFLITOS
X QUÓRUM                        XX  FORO

[fecho, local e data, assinaturas, visto de advogado]
```

**Numeração.** Capítulo em romano; cláusula em **sequência contínua e única do início ao fim**, atravessando os capítulos. Um só sistema de subdivisão por documento.

A numeração contínua não é estética: toda alteração futura dirá "altera-se a Cláusula 45ª". Consolidação sem número de cláusula inutiliza o contrato para a alteração seguinte — foi o que aconteceu com a Lawletter.

Aditando instrumento que usa `CLÁUSULA PRIMEIRA` com itens decimais (padrão Megga), **mantenha a arquitetura dele**.

## 5. As duas travas

> **Onde estão os scripts.** No chat, ficam em `scripts/` dentro desta skill. No plugin instalado, a pasta é reposicionada para a raiz. Localize relativo ao diretório-base da skill: tente `<base>/scripts/` e, não achando, `<base>/../../scripts/`. Os três arquivos (`quadro-societario.ps1`, `conferir-instrumento.ps1`, `lib-extenso.ps1`) viajam juntos — o dot-source usa `$PSScriptRoot`, então funcionam em qualquer um dos dois layouts.

### 5.1 Quadro societário — nunca some à mão

```bash
powershell -NoProfile -ExecutionPolicy Bypass -File "scripts/quadro-societario.ps1" dados.json
```

```bash
powershell -NoProfile -ExecutionPolicy Bypass -File "scripts/quadro-societario.ps1" -Rapido "FULANO:55; BELTRANO:45" -Capital 66000
```

Devolve diagnóstico (quotas que não fecham, capital indivisível pelo valor nominal, percentual que não dá quota inteira, integralização parcial sem prazo, PJ sócia sem representante, unipessoalidade), a tabela pronta e a cláusula do capital **com o extenso gerado por algoritmo**. Sai com código 1 se o quadro não fecha.

Flags: `-ValorQuota`, `-UmMil`, `-Clausula`, `-Saida`, `-Json`. Entrada de exemplo em `scripts/exemplo-quadro.json`.

### 5.2 Conferência do instrumento — antes de entregar, sempre

```bash
powershell -NoProfile -ExecutionPolicy Bypass -File "scripts/conferir-instrumento.ps1" "minuta.docx"
```

21 verificações contra os defeitos que **existem no acervo** — vários já arquivados. Aceita `.docx`, `.md` e `.txt`; para PDF, converta antes com `armando-pdf-markdown`. Reconhece se é contrato social, acordo de sócios ou ata, e não cobra de um o que só o outro exige.

Pega: placeholder esquecido, art. 2.031 do CC, EIRELI, quórum de 3/4 pré-Lei 14.451, deliberação/dissolução/exclusão atribuídas a administradores, silêncio como anuência, futuro na consolidação, capital contraditório, remissão quebrada, numeração que regride, extenso que não bate, grafia divergente de nome, foro duplo ou herdado, falta de desimpedimento, partilha do passivo, regência supletiva malformada, objeto sem CNAE, integralização em bens sem o art. 1.055 § 1º, prazo impossível.

Severidades: **ERRO** (código de saída 1 — não entregue), **ALERTA** (decida conscientemente), **CONFERIR** (confirmação humana). Flags: `-SoErros`, `-Saida`, `-Json`.

**Instrumento com ERRO não sai do escritório.**

Para a varredura final de todo par `R$ X (extenso)` do documento — inclusive valores fora do quadro societário — use também `armando-advogados/scripts/extenso.ps1` no modo `-Path`.

## 6. Redação

- **Presente do indicativo com força prescritiva.** Na alteração o ato se consuma ("o capital **é elevado**"); na consolidação o estado é presente ("o capital **é** de").
- **Valores, quantidades e percentuais** sempre em algarismo seguido de extenso entre parênteses — gerados pelo script, nunca digitados.
- **Nomes em caixa alta e negrito**, com grafia idêntica em todas as ocorrências.
- **Prazo qualificado**: dias corridos ou úteis, com termo inicial expresso.
- **Remissão por número**, nunca por descrição. Uma operação por cláusula.
- Sem "outrossim", sem "destarte", sem latinismo. Contrato social é documento de registro público: registro seco.

## 7. Controle de qualidade

`referencias/controle-de-qualidade.md` — nove blocos: trava automática, aritmética, identidade das pessoas, numeração e remissões, antinomias, alteração × consolidação, conteúdo mínimo, forma, e **competência, base legal e vícios materiais**. Os itens marcados com ⚠ são defeitos reais do acervo.

## 8. Entrega

`.docx` em papel timbrado — acione `armando-timbrado`. Parecer de análise segue o formato de `referencias/analise-de-instrumento.md`.

Ao entregar, liste sempre:

1. **Pendências** — todo `[......]` em aberto e os documentos a coletar.
2. **Escolhas de risco** — quóruns e a quem protegem; critério de apuração de haveres; anuência tácita ou expressa; distribuição desproporcional; regência supletiva; alçada da administração em face do ativo.
3. **Providências de registro** — prazo de 30 dias para protocolo, visto de advogado (ou a dispensa por ME/EPP), viabilidade e licenças, e o que fazer depois do deferimento.
4. **Saída do `conferir-instrumento.ps1`** — se restou ALERTA ou CONFERIR, diga qual e por que foi mantido.
