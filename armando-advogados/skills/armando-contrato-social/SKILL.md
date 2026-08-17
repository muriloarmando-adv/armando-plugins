---
name: armando-contrato-social
description: Redige contrato social, alteração contratual e consolidação de sociedade limitada no padrão do escritório Armando Advogados — preâmbulo com qualificação apta a arquivamento, capítulos romanos com numeração contínua de cláusulas, quadro societário fechado por script, quóruns conferidos contra a Lei 14.451/2022, apuração de haveres, exclusão extrajudicial, regência supletiva e foro. Use SEMPRE que o usuário pedir para "abrir empresa", "constituir sociedade", "fazer o contrato social", "alteração contratual", "consolidar o contrato", "aumento de capital", "entrada/saída de sócio", "cessão de quotas", "mudar o administrador", "mudança de sede ou de objeto social", "holding familiar", "sociedade unipessoal", "distrato social" — mesmo que não diga "contrato social" ou "Junta Comercial". Para contrato entre empresas (locação, prestação de serviços, compra e venda), use `armando-elaborar-contrato`; para analisar contrato de terceiro, `armando-analise-contrato`.
---

# Contrato Social — Padrão Armando Advogados

Padrão extraído dos instrumentos societários do Drive do escritório: **Lawletter Agência Digital Ltda** (1ª Alteração e Consolidação — a arquitetura mais moderna da casa), **Megga Distribuidora Ltda** (XXVIII Alteração e Consolidação), **Distribuidora de Gás Correa Ltda** (XXII Alteração e Consolidação).

Esta skill cobre **atos societários da limitada**: constituição, alteração, consolidação e distrato. Contrato entre empresas é `armando-elaborar-contrato`.

## 1. Apuração prévia obrigatória

Não redija sem estas respostas. Pergunte em bloco:

1. **É constituição ou alteração?** Se for alteração: **qual é o número da série** (a XXVIII vem depois da XXVII) e **cadê o último instrumento arquivado**. Sem ele não há como conferir numeração, redação vigente nem quóruns.
2. **Quem são os sócios**, com qualificação completa — PF: nome, nacionalidade, naturalidade, data de nascimento, estado civil **e regime de bens se casado**, profissão, CPF, RG com órgão expedidor, endereço com CEP. PJ: denominação, CNPJ, sede, NIRE **e o representante que assina**.
3. **Capital social**: valor total, valor nominal da quota, distribuição entre os sócios (em quotas ou em percentual), e se está totalmente integralizado — se não, em quê, em quanto tempo e de que forma.
4. **Objeto social** e os CNAE correspondentes. Se a atividade depende de licença, diga qual.
5. **Quem administra**, isolada ou conjuntamente, e com que limites de alçada.
6. **Sede** (endereço completo) e **foro**.
7. **O que o cliente quer proteger** — é a pergunta que define os quóruns, a cláusula de preferência, o critério de apuração de haveres e a exclusão extrajudicial. Sociedade 50/50 e sociedade 90/10 não levam o mesmo contrato.

Nunca invente CNPJ, CPF, NIRE, RG, CEP, CNAE ou data de arquivamento. Campo não apurado entra como `[......]` e sobe para a lista de pendências da entrega.

## 2. Buscar o precedente no Drive antes de redigir

```
search_files: title contains '[nome da empresa]'
search_files: title contains 'ALTERAÇÃO CONTRATUAL'
search_files: fullText contains 'SOCIEDADE EMPRESÁRIA LIMITADA' and mimeType != 'application/vnd.google-apps.folder'
```

Instrumentos de referência já localizados:

| Instrumento | ID | Situação |
|---|---|---|
| **Lawletter — 1ª Alteração e Consolidação** (`.docx`) | `1cw0tkOCxhSBx0sPpT02Mvczc1BpAAZd3` | lido — arquitetura de capítulos, DCF na apuração de haveres, confidencialidade |
| Lawletter — 2ª Alteração (`.docx`) | `1yhI1ciPS8t5m-ZHSRgHiZbHAv6FyHcU0` | localizado |
| **Megga Distribuidora — XXVIII Alteração e Consolidação** (`.docx`) | `1jik66mG2jcxZNhRJd5AnXPZuafvomPkb` | lido — cláusulas ordinais com itens decimais, filiais, capital destacado |
| **Distribuidora de Gás Correa — XXII Alteração** (`.docx`) | `1DlPyUJ0-3-3Pu8v_mlC4NcZ53RB_qWSZ` | lido — alteração cláusula a cláusula, modelo enxuto de Junta |
| Chaparini — 7ª Alteração e Consolidação (`.docx`) | `16BEgXxR54rN9YilJs8YnZ8r_hH4_ACPD` | localizado (marcado "não implementada") |
| Fourmaq Participações — 2ª Alteração (`.pdf`) | `1NTzHjlcXHXPgJmjd9ZFMSzCvDKSRHl-r` | localizado |
| Pasta "contrato social" | `15ndnjzRMg5Y4dbruBspvZ-NSNDSfRn20` | pasta |
| Estatuto Social — Maximus Participações S.A. (`.pdf`) | `18LMTm2oGB0hBzom5as-ii1TkH8cuFj3K` | localizado — **S.A., não limitada**; serve de contraste, não de modelo |

