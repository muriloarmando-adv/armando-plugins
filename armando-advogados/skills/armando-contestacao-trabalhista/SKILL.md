---
name: armando-contestacao-trabalhista
description: Redige contestação em reclamação trabalhista no padrão do escritório Armando Advogados — preâmbulo do art. 847 da CLT, síntese e realidade dos fatos, preliminares da casa (inépcia, valor da causa, gratuidade, compensação, limites da lide), mérito montado por módulos conforme os pedidos da inicial, pedido contraposto, honorários do art. 791-A e bloco de assinaturas. Use SEMPRE que o usuário pedir para "fazer a contestação", "contestar a reclamatória", "defesa trabalhista", "responder a reclamação", "peça de defesa na Vara do Trabalho", "impugnar os pedidos do reclamante", "contestação da empresa", "defender a empresa no processo trabalhista", ou entregar a inicial trabalhista para resposta — mesmo que não diga "contestação" ou "padrão do escritório". Para réplica ou impugnação à contestação, esta skill não serve. Para petição inicial, use `armando-peticao-inicial`; para outras peças, apenas `armando-timbrado`.
---

# Contestação Trabalhista — Padrão Armando Advogados

Padrão extraído do **acervo integral de contestações do Drive: 64 peças** lidas por inteiro em setembro de 2026 — 57 trabalhistas, 6 cíveis e 1 sem número de autos. Não é amostra.

Clientes recorrentes: **HM Cirúrgica** e o grupo JVMED/Muriel Santos Melo (26 peças, empresa em recuperação judicial), **Construtora Porto** (7), **Fourmaq** (4), MaxPec, E&J/T&J, Frigotins, Calcário Milenium, Casa Fama, Agro JAN. Foro dominante é o **TRT-10** (Palmas, varas 0801 e 0802; Gurupi, 0821), com peças também no TRT-8, TRT-11, TRT-16, TRT-17 e TRT-18.

A defesa da casa é **uniforme na moldura e modular no mérito**. O preâmbulo, as cinco preliminares de núcleo, o ônus da prova, os honorários, a impugnação aos documentos e o fecho são sempre os mesmos. O que muda é quais módulos de mérito entram — e isso é ditado exclusivamente pelo rol de pedidos da inicial.

---

## 1. Apuração prévia obrigatória

Não redija sem estas respostas. Pergunte em bloco, de uma vez:

1. **Prazo e audiência.** A contestação trabalhista se oferece até a audiência (art. 847 da CLT). No PJe-JT, o costume é protocolar antes. **Qual a data da audiência?** Sem isso não se sabe se há peça a fazer ou se o prazo já correu.
2. **Quem é a reclamada** que representamos, e se há litisconsórcio. Cliente recorrente: procure no Drive antes de perguntar.
3. **A petição inicial** — o arquivo. Dela saem o rol de pedidos, a jornada declinada, as datas e o valor da causa.
4. **Os documentos da empresa**: CTPS, contrato de trabalho, ficha de registro, controles de ponto, recibos, extrato de FGTS, fichas de EPI, ASO, TRCT.
5. **A versão da empresa** sobre cada fato controvertido. A defesa não se escreve só com direito.
6. **A empresa está em recuperação judicial?** Muda preliminar e pedido.
7. **Quantos empregados tem o estabelecimento?** Abaixo de 20, o art. 74, §2º, da CLT dispensa controle de ponto — e isso vira tese.

**Nunca invente** número de autos, CNPJ, data, valor, número de OAB ou de recuperação judicial. Campo não apurado entra como `[......]` e a pendência vai listada ao final da entrega.

**Nunca invente jurisprudência.** `referencias/precedentes.md` traz a biblioteca colhida das próprias peças do escritório — use-a. Para tese sem julgado ali, acione o agente `jurisprudencia` (Jus IA). Nunca fabrique ementa, número de recurso ou relator.

---

## 2. O passo que evita o erro mais caro: mapa pedido → módulo

Antes de escrever uma linha, **enumere os pedidos da inicial e associe cada um a um módulo**. Escreva esse mapa e mostre ao usuário. Ele governa a peça inteira.

| Pedido na inicial | Módulo da defesa |
|---|---|
| rescisão indireta | III – Inexistência de falta grave |
| horas extras | III – Jornada e horas extras |
| … | … |

Duas regras de mão dupla, e as duas são fatais:

- **Módulo sem pedido correspondente = excluir.** Um tópico herdado de outra contestação abre discussão que o reclamante não trouxe. No acervo isso acontece: peças com módulo de insalubridade em processo sem pedido de insalubridade.
- **Pedido sem módulo correspondente = defesa faltando.** Fato não impugnado é fato incontroverso (art. 341 do CPC). É o erro mais caro que uma contestação pode ter.

O script `revisar-contestacao.ps1 -Pedidos '...'` confere as duas direções automaticamente. Rode-o com a lista.

---

## 3. Arquitetura

