# Acordo de sócios

O escritório tem **prática consolidada** de acordo de sócios — Casa 63, Riviera SPE, Viva Construções, Construtora M21, Crédito Fácil Araguaína, On Flow Mídia, Mundo Diesel MA, Agricomex Brazil Trade, SPE Vértice, Pier 14, Gastrocentro — e mantém um **modelo em branco**: `Minuta - Acordo de Sócios - Completo` (Drive `1QTpS4qMsuL1TRWjNqVezWIrXX5jSfZ_w`), redigido sobre a "SOCIEDADE XPTO LTDA".

Este arquivo descreve esse modelo, o que ele resolve e **os cinco defeitos que ele carrega** — todos verificados no arquivo, todos capazes de viajar para a próxima minuta por copiar-e-colar.

## 1. Por que existe, e o que não pode entrar nele

O contrato social é público, arquivado na Junta, e a Junta faz exigência sobre o que não entende. O acordo de sócios é **privado**, arquivado na sede da sociedade, e comporta o que o contrato social não comporta bem: preço, fórmula de avaliação, tag along, drag along, opção de compra, não concorrência com raio e prazo, política de dividendos, governança fina.

Base: art. 1.053, parágrafo único, do Código Civil (regência supletiva pela LSA) combinado com o **art. 118 da Lei 6.404/1976**, que o modelo invoca expressamente no preâmbulo.

**Divisão de trabalho:**

| Vai no contrato social | Vai no acordo de sócios |
|---|---|
| quadro societário, objeto, sede, administração, quóruns legais | preço e fórmula de apuração de haveres |
| preferência na cessão (existência do direito) | procedimento detalhado da preferência, prazos, sobras |
| exclusão por justa causa (art. 1.085 exige previsão contratual) | tag along, drag along, opção de compra |
| exercício social, distribuição proporcional | política de distribuição, reserva, distribuição desproporcional |
| foro | não concorrência, não aliciamento, confidencialidade, arbitragem |

**O contrato social precisa reconhecer o acordo.** Sem isso, o administrador não é obrigado a observá-lo. A consolidação Lawletter traz a cláusula certa: *"Este Contrato Social está vinculado ao Acordo de Sócios assinado pelos sócios, devendo ser observado na íntegra pelos sócios e sucessores, especialmente para os atos de administração e em caso de resolução de conflitos."*

**Eficácia.** Arquivado na sede, o acordo vincula a sociedade (art. 118, *caput*, LSA). O voto proferido contra o acordo **não é computado** (art. 118, § 8º) — e o modelo da casa reproduz isso na Cláusula 5.4. E comporta **execução específica** (art. 118, § 3º, LSA; art. 501 do CPC), o que a Cláusula 17.2 declara expressamente.

## 2. Estrutura das 17 cláusulas

| # | Cláusula | O que resolve |
|---|---|---|
| 1ª | **Definições** | tabela remissiva de todo termo definido, com a cláusula onde é definido |
| 2ª | **Objeto do Acordo** | tabela de participação + extensão a quotas futuras (transformação, cisão, fusão, aumento, conversão) + limite de diluição |
| 3ª | **Objeto Social da Sociedade** | trava o ramo de atuação |
| 4ª | **Administração** | administração conjunta, rol de poderes, alçada financeira, procurações |
| 5ª | **Deliberações de Sócios** | matérias reservadas com quórum próprio; voto contra o acordo é nulo |
| 6ª | **Política de Distribuição de Lucros** | reserva, percentual distribuível, distribuição desproporcional |
| 7ª | **Transferências de Quotas / Admissão de Terceiros** | vedação geral, ônus, controle, requisitos do entrante, morte e incapacidade permanente |
| 8ª | **Direito de Preferência** | notificação da oferta, prazo, sobras, prazo para vender a terceiro |
| 9ª | **Direito de Venda Conjunta (Tag Along)** | minoritário acompanha a venda do majoritário |
| 10ª | **Obrigação de Venda Conjunta (Drag Along)** | majoritário arrasta o minoritário na venda |
| 11ª | **Opção de Compra** | constrição de quotas (penhora/arresto) e sócio inadimplente |
| 12ª | **Aporte de recursos / Sócio em Mora** | chamada de capital, diluição, opção de compra do inadimplente |
| 13ª | **Não concorrência e não aliciamento** | durante e após a participação |
| 14ª | **Confidencialidade** | inclusive instruindo os representantes na administração |
| 15ª | **Vigência** | prazo mais longo entre X anos e a permanência no quadro |
| 16ª | **Notificações** | forma, endereços, comprovação de recebimento |
| 17ª | **Disposições Gerais** | execução específica, cessão do acordo, independência, correção monetária, mediação, arbitragem, foro |

