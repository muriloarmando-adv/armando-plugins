---
name: armando-analise-processo
description: Analisa processo judicial em curso no padrão do escritório Armando Advogados — lê os autos na ordem certa (extrato atual → índice oficial → último ato → peça inaugural → defesa → prova), fixa o último movimento e o prazo em curso, mapeia as peças e entrega um dos quatro produtos da casa: FICHA RESUMO, RESUMO PARA O CLIENTE, PARECER ESTRATÉGICO ou TRIAGEM DE PRAZO. Use SEMPRE que o usuário pedir para "analisar esse processo", "resumir os autos", "fazer a ficha resumo", "em que pé está", "qual a fase", "últimos movimentos", "tem prazo correndo?", "o que o juiz decidiu", "vale a pena recorrer", "monta a estratégia", "diagnóstico do caso" — mesmo sem dizer "análise". Vale também quando o PDF entregue é o processo (a conversão é só o 1º passo; quem conduz é esta skill, não `armando-pdf-markdown`). Para redigir depois, use `armando-peticao-inicial` ou `armando-timbrado`. Para contrato, `armando-analise-contrato`.
---

# Análise de Processo — Padrão Armando Advogados

Padrão extraído de **13 fichas e resumos reais do Drive**, de **três peças opinativas**, de **três peças de defesa criminal** — para saber o que a análise precisa entregar para que a peça seja escrevível sem reabrir os autos — e da leitura de **sete acervos completos de autos** em PJe, PJe-JT, eSAJ e PJe híbrido, de 4 a 375 páginas. Inventário em `referencias/precedentes.md`.

**Cada regra desta skill mora em um lugar só.** O `SKILL.md` decide e remete; as referências detalham. Se algo estiver escrito duas vezes, é defeito — avise.

**Leitura obrigatória antes de analisar:** `ordem-de-leitura.md` e `modelos-de-entrega.md`. As demais se abrem quando o caso pedir. `precedentes.md` é material de apoio: abra quando quiser ver uma ficha real.

---

## 0. Quatro perguntas antes do caso

**1. De quando é este retrato?** Ver seção 3.

**2. O arquivo cobre o presente?** Não cobre em três hipóteses, e todas se declaram na abertura da entrega:
- extrato vencido (mais de ~30 dias entre o último ato e hoje);
- **a fase corre em autos apartados** que você não tem — cumprimento de sentença registrado em dependente, embargos, incidente. A ficha então **não pode afirmar a fase**, só o que estes autos mostram;
- páginas sem camada de texto: o que está nelas é desconhecido, e costuma ser a prova.

**3. De que lado estamos?** Sem isso a análise sai do lado errado — é o defeito nº 1 do acervo. Se não der para apurar, escreva `CLIENTE: não apurado` no topo e não emita prognóstico.

**4. O escritório, seus sócios ou seus advogados aparecem na narrativa dos fatos — e não apenas no cabeçalho?** Procure os nomes da casa no corpo da denúncia, da inicial e da prova, não só no bloco de procuradores. Num caso real um sócio figurava nominalmente na denúncia como a autoridade que subscreveu o ato administrativo central da imputação: não era denunciado, e a defesa até se servia desses atos — mas é questão de **testemunha e de impedimento**, e decide-se antes de protocolar, não depois.

Havendo coincidência de nome, ela vai para `RISCOS` como providência **anterior a qualquer protocolo**. E vai como coincidência: homonímia é comum, e a identidade **nunca se afirma sem confirmação** — escreva *"consta o nome X, que coincide com o do sócio X; confirmar se é a mesma pessoa"*, jamais *"o sócio X assinou"*.

---

## 1. Apuração prévia — e o que fazer sem ela

Pergunte em bloco, de uma vez: (1) quem representamos e em que polo; (2) para que serve a análise — isso escolhe o produto; (3) onde estão os autos; (4) há prazo que o usuário já conheça; (5) quem no escritório acompanha.

**O modo mais frequente é "analise estes autos e me diga o que tem", sem interlocutor.** Nesse caso **não pare**: entregue a **FICHA**, responda o que os autos responderem, e mova as perguntas sem resposta para `PENDÊNCIAS`, nominalmente. A rubrica `PERGUNTAS PARA O CLIENTE` da ficha é o lugar delas — abra o bloco dizendo que nenhuma foi respondida ainda.

