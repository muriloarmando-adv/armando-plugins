---
name: armando-mou
description: Redige o Memorando de Entendimentos (MOU) do planejamento empresarial, patrimonial e sucessório no padrão do NPPS do escritório Armando Advogados — preâmbulo com partes, empresas e intervenientes anuentes, considerandos, objeto, vigência, os capítulos do caso escolhidos num catálogo de módulos (holding empresarial, holding patrimonial com quadro de matrículas, doação com usufruto e reversão, vedação de cônjuges, testamento, herdeiro curatelado, partilha pós-divórcio com cronograma de pagamento), etapas, rescisão e disposições gerais. Numeração e remissões por script, e conferência que barra parte sem assinatura, cláusula pulada ou repetida, extenso errado, CPF inválido e total que não fecha. Use SEMPRE que pedirem "MOU", "memorando de entendimentos", "memorando do planejamento", "documento de intenções da holding", ou entregarem o mapeamento de um cliente do NPPS para formalizar a estrutura. Contrato social da holding: armando-holding-empresarial ou armando-holding-patrimonial.
---

# MOU do planejamento patrimonial e sucessório (NPPS)

Produto do **Núcleo de Planejamento Patrimonial e Sucessório (NPPS)**, coordenado pela **Dra. Náira Carvalho Wolney Scherer (OAB/TO 13.055)**. É o item 5 do documento *Ideias de Skills para o NPPS*, aprovado na reunião de alinhamento de 06/10/2026: "elaborado em praticamente todos os projetos. É um documento muito específico para cada caso e os MOUs não ficam iguais entre si, mas temos modelos prontos que podem servir de base para uma skill com o modelo de estrutura".

**Por isso a skill não gera o MOU de um JSON.** Ela dá:
- um **esqueleto fixo**: preâmbulo, considerandos, objeto, vigência, obrigações, rescisão, disposições gerais, fecho;
- um **catálogo de módulos** para os capítulos que mudam de caso a caso;
- um **montador**, que numera e resolve as remissões;
- um **conferidor**, que barra os defeitos que o acervo mostrou serem os mais comuns.

**Base:** os quatro MOUs da pasta `5. MOU` do NPPS (Drive `1GxYjmwA6tLLVoZfWtEjK9S2wJq2IBiRo`): Megga (2024), M21 (2025), Mulinari e Agroboi (2026). O texto fixo segue os dois mais recentes. Cada desvio está em `referencias/notas-ao-modelo.md`, e os pontos marcados **[DECISÃO]** aguardam a coordenação.

**Onde o MOU entra no projeto:**
```
mapeamento patrimonial (item 1) ─► CIT (item 2) ─► estrutura/organograma (item 10)
        ─► MOU (item 5) ─► contratos das holdings (itens 3 e 4) ─► acordo de sócios (6) ─► ITBI (7)
```
O MOU registra a estrutura **antes** dos instrumentos definitivos. Tudo o que ele diz (quem doa, quem administra, que imóveis vão para qual holding) **amarra** os passos seguintes. Número no MOU que diverge do contrato social é defeito do MOU.

**Fora do escopo:**
- contrato social das holdings: `armando-holding-empresarial` (quotas) e `armando-holding-patrimonial` (imóveis);
- acordo de sócios: item 6 do NPPS, ainda sem skill;
- MOU de M&A ou de negócio entre empresas: é outra peça. Use `armando-elaborar-contrato`.

---

## 1. Fluxo

```
ficha do caso ─► escolher módulos ─► rascunho <cliente>.mou.md ─► montar_mou.py
      ─► conferir_mou.py ─► revisar ─► .docx no timbrado ─► conferir_mou.py --final ─► entrega
```

### 1.1 Ficha do caso: pergunte em bloco, uma vez

As dez perguntas estão em `referencias/catalogo-de-modulos.md`, §1:
- quem assina, e os regimes de bens;
- a estrutura das holdings;
- o que vai para cada uma;
- a sucessão: doação, usufruto, cláusulas, **colação**, reversão;
- a administração antes e depois do usufruto;
- herdeiro vulnerável;
- cônjuges dos herdeiros;
- testamento;
- custos;
- foro, local, data e forma de assinatura.

