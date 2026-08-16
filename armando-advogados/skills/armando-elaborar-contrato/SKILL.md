---
name: armando-elaborar-contrato
description: Redige contratos e minutas no padrão do escritório Armando Advogados — preâmbulo com qualificação completa, cláusulas numeradas em "CLÁUSULA 1ª - DO OBJETO" com itens decimais, bloco de disposições gerais da casa (anticorrupção, trabalho análogo a escravo, LGPD, integralidade, tolerância, independência das cláusulas, assinatura eletrônica), foro com renúncia, fecho e anexos. Use SEMPRE que o usuário pedir para "elaborar contrato", "redigir contrato", "fazer uma minuta", "montar o instrumento", "escrever o aditivo", "contrato de locação/arrendamento/prestação de serviços/fornecimento/compra e venda", "termo de confissão de dívida", "distrato" — mesmo que não diga "minuta" ou "padrão do escritório". Para ANALISAR contrato de terceiro, use `armando-analise-contrato`.
---

# Elaboração de Contrato — Padrão Armando Advogados

Padrão extraído dos instrumentos do Drive do escritório: Contrato de Construção por Administração (Armando Advogados × Lemes & Bringel), Fornecimento de Mão de Obra (Souza e Borges × Agroboi Serviços), Locação de Veículos (Pereira & Magalhães × Trans Agroboi) e Arrendamento Rural (Sítio Dois Irmãos).

## 1. Apuração prévia obrigatória

Não redija sem estas respostas. Pergunte em bloco:

1. **Espécie contratual** e **qual parte representamos** — o instrumento se redige *para alguém*. A alocação de risco muda inteiramente.
2. **Qualificação completa das partes**: razão social ou nome, CNPJ/CPF, endereço com CEP, e — se PJ — o representante legal com nacionalidade, estado civil, profissão e CPF. Se for PJ do escritório ou de cliente recorrente, procure no Drive antes de perguntar.
3. **Núcleo econômico**: objeto, valor, forma e data de pagamento, prazo/vigência, dados bancários do credor.
4. **Foro** pretendido.
5. **Se há documento-base** — proposta comercial, contrato anterior, minuta da outra parte, anexo técnico. Se houver, leia antes.

Nunca invente CNPJ, CPF, endereço, conta bancária, número de matrícula, INCRA ou placa. Campo não apurado entra como `[......]` sublinhado, e a pendência vai listada ao final da entrega.

## 2. Buscar precedente no Drive antes de redigir

O escritório já redigiu instrumento da mesma espécie em quase todos os casos. Antes de escrever do zero:

```
search_files: title contains '[espécie]'
search_files: fullText contains '[espécie]' and mimeType != 'application/vnd.google-apps.folder'
```

Pastas de referência conhecidas:

**Hub de contratos padrão** — `17eYncRB1k_Plv7IzSmupmspcof5xI5H1`. É a primeira parada:

| Pasta | ID |
|---|---|
| **00 - CONTRATOS PADRÕES** (modelos da casa) | `1KZs07I62r90mqYsm9T10vMtKYjOvMnVt` |
| 01 - Prestação de Serviços | `1wXG60O9jP9FH-dvQqoxPxy8ErW2BpJfV` |
| 02 - Locação de Bens | `1ISnRbpxO7FCQ5YDEFQGBhJYx7U35UqwD` |
| 03 - Compra e Venda | `1s2alootvqKTCRPKcCBvbPUYCXWYPcJac` |
| 04 - Arrendamento | `1tMAJJ3RXhu7yRGJU_VqhgdEi4FPc_Mjy` |
| 05 - Comodato | `1yuSA0I-qSZeecPKCoM_djwpKyiBz1F9p` |
| 06 - Termos | `1nRsS927v9qsFSIMfMHid6jg42SeSb1R1` |

Modelos nomeados em `00 - CONTRATOS PADRÕES`:

| Modelo | ID |
|---|---|
| Locação de Bem Imóvel – Padrão Blaster | `1ifytCDIViHrSfmfegOmYsjBj44LQteyM` |
| Locação de Bem Móvel – Padrão Blaster | `1OuDkum1Rgqi8e9LqjElAhtcnGl5lWpTN` |
| Prestação de Serviços – Padrão Blaster | `14bfIX76kCppI1iwA89YRKZKCVWmUkBfT` |
| Termo de Entrega de Chaves – Blaster | `1SLcFA7pUxuSEKjWxZ9fv8QIPWRq0Vw6A` |

Outras pastas por espécie:

| Pasta | ID |
|---|---|
| Contratos (raiz alternativa) | `17sblxhqoE7zlD9AMxVgcPpQsDg04G1vB` |
| Contratos de Arrendamento | `14iW-kFwtslczekUJ4BqhYu3q-7u5diwt` |
| Prestações de Serviços – Agroboi | `1Qw936pcmTXEyiK_WwQfWowEVxyXq2svN` |
| Fornecimento de Mão de Obra | `1xdkHCMwk4ltkHMuRN3YGkMswYU9R4RcG` |
| Locação de Depósitos | `1Z4wsNNkHEpY07aocVqx9znFUe01-jQV9` |
| Transporte | `10zAEOCIujx_pQhW1TcA8txFO2d1V1bZv` |
| Termo de Confissão de Dívida | `1uipuxVr9T6054Nkmvfo_I6_CZFsbBMwJ` |
| Termo de Quitação | `1ZoqyRNHjoWS-bgrMIzE28pu9Xllb_VvN` |
| Compra de Área | `17jb_xMATmn0FYtMGdOKgnSdlUegS1j4r` |

