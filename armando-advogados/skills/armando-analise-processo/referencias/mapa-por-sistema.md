# Mapa por sistema — onde cada informação mora

Anatomia levantada sobre autos reais: PJe do TRF1, TRF3, TJBA e TJPI; PJe-JT do TRT-18; eSAJ do TJSP; e PJe híbrido (processo físico de 2003 digitalizado e migrado).

---

## PJe — 1º grau (TRF, TJ estadual)

**Reconhece-se por:** cabeçalho `<Tribunal> PJe - Processo Judicial Eletrônico` seguido da data de geração do extrato; capa em campos fixos; tabela `Documentos / Id. / Data da Assinatura / Documento / Tipo`; rodapé `Assinado eletronicamente por: NOME - dd/mm/aaaa hh:mm:ss`. **Não** tem carimbo lateral com QR (isso é eSAJ).

**Montagem em três blocos:**

| Bloco | Onde | Contém |
|---|---|---|
| Capa | p. 1 | Número, Classe, Órgão julgador, Última distribuição, Valor da causa, Assuntos, Nível de sigilo, Justiça gratuita, Pedido de liminar, quadro **Partes / Advogados** |
| Índice | p. 1-2 | tabela de documentos, em ordem cronológica crescente |
| Corpo | p. 3 → fim | as peças na ordem do índice, sem separador visível |

**Identificador da peça:** ID numérico de 9 ou 10 dígitos. É por ele que se cita (`ID 1491123365`), nunca por "fls.".

**Fronteira entre peças:** o rodapé `Assinado eletronicamente por`. Enquanto o nome e a data não mudam, é a mesma peça, ainda que virem dez páginas.

**Armadilhas próprias:**
- O ID pode sair **quebrado em dois pedaços** pelo texto do documento no índice (`47126 ... 0086` = `471260086`). Lido literalmente vira um número que não existe.
- A hora da assinatura quebra para a linha vizinha: a hora ao lado de um ID pode ser do lançamento anterior.
- A coluna **Polo** do índice pode estar desatualizada. Depois de uma inversão de polos (conhecimento → cumprimento), peças do exequente continuam rotuladas "Polo passivo". Ler o polo do índice como autoria da peça atribui ao cliente o cálculo que foi feito **contra** ele.
- Metade do PDF pode não ser processo: anexos de uma única petição (ficha JUCESP, atas, estatuto) ocupam dezenas de páginas.
- Documento cadastrado com **nome errado** existe: um ID do acervo está registrado com o número do processo trocando 2003 por 2023, e some de qualquer busca por número.

---

## PJe-JT — Justiça do Trabalho (TRT)

**Reconhece-se por:** `Poder Judiciário Justiça do Trabalho Tribunal Regional do Trabalho da Nª Região`; capa com `Data da Autuação` e `Valor da causa`; a marca `PAGINA_CAPA_PROCESSO_PJE` colada ao fim da lista de advogados; rodapé `Documento assinado eletronicamente por NOME, em dd/mm/aaaa, às hh:mm:ss - <id de 7 hex>`; URL `https://pje.trtNN.jus.br/pjekz/validacao/<26 dígitos>?instancia=N`; carimbo `Fls.: NN` no alto; classe grafada `ATOrd`, `ATSum`, `RTOrd`.

**Diferença decisiva: o SUMÁRIO fica na ÚLTIMA folha**, não na primeira. A capa só traz o link "PARA ACESSAR O SUMÁRIO, CLIQUE AQUI". **Leia o PJe-JT de trás para frente.**

**A capa NÃO traz** órgão julgador, assuntos CNJ, segredo de justiça nem audiência. Tudo isso está no **recibo/certidão de distribuição**, algumas folhas adiante — a peça com a tela "Sua Petição foi finalizada com sucesso". Vá a ela antes de responder qualquer pergunta cadastral.

**Identificador da peça:** hash de 7 caracteres hexadecimais (`057bd84`). É a identidade real no PJe-JT.

**Datar com precisão de segundo:** os 12 primeiros dígitos da URL de validação são `AAMMDDHHMMSS`. `26030421133522100000079227759` = 04/03/2026, 21:13:35. Funciona mesmo quando o sumário está incompleto.

**Armadilha maior do sistema:** **a contestação pode não constar do sumário.** Protocolada antes da frustração da conciliação, fica com visibilidade restrita (art. 22 da Res. CSJT 185/2017). Está fisicamente nos autos; some do índice. Localize-a pelo texto e pela URL de validação.

**Prazo:** no rito sumaríssimo não há prazo autônomo de contestação — a notificação inicial já designa audiência, e o marco é a audiência. As advertências numeradas da notificação (revelia e confissão do art. 844 da CLT, carta de preposto, art. 74 §2º sobre cartões de ponto, 5 dias úteis para se opor ao Juízo 100% Digital com aceitação tácita) fixam tudo o que a ré tinha de fazer.

