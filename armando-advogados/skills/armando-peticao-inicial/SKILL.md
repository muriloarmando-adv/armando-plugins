---
name: armando-peticao-inicial
description: Redige petição inicial no padrão do escritório Armando Advogados — endereçamento, preâmbulo de qualificação em parágrafo único terminado em "propor a presente [AÇÃO]", seções em algarismo romano, transcrição integral de lei e de ementa, antecipação da defesa do réu, valor da causa fundamentado no art. 292 do CPC e bloco de assinaturas da casa. Use SEMPRE que o usuário pedir para "fazer uma inicial", "redigir petição inicial", "ajuizar ação", "entrar com ação de X", "propor ação anulatória/monitória/de execução/possessória/declaratória/de cobrança", "mandado de segurança", "exceção de pré-executividade", "cumprimento de sentença", "tutela antecedente", "alvará judicial", "reclamação pré-processual no CEJUSC", "emenda à inicial" — mesmo que não mencione "inicial" ou "padrão do escritório". Para peça de defesa ou recurso, siga apenas a formatação de `armando-timbrado`. Para contrato, use `armando-elaborar-contrato`.
---

# Petição Inicial — Padrão Armando Advogados

Padrão extraído de **21 iniciais do Drive do escritório** (ambiental federal, monitória, execução de título extrajudicial, possessória, declaratória, consumerista, mandado de segurança cível e tributário, consignação, evicção, resolução contratual, tutela antecedente, alvará de jurisdição voluntária, reclamação pré-processual e cumprimento de sentença). O inventário com os IDs está em `referencias/precedentes.md`.

O padrão da casa é **uniforme na moldura e variável no miolo**: o endereçamento, o preâmbulo, a arquitetura de seções, o bloco de tutela, o rol de pedidos, o valor da causa e o fecho são sempre os mesmos. O que muda entre uma monitória de R$ 1.207,00 e uma anulatória de R$ 1,2 milhão é a densidade da fundamentação — não a forma.

---

## 1. Apuração prévia obrigatória

Não redija sem estas respostas. Pergunte em bloco, de uma vez:

1. **Quem representamos** e em que polo. A inicial se escreve *para alguém*.
2. **Qualificação completa** de autor e réu — nome/razão social, CPF/CNPJ, RG com órgão emissor, nacionalidade, estado civil, profissão, endereço com CEP. Para PJ, o representante legal. Cliente recorrente: procure no Drive antes de perguntar.
3. **Espécie de ação** pretendida e **fundamento legal** (artigos do CPC/CC/lei especial que autorizam a via eleita).
4. **Narrativa dos fatos com datas** e a lista de documentos que a comprovam. Cada fato relevante precisa de um documento numerado.
5. **Há tutela de urgência?** Se sim, qual o dano que se agrava a cada dia.
6. **Valor da causa** e o inciso do art. 292 do CPC que o justifica.
7. **Foro** — de eleição contratual, do domicílio do réu, do local do fato ou da situação da coisa.
8. **Gratuidade ou parcelamento de custas?**

**Nunca invente** número de processo, número de autos administrativos, CNPJ, CPF, matrícula, número de contrato, data ou valor. Campo não apurado entra como `[......]` e a pendência vai listada ao final da entrega.

**Nunca invente jurisprudência.** Ementa, número do recurso, relator, órgão julgador e data têm de ser reais. Para buscar precedente, acione o agente `jurisprudencia` (Jus IA). Se a tese não tiver julgado localizado, escreva o argumento sem ementa — nunca com ementa fabricada. Uma das iniciais do acervo carrega, no corpo, a marcação `PROCURAR UMA JURISPRUDENCIA MELHOR`: é exatamente o que se deve fazer antes de protocolar, e nunca preencher por conta própria.

---

## 2. Buscar precedente no Drive antes de redigir

O escritório quase sempre já ajuizou ação da mesma espécie. Antes de escrever do zero:

```
search_files: title contains 'Inicial'
search_files: title contains '[espécie]'
search_files: fullText contains '[tese central]' and mimeType = 'application/vnd.openxmlformats-officedocument.wordprocessingml.document'
```

`referencias/precedentes.md` traz a tabela de iniciais já mapeadas por espécie, com ID de arquivo. Reaproveite a estrutura e os blocos de fundamentação; **não reaproveite os defeitos** — confira contra `referencias/controle-de-qualidade.md`.

---

## 3. Arquitetura