`SPE Caracol Ltda - Contrato Social.pdf` (`1RZ3ZsbG8G_zqHSQ_ma1l16U4OLduClgG`) é **digitalizado** — só devolve a folha de rosto da Junta. Não gaste leitura nele.

Para ler PDF societário, use `armando-pdf-markdown`.

**Reaproveite a estrutura do precedente. Não reaproveite os defeitos** — o `referencias/controle-de-qualidade.md` lista, um a um, os que estão nesses arquivos.

## 3. Estrutura

Detalhamento e texto literal em `referencias/estrutura-e-preambulo.md`.

```
CONTRATO SOCIAL DE CONSTITUIÇÃO DA SOCIEDADE EMPRESÁRIA LIMITADA
[DENOMINAÇÃO] LTDA

[qualificação de cada sócio, em parágrafo próprio]
[fórmula de vinculação]

CAPÍTULO I    — DA DENOMINAÇÃO E DO ENDEREÇO DA SEDE
CAPÍTULO II   — DO OBJETO SOCIAL E DO PRAZO DE DURAÇÃO
CAPÍTULO III  — DO CAPITAL SOCIAL E DAS QUOTAS
CAPÍTULO IV   — DA CESSÃO DE QUOTAS
CAPÍTULO V    — DO AUMENTO E DA REDUÇÃO DO CAPITAL SOCIAL
CAPÍTULO VI   — DOS DEVERES SOCIAIS
CAPÍTULO VII  — DA ADMINISTRAÇÃO
CAPÍTULO VIII — DAS DELIBERAÇÕES SOCIAIS
CAPÍTULO IX   — DA CONVOCAÇÃO E DO VOTO
CAPÍTULO X    — DO QUÓRUM DE DELIBERAÇÃO
CAPÍTULO XI   — DO CONSELHO FISCAL
CAPÍTULO XII  — DA CONTABILIDADE E DOS RESULTADOS DO EXERCÍCIO
CAPÍTULO XIII — DO PRÓ-LABORE
CAPÍTULO XIV  — DA INTERDIÇÃO DE SÓCIO E DA EXCLUSÃO JUDICIAL
CAPÍTULO XV   — DO FALECIMENTO OU DIVÓRCIO E DA APURAÇÃO DE HAVERES
CAPÍTULO XVI  — DA EXCLUSÃO EXTRAJUDICIAL E DA RETIRADA DE SÓCIO
CAPÍTULO XVII — DA DISSOLUÇÃO E DA LIQUIDAÇÃO
CAPÍTULO XVIII— DA CONFIDENCIALIDADE
CAPÍTULO XIX  — DA REGÊNCIA SUPLETIVA E DA RESOLUÇÃO DE CONFLITOS
CAPÍTULO XX   — DO FORO

[fecho, local e data, assinaturas, visto de advogado]
```

**Numeração.** Capítulo em algarismo romano; cláusula em **sequência contínua e única do início ao fim do instrumento** (`CLÁUSULA 1ª` … `CLÁUSULA 79`), atravessando os capítulos. Subdivisões em `Parágrafo único` / `Parágrafo primeiro`, ou em itens decimais — **um sistema só por documento**.

A numeração contínua não é estética: toda alteração futura vai dizer "altera-se a Cláusula 45ª". Consolidação sem número de cláusula inutiliza o contrato para a alteração seguinte — e é exatamente o que aconteceu com o precedente Lawletter.

Se estiver aditando instrumento que usa a arquitetura de `CLÁUSULA PRIMEIRA` com itens decimais (padrão Megga), **mantenha a dele**. Não converta a arquitetura pelo caminho.

## 4. Texto das cláusulas

`referencias/clausulas-por-capitulo.md` traz o **modelo completo**, capítulo a capítulo, com o texto literal de cada uma das 79 cláusulas, já corrigido dos defeitos dos precedentes. **Copie de lá.** Suprima o que não se aplicar e renumere.