**Nunca invente** número de autos, evento, ID, folha, data, valor, nome de juiz ou teor de decisão. O que não estiver no arquivo entra como **`não apurado`**, e a lista vai ao final.

**Há três espécies de lacuna, e elas se registram diferente:**

| Lacuna | Como se reconhece | Como se escreve |
|---|---|---|
| **Ausência de peça** | os autos não a contêm | `Não há nos autos prova de cumprimento: nenhuma certidão, extrato ou intimação.` — e é frequentemente a tese |
| **Página sem texto** | documento digitalizado sem OCR | `ID 037030e (extrato do FGTS) — página sem camada de texto, não lida.` |
| **Perdida na conversão** | a página tem texto, mas o dado não saiu | `Endereço requerido em 05/12/2023 — não extraído do arquivo; recuperável abrindo o PDF original.` |

Uma quarta, rara: página que rende **erro de PostScript** (`ERROR: undefined / OFFENDING COMMAND`). Não é imagem nem texto — trate como página não lida e diga por quê.

---

## 2. Preparar os autos

Dois passos, converter e mapear. **Escolha a coluna pelo ambiente**; a navegação depois (`grep`, `sed`) roda no Bash em qualquer um dos dois.

**Antes de tudo, localize a pasta dos scripts.** Quando esta skill carrega, o
prompt informa o **diretorio-base** dela (`Base directory for this skill: ...`).
Chame-o de `<base>`. A pasta `scripts/` aparece em duas disposicoes diferentes, e
voce tem de tentar as duas na ordem — no chat ela vem **dentro** da skill; no
plugin instalado, na **raiz** dele:

```bash
AA=$(ls -d "<base>/scripts" "<base>/../../scripts" 2>/dev/null | head -1)
```

```powershell
$AA = @("<base>\scripts", "<base>\..\..\scripts") |
      Where-Object { Test-Path $_ } | Select-Object -First 1
```

E o conversor de PDF, que mora na skill vizinha:

```bash
PDF2MD=$(ls "<base>/../armando-pdf-markdown/scripts/pdf2md.py" 2>/dev/null | head -1)
```

```powershell
$PDF2MD = "<base>\..\armando-pdf-markdown\scripts\pdf2md.ps1"
```

Saindo vazio, **pare e diga que nao localizou os scripts** — nunca chute caminho.

| Passo | Windows / PowerShell | Nuvem, Cowork, Linux, Mac / Python |
|---|---|---|
| **1. Converter** | `& "$PDF2MD" "autos.pdf" -Out "autos.md" -ManterRepetidos` | `python3 "$PDF2MD" autos.pdf --out autos.md --manter-repetidos` |
| **2. Mapear** | `& "$AA\mapear-autos.ps1" -Path "autos.md" -Out "mapa.md"` | `python3 "$AA/mapear-autos.py" autos.md --out mapa.md` |

**Converta sempre com `-ManterRepetidos` / `--manter-repetidos`**, porque o carimbo de folha repete em toda página — é o que o define — e sem a opção ele é descartado junto com o cabeçalho: **sem o carimbo, as âncoras 2 e 3 da seção 3 mentem** e a citação por folha fica impossível.

Em Windows use também `-Out`: **no console o PowerShell corrompe os acentos**. Na versão Python o console já sai em UTF-8, mas `--out` continua sendo o caminho normal — o mapa é para ser lido em arquivo.

Recebendo um `.md` já convertido, salte o primeiro passo. O `mapear-autos` também aceita o PDF direto e converte sozinho.

O mapa devolve, em seções numeradas: as **cinco** âncoras de data com o cálculo do vencimento · **o que o arquivo não mostra** (páginas sem texto, em faixas, e o teste de acentuação) · **a continuidade da foliação, com os reinícios** · números CNJ com dígito verificador conferido · campos da capa e partes · o índice oficial do sistema · as fronteiras de peça por assinatura, com a cobertura declarada · peças por título · **peças por fórmula** · a linha do tempo com as datas futuras destacadas · prazos · alertas ALTA e MÉDIA · valores e OAB.

