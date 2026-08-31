# Controle de qualidade

Passagem obrigatória antes de entregar. **A tabela é para varrer**; os casos reais em que cada defeito apareceu estão no apêndice, ao final — leia uma vez, depois use só a tabela.

Rode primeiro o mecânico:

```powershell
& "$AA\scripts\mapear-autos.ps1"             -Path "<autos.md>"  -Out "<mapa.md>"
& "$AA\scripts\validar-identificadores.ps1"  -Path "<análise>"
& "$AA\scripts\extenso.ps1"                  -Path "<análise>"
```

> `$AA` e a raiz do plugin, e nao um caminho fixo: ela muda entre a maquina do
> escritorio, a nuvem e o Cowork. Obtenha-a uma vez por sessao, antes de rodar
> qualquer script acima:
>
> ```powershell
> $AA = @($env:CLAUDE_PLUGIN_ROOT,
>         "$env:USERPROFILE\.claude\plugins\marketplaces\armando-advogados\armando-advogados",
>         "$env:USERPROFILE\armando-plugins\armando-advogados") |
>       Where-Object { $_ -and (Test-Path $_) } | Select-Object -First 1
> ```
>
> ```bash
> AA=$(ls -d "$CLAUDE_PLUGIN_ROOT" \
>         "$HOME/.claude/plugins/marketplaces/armando-advogados/armando-advogados" \
>         "$HOME/armando-plugins/armando-advogados" 2>/dev/null | head -1)
> ```
>
> Saindo vazio, o plugin nao esta instalado: **diga isso e pare**, em vez de
> adivinhar caminho.


| Script | O que apanha |
|---|---|
| `mapear-autos.ps1` | extrato vencido · CNJ com DV inválido · mais de um CNJ · páginas sem texto · acentuação perdida · índice × fronteiras de peça · datas futuras · alertas ALTA |
| `validar-identificadores.ps1` | dígito verificador de CPF, CNPJ e CNJ (mod 97) |
| `extenso.ps1` | cada par `R$ X (extenso)`; ignora linha de tabela e valor já glosado noutro lugar |

Um `MÉDIA` residual do `extenso.ps1` sobre valor que **só** aparece em tabela é aceitável — não é motivo para desfazer a tabela.

---

## A. É de um caso só, e do lado certo

| ✓ | Verificação |
|---|---|
| ☐ | O nome das partes do cabeçalho — e só ele — aparece em todo o corpo |
| ☐ | A data de distribuição do cabeçalho é anterior a todos os atos **judiciais** da cronologia (fato pré-processual e fase administrativa são exceção legítima — ver § C) |
| ☐ | A fase declarada no cabeçalho não é desmentida por nenhuma linha do corpo |
| ☐ | Tratando de processos conexos, **cada evento diz a que autos pertence** |
| ☐ | Existe o campo `CLIENTE`, preenchido ou marcado `não apurado` |
| ☐ | Existe o campo `ANALISTA` e o campo `ANÁLISE FECHADA EM` |
| ☐ | O prognóstico raciocina do lado do cliente |
| ☐ | A conclusão não recomenda o que prejudica o cliente |
| ☐ | Ato desfavorável não é qualificado como acerto |
| ☐ | O documento não se apresenta como instrumento de decisão do órgão que julga o cliente |

## B. Atualidade e rastreabilidade

| ✓ | Verificação |
|---|---|
| ☐ | A data de corte da consulta está declarada |
| ☐ | Extrato com mais de ~30 dias: o aviso está **na abertura** |
| ☐ | A âncora usada está nomeada, e a inferida está rotulada como inferida |
| ☐ | Nenhum marco temporal vencido aparece em tempo futuro |
| ☐ | Nenhum prazo já vencido é anunciado como aberto sem dizer o que foi feito |
| ☐ | Se a fase corre em autos apartados que não temos, a ficha **não afirma a fase** |
| ☐ | Link da pasta do caso no Drive |

## C. Coerência interna

