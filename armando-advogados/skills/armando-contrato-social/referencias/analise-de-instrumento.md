# Análise de instrumento societário de terceiro

Metade do trabalho societário do escritório não é redigir: é **revisar antes do arquivamento** a minuta que veio do contador, do advogado da outra parte ou de um modelo de internet. O produto dessa revisão é um parecer curto e dispositivo.

Modelo de referência: **Análise da 7ª Alteração Contratual — Biomassa Chaparini Comércio Exploração e Transporte de Madeira Ltda** (Drive `15WqH7ywCNar-gCbDeDEfhB5sq4qio5lk`), assinada por Henrique Rocha Armando, Sandro Henrique Armando e Quintiliana Janis Cardoso Marques, em 13/07/2026. É o formato da casa — siga-o.

## 1. Formato

```
ANÁLISE DA [Nª] ALTERAÇÃO CONTRATUAL — SOCIEDADE LIMITADA
[DENOMINAÇÃO COMPLETA]
CNPJ Nº [.....]

[parágrafo de objeto]

1. [TÍTULO DO PONTO, EM CAIXA ALTA]
   [o que o instrumento diz, com a cláusula identificada]
   [por que é problema, com o fundamento]
   Recomendação: [o que fazer, em uma frase]

2. [...]

SÍNTESE DAS ALTERAÇÕES RECOMENDADAS
• [...]
• [...]

[Cidade]/[UF], [DD] de [mês] de [AAAA].

[NOMES]
OAB/[UF] [.....]
```

**Parágrafo de objeto** — reproduza a fórmula:

> O presente parecer tem por objeto a análise técnica do instrumento de [Nª] Alteração Contratual da sociedade **[DENOMINAÇÃO]**, apresentado para revisão, com indicação dos pontos de atenção identificados, seus respectivos fundamentos e as alterações recomendadas antes do arquivamento perante a Junta Comercial do Estado de [.....].

**Regras do formato:**

- **Título em caixa alta por ponto**, numerado. O título nomeia o defeito, não o remédio: "INCONSISTÊNCIA NO NOME FANTASIA", não "corrigir o nome fantasia".
- **Três movimentos por ponto**: o que o instrumento diz (com a cláusula identificada) → por que é problema (com o fundamento legal ou registral) → **Recomendação:** em uma frase.
- **Síntese em bullets ao final.** É a página que o cliente lê. Cada bullet é acionável e independente.
- **Sem preliminares, sem histórico, sem "cumpre-nos informar".** O parecer da Biomassa tem cinco pontos e três páginas.
- **Reconheça a decisão do cliente.** A síntese da Biomassa diz: *"Corrigir o nome fantasia para refletir 'Cavaco' (ou manter 'Madeira' apenas se for decisão consciente do cliente)"*. Nem todo apontamento é ordem.

## 2. Os cinco pontos do parecer Biomassa — e por que cada um se repete

Este é o roteiro material da análise. Rode-o sempre; foi calibrado num caso real.

### 2.1 Coerência entre o que muda e o que fica

A Cláusula I alterava a razão social de "…Transporte de Madeira" para "…Transporte de **Cavaco**", e a Cláusula Primeira do texto consolidado mantinha o nome fantasia "…TRANSP. DE **MADEIRA**".

> *"Trata-se de contradição interna no mesmo instrumento, sugerindo reaproveitamento de minuta anterior sem revisão completa."*

**Regra geral:** toda alteração produz efeito em cascata. Mudou a denominação? Confira nome fantasia, cabeçalho, preâmbulo, assinaturas e o objeto. Mudou o capital? Confira a tabela, o extenso e toda remissão a valor.

### 2.2 Base legal da consolidação

O preâmbulo invocava o **art. 2.031 do Código Civil**.

> *"Esse dispositivo trata do prazo de adaptação das sociedades constituídas antes da vigência do CC/2002 às suas regras — prazo já exaurido há duas décadas e, de todo modo, inaplicável a sociedade registrada em 2016. É erro recorrente em minutas copiadas de modelos antigos. A consolidação é válida e praxe comum nas Juntas Comerciais, mas não depende desse fundamento."*

`scripts/conferir-instrumento.ps1` acusa esse artigo automaticamente. É o achado que mais aparece em minuta de contador.

### 2.3 Objeto social e CNAE em face da atividade real