**Ele localiza; não interpreta, não classifica e não conta prazo.** Rótulo de peça é palpite: uma linha pode vir rotulada errado, e peça sem título não aparece na tabela de títulos — por isso existe a de fórmulas. **Nunca conclua "não há sentença nos autos" a partir do mapa.**

---

## 3. De quando é este retrato — a regra única

Cinco âncoras, **e vale sempre a mais recente**:

1. **URL de validação** do PJe-JT — os 12 primeiros dígitos são `AAMMDDHHMMSS`. É a única que data peça sem rodapé de assinatura.
2. **Última linha do índice oficial.**
3. **Última assinatura eletrônica** no rodapé.
4. **Metadados do arquivo** — o `CreationDate` do PDF (`pdfinfo`, ou o cabeçalho HTML que o `pdf2md` grava na primeira linha do `.md`). É a única que existe mesmo quando o texto não traz data nenhuma: num extrato real do e-STJ era `04/02/2026`, e sem ela a análise teria datado o retrato em janeiro de 2025 — treze meses de erro.
5. **Data mais recente do texto** — só quando nenhuma das quatro existe (é o caso do eSAJ depois da conversão). Vale como estimativa e **se declara como inferida**.

**A `Data de geração do extrato` e o `CreationDate` dizem a mesma coisa e não dizem o movimento:** ambos marcam quando o PDF foi tirado, não quando o processo andou. Registre a data do retrato e a do último ato — as duas, sempre, e nomeadas.

O `mapear-autos` monta essa tabela e faz a conta. **Confira-a**: usar uma âncora só já errou por 48 dias num caso real e falhou inteiramente noutro.

Quando as âncoras divergem muito, o arquivo pode estar truncado. Diga isso.

---

## 4. A ordem de leitura — sete passes

Detalhe em **`referencias/ordem-de-leitura.md`**.

| # | Passe | O que se fixa |
|---|---|---|
| 1 | **Atualidade** | seção 3 acima |
| 2 | **Capa e partes** | número, classe, órgão, valor, distribuição, sigilo, **quem tem advogado — e se somos nós** |
| 3 | **Índice oficial** | o que existe, de que tipo, em que datas |
| 4 | **Último ato de juízo** | fase, comando vigente, prazo aberto, **e o que foi deferido e não cumprido** |
| 5 | **Peça inaugural** | causa de pedir, pedidos, valores |
| 6 | **Defesa e réplica** | controvertido × incontroverso |
| 7 | **Prova e constrição** | laudo, cálculo, penhora, o que falta |

**Passe 4 antes do 5** é a regra que mais economiza trabalho: ler a inicial antes da última decisão faz perder tempo com tese já superada.

---

## 5. Onde cada informação mora — por sistema

**`referencias/mapa-por-sistema.md`**: PJe, PJe-JT, eSAJ, eproc, híbrido e 2º grau — como se reconhece cada um, onde fica a capa, onde fica o índice, o que separa uma peça da outra, como se cita, e as armadilhas próprias.

Cinco fatos valem para todos:

- **A fronteira entre peças é o carimbo de assinatura do rodapé, não o título.** Mas nem todo sistema carimba todas as peças: o mapa declara a cobertura, e onde ela não chega a seção não serve de índice.
- **Assinante servidor ou magistrado = ato do juízo** — nele mora o prazo. **Advogado = peça de parte** — nela mora a tese, nunca o prazo.
- **Data de assinatura ≠ data de juntada ≠ data do ato.** Três datas para um evento; diga qual você usa.
- **O índice é um índice, não um inventário.** No PJe-JT a contestação protocolada antes da conciliação some do sumário e está nos autos. Concluir revelia onde há defesa é o pior erro possível.
- **Numeração é múltipla e conflitante** — folha carimbada, numeração interna da peça, ID/evento, foliação do físico. Cite pelo **ID ou evento**; citando folha, diga de qual numeração. **E a foliação pode reiniciar dentro do mesmo arquivo**, quando começa um apenso: aí o mesmo número de folha existe duas vezes, e a citação tem de dizer de qual autuação. O Passe 3 de `ordem-de-leitura.md` traz a verificação.

---

## 6. Últimos movimentos e prazo

Detalhe em **`referencias/prazos-e-movimentos.md`**, que traz também a tabela de gatilhos por rito e o formato da cronologia.