| ✓ | Verificação |
|---|---|
| ☐ | Nome de pessoa, empresa, operação e órgão grafado sempre igual |
| ☐ | Gênero do rótulo processual não muda no meio |
| ☐ | Números de processo, inquérito, auto e sindicância idênticos em todas as ocorrências |
| ☐ | Número CNJ **com máscara**, completo e bem formado |
| ☐ | Datas consistentes: nenhum fato posterior citado como anterior |
| ☐ | Intervalo declarado não contém data fora dele |
| ☐ | Ano de transcrição de prova conferido contra o contexto |
| ☐ | Remissões internas apontam para seção existente |
| ☐ | O cabeçalho não é mais restrito que o corpo |
| ☐ | Cronologia com fase administrativa: o corte entre ela e a judicial está explícito |

## D. Aritmética

| ✓ | Verificação |
|---|---|
| ☐ | Toda soma fecha |
| ☐ | Todo percentual se reproduz da base declarada — e a base está dita |
| ☐ | Composição de pagamento não excede o preço |
| ☐ | Toda diferença entre documento e transferência é explicada |
| ☐ | Todo valor tem data-base |
| ☐ | Algarismo e extenso conferem, e o mesmo valor é igual em todas as ocorrências |
| ☐ | Valor "estimado" ao centavo tem fonte |
| ☐ | Cifra sem espaçamento quebrado (`R $2.357.373,00`) |
| ☐ | Contagem de vezes × número de vítimas/verbas fecha |
| ☐ | **Cálculo derivado** (multa e honorários do art. 523, atualização, projeção) vem rotulado `projeção desta análise, não valor fixado nos autos`, com a fórmula |

## E. Campos e resíduo

| ✓ | Verificação |
|---|---|
| ☐ | Nenhum campo do cabeçalho em branco que o próprio corpo preencha |
| ☐ | Padrão da lista mantido (todos com CPF, ou nenhum) |
| ☐ | **Nenhum campo `Persona:`** — é instrução de prompt vazada |
| ☐ | Sem `[......]`, `xxxxxxxxxx`, `TODO`, `MinutaIA`, parêntese aberto, título com sintaxe quebrada |
| ☐ | Separador é quebra de seção, não linha de sublinhados |
| ☐ | Título não vem duplicado; tabela não abre com linha vazia |
| ☐ | Destinatário nomeado, e tratamento no mesmo número do começo ao fim |
| ☐ | O documento diz **sobre qual processo** trata |

## F. Fidelidade aos autos

| ✓ | Verificação |
|---|---|
| ☐ | Nenhum número, data, valor, nome ou teor inventado; o não apurado está rotulado |
| ☐ | A descrição do título confere com o título — **subiu-se até o acórdão** |
| ☐ | Leu-se o **dispositivo**, não o relatório |
| ☐ | Transcrição com aspas de abertura e reticências de corte |
| ☐ | **Nenhuma tese foi construída sobre trecho truncado.** Antes de afirmar o que um ato diz, transcreva o **período inteiro** — a oração cortada costuma dizer o contrário |
| ☐ | **Nenhuma afirmação categórica sobre o que a decisão *não* diz** sem ter relido o ato inteiro, relatório e dispositivo |
| ☐ | O que a peça atribui a um documento é o que o documento diz — não a paráfrase que outra peça fez dele |
| ☐ | Ordem determinada não é descrita como cumprida (*"coloque-se como fiel depositária"* ≠ termo de depósito lavrado) |
| ☐ | Números calculados pelo mapa (dias de defasagem, páginas sem texto) foram **copiados**, não recalculados à mão |
| ☐ | Página sem camada de texto listada como não lida, uma a uma |
| ☐ | Dado perdido na conversão distinguido de dado ausente dos autos |
| ☐ | Ausência de peça registrada como ausência, não presumida |
| ☐ | Contradição **dentro dos autos** (ato do juízo × certidão) registrada, não silenciada |
| ☐ | Rubrica do tipo penal / da verba única na peça inteira |
| ☐ | Acentuação íntegra: se o mapa acusou <1%, toda transcrição foi conferida no PDF |

## G. Prazo e fase