**Leia antes o que já existe no projeto.** O quadro do mapeamento patrimonial (`armando-mapeamento-patrimonial`) e o das CIT (`armando-mapeamento-cit`) respondem metade da ficha: titulares, regimes, empresas, matrículas, cartórios, proprietários. O MOU **copia** desses quadros. Não pergunta de novo nem digita de memória.

**Nunca invente** CPF, CNPJ, NIRE, matrícula, percentual nem valor. O que faltar fica `[[ ]]` e vai para as pendências.

### 1.2 Escolher os módulos

`referencias/catalogo-de-modulos.md`, §2 (a ordem) e §3 (cada módulo: quando usar, variantes e o que decidir). Os casos típicos:

| Caso | Módulos |
|---|---|
| Casal com empresas e imóveis, doação aos filhos (Agroboi) | M01 · M02 · M10 · M03 · M04 · M05 |
| Patriarca, holdings individuais dos filhos, herdeiro curatelado (Mulinari) | M01 · M02 · M03 · M04 · M05 · M08 · M09 |
| Sócios com patrimoniais separadas e reorganização prévia (M21) | M11 · M01 · M02 · M03 (×2) · M04 · M05 · M06 · M07 |
| Partilha pós-divórcio pela via das holdings (Megga) | M12 · M13 · M14 · M15 · M16 · M01 · M03 · M17 · M18 |

### 1.3 Escrever o rascunho

Copie `assets/esqueleto.mou.md` para a pasta do cliente como `<cliente>.mou.md`. Cole os módulos de `assets/modulos.mou.md` no ponto `>>> MÓDULOS DO CASO AQUI <<<` e preencha.

**Marcadores** (descritos no cabeçalho de `scripts/montar_mou.py`):

| No rascunho | Sai como |
|---|---|
| `# CAP chave \| TÍTULO` | `**3. TÍTULO**` |
| `#. {chave} texto` / `##.` / `###.` | `**3.1.** texto` / `**3.1.1.**` / `**3.1.1.1.**` |
| `(i)` em todos os considerandos | renumerados em sequência |
| `{ref:chave}` · `{Ref:chave}` · `{cap:chave}` · `{num:chave}` | "cláusula 3.1" · "Cláusula 3.1" · "Capítulo 3" · "3.1" |
| `{rs:1500000,00}` | "R$ 1.500.000,00 (um milhão e quinhentos mil reais)" |
| `{n:60}` · `{nf:2}` · `{qt:5100000}` | "60 (sessenta)" · "2 (duas)" · quotas no feminino |
| `{pct:50}` · `{fr:1/4}` | "50% (cinquenta por cento)" · "1/4 (um quarto)" |
| `[[...]]` | passa intacto, e a conferência o acusa como campo em aberto |
| `%% ...` | some |

**Nunca digite número de cláusula nem extenso.** Os quatro modelos têm numeração quebrada, e o defeito some quando o número não é digitado.

Para mudar o texto da casa, edite `assets/`, não o script.

### 1.4 Montar e conferir

> **Onde estão os scripts.** Em `scripts/` desta skill. No plugin instalado, também em `armando-advogados/scripts/`. Localize pelo diretório-base da skill: tente `<base>/scripts/` e depois `<base>/../../scripts/`. São Python 3 puro, sem dependência. No chat use `python3`; no Windows, `py` ou `python`.

```bash
python3 scripts/montar_mou.py cliente.mou.md --saida cliente-MOU.md
python3 scripts/conferir_mou.py cliente-MOU.md
```

Com chave repetida ou remissão a chave inexistente, **o montador não grava** e sai com código 1. Corrija o rascunho.

O conferidor lê `.md`, `.txt` e `.docx`. Ele separa três níveis:
- **ERRO** bloqueia;
- **ALERTA** é corrigir ou justificar na entrega;
- **CONFERIR** pede decisão humana.

O que cada regra pega e de que modelo veio está em `referencias/defeitos-do-acervo.md`. O essencial:
- **ERRO:**
  - parte ou interveniente qualificado sem linha de assinatura;
  - cláusula que pula, repete ou foge do capítulo, e número solto;
  - remissão a cláusula, capítulo ou seção inexistente;
  - CPF ou CNPJ com dígito errado, e a mesma empresa com dois CNPJ;
  - extenso que não bate (valor, número, percentual, fração);
  - TOTAL de tabela que não fecha;
  - considerando fora de sequência;
  - sem objeto, sem disposições gerais, sem foro, ou sem fecho com local e data;