## 3. Os cinco defeitos do modelo em branco

Verificados no arquivo em 08/09/2026. **Corrija todos antes de usar o modelo.**

### 3.1 Foro de Recife/PE no modelo da casa

> `17.11. As Partes neste ato elegem o foro da Cidade de Recife/PE, Brasil, com a renúncia expressa de qualquer outro, por mais privilegiado que possa ser.`

O escritório é de Palmas/TO e atende Tocantins, Goiás, Pará, Distrito Federal. **O foro de Recife veio do modelo de origem e ficou.** É o defeito mais perigoso do conjunto: um foro errado num acordo assinado desloca todo o litígio societário para outro estado. `scripts/conferir-instrumento.ps1` sinaliza todo foro eleito por esse motivo.

### 3.2 Numeração que regride dentro da Cláusula 11ª

Os itens vão `11.1 … 11.7, 11.8`, então **`10.9`**, e voltam para `11.10`. O item 10.9 é, na verdade, o 11.9 — e ele trata de matéria grave (outorga de mandato em causa própria para assinar a alteração contratual sem o sócio ausente, arts. 684 e 685 do Código Civil). Remissão futura a "item 11.9" não encontra nada.

### 3.3 Auto-remissão à cláusula errada

> `7.3. Observados os eventuais impedimentos legais para a transferência das Quotas e o disposto nesta Cláusula 6ª, …`

Está **dentro da Cláusula 7ª** e remete a "esta Cláusula 6ª". Sobra de uma versão em que transferências eram a cláusula 6.

### 3.4 Drag Along com o texto do Tag Along

A Cláusula 10ª é a **Obrigação** de Venda Conjunta (drag along). Seu item 10.3 diz:

> `10.3. O exercício do Direito de Venda Conjunta será irretratável e irrevogável…`

É cópia literal do item 9.3, que trata do **Direito** (tag along). O item operativo da cláusula 10 nomeia o instituto errado. Quem for executar o drag along encontra, no dispositivo, o nome do direito oposto.

### 3.5 Lucro bruto e lucro líquido na mesma cláusula

A Cláusula 6.1 abre dizendo que **o lucro líquido** será distribuído "observadas as seguintes disposições" e a alínea (a) manda destinar "o percentual de X% **do lucro bruto**" para reserva. As duas grandezas não se somam: reservar percentual do lucro bruto dentro da distribuição do lucro líquido não tem operação aritmética definida. Escolha uma base e mantenha.

## 4. Pontos de redação que exigem decisão, não cópia

- **Quórum das matérias reservadas (5.2)** — o modelo traz `[-INSERIR-]%`. Defina olhando o quadro societário real: 75% em sociedade 55/25 dá veto ao segundo; "maioria" entrega tudo ao primeiro.
- **Prazo da preferência (8.3)** — `[-INSERIR-]` dias. O contrato social da casa usa 30 dias; mantenha coerência entre os dois instrumentos, ou um contradiz o outro.
- **Limite de diluição (2.4.1)** — quanto a participação conjunta dos signatários pode encolher num aumento de capital. É a proteção central do minoritário em rodada de aporte.
- **Incapacidade Permanente (7.7.1)** — o modelo a define por laudo de "pelo menos dois médicos devidamente licenciados". Diga quem os indica e como se resolve divergência.
- **Interveniente anuente cônjuge** — o modelo prevê a esposa do Sócio 2 assinando como anuente "especificamente no tocante à apuração de haveres e liquidação de quotas". Confira o regime de bens antes: em comunhão, a anuência não é cortesia, é requisito.
- **Não concorrência (13ª)** — sem prazo, território e objeto delimitados, é inexigível. O modelo deixa os três em branco.
- **Vigência (15ª)** — "o prazo mais longo entre [X] anos ou o período em que detiverem participação". Preencha o X.
- **Mediação e arbitragem (17.9 e 17.10)** — se optar por arbitragem, a cláusula precisa de instituição, sede, número de árbitros, idioma e custas; e o foro da 17.11 passa a ser apenas residual (medidas de urgência e execução da sentença arbitral). Diga isso, ou as duas cláusulas brigam.

## 5. Antes de entregar

```bash
powershell -NoProfile -ExecutionPolicy Bypass -File "scripts/conferir-instrumento.ps1" "acordo.docx"
```

O script identifica o instrumento como acordo de sócios e **não** cobra dele o que só o registro na Junta exige (declaração de desimpedimento, CNAE). Continua conferindo: placeholders, numeração, remissões internas, extenso, grafia divergente de nomes, foro e coexistência de foro com arbitragem.

Depois, o crivo humano de `controle-de-qualidade.md` — em especial a varredura de antinomias, que é onde os defeitos 3.3 e 3.4 acima moram.
