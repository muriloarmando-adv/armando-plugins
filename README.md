# Plugins — Armando Advogados

Marketplace interno do escritório. Distribui as skills da casa para todo mundo, com versionamento:
quando uma skill melhora aqui, todos recebem a melhoria.

## Como instalar (cada colega roda uma vez)

```
/plugin marketplace add muriloarmando-adv/armando-plugins
```

```
/plugin install armando-advogados@armando-advogados
```

Depois disso, as skills abaixo passam a estar disponíveis em qualquer sessão.

## O que vem no plugin

| Skill | Para que serve |
|---|---|
| `armando-analise-processo` | Analisa processo judicial **já em curso** — lê os autos na ordem certa, fixa o último movimento e o prazo em curso, e entrega a FICHA RESUMO DO PROCESSO, o RESUMO PARA O CLIENTE, o PARECER ESTRATÉGICO ou a TRIAGEM DE PRAZO. Padrão extraído de 13 fichas do Drive e de 7 acervos completos de autos em PJe, PJe-JT, eSAJ e PJe híbrido. |
| `armando-analise-contrato` | Analisa contrato recebido de terceiro. Modo 1: análise inicial cláusula a cláusula, com página dispositiva ao final. Modo 2: memorando de cotejo quando a contraparte devolve a minuta alterada. |
| `armando-elaborar-contrato` | Redige minuta nova no padrão da casa — preâmbulo, cláusulas numeradas, bloco de disposições gerais, foro com renúncia. |
| `armando-contrato-social` | Contrato social, alteração e consolidação de sociedade limitada — preâmbulo apto a arquivamento, quóruns conferidos contra a Lei 14.451/2022, apuração de haveres, exclusão extrajudicial. |
| `armando-peticao-inicial` | Redige petição inicial no padrão da casa — endereçamento, preâmbulo, seções em romano, tutela de urgência, rol de pedidos, valor da causa e bloco de assinaturas. Padrão extraído de 21 iniciais do Drive. |
| `armando-timbrado` | Gera o `.docx` em papel timbrado, Book Antiqua 12, entrelinha 1,5, 8 pt entre parágrafos. |
| `armando-naji-tarefa` | Monta o card de tarefa no template oficial do NAJI. |
| `armando-pdf-markdown` | Converte PDF em Markdown enxuto antes de ler — remonta parágrafos, marca títulos e remove o carimbo repetido em toda página. Gasta uma fração dos tokens de ler o PDF direto. Não faz OCR. |

Em `scripts/` vão também as verificações mecânicas — `revisar-inicial.ps1` (resíduo de trabalho,
identificador divergente, numeração, requisitos do art. 319), `extenso.ps1` (confere cada par
`R$ X (extenso)` e gera o extenso avulso) e `validar-identificadores.ps1` (dígito verificador de
CPF, CNPJ e número CNJ). Aceitam `.docx`, `.md` e `.txt`, e saem com código `1` quando há achado
grave.

E o **`mapear-autos.ps1`**, motor da análise de processo: recebe os autos (`.md` do `pdf2md.ps1`,
ou o PDF direto) e devolve um mapa navegável — alerta de extrato vencido, números CNJ com dígito
verificador conferido, campos da capa, o índice oficial do sistema, as fronteiras de peça por
assinatura eletrônica, a linha do tempo com as datas futuras destacadas, os prazos mencionados e
os alertas de severidade ALTA. Serve para **não** ler 375 páginas: lê-se o mapa e abre-se só o que
importa, por faixa de linha. Ele localiza; não interpreta e não conta prazo.

Vai junto também o agente **`jurisprudencia`** (`agents/jurisprudencia.md`), que pesquisa precedentes
no Jus IA e é acionado pela skill de análise para embasar tese. Como vêm dentro do plugin, o colega não precisa
copiar nada para `~/.claude/agents` nem para `~/.claude/tools` — é o ganho sobre a distribuição
manual por Drive.

A leitura de PDF fica em `skills/armando-pdf-markdown/scripts/pdf2md.ps1`. O antigo
`scripts/pdftext.ps1` continua no repo por compatibilidade, mas está superado: devolvia uma palavra
por linha, perdia o conteúdo dos PDFs do PJe (que fica dentro de Form XObject) e travava em
arquivo grande.

## Atualizando as skills

Edite os arquivos em `armando-advogados/skills/`, suba a `version` no
`armando-advogados/.claude-plugin/plugin.json` e no `.claude-plugin/marketplace.json`, e faça push.
Os colegas recebem a atualização no próximo `/plugin marketplace update`.

**Antes do push, rode a conferência de `description`:**

```
armando-advogados\scripts\conferir-descricoes.ps1
```

A `description` do `SKILL.md` é o único texto que o modelo lê para decidir se a skill entra, e ela
tem **limite de 1024 caracteres**. Passando disso a skill é recusada no carregamento — e o sintoma
é ela simplesmente não existir, sem mensagem de erro. Já aconteceu com duas skills da casa sem que
ninguém percebesse. O script mede em caracteres e em bytes, cobra pelo maior dos dois (em português
a diferença chega a 40, por causa dos acentos) e sai com código `1` quando alguma estoura.

## Instalação automática (opcional)

Para não depender de cada um rodar os comandos, coloque no `.claude/settings.json` do repositório de
trabalho do escritório:

```json
{
  "extraKnownMarketplaces": {
    "armando-advogados": {
      "source": { "source": "github", "repo": "muriloarmando-adv/armando-plugins" }
    }
  },
  "enabledPlugins": {
    "armando-advogados@armando-advogados": true
  }
}
```

Em plano Team/Enterprise, o mesmo pode ser empurrado pelo admin via managed settings, valendo para a
organização inteira sem ninguém instalar nada.