- **ALERTA:**
  - campo em aberto;
  - nome grafado de dois jeitos;
  - casado sem regime, e "casado com Fulana" estando Fulana solteira;
  - PJ sem representante;
  - palavra repetida, e erro de digitação do acervo;
  - "deste Contrato", "INTERESSADOS" e renúncia genérica;
  - "incapacidade absoluta";
  - reversão em favor dos filhos;
  - "R-3-M-308" como matrícula;
  - art. 1.831 como regra de sucessão;
  - autorremissão;
- **CONFERIR:**
  - força vinculante pelo art. 462;
  - colação e justa causa na doação;
  - vedação de cônjuge que precisa de espelho no contrato social;
  - cônjuge nomeado que não anui.

### 1.5 Revisar o que o script não vê

O script confere a forma. Leia o MOU inteiro, contra a ficha do caso, e confira:

1. **Aritmética de participação.** Frações da doação que somam 100%; percentual sobre o capital × sobre a quota do sócio (a M21 trocou as bases); valor unitário × quantidade.
2. **Coerência com os quadros.** Matrícula, cartório e proprietário iguais aos da CIT; quotas e valores iguais aos do contrato social das investidas.
3. **Remissão que existe, mas aponta para o lugar errado.** A M21 remetia à cláusula 5.2 (reversão) para falar do planejamento patrimonial.
4. **Termos definidos.** "Partes" para todos, "sócios" só para quem já é sócio.
5. **Módulo que sobrou de outro caso:** nome, empresa ou cidade de outro cliente.
6. **Os [DECISÃO] de `notas-ao-modelo.md`** que o caso toca: D1 (art. 462), D3 (reversão), D4 (colação e justa causa).

### 1.6 Gerar o `.docx` e conferir de novo

Gere no papel timbrado com `armando-timbrado`, a partir do `.md` montado. Depois:

```bash
python3 scripts/conferir_mou.py cliente-MOU.docx --final
```

Com `--final`, campo em aberto passa a ser ERRO. **MOU com ERRO não vai ao cliente.**

Se o `.docx` usar numeração automática do Word, os números não estão no texto. O conferidor avisa e confere pelo que conseguir ler. Prefira número digitado, que é o que o montador produz.

---

## 2. Entrega: sempre com estes quatro blocos

1. **Pendências:** cada `[[ ]]` que restou e os documentos a colher (CIT faltante, regime de bens, contrato social atualizado).
2. **Escolhas que o cliente precisa entender:**
   - quem administra durante e depois do usufruto;
   - o que a doação faz no inventário (adiantamento ou parte disponível);
   - o que a vedação de cônjuges protege e o que não protege;
   - se o MOU obriga ou só registra intenção.
3. **Próximos instrumentos:** a lista da etapa de OBRIGAÇÕES, com a skill de cada um (`armando-holding-empresarial`, `armando-holding-patrimonial`, acordo de sócios, pedido de ITBI).
4. **Saída do `conferir_mou.py --final`:** se restou ALERTA ou CONFERIR, diga qual e por que ficou.

---

## 3. Referências

| Arquivo | Conteúdo |
|---|---|
| `assets/esqueleto.mou.md` | o MOU fixo da casa, com marcadores e `[[ ]]` |
| `assets/modulos.mou.md` | os 19 módulos (M01 a M19), prontos para colar |
| `referencias/catalogo-de-modulos.md` | a ficha do caso, a ordem dos capítulos e cada módulo: quando, variantes, o que decidir |
| `referencias/defeitos-do-acervo.md` | o censo dos 4 modelos, com a taxonomia e o que é trava de script × leitura humana |
| `referencias/notas-ao-modelo.md` | desvios adotados e os [DECISÃO] para a coordenação do NPPS |
| `scripts/montar_mou.py` | rascunho → MOU numerado, com remissões e extenso |
| `scripts/conferir_mou.py` | conferência de `.md`/`.docx` |
| `scripts/testes/` | `exemplo-familia.mou.md` (caso fictício completo), `defeitos-do-acervo.md` e `rodar_testes.py`. Rode depois de mexer em script |