**Numeração tripla:** o carimbo `Fls.:` dos autos, a numeração interna que o advogado imprimiu na própria peça, e o ID. A contestação que cita "fl. 7 da inicial" quase sempre se refere à numeração interna — que é a folha 8 dos autos.

---

## eSAJ — TJSP (Pasta Digital)

**Reconhece-se por:** carimbo **vertical na margem esquerda** de cada página (`Este documento é cópia do original, assinado digitalmente por … protocolado em dd/mm/aaaa às hh:mm, sob o número W…`); foliação `fls. N` no alto; cabeçalho institucional repetido em cada peça de cartório; a sequência `CONCLUSÃO → DESPACHO/SENTENÇA → "Int." + cidade e data`; atos de cartório no par `ATO ORDINATÓRIO` + `CERTIDÃO - Ato Ordinatório` + `CERTIDÃO - Remessa ao DJE`.

**Não há capa, não há índice, não há sumário.** A espinha é a foliação e a ordem cronológica de juntada. O juiz se refere às peças por folha ("Fls. 41/44 — Designe-se nova audiência"), e é assim que se cita.

**Onde está o quê:**

| Informação | Onde |
|---|---|
| Número, classe, assunto, partes | bloco de cabeçalho repetido em **toda** peça de cartório |
| Valor da causa e qualificação completa | só no **Termo de Ajuizamento** / inicial, na primeira página |
| Causa de pedir e pedido (JEC) | campos `Histórico*` e `Pedido` do formulário — são **AcroForm**: a extração de texto pega o rótulo e perde o conteúdo digitado |
| Data real de cada ato | linha `CONCLUSÃO Aos DD de MMM de AAAA` e o fecho `Int. Cidade, DD de MMM de AAAA` |
| Quem decidiu | `Juiz(a) de Direito Dr(a):` logo abaixo de DESPACHO |
| Audiência | `Data da Audiência: dd/mm/aaaa às hh:mm - sala` no cabeçalho das cartas |
| Quando a peça entrou | **o carimbo lateral**, não o texto |
| Sentença | **dentro do Termo de Audiência**, após "foi proferida a seguinte sentença". No JEC ela quase nunca é peça autônoma |

**O dispositivo começa em `Ante o exposto, JULGO…`.** O que vem depois — preparo, custas, DARE, FEDTJ, GRD, planilha de recurso inominado — é boilerplate, não condenação.

**Prazo:** a certidão `Remessa ao DJE` costuma vir **com a data em branco**. A contagem só fecha com o andamento no portal ou com a publicação. Duas notas no JEC: sentença proferida em audiência intima as partes presentes ali mesmo; e parte sem advogado costuma ser intimada por carta ou e-mail — mas o art. 19 da Lei 9.099/95 admite qualquer meio idôneo, e há atos ordinatórios remetidos ao DJe nos próprios autos. Não trate a intimação por carta como regra absoluta.

**Atenção à fórmula de intimação da sentença em audiência.** A do acervo diz: *"Ante a impossibilidade de intimação pessoal das partes e seus respectivos patronos da presente sentença, ficam imediatamente intimados…"*. Lida a partir de "ficam imediatamente intimados", ela parece pressupor presença; lida inteira, diz o contrário — é **intimação ficta**. Transcreva o período inteiro antes de construir qualquer tese sobre ela.

**Conversão — e o problema que ela cria.** O carimbo lateral é removido pelo `pdf2md.ps1` (é a marca repetida em toda página). Com ele vão embora o protocolo, o código de conferência **e a foliação**. Sobra só o marcador `[p. N]`, que é a página do PDF.

**Como recuperar a foliação depois da conversão:** as cartas e os cabeçalhos de cartório costumam repetir `fls. N` no corpo. Ache duas dessas ocorrências, compare com o `[p. N]` da mesma página e apure o **deslocamento constante** (tipicamente +1 ou +2, conforme a capa). Verifique numa terceira ocorrência antes de extrapolar. Se não houver duas ocorrências, **não deduza**: cite por `[p. N]` dizendo que é página do PDF, e registre em pendências que a foliação exige o PDF original.

**A confirmação por dois caminhos não existe aqui.** O eSAJ não tem índice, e a conversão apaga o carimbo de assinatura: os dois caminhos que a regra geral manda cruzar simplesmente não existem neste sistema. Não finja que existem. Escreva que a convergência obtida é **entre duas leituras do mesmo arquivo** e não vale como prova de atualidade — e trate a atualidade pela âncora inferida, declarada como tal.

---

## eproc (TJTO, TRF4)