```
AO DOUTO JUÍZO DA [Nº]ª VARA DO TRABALHO DE [CIDADE]/[UF]

PROCESSO Nº / RECLAMANTE / RECLAMADA

[PREÂMBULO — razão social + "já devidamente qualificada nos autos do processo em
 epígrafe, por intermédio de seu advogado (procuração anexa), vem à presença de
 Vossa Excelência, nos moldes do artigo 847 da CLT, oferecer"]

                        CONTESTAÇÃO                      ← centralizado, isolado

[aos termos da Reclamação Trabalhista movida por NOME, o que passa a fazer pelas
 razões e fundamentos jurídicos a seguir expostos.]

I    – SÍNTESE E REALIDADE DOS FATOS
II   – PRELIMINARMENTE          ← núcleo: II.1 a II.5; modulares: II.6 a II.9
III  – QUANTO AO MÉRITO         ← inteiramente modular, ver referencias/modulos.md
IV   – DO PEDIDO CONTRAPOSTO    ← só com rescisão indireta
V    – DA LITIGÂNCIA DE MÁ-FÉ   ← só com inverdade demonstrável
VI   – DO ÔNUS DA PROVA
VII  – DOS HONORÁRIOS DE SUCUMBÊNCIA
VIII – DA IMPUGNAÇÃO AOS DOCUMENTOS JUNTADOS COM A EXORDIAL
IX   – DOS PEDIDOS

[protesto por provas] [prequestionamento] [art. 830 da CLT] [fecho] [assinaturas]
```

As preliminares de núcleo, que entram em toda contestação: **inépcia da inicial** (38 peças), **impugnação à gratuidade** (39), **compensação e dedução** (38), **incorreção do valor da causa** (35) e **limites da lide** (32).

O catálogo completo — 32 módulos, com quando ligar cada um, a redação-âncora da casa e o fecho obrigatório — está em `referencias/modulos.md`. As variáveis a preencher, em `referencias/variaveis.md`.

---

## 4. Regra de fecho de cada módulo de mérito

**Todo módulo de mérito termina pedindo a improcedência do pedido que enfrenta.** Não é estilo: é a trava contra inversão de sentido.

Há peça no acervo — *Anderson x Calcário Milenium* — que, no tópico de dano moral, escreve "verifica-se **a pertinência** do pleito autoral consoante a indenização por dano moral". Concede exatamente o que a defesa pretendia negar. O parágrafo passou por revisão humana e foi protocolado.

Fórmulas aceitas: *improcede* · *deve ser julgado improcedente* · *requer-se o indeferimento* · *não prospera* · *não merece acolhimento* · *resta indevido* · *deve ser afastado* · *devem ser desconsiderados*.

O script verifica isso módulo a módulo e manda ler palavra por palavra o que não fechar.

---

## 5. Gerar em papel timbrado

A peça sai em `.docx` no timbrado da casa pela skill **`armando-timbrado`** — Book Antiqua 12, entrelinha 1,5, 8 pt entre parágrafos, justificado, recuo de 1,5 cm. Não reproduza aqui o procedimento: carregue aquela skill.

Modelo-base pronto, com os 32 módulos e as notas de conferência: `assets/modelo-contestacao.md`. Copie, apague o que não se aplica, **renumere** e preencha.

---

## 6. Controle de qualidade — obrigatório antes de entregar

```powershell
& "<scripts>\revisar-contestacao.ps1" -Path "<peça>" -Pedidos 'rescisao indireta','insalubridade','dano moral'
& "<scripts>\extenso.ps1"                 -Path "<peça>"
& "<scripts>\validar-identificadores.ps1" -Path "<peça>"
```

> A pasta dos scripts: quando esta skill carrega, o prompt informa o **diretório-base** dela. Tente, nesta ordem, `<base>/scripts` e `<base>/../../scripts` — no chat a pasta vem dentro da skill; no plugin instalado, na raiz. Saindo vazio, **pare e diga que não localizou os scripts**.

Saída com código `1` quando há achado ALTA. **Achado ALTA é impedimento de protocolo.**

O que os scripts cobrem e o que não cobrem, mais a lista de leitura dirigida que nenhum script substitui, está em `referencias/controle-de-qualidade.md`. Passe por ela.

---

## 7. Teses de risco — leia antes de repetir o boilerplate da casa

Três pontos em que o padrão do escritório é discutível ou está desatualizado. `referencias/controle-de-qualidade.md` desenvolve cada um.

1. **Súmulas 219 e 329 do TST + OJ 348 da SBDI-1** para limitar honorários — em 42 das 64 peças. São verbetes de honorários *assistenciais*, anteriores ao art. 791-A. Não limitam a sucumbência da Reforma. Suprimidas do modelo.
2. **Honorários contra beneficiário da justiça gratuita** — pedidos a 15% em todas as 80 ocorrências do acervo, sem ressalva. O STF, na **ADI 5766**, declarou inconstitucional parte do art. 791-A, §4º, da CLT. Confira o alcance atual antes de formular o pedido; não é caso de suprimir, e sim de formular com a ressalva correta.
3. **Valores dos pedidos como teto da condenação** (art. 840, §1º) — a casa sustenta que vinculam. Há entendimento consolidado em sentido contrário, tratando-os como estimativa quando a inicial assim ressalva. Sustente a tese, mas sabendo que é contestada, e não a apresente ao cliente como certeza.

Antes de repetir qualquer súmula ou OJ do acervo, **confira a vigência**. Verbete cancelado ou superado numa peça se propaga para as próximas por cópia — foi exatamente assim que o art. 333 do CPC/1973 chegou a 39 peças.

---

## 8. Não confundir

| Situação | Skill |
|---|---|
| Contestar reclamação trabalhista | **esta** |
| Réplica / impugnação à contestação | nenhuma — só `armando-timbrado` |
| Petição inicial | `armando-peticao-inicial` |
| Analisar os autos antes de decidir a estratégia | `armando-analise-processo` |
| Ler o PDF do processo | `armando-pdf-markdown` |
| Gerar o .docx no timbrado | `armando-timbrado` |
| Buscar precedente novo | agente `jurisprudencia` |
