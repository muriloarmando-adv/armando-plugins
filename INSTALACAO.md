# Instalação — plugin `armando-advogados`

O repositório é **privado**, em `github.com/muriloarmando-adv/armando-plugins`.

**`muriloarmando-adv` é uma conta pessoal, não uma organização.** Consequência prática: não basta o
colega "estar no GitHub do escritório" — cada um precisa ser convidado como **colaborador do
repositório**, um a um, e aceitar o convite por e-mail.

Em **Settings → Collaborators → Add people**, convide cada advogado pelo usuário do GitHub ou pelo
e-mail. Acesso de **Read** basta. Enquanto o convite não for aceito, o plugin não carrega na máquina
daquele colega — e o sintoma é a skill simplesmente não existir, sem mensagem de erro.

Migrando um dia para uma organização, os convites individuais deixam de ser necessários e o
Caminho A abaixo passa a valer para todo mundo de uma vez.

---

## Caminho A — admin instala para o escritório inteiro (recomendado)

Vale para plano **Team ou Enterprise**. Ninguém precisa rodar comando: o plugin chega instalado
para todo mundo, e as atualizações também.

No console de administração da Anthropic, em **Admin Settings → Claude Code → Managed settings**,
publique:

```json
{
  "extraKnownMarketplaces": {
    "armando-advogados": {
      "source": {
        "source": "github",
        "repo": "muriloarmando-adv/armando-plugins"
      }
    }
  },
  "enabledPlugins": {
    "armando-advogados@armando-advogados": true
  }
}
```

**Atenção ao repositório privado.** Managed settings entrega a configuração, mas cada máquina ainda
precisa conseguir clonar o repo. Garanta que todos os advogados já tenham **aceitado o convite de
colaborador** e que o git esteja autenticado na máquina (GitHub CLI, credential manager ou chave
SSH). Se o clone falhar, o plugin simplesmente não carrega — e o sintoma é a skill "não existir",
sem erro visível.

---

## Caminho B — cada um instala na sua máquina

Dois comandos, uma vez só, em qualquer sessão do Claude Code:

```
/plugin marketplace add muriloarmando-adv/armando-plugins
```

```
/plugin install armando-advogados@armando-advogados
```

Para conferir se pegou: `/plugin` e procurar `armando-advogados` na lista de instalados.

---

## Mensagem pronta para mandar no grupo do escritório

> Pessoal, as skills do escritório para o Claude estão disponíveis. São oito:
>
> - **análise de processo em curso** — lê os autos, diz em que pé está, qual foi o último
>   movimento e o que vence primeiro, e entrega a ficha resumo no padrão da casa;
> - análise de contrato recebido de terceiro;
> - redação de minuta no padrão da casa;
> - contrato social, alteração e consolidação de limitada;
> - redação de petição inicial no padrão da casa;
> - geração de peça em papel timbrado;
> - card de tarefa do NAJI;
> - conversão de PDF em Markdown enxuto, que gasta uma fração dos tokens de ler o PDF direto.
>
> Rodem esses dois comandos uma vez, dentro do Claude Code:
>
> `/plugin marketplace add muriloarmando-adv/armando-plugins`
> `/plugin install armando-advogados@armando-advogados`
>
> Depois é só pedir normalmente — "analisa esse processo", "em que pé está o processo do fulano",
> "analisa esse contrato", "faz a minuta de locação", "entra com a monitória", "monta a tarefa no
> NAJI" — que a skill certa entra sozinha. Não precisa chamar pelo nome.

---

## Aviso para quem já tem as skills soltas em `~/.claude/skills`

Se a máquina já tiver as pastas `armando-*` dentro de `~/.claude/skills` (cópias antigas ou
junções para um clone local do repo), **elas vão conflitar com o plugin**: a mesma skill aparece
duas vezes, e não há garantia de qual versão o Claude usa.

Antes de instalar o plugin, apague ou renomeie essas pastas. O plugin passa a ser a única fonte.

---

## Atualizando depois

Editou uma skill? Suba a `version` no `armando-advogados/.claude-plugin/plugin.json` e no
`.claude-plugin/marketplace.json`, faça commit e push. Os colegas puxam com:

```
/plugin marketplace update armando-advogados
```