```
[ENDEREÇAMENTO EM CAIXA ALTA]
[Processo nº ... / Distribuição por dependência ao processo nº ...]   ← só quando houver

[PREÂMBULO — parágrafo único: autor qualificado → fórmula de comparecimento →
 fundamento legal → "propor a presente" → NOME DA AÇÃO → "em face de" →
 réu qualificado → fórmula de remate]

I – DO FORO COMPETENTE                      ← quando há foro de eleição ou dúvida
II – DAS PRELIMINARES                       ← gratuidade, parcelamento, legitimidade, litisconsórcio
III – DOS FATOS
IV – DO DIREITO
     IV.1 – [primeira tese]
     IV.2 – [segunda tese]
     IV.3 – [antecipação da defesa do réu]
V – DA TUTELA DE URGÊNCIA
     Do fumus boni iuris
     Do periculum in mora
VI – DOS PEDIDOS
     [protesto por provas]
     [valor da causa]

[fecho, local e data, bloco de assinaturas]
[ANEXOS]                                    ← quando o rol for extenso
```

**Numeração das seções.** Algarismo romano em caixa alta com travessão (`I – DOS FATOS`) ou apenas o romano com ponto (`I. DOS FATOS`). Subitens em `III.1`, `III.2` ou `III.a)`, `III.b)`. Mantenha um único sistema no documento inteiro.

**Rubricas.** Sempre em caixa alta, precedidas de `DO`/`DA`/`DOS`/`DAS`. As variantes que a casa usa e que são intercambiáveis: `DOS FATOS` / `DA SÍNTESE FÁTICA` / `DA SÍNTESE DOS FATOS`; `DO DIREITO` / `DOS FUNDAMENTOS` / `DOS FUNDAMENTOS JURÍDICOS`; `DOS PEDIDOS` / `DOS PEDIDOS E REQUERIMENTOS FINAIS`.

**Seções condicionais.** `DO FORO COMPETENTE` só entra quando há cláusula de eleição a invocar ou quando a competência pode ser questionada — nas execuções e monitórias fundadas em contrato ele é sistemático. `DA TUTELA DE URGÊNCIA` só entra quando há urgência real; sem ela, a inicial vai direto de `DO DIREITO` para `DOS PEDIDOS`.

Texto literal de endereçamento e preâmbulo: **`referencias/preambulo-e-enderecamento.md`**.

---

## 4. Blocos padrão

**`referencias/blocos-padrao.md`** traz, com a redação literal do escritório:

- bloco de tutela de urgência (com a tabela de duas colunas `PROBABILIDADE DO DIREITO` / `PERIGO DE DANO`);
- catálogo de pedidos por espécie — citação, penhora, SISBAJUD, RENAJUD, honorários, custas, art. 82 §2º, art. 212 §2º, dispensa de audiência de conciliação;
- protesto por provas;
- fórmulas de valor da causa por inciso do art. 292 do CPC;
- fecho, local e data;
- bloco de assinaturas com a composição real da banca;
- legenda de imagem e rol de anexos.

**Copie de lá.** São fórmulas já rodadas em juízo; não as reescreva por conta própria.

---

## 5. Como o escritório escreve

Detalhamento e vedações em **`referencias/estilo-e-vedacoes.md`**. O essencial:

- **Terceira pessoa, sempre.** "A Autora requer", "a Requerente demonstrou", nunca "eu" ou "nós". Os rótulos processuais (Autora, Ré, Requerente, Requerido, Exequente, Executada, Impetrante, Excipiente) vão em **maiúscula inicial** e são mantidos em todas as ocorrências.
- **Um fato, um parágrafo, uma data.** A narrativa é cronológica e ancorada: "Em 15/07/2026, a Requerida, por iniciativa própria e mediante mensagens de WhatsApp (anexo 02)…". Fato sem data ou sem remissão a documento é defeito.
- **Lei transcrita por extenso**, em bloco recuado, precedida de `que dispõe:` / `nos seguintes termos:` / `vejamos:` / `preceitua:`. Nunca só a remissão numérica quando o dispositivo é o eixo do argumento.
- **Ementa integral**, tal como saiu do tribunal (inclusive em caixa alta), seguida da citação completa entre parênteses. E — esta é a marca da casa — **antecedida ou sucedida de uma frase que diz por que aquele precedente serve**: *"O precedente é especialmente relevante ao caso em exame, na medida em que reconhece, de forma expressa, que…"*. Ementa solta, sem ponte com o caso, é defeito.
- **Antecipe a defesa do réu.** Presente em quase todas as iniciais do acervo: *"Cabe prevenir eventual questionamento quanto a…"*, *"Impende antecipar o argumento que certamente será suscitado pela instituição financeira ré…"*, *"Ainda que a Requerida venha a sustentar, em sua defesa, que…"*, *"Cientes de que os negócios remontam a dezembro de 2011, os Requerentes antecipam-se à eventual arguição de prescrição."*
- **Tese principal e tese subsidiária explicitadas**, quando houver: *"seja pela tese principal — nulidade integral do aval —, seja pela tese subsidiária — ineficácia quanto à meação —, a probabilidade do direito está robustamente demonstrada."*
- **Encerre a seção fática** com `Em síntese, os fatos.` ou `São esses, em síntese, os fatos.`
- **Valores e prazos** em algarismo seguido do extenso entre parênteses: `R$ 13.173,13 (treze mil, cento e setenta e três reais e treze centavos)`, `3 (três) dias`, `20% (vinte por cento)`. Sem exceção, inclusive no valor da causa.
- **Registro formal com latinismo medido.** A inicial admite o que o contrato não admite: *ocorre que*, *com efeito*, *impende destacar*, *cumpre esclarecer, desde logo*, *destarte*, *entrementes*, *pari passu*, *isto posto*, *ademais*, *não obstante*, *sucede que*, *in casu*, *sub judice*. Use com parcimônia — dois ou três por seção, não um por parágrafo.
- **Imagem sempre legendada.** Prints, mapas, tabelas e capturas de tela entram em tabela de uma coluna com a legenda descrevendo o que a imagem prova. Nunca imagem solta.

---

## 6. Espécies

**`referencias/por-especie.md`** — o que não pode faltar em cada uma: monitória, execução de título extrajudicial (com e sem arresto), execução de honorários advocatícios, ação anulatória de ato administrativo, mandado de segurança, declaratória de inexistência de débito com dano moral, declaratória de inexistência de relação jurídica, possessória, consignação, evicção, resolução contratual com cláusula penal, tutela antecedente do art. 303, alvará de jurisdição voluntária, reclamação pré-processual no CEJUSC, cumprimento de sentença e exceção de pré-executividade.

---

## 7. Controle de qualidade

Antes de entregar, rode **`referencias/controle-de-qualidade.md`**. Ele apanha o que efetivamente vazou nas iniciais do acervo: nome de parte trocado no meio da peça, número de auto de infração digitado com um caractere errado em relação ao preâmbulo, valor por extenso divergente do algarismo, `Dá-se à causa o valor de xxxxxxxxxx` esquecido, campo `EDER...........` não preenchido, marcação de pesquisa pendente no corpo, seção numerada duas vezes com o mesmo romano.

**A parte mecânica é automatizada — rode sempre**, antes da conferência de leitura. Os três scripts ficam na pasta `scripts/` do plugin (localize o caminho: ele muda conforme a instalação). Aceitam `.docx`, `.md` e `.txt`, e devolvem código de saída `1` quando há achado de severidade ALTA:

```powershell
& "<plugin>\scripts\revisar-inicial.ps1"          -Path "<peça>"   # resíduo, identificador divergente, numeração, requisitos do art. 319
& "<plugin>\scripts\extenso.ps1"                  -Path "<peça>"   # confere cada par "R$ X (extenso)"
& "<plugin>\scripts\validar-identificadores.ps1"  -Path "<peça>"   # dígito verificador de CPF, CNPJ e número CNJ
```

O `extenso.ps1` também gera o extenso avulso, útil na hora de redigir: `-Valor 13173.13` devolve `R$ 13.173,13 (treze mil, cento e setenta e três reais e treze centavos)`.

Os scripts cobrem só o mecânico. Ementa, tese, cabimento e adequação do rito continuam exigindo leitura — e nada neles substitui o restante do `controle-de-qualidade.md`.

---

## 8. Entrega

`.docx` em papel timbrado, Book Antiqua 12, entrelinha 1,5, espaçamento de 8 pt entre parágrafos, justificado, recuo de primeira linha de 1,5 cm — acione **`armando-timbrado`**.

Ao entregar, liste sempre:

1. **Pendências** — todo `[......]` em aberto e todo documento citado que ainda não existe.
2. **Riscos da tese** — onde a peça é forte, onde é vulnerável e o que o réu provavelmente vai alegar.
3. **Providências prévias ao protocolo** — custas, procuração, notificação extrajudicial, declaração de hipossuficiência, guia de recolhimento.
