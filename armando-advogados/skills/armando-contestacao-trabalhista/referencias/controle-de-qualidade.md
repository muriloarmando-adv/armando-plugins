# Controle de qualidade — contestação trabalhista

Passagem obrigatória antes de entregar. Os defeitos marcados com ⚠️ foram **contados no acervo de 64 contestações do escritório**, não são hipóteses. O número entre parênteses é quantas peças protocoladas trazem o erro.

---

## 0. Por que checklist sozinho não resolve

O acervo é a prova. Toda contestação da casa passou por revisão humana antes do protocolo, e mesmo assim **39 peças remetem ao art. 333 do CPC — dispositivo revogado em 2015**. Não é desatenção pontual: é a assinatura de uma classe de erro que a leitura humana estruturalmente não pega.

O olho lê o que espera ler. Boilerplate correto na forma e errado no conteúdo atravessa qualquer número de revisões, porque o revisor lê a peça procurando o que é novo — e o erro está justamente no que é velho.

Daí a divisão de trabalho deste documento:

| Classe de falha | Por que a leitura falha | Trava que efetivamente prende |
|---|---|---|
| **A. Referência legal revogada** | ninguém relê o boilerplate | grep determinístico em lista negra |
| **B. Resíduo de reaproveitamento** | "parece certo" porque *era* certo na peça anterior | aritmética e regex |
| **C. Identificador errado** | humano não confere dígito verificador | registro fechado + validador |
| **D. Módulo órfão / pedido sem defesa** | o redator não relê a inicial ao podar | mapa pedido→módulo declarado antes de redigir |
| **E. Inversão de sentido** | frase gramaticalmente perfeita, juridicamente suicida | verificação estrutural do fecho + leitura dirigida |
| **F. Tese superada** | o redator não sabe que não sabe | nota de risco embutida no módulo |
| **G. Perda de prazo** | — | trava na apuração prévia |

As classes A, B, C e D são automatizáveis e estão no script. E é semiautomatizável. F e G são humanas e ficam nos itens 7 e 8.

---

## 1. Varredura automática — rode primeiro

```powershell
& "<scripts>\revisar-contestacao.ps1" -Path "<peça>" -Pedidos 'lista','dos','pedidos'
& "<scripts>\extenso.ps1"                 -Path "<peça>"
& "<scripts>\validar-identificadores.ps1" -Path "<peça>"
```

| Script | O que apanha |
|---|---|
| `revisar-contestacao.ps1` | lei revogada; resíduo de reaproveitamento; gênero misturado; OAB trocada; módulo de mérito sem fecho de improcedência; alínea e romano saltados; requisitos formais da defesa; módulo órfão e pedido sem defesa |
| `extenso.ps1` | cada par `R$ X (extenso)` conferido dígito a dígito |
| `validar-identificadores.ps1` | dígito verificador de CPF, CNPJ e número CNJ (mod 97, ISO 7064) |

Código de saída `1` quando há achado ALTA. **Achado ALTA é impedimento de protocolo.**

**O que os scripts não fazem:** dizer se a ementa existe, se o precedente se aplica, se a tese fecha, se a defesa é compatível com os documentos da empresa, se o preposto vai sustentar em audiência o que a peça afirma. Isso é dos itens 5 a 8.

---

## 2. Classe A — referência legal revogada

Lista negra do script. Cada item foi encontrado no acervo ou é vizinho direto de um que foi.

| Referência | Situação | Peças |
|---|---|---|
| ⚠️ **art. 333 do CPC** | revogado; o ônus da prova é o art. 373 do CPC/2015 | **39** |
| ⚠️ **Súmulas 219 e 329 do TST** para limitar honorários | honorários *assistenciais*, anteriores ao art. 791-A | **42** |
| ⚠️ **OJ 348 da SBDI-1** | mesma origem; não é teto do art. 791-A | 42 |
| **art. 384 da CLT** | revogado pela Lei 13.467/2017 | — |
| **§§1º e 3º do art. 477** (homologação sindical) | revogados pela Lei 13.467/2017 | — |
| **"declaração de pobreza"** | terminologia pré-Reforma; hoje é o art. 790, §§3º e 4º | — |

**Regra permanente:** antes de repetir qualquer súmula, OJ ou artigo colhido de peça anterior, confira a vigência. Um verbete superado numa peça se propaga para todas as seguintes por cópia. Foi assim que o art. 333 chegou a 39.

---

## 3. Classe B — resíduo de reaproveitamento

