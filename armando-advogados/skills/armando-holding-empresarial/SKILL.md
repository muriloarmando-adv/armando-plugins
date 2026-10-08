---
name: armando-holding-empresarial
description: Redige, no padrão do NPPS do escritório Armando Advogados, o contrato social de holding empresarial (limitada, CNAE 6462-0/00) com capital integralizado por quotas que os sócios têm em outras sociedades, e gera junto a alteração contratual de cada sociedade investida que transfere as quotas para a holding (1º e 2º Atos do item 4.3.5 do Manual DREI). Lê antes os contratos das investidas, monta a ficha de cada uma, fecha a aritmética por script, trava erros (quota a mais do que o sócio tem, capital não integralizado, art. 977) e confere a minuta final. Use SEMPRE que pedirem "holding empresarial", "holding de participações", "constituir a holding com as quotas das empresas", "integralizar capital com quotas", "passar as empresas para a holding", "alteração das empresas investidas", "contrato da holding do NPPS", ou entregarem contratos sociais de empresas para montar holding. Holding com imóveis (patrimonial) não é esta skill; ato societário comum, `armando-contrato-social`.
---

# Holding empresarial — contrato social e alterações das investidas (NPPS)

Produto do **Núcleo de Planejamento Patrimonial e Sucessório (NPPS)**. É o item 3 da lista de skills pedida pela coordenadora, Dra. Náira Wolney: "contrato modelo com integralização do capital por meio de quotas de outras sociedades [...] a skill deve gerar também as minutas de alteração contratual de cada sociedade investida, formalizando a transferência das quotas para a holding".

**Base:** o modelo da Dra. Náira, `Contrato holding empresarial.docx` (Drive `174LuBg7KX_pVgPs0DOyEhaH3v8cTR_Wv`), reproduzido em `assets/modelo-contrato-holding.md`. A skill segue **esse** modelo. Não segue a estrutura da `armando-contrato-social`, que é outra redação.

**Não é fusão.** As investidas continuam existindo, com o mesmo CNPJ e o mesmo patrimônio. Muda só quem é o titular das quotas. O nome da operação é *integralização de capital com quotas de outra sociedade* (Manual DREI, item 4.3.5). Se o pedido chegar como "fusão das empresas", trate-o como esta operação e explique a diferença na entrega.

**Fora do escopo:**
- holding com **imóveis** (patrimonial): é o item 4 do NPPS e exige a descrição da matrícula a partir da CIT;
- estatuto de S.A.;
- acordo de sócios: é o item 6 do NPPS, ainda sem skill própria.

---

## 1. Fluxo

```
apurar documentos ─► ler cada investida (ficha) ─► dados.json ─► gerar_holding.py
        ─► resolver ERROs ─► revisar texto ─► .docx no timbrado ─► conferir_minuta.py ─► entrega
```

### 1.1 Apurar — peça em bloco, de uma vez

Lista completa em `referencias/leitura-das-investidas.md`, §1. O essencial:

- qualificação completa e **regime de bens** de cada sócio, e a **DIRPF** (custo das quotas);
- de cada investida: **último contrato consolidado arquivado e as alterações posteriores**, certidão simplificada recente, último balanço, e se é Simples/ME/EPP;
- dados da holding: nome, sede, quem administra, foro, se haverá acordo de sócios.

**Nunca invente** CNPJ, NIRE, CPF, número de alteração ou de cláusula. Campo sem fonte fica vazio no `.json` e sobe como pendência.

### 1.2 Ler as investidas: o "apanhado das empresas"

É o que mais se pula, e o que mais derruba o registro. Para cada investida, preencha a **ficha** de `referencias/leitura-das-investidas.md`, §2, a partir do **instrumento arquivado**, não do que o cliente diz. Atenção às dez armadilhas do §3: capital não integralizado, quadro divergente, cessão restrita, administrador que sai, sócia única, Simples, gravames, outra UF, valor acima do custo e cônjuge.

PDF de contrato: converta antes com `armando-pdf-markdown`.

### 1.3 Gerar

> **Onde estão os scripts.** Em `scripts/` desta skill; no plugin instalado, também em `armando-advogados/scripts/`. Localize pelo diretório-base da skill: tente `<base>/scripts/` e depois `<base>/../../scripts/`. São Python 3 puro, sem dependência. No Windows use `python`; no chat, `python3`. Não há PowerShell no chat.

```bash
python3 scripts/gerar_holding.py dados.json --saida minutas/
```

Exemplo completo de `dados.json`, com os números do modelo: `scripts/exemplo-holding.json`.

Saída:
- `00-diagnostico.md`: ERRO, ALERTA, CONFERIR, PENDÊNCIAS, e o quadro de cada investida antes e depois;
- `01-contrato-<holding>.md`: contrato social da holding (2º Ato);
- `02-alteracao-<investida>.md`: uma por investida (1º Ato).

