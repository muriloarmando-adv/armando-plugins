# Plugins — Armando Advogados

Marketplace interno do escritório. Distribui as skills da casa para todo mundo, com versionamento:
quando uma skill melhora aqui, todos recebem a melhoria.

## Como instalar (cada colega roda uma vez)

```
/plugin marketplace add <ORG>/armando-plugins
```

```
/plugin install armando-advogados@armando-advogados
```

Depois disso, as skills abaixo passam a estar disponíveis em qualquer sessão.

## O que vem no plugin

| Skill | Para que serve |
|---|---|
| `armando-analise-contrato` | Analisa contrato recebido de terceiro. Modo 1: análise inicial cláusula a cláusula, com página dispositiva ao final. Modo 2: memorando de cotejo quando a contraparte devolve a minuta alterada. |
| `armando-elaborar-contrato` | Redige minuta nova no padrão da casa — preâmbulo, cláusulas numeradas, bloco de disposições gerais, foro com renúncia. |
| `armando-timbrado` | Gera o `.docx` em papel timbrado, Book Antiqua 12, entrelinha 1,5, 8 pt entre parágrafos. |
| `armando-naji-tarefa` | Monta o card de tarefa no template oficial do NAJI. |

Vai junto também o agente **`jurisprudencia`** (`agents/jurisprudencia.md`), que pesquisa precedentes
no Jus IA e é acionado pela skill de análise para embasar tese, e o **`scripts/pdftext.ps1`**, que
extrai texto de PDF em máquina Windows sem Python. Como vêm dentro do plugin, o colega não precisa
copiar nada para `~/.claude/agents` nem para `~/.claude/tools` — é o ganho sobre a distribuição
manual por Drive.

## Atualizando as skills

Edite os arquivos em `armando-advogados/skills/`, suba a `version` no
`armando-advogados/.claude-plugin/plugin.json` e no `.claude-plugin/marketplace.json`, e faça push.
Os colegas recebem a atualização no próximo `/plugin marketplace update`.

## Instalação automática (opcional)

Para não depender de cada um rodar os comandos, coloque no `.claude/settings.json` do repositório de
trabalho do escritório:

```json
{
  "extraKnownMarketplaces": {
    "armando-advogados": {
      "source": { "source": "github", "repo": "<ORG>/armando-plugins" }
    }
  },
  "enabledPlugins": {
    "armando-advogados@armando-advogados": true
  }
}
```

Em plano Team/Enterprise, o mesmo pode ser empurrado pelo admin via managed settings, valendo para a
organização inteira sem ninguém instalar nada.