Reaproveite a estrutura e as cláusulas específicas do precedente. **Não reaproveite os defeitos** — confira contra `referencias/controle-de-qualidade.md` antes de entregar.

## 3. Estrutura

Detalhamento e texto literal em `referencias/estrutura-e-preambulo.md`.

```
CONTRATO DE [ESPÉCIE]

[qualificação das partes, com rubrica de rótulo]

[fórmula de vinculação]

CLÁUSULA 1ª - DO OBJETO
CLÁUSULA 2ª - DA VIGÊNCIA
CLÁUSULA 3ª - DO VALOR E PAGAMENTO
CLÁUSULA 4ª - DAS OBRIGAÇÕES DA [PARTE A]
CLÁUSULA 5ª - DAS OBRIGAÇÕES DA [PARTE B]
CLÁUSULA 6ª - [específicas da espécie]
CLÁUSULA 7ª - DA RESPONSABILIDADE
CLÁUSULA 8ª - DA RESCISÃO
CLÁUSULA 9ª - DAS DISPOSIÇÕES GERAIS
CLÁUSULA 10 - DO FORO

[fecho, local e data, assinaturas, testemunhas]
[ANEXO 1 - ...]
```

**Numeração.** `CLÁUSULA 1ª`, `2ª`, `3ª`… com ordinal sobrescrito até a 9ª; da 10ª em diante, cardinal (`CLÁUSULA 10`). Rubrica em caixa alta precedida de `DO`/`DA`/`DAS`/`DOS`, separada por travessão. Itens em decimal — `1.1`, `1.2`, `1.2.1`. Alíneas em `a)`, `b)`, `c)` quando a enumeração for de obrigações dentro de um mesmo item.

Só use a variante `CLÁUSULA PRIMEIRA` (por extenso) se estiver aditando instrumento que já a adote — não misture as duas no mesmo documento.

**Ordem das obrigações.** Primeiro as da parte que presta, depois as da que paga. Uma cláusula para cada; nunca as duas no mesmo dispositivo.

## 4. Blocos padrão

`referencias/blocos-padrao.md` traz, com o texto literal do escritório: disposições gerais (nove itens), foro, elisão de solidariedade trabalhista, fecho, blocos de assinatura, testemunhas e anexos. **Copie de lá** — são cláusulas já rodadas, não as reescreva por conta própria.

O bloco de disposições gerais completo é o do Arrendamento Rural. Os contratos mais antigos e enxutos do escritório omitem anticorrupção, LGPD e integralidade; **inclua sempre**, salvo instrução em contrário.

## 5. Cláusulas por espécie

`referencias/clausulas-por-especie.md` — inventário do que não pode faltar em cada espécie: locação de bem móvel, arrendamento rural, prestação de serviços, fornecimento de mão de obra, fornecimento continuado, compra e venda, confissão de dívida, aditivo e distrato.

**`referencias/locacao-imovel.md`** — módulo próprio para locação de imóvel, com o padrão Blaster, os oito defeitos do arquivo-fonte que precisam ser corrigidos a cada uso, as regras de ordem pública da Lei 8.245/91, as cláusulas ausentes com redação pronta, a variante não residencial e o Termo de Entrega de Chaves.

## 6. Redação das cláusulas

- **Presente do indicativo com força prescritiva**: "A CONTRATADA fornecerá…", "O pagamento será realizado…". Evite "deverá" em cadeia.
- **Rótulos das partes em caixa alta**, sempre, em todas as ocorrências.
- **Valores e prazos em algarismo seguido do extenso entre parênteses**: `R$ 50.000,00 (cinquenta mil reais)`, `30 (trinta) dias`, `20% (vinte por cento)`. Sem exceção.
- **Prazo sempre qualificado**: dias *corridos* ou *úteis*, e o termo inicial ("contados do recebimento da notificação"). Prazo sem qualificação é defeito.
- **Um comando por item.** Se o item tem duas obrigações independentes, são dois itens.
- **Remissão por número, nunca por descrição**: "na forma do item 5.2", não "conforme acima".
- Sem "outrossim", sem "destarte", sem latinismo em corpo de cláusula. O registro do contrato é seco; o floreio pertence ao memorando de análise.

## 7. Controle de qualidade

Antes de entregar, rode `referencias/controle-de-qualidade.md`. É a passagem do instrumento pelo mesmo crivo que a skill `armando-analise-contrato` aplicaria se ele viesse da outra parte — inclusive a varredura de antinomias internas e de remissões quebradas.

Se estivermos redigindo em favor de uma das partes, confira também o catálogo de garantias: fica na skill irmã `armando-analise-contrato`, em `referencias/catalogo-clausulas-garantia.md` — pasta vizinha a esta, dentro do mesmo diretório de skills.

## 8. Entrega

`.docx` em papel timbrado, Book Antiqua 12, espaçamento 1,5, justificado, recuo de primeira linha de 1,5 cm — acione `armando-timbrado` (versão com espaçamento de 8 pt entre parágrafos) ou `docx`.

Ao entregar, liste sempre:
1. **Pendências** — todo campo `[......]` que ficou em aberto.
2. **Escolhas de risco** — onde a redação favorece nossa parte e onde se pode esperar resistência.
3. **O que foi deliberadamente omitido**, se algo foi.