**Reconhece-se por:** referência a **evento numerado** (`Evento 84`, `evento 96`) em vez de ID. É a numeração que o próprio escritório usa nos rascunhos estratégicos: `Evento NN (dd/mm/aaaa) — o que foi decidido`.

Cite sempre por evento. Quando o caso tem processos conexos (execução e embargos, por exemplo), **diga em quais autos está cada evento** — um rascunho do acervo mistura eventos 16, 56, 70, 82, 84, 89, 96 e 100-104 da execução com 18, 29, 38, 43, 44 e 46 dos embargos sem identificar qual é qual, e obriga o leitor a adivinhar.

---

## PJe híbrido — físico digitalizado e migrado

Autos antigos (anteriores ao PJe) digitalizados e migrados. **Duas camadas de referência no mesmo arquivo.**

**Reconhece-se por:** documentos de tipo `Volume`, e uma `Certidão de processo migrado`. Dentro dos volumes está o PDF do processo físico, com foliação manuscrita/carimbada e OCR degradado.

**Armadilhas — as piores de todas:**

- **Dois números que não se correspondem.** Convivem o CNJ (`0001219-15.2003.4.01.3901`) e o número antigo (`2003.39.01.001212-8`). A sequência **difere** (1219 × 1212): não se deduz um do outro. `grep` pelo CNJ não encontra nada nas centenas de páginas digitalizadas, que só conhecem o número antigo — e ainda em variantes corrompidas pelo OCR.
- **ID × folha × página do PDF do volume.** As peças do PJe citam folhas dos volumes, e às vezes citam `ID 277557943, pág. 219`, que é a página do PDF do volume e **não** a folha 219 dos autos. Num caso do acervo, essa confusão sustenta uma intimação ficta que o arquivo desmente noutro ponto.
- **OCR podre.** `FODER JUDICIARIO`, `MAMA` por IBAMA, `conenada` por condenada. Datas e números são o que mais se perde: há certidão de trânsito em julgado que sai como `transitou em julgado em / / 2009`. **Nunca cite texto de volume sem conferir no PDF.**
- **Formulários de "vistos em inspeção" com caixas de seleção.** Trazem dezenas de opções pré-impressas (`ARQUIVEM-SE OS AUTOS`, `SUSPENDA-SE A EXECUÇÃO NA FORMA DO ART. 40 DA LEF`, `CITE-SE POR EDITAL`). **O OCR não preserva qual quadrado foi marcado.** Ler a lista como teor da decisão produz conclusões inteiramente falsas — inclusive a de que o feito foi arquivado.
- **Referência estranha ao feito.** Os mesmos formulários citam a LEF e IPTU em processo que não é execução fiscal; e há ementas juntadas como precedente por alguma das partes, sobre matéria que nada tem a ver com o caso.
- **Peça de outro processo dentro dos autos.** Acontece, e às vezes é o próprio advogado que protocola por engano e requer o desentranhamento no mesmo dia.
- **Afirmação repetida que o título não sustenta.** Numa cadeia de petições do acervo, três peças afirmam que a parte "foi condenada a restituir"; subindo até o acórdão, o mandado de segurança havia sido **denegado**, e o único ato é um despacho mandando intimar. Quem lê a decisão de conversão sem subir até o título repete o erro.

---

## Feito de 2º grau

Além de tudo acima:

- A capa traz **Órgão julgador colegiado** (Câmara/Turma) e **relator nominal**. Ambos são obrigatórios no endereçamento da peça seguinte.
- Nos tribunais superiores há **número de registro** paralelo ao número da classe (`APn 1.082/DF (2025/0097736-5)`). Cite os dois.
- **Cadeia de autuações:** o mesmo objeto passa por vários números — notícia-crime, inquérito, medida cautelar sigilosa, ação penal na origem, ação penal no tribunal. A análise entrega **todos**, porque a peça vai citar todos ("a então Ação Penal nº …, atual APn …").
- Recurso cabível na origem e se tem **efeito suspensivo**, com o artigo do regimento interno: disso depende a via eleita.
- Prevenção: números e relatores de recursos anteriores do mesmo cliente.

---

## O que fazer quando o PDF não tem texto

Se o `.md` sai com menos de ~200 caracteres por página, o PDF é digitalizado. O `pdf2md.ps1` avisa.

Nesse caso:

1. **Não conclua nada sobre o conteúdo.** Registre "documento sem camada de texto — não lido".
2. Liste **quais** páginas ou IDs ficaram de fora. Costumam ser ASO, extrato de FGTS, ficha de registro, laudo, termo de declarações, fotos de álbum policial — a prova.
3. O rodapé de assinatura às vezes é a **única** informação textual da página. Ele ainda diz a que peça a folha pertence.
4. Peça o documento ao cliente, ou abra o PDF original no visualizador.
