# Controle de qualidade

Os scripts pegam o que é mecânico. Esta lista pega o que não é. **Passe por ela antes de entregar.**

---

## 1. Os scripts

```
& "<scripts>\triar-carteira.ps1"           -Path "<planilha.csv>"
& "<scripts>\revisar-inicial.ps1"          -Path "<peça>"
& "<scripts>\extenso.ps1"                  -Path "<peça>"
& "<scripts>\validar-identificadores.ps1"  -Path "<peça>"
```

Localização da pasta: tente `<base>/scripts`, depois `<base>/../../scripts`. Vazio nos dois, **pare e diga que não localizou**.

Código de saída `1` = achado **ALTA** = **impedimento de protocolo**.

### O que `triar-carteira.ps1` cobre

- prescrição de 5 anos por vencimento, com sinalização de quem está **a menos de 12 meses** de prescrever (a coluna que faz o cliente agir)
- coerência do valor atualizado ≥ valor principal
- classificação de via pela espécie do título declarada
- status sugerido: `Ajuizar` / `Notificar` / `Triagem` / `Prescrito`
- agregados: totais, quanto prescreveu em reais e em percentual

### O que os scripts **não** cobrem

- **se o canhoto existe.** Nenhum script sabe olhar o PDF e ver se há assinatura. Só a conferência documento por documento resolve — e é o filtro 2 inteiro.
- **se a interrupção da prescrição se prova.** O script marca prescrito pela data; cabe a você procurar pagamento parcial e protesto antes de aceitar o veredito.
- **se o valor do cliente está certo.** Planilha de cliente vem suja. O script acusa atualizado < principal, mas não recalcula.
- **coerência entre a via escolhida e os artigos citados** na peça — é a trava do §6 do SKILL.md, e é leitura humana.

---

## 2. Leitura dirigida — nove conferências

### Na triagem

1. **Cada vencimento foi contado individualmente?** Contar do vencimento mais recente da carteira e aplicar a todos é o erro que salva crédito morto e mata crédito vivo. Um devedor com títulos de 2019 e 2024 tem os dois destinos na mesma linha.

2. **Procurou interrupção antes de declarar prescrito?** Pagamento parcial (art. 202, VI), protesto, reconhecimento por escrito. Na carteira Agroboi havia devedores marcados como prescritos com pagamento parcial recente documentado.

3. **O atualizado é maior que o principal em todas as linhas?** Onde não for, o dado está corrompido — Cleyber (4.478,60 → 1.075,31) e Jason (4.270,70 → 3.025,51) na planilha original. Não use número corrompido em peça nem em parecer.

4. **A observação diz *qual* documento falta?** "Triagem" sem dizer o que pedir devolve a bola ao cliente sem instrução. O acervo acerta nisso: *"Precisamos do envio da NF e canhoto; na pasta tem apenas boleto."*

### Na peça

5. **Os artigos correspondem à via?** Monitória: art. 700 e seguintes, **sem** o 778. Execução: arts. 783/784, **sem** o art. 44 do CC. Ambos os erros estão em duas peças cada no acervo.

6. **Os prazos correspondem à via?** Monitória: **15 dias** e **5%** (art. 701). Execução: **3 dias** (art. 829). Trocar é o erro de cópia mais provável depois dos artigos.

7. **Gênero e número do réu, em cada pedido.** No rol de onze pedidos da execução é onde os resíduos sobrevivem: "Requerida" para réu homem, "paguem" para executada singular. Leia pedido por pedido, não a peça inteira de corrida.

8. **A praça da assinatura é a comarca do endereçamento?** Endereçada a Miranorte e assinada em Palmas — está no acervo.

9. **Todo valor em algarismo tem o extenso, e os dois batem?** `extenso.ps1` confere. O valor da causa, o do mandado e o dos fatos têm de ser **o mesmo número** — atualizado, não nominal.

---

## 3. Antes de qualquer entrega

- [ ] Nenhum `[......]` sobrou sem constar da lista de pendências
- [ ] Nenhum identificador inventado — NF, chave de NF-e, CPF/CNPJ, cheque, agência, conta, comarca, OAB (`validar-identificadores.ps1`)
- [ ] Nenhuma ementa, número de recurso ou relator fabricado — tudo de `referencias/precedentes.md` ou do agente `jurisprudencia`
- [ ] Os três filtros rodaram, **nesta ordem**, e o resultado está dito
- [ ] Se há acordo possível, isso foi oferecido antes da peça judicial
- [ ] Se a dívida protestada passa de 40 salários mínimos, a via falimentar foi **avaliada e mencionada** — ainda que descartada
- [ ] Data e praça conferem com a comarca
- [ ] A pendência documental do cliente saiu como lista, por devedor

---

## 4. Duas conversas que não são jurídicas, e valem mais que a peça

**Ao cliente, em toda triagem:** a orientação preventiva do canhoto — assinatura **datada e identificada** no ato da entrega, como norma da empresa. É o único conselho da área que zera o problema para o futuro, e não custa nada. Está na nota doutrinária da casa e deve sair em toda entrega de triagem.

**Ao cliente, quando a carteira tem crédito perto de prescrever:** diga o número em reais e o prazo em meses. Mais de 70 dos ~120 devedores da carteira Agroboi prescreveram enquanto a documentação era procurada. O risco não é abstrato — é o histórico da própria carteira.