Cada capítulo vem com a nota do que costuma dar errado nele — silêncio na preferência, antinomia entre administração conjunta e isolada, exclusão automática por interdição, partilha do passivo na liquidação, regência supletiva mal enunciada.

## 5. Quadro societário — sempre pelo script

**Nunca some quotas à mão, nunca escreva extenso à mão.** O acervo tem instrumento arquivado com o extenso errado (`R$ 350.000,00 (quinhentos mil reais)`).

```bash
powershell -NoProfile -ExecutionPolicy Bypass -File "scripts/quadro-societario.ps1" dados.json
```

Conferência rápida, sem arquivo:

```bash
powershell -NoProfile -ExecutionPolicy Bypass -File "scripts/quadro-societario.ps1" -Rapido "FULANO:55; BELTRANO:45" -Capital 66000
```

O script devolve: **diagnóstico** (quotas que não fecham, capital indivisível pelo valor nominal, percentual que não dá número inteiro de quotas, integralização parcial sem prazo, PJ sócia sem representante, sociedade unipessoal), a **tabela pronta para colar** e a **cláusula do capital social** com todos os valores por extenso. Sai com código 1 se houver erro — o quadro não fecha, a minuta não sai.

Flags úteis: `-ValorQuota`, `-UmMil` (grafia "um mil reais", usada nos instrumentos da casa), `-Clausula`, `-Saida arquivo.md`, `-Json`. Modelo de entrada em `scripts/exemplo-quadro.json`; a documentação completa está no cabeçalho do próprio `.ps1`.

**Depois de redigida a minuta**, passe o documento inteiro pelo `scripts/extenso.ps1` do plugin (`armando-advogados/scripts/extenso.ps1`, modo `-Path`): ele varre a peça e acusa todo par `R$ X (extenso)` em que o extenso não bate com o algarismo — o erro típico de reaproveitar instrumento anterior e trocar só o número.

## 6. Alteração e consolidação

`referencias/alteracao-e-consolidacao.md` — anatomia do instrumento de duas partes, os três verbos (altera-se / inclui-se / suprime-se), redação pronta para aumento de capital, capitalização de reservas, cessão de quotas, retirada de sócio e troca de administração, e o roteiro de arquivamento.

A regra que mais se descumpre: **o texto consolidado reproduz, palavra por palavra, o texto aprovado no corpo da alteração** — inclusive o tempo verbal.

## 7. Quóruns e registro

`referencias/quoruns-e-registro.md` — tabela dos quóruns legais **depois da Lei 14.451/2022** (que rebaixou de 3/4 para mais da metade do capital a modificação do contrato e as operações societárias), as oito indicações obrigatórias do art. 997, os impedimentos (cônjuges em comunhão universal, menor sócio, sócio estrangeiro, administrador impedido), a sociedade unipessoal e o roteiro de registro na Junta.

Quórum copiado de precedente é quórum errado. Confira contra o quadro societário real: 75% em sociedade 55/25 dá veto ao segundo sócio; "mais da metade" entrega a sociedade ao primeiro.

## 8. Redação

- **Presente do indicativo com força prescritiva**: "A administração compete a…", "O capital social é de…". Na alteração, o ato se consuma: "o capital **é elevado**".
- **Valores, quantidades e percentuais** sempre em algarismo seguido de extenso entre parênteses — sem exceção, e gerados pelo script.
- **Nomes das pessoas em caixa alta e negrito**, com grafia idêntica em todas as ocorrências.
- **Prazo qualificado**: dias corridos ou úteis, com termo inicial expresso.
- **Remissão por número**, nunca por descrição.
- **Um comando por cláusula.**
- Sem "outrossim", sem "destarte", sem latinismo. Contrato social é documento de registro público: registro seco.

## 9. Controle de qualidade

Antes de entregar, rode `referencias/controle-de-qualidade.md`. Sete blocos — aritmética, identidade das pessoas, numeração e remissões, antinomias internas, coerência entre alteração e consolidação, conteúdo mínimo e forma. Os itens marcados com ⚠ são defeitos que **existem nos precedentes do escritório**; a checagem serve para não os propagar.

## 10. Entrega

`.docx` em papel timbrado — acione `armando-timbrado`.

Ao entregar, liste sempre:

1. **Pendências** — todo campo `[......]` em aberto e os documentos a coletar.
2. **Escolhas de risco** — quóruns adotados e a quem protegem; critério de apuração de haveres; anuência tácita ou expressa na preferência; distribuição desproporcional de lucros; regência supletiva escolhida.
3. **Providências de registro** — prazo de 30 dias para protocolo, visto de advogado (ou a dispensa por ME/EPP), viabilidade e licenças, e o que fazer depois do deferimento.