| Padrão | O que é | Peças |
|---|---|---|
| ⚠️ `Vejamos:` seguido de nada | a imagem ou o print não foi colado | **32** |
| ⚠️ mistura de `o Reclamante` e `a Reclamante` | gênero herdado da peça anterior | **41** |
| ⚠️ `não comprovem os fatos` | deve ser *comprovam* | **17** |
| ⚠️ `Executada` / `Executado` | resíduo de peça de execução em fase de conhecimento | **8** |
| ⚠️ extenso herdado | `R$ 62.798,65 (dezenove mil e trinta e seis reais…)` | 1 |
| ⚠️ algarismo corrompido | `R$3.4150,50` para três mil, quatrocentos e quinze reais | 1 |
| ⚠️ alíneas saltando `b)` → `f)` | módulo excluído sem renumerar | 4 |
| ⚠️ `Nesses termos, pede deferimento` no meio da peça | fecho de módulo colado | 2 |
| ⚠️ `AO DOUTO JUÍZO DA VARA 2ª VARA DO TRABALHO` | cabeçalho remendado | 3 |
| ⚠️ data de admissão repetida como data de dispensa | | 1 |

O par valor/extenso é o caso didático. `R$ 19.036,86 (dezenove mil e trinta e seis reais…)` está numa peça, e `R$ 62.798,65 (dezenove mil e trinta e seis reais…)` está em outra. O algarismo foi atualizado, o extenso não. Nenhuma leitura pega isso; a aritmética pega sempre.

---

## 4. Classe C — identificador de advogado

**Registro fechado.** Assinar sob inscrição alheia é o defeito mais grave do acervo.

| Advogado | OAB |
|---|---|
| Henrique Rocha Armando | OAB/TO 10.167 |
| Sandro Henrique Armando | OAB/TO 11.459-A · **OAB/SP 128.510** |
| Lucas Almeida Monteiro | OAB/DF 70.224 |
| Maiane Lukarine S. do Carmo | OAB/TO 11.661 |
| Bruno Otávio Pereira Alves | OAB/TO 4.893 |
| Raquel Xavier Mendes | OAB/DF 70.204 |
| Quintiliana Janis Cardoso Marques | OAB/TO 9.272 |

⚠️ **Em 16 peças o Dr. Lucas assina sob OAB/TO 10.167 — registro do Dr. Henrique.**

⚠️ **OAB/SP do Dr. Sandro: 52 peças trabalhistas trazem 125.510; as cíveis trazem 128.510.** O script `revisar-inicial.ps1`, escrito antes desta skill, já declara **128.510** como o correto. É o que se adota aqui.

Atenção ao par **70.224 (Lucas) / 70.204 (Raquel)** — diferem em um dígito e trocam com facilidade.

---

## 5. Classe D — módulo órfão e pedido sem defesa

Erro de poda, e vai nas duas direções.

**Módulo sem pedido.** Tópico herdado de outra contestação. Custo: a defesa abre discussão que o reclamante não trouxe, e às vezes admite fato que ninguém alegou.

**Pedido sem módulo.** Custo muito maior: fato não impugnado é fato incontroverso (art. 341 do CPC). A defesa perde o pedido sem que ele tenha sido discutido.

A trava é procedimental e vem **antes** da redação: o mapa pedido→módulo do item 2 da SKILL.md. Depois, o script confere:

```powershell
& "<scripts>\revisar-contestacao.ps1" -Path "<peça>" -Pedidos 'rescisao indireta','insalubridade','dano moral','FGTS'
```

Sem `-Pedidos` o script apenas lista os módulos detectados e manda conferir um a um.

---

## 6. Classe E — inversão de sentido

A falha que nenhum regex lê e todo revisor deixa passar, porque a frase é gramaticalmente perfeita.

⚠️ Em *Anderson x Calcário Milenium*, no tópico de dano moral:

> "Verifica-se, por fim, **a pertinência** do pleito autoral consoante a indenização por dano moral, vez que, conforme demonstrado, a Reclamada não contribuiu ou concorreu sob qualquer forma para o acometimento do dano alegado."

A segunda metade nega; a primeira concede. Faltou o "im-" de *impertinência*. A peça foi protocolada assim.

**Trava estrutural:** todo módulo de mérito da casa fecha pedindo improcedência. Módulo que não fecha assim é anômalo — e o script sinaliza. Não porque leia sentido, mas porque lê estrutura.

**Leitura dirigida — o passo humano que não se pula.** Depois do script, releia **apenas a última frase de cada módulo de mérito**, em sequência, ignorando o resto. São 10 a 20 frases. Cada uma tem de negar alguma coisa. Qualquer frase que conceda, admita ou reconheça é candidata a inversão.