**Com ERRO, o script não grava as minutas** e sai com código 1. Corrija o `.json`, nunca o texto gerado. `--forcar` existe só para inspecionar.

O que o gerador garante por construção:
- numeração contínua de cláusulas e capítulos;
- remissões resolvidas por chave;
- extenso por algoritmo, com quotas no feminino ("cinquenta e **uma** mil quotas");
- a mesma quantidade e o mesmo valor de cada participação nos dois lados da operação.

### 1.4 Revisar e montar o `.docx`

1. Leia o diagnóstico inteiro. **ALERTA** é decisão consciente, e cada um vai para a entrega. **CONFERIR** pede confirmação humana.
2. Para ajustar redação, corrija o `.json` e gere de novo, ou edite o `.md`. Mudança de **número** (quotas, valor) só pelo `.json`.
3. Gere o `.docx` no papel timbrado com `armando-timbrado`.

### 1.5 Conferir a minuta final — sempre, sobre o `.docx`

```bash
python3 scripts/conferir_minuta.py minuta-holding.docx alteracao-*.docx --dados dados.json
```

`--protocolo` na versão que vai à Junta: campo em aberto passa a ser ERRO.

A conferência pega:
- cláusula ou capítulo que pula ou repete, e "CLÁUSULA XX" usada como capítulo;
- remissão inexistente;
- extenso errado, e quotas no masculino;
- CNAE "6462-00/00";
- deliberação por escrito da maioria;
- "incorporação de quotas" e "fusão de empresas";
- tabela cujo TOTAL não fecha;
- ausência do art. 1.055, § 1º, do 1º Ato e do visto de advogado;
- quotas e CNPJ divergentes do `.json`.

**Minuta com ERRO não sai do escritório.**

---

## 2. Rota de registro: decida antes de gerar

| `"rota"` | O que faz | Quando |
|---|---|---|
| `conjunta` (padrão) | 1º e 2º Atos protocolados juntos; as investidas mencionam a holding "em constituição" | todas na mesma UF, que é o caso típico na JUCETINS |
| `posterior` | redação literal do modelo: os sócios apresentam as alterações das "empresas compartilhadoras" em 30 dias | Junta que não vincula processos, ou investida em outra UF |

Terceira via, em dois tempos (holding com dinheiro e depois aumento de capital com quotas), no precedente Fourmaq: ver `referencias/registro-e-tributos.md`, §1.

---

## 3. Redação

- O texto da casa está em `assets/`. **Para mudar a redação, edite o modelo, não o script.** Use `{ref:chave}` e `{cap:chave}` e nunca digite número de cláusula.
- Cada desvio do modelo da Dra. Náira está em `referencias/notas-ao-modelo.md`, com o motivo. Os itens **[DECISÃO]** aguardam a palavra dela.
- Valores e quantidades sempre com algarismo e extenso, gerados pelo script.
- Nomes em caixa alta e negrito, com grafia idêntica à da Junta.

---

## 4. Entrega — sempre com estes quatro blocos

1. **Pendências:** todo campo em aberto e os documentos a colher.
2. **Escolhas de risco:**
   - valor de conferência × custo na DIRPF (ganho de capital) × patrimônio líquido (art. 1.055, § 1º);
   - quórum e impasse (50/50);
   - quem administra cada investida depois;
   - investidas que viram sócia única;
   - perda do Simples.
3. **Roteiro de registro:** rota escolhida, protocolo em 30 dias, visto de advogado, DBE/QSA, desenquadramento e DIRPF. Ver `referencias/registro-e-tributos.md`, §2.
4. **Saída do `conferir_minuta.py`:** se restou ALERTA, diga qual e por que ficou.

Junte a **ficha de cada investida** como anexo de trabalho. É o "apanhado das empresas" que o NPPS pediu.

---

## 5. Referências

| Arquivo | Conteúdo |
|---|---|
| `referencias/leitura-das-investidas.md` | documentos, ficha por investida, as dez armadilhas, ficha → `.json` |
| `referencias/alteracao-da-investida.md` | exigências do DREI 4.3.5, anatomia, variantes, consolidação, assinaturas |
| `referencias/registro-e-tributos.md` | rotas, roteiro pós-assinatura, valor de conferência, Simples, dividendos (Lei 15.270/2025), CADE, quóruns |
| `referencias/notas-ao-modelo.md` | os 21 desvios do modelo de origem e os 8 pontos para leitura crítica; precedentes Fourmaq |
| `assets/modelo-contrato-holding.md` | texto do contrato da holding (modelo da Dra. Náira) |
| `assets/modelo-alteracao-investida.md` | texto da alteração da investida |