| ✓ | Verificação |
|---|---|
| ☐ | Último movimento confirmado por dois caminhos — ou dita a impossibilidade de confirmar |
| ☐ | Prazo com gatilho nomeado (ato, ID/folha, data), quantidade, dispositivo e destinatário |
| ☐ | Consta a ressalva de conferência da contagem no sistema |
| ☐ | Está dito o que acontece se o prazo correr em branco |
| ☐ | Existem as rubricas `FASE ATUAL` e `PRÓXIMO ATO / PRAZO` |
| ☐ | Último ato sendo petição de parte pendente: registrado como **espera com risco de decisão surpresa**, com há quanto tempo |
| ☐ | Audiência com data, hora e modalidade |

## H. Direito citado

| ✓ | Verificação |
|---|---|
| ☐ | Nenhum julgado inventado — pesquisa pelo agente `jurisprudencia` |
| ☐ | Julgado com tribunal, classe, número, UF, relator, órgão e data |
| ☐ | Nome de relator conferido contra a composição real do tribunal |
| ☐ | Dispositivo conferido contra a **redação vigente** |
| ☐ | Instituto em negrito tem citação atrás |
| ☐ | Referência doutrinária na ordem certa |
| ☐ | Grafia: **desconstrução**, não "deconstrução" |

## I. Fecho

| ✓ | Verificação |
|---|---|
| ☐ | **Pendências** — todo `não apurado`, documento citado e não juntado, página sem OCR, pergunta ao cliente sem resposta |
| ☐ | **Riscos** — onde é forte, onde é vulnerável, o que o adversário tem de melhor, e o custo da via quando ele pesa perto do proveito |
| ☐ | **Próximo passo** — o que fazer, quem faz, até quando |
| ☐ | Checklist de documentos **adaptado ao caso** |
| ☐ | Perguntas ao cliente falam do caso deste documento |
| ☐ | Teses e pedidos não estão fundidos na mesma lista |
| ☐ | Saindo do escritório: timbrado, local, data, nome e OAB — com a inscrição conferida |

---

# Apêndice — os defeitos, tal como ocorreram

Cada um foi encontrado em documento real do acervo. Estão aqui para calibrar o olho, não para conferir.

**Dois casos num arquivo só.** Uma ficha traz no cabeçalho o processo `0000671-73.2026.5.10.0821` (José Lacy × Simão e Vera, distribuído em 08/06/2026, "ainda não houve apresentação de defesa") e, do meio para o fim, outro reclamante contra ZEN e META — com defesa, réplica e audiência realizada em 24/11/2025.

**Lado errado.** Uma ficha faz prognóstico de devedor ("chance de não pagar nada é baixa, cerca de 10%") num processo em que o escritório é o credor — porque não tem campo `CLIENTE`. Um relatório escrito para a defesa de um investigado fecha recomendando "o prosseguimento das diligências para a completa elucidação da cadeia de lavagem". E o indeferimento do adiamento do interrogatório do próprio cliente aparece como "medida estratégica necessária para evitar riscos de prescrição" — justificativa do juízo escrita como avaliação da defesa, quando a prescrição corre a favor do cliente.

**Sem data de corte.** Nenhum documento do acervo diz quando foi fechado nem quem o redigiu. Em nenhum é possível saber se o "status atual" ainda é atual. Dois anunciam prazo já vencido como se aberto: `Prazo: 21/08/2026` num arquivo ainda rotulado "RASCUNHO", e "5 dias para juntada de procuração" num resumo sem data. Um relatório diz que "o interrogatório designado **será** o marco decisivo" para data já passada.

**Nomes e números instáveis.** "Gabriela Almeida Carvalho" e "Gabriela Carvalho" no mesmo parecer, com o mesmo valor atribuído. "Sindicância nº 764/DF" e "nº 74/DF" a poucas linhas. O mesmo precedente como "APN nº 557/PR" e "APN nº 527/PR". `PROCESSO: 00157271720248272722` no campo indexável e `0015727-17.2024.8.27.2722` no corpo. `0003644-22.2021.8272706` sem pontuação, na peça cujo cabeçalho traz o número principal correto. Mensagem de WhatsApp transcrita como "13/11/2010" em contexto cujos fatos são todos de novembro de 2019. "Operação Hygea e Assombro" / "Assombro e Hyega" / "Eris e Hygea".

**Intervalo impossível.** `out/2024 a mai/2025` listando, dentro, cancelamentos em `04/06/2025` e `01/09/2025`.