Outras inversões a procurar na mesma passada:
- "a Reclamada **reconhece**" onde se queria "não reconhece"
- "**houve** exposição a agente insalubre" onde se queria "não houve"
- "**faz jus**" onde se queria "não faz jus"
- pedido subsidiário formulado como principal
- "requer a procedência" no rol de pedidos

---

## 7. Classe F — falta de expertise, e o que fazer a respeito

O redator não sabe o que não sabe. Nenhum script cobre isso. Três métodos, em ordem de eficácia.

### 7.1 Ancorar no acervo, nunca na memória

Precedente, redação de tese e fórmula de pedido saem de `referencias/precedentes.md` e `referencias/modulos.md`, colhidos das peças reais do escritório. Tese sem julgado ali: acione o agente `jurisprudencia` (Jus IA). **Nunca escreva ementa de memória** — número, relator, órgão e data têm de ser reais.

### 7.2 Marcar a tese de risco no próprio módulo

Onde o padrão da casa é discutível, o módulo carrega a advertência. O redator não precisa saber de antemão: ele encontra o aviso no caminho. Os três riscos vivos:

**(a) Súmulas 219/329 e OJ 348 para limitar honorários.** Em 42 peças. São verbetes de honorários assistenciais, anteriores ao art. 791-A. Não limitam a sucumbência da Reforma; invocá-los enfraquece a peça e sinaliza cópia. Suprimidos do modelo.

**(b) Honorários contra beneficiário da justiça gratuita.** A casa pede 15% em todas as 80 ocorrências do acervo, sem ressalva. O STF, na **ADI 5766**, declarou inconstitucional parte do art. 791-A, §4º, da CLT, que permitia satisfazer os honorários com créditos obtidos no próprio processo. Confirme o alcance atual antes de formular. Não é caso de suprimir o pedido — é caso de formulá-lo com a ressalva correta, sob pena de o juízo tratar o pedido como desatento à jurisprudência vinculante.

**(c) Valores dos pedidos como teto da condenação.** O art. 840, §1º, da CLT exige pedido certo, determinado e com indicação de valor, e a casa sustenta que isso limita a condenação. Há entendimento consolidado em sentido contrário, tratando os valores como mera estimativa quando a inicial assim ressalva. Sustente a tese — é defensável e favorece o cliente —, mas saiba que é contestada e **não a apresente ao cliente como garantia**.

### 7.3 Não deixar a defesa contradizer a prova

A contestação afirma fatos que os documentos da empresa têm de sustentar e que o preposto vai repetir em audiência. Antes de fechar, confronte:

- afirmou jornada regular? o cartão de ponto anexo bate?
- afirmou fornecimento de EPI? há ficha assinada?
- afirmou pagamento em dia? o extrato mostra?
- negou o grupo econômico? os contratos sociais anexos sustentam endereço e quadro societário distintos?
- alegou abandono? há notificação com AR?

Afirmação sem lastro documental é pior do que silêncio: entrega ao reclamante a contradição pronta.

---

## 8. Classe G — prazo

A contestação trabalhista se oferece **até a audiência** (art. 847 da CLT), com apresentação eletrônica pelo PJe-JT. Confirme a data da audiência **na apuração prévia**, antes de qualquer redação. Peça perfeita fora do prazo é revelia.

Se a empresa está em recuperação judicial, confira também o efeito sobre atos de constrição (art. 6º da Lei 11.101/2005) e inclua a preliminar própria.

---

## 9. Requisitos formais — conferência final

- [ ] Endereçamento com vara, cidade e UF corretos
- [ ] Número dos autos conferido pelo dígito verificador
- [ ] Preâmbulo com remissão ao **art. 847 da CLT**
- [ ] `CONTESTAÇÃO` centralizado e isolado entre preâmbulo e "aos termos da Reclamação"
- [ ] Impugnação especificada de cada fato (art. 341 do CPC)
- [ ] Todo módulo de mérito fechando em improcedência
- [ ] Rol de pedidos com alíneas contíguas
- [ ] Protesto por provas, com perícia quando houver insalubridade, periculosidade ou doença
- [ ] Prequestionamento
- [ ] Declaração de autenticidade — art. 830 da CLT e art. 425, IV, do CPC
- [ ] Fecho com local e data
- [ ] Assinaturas com OAB conferida no registro do item 4
- [ ] Nenhum `{{placeholder}}` e nenhuma nota do modelo sobrevivendo
- [ ] Todo `Vejamos:` com a imagem correspondente colada