A regra, uma vez só:

> **Localize o gatilho. Nomeie o prazo. Não conte o prazo.**

Escreva *"prazo de 15 dias indicado no ato, aberto pela intimação de 14/08/2026 — conferir a contagem no sistema"*. Nunca *"vence dia 09/09"*. Dia útil, suspensão, feriado local, prazo em dobro, intimação pessoal e data de disponibilização no DJe decidem a contagem, e o extrato quase nunca traz a publicação.

**Confirme o último movimento por dois caminhos** (índice × corpo). Quando os dois não existem — é o caso do eSAJ depois da conversão —, diga que a convergência obtida é entre duas leituras do mesmo arquivo e **não vale como prova de atualidade**.

---

## 7. O que focar — por ramo

**`referencias/por-ramo.md`**: trabalhista, cível de conhecimento, execução e cumprimento, execução fiscal, JEC, criminal, 2º grau e cliente em recuperação judicial. Traz também, ao fim, **o que a análise precisa entregar quando alimenta uma peça**.

Duas coisas valem para todos:

- **Cruze documento com documento, não com a narrativa.** Comprovante bancário não diz a competência; contracheque impresso em duplicata dobra a contagem de faltas; comprovante repetido soma duas vezes.
- **Procure o que contraria o cliente antes do que o favorece** — inclusive quando o que contraria é a peça que a própria casa já protocolou. Achado assim vai para `RISCOS`, como coisa a corrigir antes da peça seguinte; nunca para o corpo descritivo como concessão, e nunca escondido.

---

## 8. Os quatro produtos

**`referencias/modelos-de-entrega.md`** traz cada um com a redação literal da casa, e é lá que está a regra de estilo. Escolha pelo leitor:

| Produto | Leitor | Quando |
|---|---|---|
| **FICHA RESUMO DO PROCESSO** | o escritório, a pasta | padrão. Caso novo, passagem de bastão, controle |
| **RESUMO PARA O CLIENTE** | leigo com uma decisão na mão | fechar negócio, aceitar acordo, esperar |
| **PARECER ESTRATÉGICO** | quem decide a tese | há tese a testar, ou peça a escrever |
| **TRIAGEM DE PRAZO** | quem vai protocolar | intimação recém-publicada |

A ficha é a espinha; os outros três se montam a partir dela. **Na dúvida, e sempre que não houver interlocutor, entregue a ficha.**

---

## 9. Controle de qualidade

**`referencias/controle-de-qualidade.md`** — 81 verificações em nove tabelas, varrível numa passada. Os exemplos reais do acervo estão no apêndice, fora do caminho.

Automatize o mecânico primeiro. Mesma escolha de coluna da seção 2, e o mesmo `$AA` de lá:

| O que confere | Windows / PowerShell | Nuvem, Cowork, Linux, Mac / Python |
|---|---|---|
| Mapa dos autos | `& "$AA\mapear-autos.ps1" -Path "<autos.md>" -Out "<mapa.md>"` | `python3 "$AA/mapear-autos.py" "<autos.md>" --out "<mapa.md>"` |
| CPF, CNPJ e nº CNJ | `& "$AA\validar-identificadores.ps1" -Path "<análise>"` | `python3 "$AA/validar-identificadores.py" --path "<análise>"` |
| Valor por extenso | `& "$AA\extenso.ps1" -Path "<análise>"` | `python3 "$AA/extenso.py" --path "<análise>"` |

---

## 10. Entrega e encaixe

- **Formato**: `.docx` em papel timbrado pela **`armando-timbrado`** quando a análise sai da casa. Markdown basta para a pasta.
- **Toda entrega termina em três blocos**: **Pendências** · **Riscos** · **Próximo passo** (o que fazer, quem faz, até quando).
- **Prazo ou tarefa** viram card pela **`armando-naji-tarefa`** — cujo `TIPO DE TAREFA` padrão já é `Análise Processual`.
- **Precedente** pelo agente **`jurisprudencia`**; **intimação publicada** pelo agente **`diario-justica`**. Indisponíveis, registre como pendência — nunca simule a saída.
- **Peça** depois da análise: inicial pela **`armando-peticao-inicial`**; defesa e recurso seguem apenas a formatação da **`armando-timbrado`**.