**Contas que não fecham.** Total R$ 30.176,62 menos depósito R$ 22.810,06 escrito como "aproximadamente R$ 8.100,00" (a diferença é R$ 7.366,56). Rendimentos de R$ 2.562.714,15 + R$ 904.456,65 = R$ 3.467.170,80 afirmados como "superiores a R$ 3.467.972,79". "Cerca de 12%" para o que é 9,4% da base que a própria peça acabara de fixar — e o cálculo ainda dobra um bem dado como parte do pagamento do outro. Composição de pagamento somando R$ 180.980,00 contra preço de R$ 179.900,00. Nota fiscal de R$ 146.000,00 e TED de R$ 148.000,00 na mesma data, justapostos sem uma palavra sobre os R$ 2.000,00. "Juros (21 meses e 13 dias)" sem informar o vencimento nem a data final. "Exatamente dois dias de prêmio médico" sem que o prêmio diário apareça. "Prejuízo estimado de R$ 296.390,16" — único dado da peça sem laudo atrás. `R $2.357.373,00` e `R$  716.900,00`, quatro vezes. "Por sete vezes" com seis nomes listados.

**Campos e resíduo.** `VALOR DA CAUSA:` e `AUDIÊNCIA:` vazios numa ficha cujo corpo informa R$ 192.000,00 e a audiência de 13/02/2025. Lista de interpostas pessoas com CPF em dois nomes e nada no terceiro. Campo `Persona: Consultor Jurídico Sênior e Estrategista em Direito Penal Econômico` num parecer que, em compensação, não tem assinatura, OAB, local nem destinatário. Três títulos empilhados no topo e tabelas abrindo com `|  |  |`. "Prezado(a) Cliente," seguido de tratamento no plural. Parecer que pede rejeição da denúncia sem dizer em que autos; resumo ao cliente que descreve "um processo trabalhista antigo (de 2019)" sem número e sem vara.

**Infidelidade aos autos.** Três peças repetem que a parte "foi condenada a restituir" quando o mandado de segurança fora **denegado** e o único ato era um despacho de intimação. O relatório de uma decisão criminal menciona três endereços e duas pessoas jurídicas; o dispositivo autoriza busca exclusivamente na residência de uma pessoa física. Transcrições que começam no meio da frase, sem aspas nem reticências. "Denunciação caluniosa de servidor público" no título e "funcionário público" no corpo. Razão social ora "LTDA" ora "ME", mesmo CNPJ.

**Direito mal citado.** Decisão atribuída a ministro cujo nome não confere com a composição do tribunal. O art. 647-A do CPP invocado em duas peças como base para habeas corpus de ofício, quando a redação vigente trata de prioridade de tramitação (o de ofício é o art. 654, §2º). "Excesso de Acusação por Fragmentação de Conduta" e "Litispendência Imprópria" em negrito como institutos consagrados, num parecer que não cita um único dispositivo nem um único julgado. `10ª ed. rev., atual. e ampl. As Nulidades no processo Penal` — edição e título invertidos. "Deconstrução Técnica" como rubrica da casa.

**Fecho.** A lista trabalhista padrão de documentos aparece idêntica num caso de acidente de trabalho de prestador de serviço, em que a discussão era responsabilidade civil do tomador — e traz, fossilizado em duas fichas, o erro "Ficha de registro **da** funcionário". Numa ficha, as `PERGUNTAS PARA O CLIENTE` indagam sobre duas empresas que não aparecem em nenhum outro ponto do arquivo. Outra repete "conversão do pedido de demissão em rescisão indireta" duas vezes e arrola verbas como se fossem teses. Um parecer não registra um único ponto fraco da própria tese. Peça datada em Palmas/TO assinada só com OAB/SP.

**Sobre a variante de grande volume.** Uma ficha cível abandona o formulário depois de `RESUMO DOS FATOS` e vira relatório de leitura em 15 "PARTES" numeradas por lote de páginas — de modo que o mesmo assunto reaparece espalhado e só é reunido na `ANÁLISE CONSOLIDADA` do fim. Estrutura ditada pelo lote de leitura, não pela lógica do caso: o leitor precisa chegar ao fim para ter a informação organizada.