O nome mudava para "Cavaco", mas o objeto mantinha só CNAE de serraria, extração e transporte de madeira — enquanto **o bem de maior valor integralizado era um Picador Florestal de R$ 550.000,00**, equipamento de produção de cavaco.

> *"Sem CNAE compatível, há risco de questionamento fiscal quanto ao enquadramento da atividade e dificuldade de emissão de nota fiscal para essa operação específica."*

**Método:** leia a lista de bens integralizados e a denominação como **prova da atividade real**, e cobre o objeto social delas. O ativo denuncia o negócio antes de o cliente contar.

### 2.4 Integralização em bens

R$ 1.520.000,00 integralizados com veículos e maquinário, sem laudo anexo e sem a cláusula do art. 1.055, § 1º.

> *"Embora essa responsabilidade exista por força de lei independentemente de previsão contratual, é boa prática incluí-la expressamente, sobretudo havendo bens de anos variados (alguns de 1995 e 2006) cujo valor de mercado pode ser questionado."*

Redação sugerida em `clausulas-por-capitulo.md`, Capítulo III.

### 2.5 Alçada da administração em face do ativo real

A cláusula de administração permitia assinatura isolada, ressalvando só **bens imóveis** — e a sociedade tinha frota e um picador de R$ 550 mil.

> *"Como Eleandro detém 99,9% das quotas, isso já lhe confere controle de fato — mas a ausência de trava para bens móveis de alto valor deixa a sociedade exposta a decisões unilaterais que podem comprometer a operação."*

**Método:** compare a alçada da administração com o balanço. Trava desenhada só para imóvel é padrão herdado de contrato de outro setor.

## 3. Roteiro completo de análise

Fluxo em quatro passos:

**Passo 1 — Contexto.** Peça o **último instrumento arquivado** e o cartão CNPJ. Sem eles não há como conferir a série da alteração, a redação vigente, o NIRE, o quadro societário anterior nem os CNAE registrados.

**Passo 2 — Conferência mecânica.**

```bash
powershell -NoProfile -ExecutionPolicy Bypass -File "scripts/conferir-instrumento.ps1" "minuta.docx"
```

Para PDF, converta antes com `armando-pdf-markdown`. E, quando houver mudança de capital:

```bash
powershell -NoProfile -ExecutionPolicy Bypass -File "scripts/quadro-societario.ps1" -Rapido "SOCIO A:60; SOCIO B:40" -Capital 250000
```

**Passo 3 — Leitura material.** Os cinco pontos da seção 2, mais o crivo de `controle-de-qualidade.md`.

**Passo 4 — Redação do parecer.** Formato da seção 1. Ordene por gravidade: o que impede o arquivamento vem antes do que apenas expõe o cliente.

## 4. Classificação dos apontamentos

Diga sempre em que categoria cada ponto cai — é o que permite ao cliente decidir.

| Categoria | Efeito | Exemplo |
|---|---|---|
| **Impede o arquivamento** | a Junta faz exigência e devolve | falta a declaração de desimpedimento; grafia divergente do nome; quadro societário que não fecha |
| **Nulidade material** | arquiva, mas a cláusula não vale | deliberações sociais atribuídas a administradores; exclusão de sócio por administrador |
| **Risco fiscal ou operacional** | arquiva e vale, mas cobra depois | CNAE incompatível; distribuição desproporcional sem propósito negocial |
| **Exposição do cliente** | vale, mas é ruim para quem representamos | alçada sem trava para bem móvel de alto valor; silêncio como anuência |
| **Defeito formal** | não invalida, mas denuncia descuido | remissão quebrada; numeração que regride; tempo verbal |

## 5. Quando a análise vira uma alteração corretiva

Se o instrumento **já foi arquivado** com o defeito, a correção não é errata: é nova alteração contratual. O acervo tem o modelo pronto — a **2ª Alteração da V Power Energia Solar** existe apenas para retificar a qualificação de uma sócia (JUCEP grafada como JUCETINS) e corrigir cinco remissões internas erradas da consolidação anterior. Redação em `alteracao-e-consolidacao.md`, seção 7.

O custo de não conferir antes é exatamente esse: outro instrumento, outra taxa, outro prazo, outra assinatura de todos os sócios.

E a lição adicional daquele caso: **a 2ª Alteração corrigiu as remissões e manteve intacta a nulidade material** — o dispositivo corrigido continuou atribuindo as deliberações sociais aos administradores não sócios. Corrigir a remissão sem reler o que o dispositivo diz é consertar a moldura e deixar o quadro torto.
