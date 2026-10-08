# Alteração contratual da sociedade investida (o "1º Ato")

Cada sociedade cujas quotas entram na holding precisa de uma alteração contratual própria. Ela formaliza a saída do sócio pessoa física (ou a redução de sua participação) e o ingresso da holding. Sem ela, a integralização prometida no contrato da holding não se realiza: a cessão de quotas só tem eficácia perante a sociedade e terceiros depois de averbada (CC, art. 1.057, parágrafo único).

## 1. O que o DREI exige (Manual de Registro de Sociedade Limitada, item 4.3.5)

Redação da IN DREI/ME 88/2022, conferida no texto vigente do Anexo IV da IN DREI 81/2020:

- **Na investida (1º Ato).** Uma cláusula dizendo que o capital do sócio (qualificado, com a empresa) será utilizado para integralizar o capital da sociedade receptora (qualificação completa), consignando a saída do sócio e o ingresso da receptora. Na transferência parcial, consigna-se a redução da participação do sócio.
- **Holding em constituição.** "Deverá ser mencionado que as quotas serão utilizadas para constituição de sociedade."
- **Na holding (2º Ato).** O contrato social indica, para cada investida, a quantidade e o valor das quotas e "o respectivo ato em que se deu o compartilhamento de quotas (1º Ato)".
- **Capital integralizado.** O capital objeto da operação deve estar totalmente integralizado.
- **Nota I.** Sociedades com sede na mesma UF: **os processos tramitam conjuntamente**.
- **Laudo de avaliação.** Não é exigido (item 4.3.4, Nota I, a). A estimação é responsabilidade dos sócios (art. 1.055, § 1º).

## 2. Anatomia da minuta gerada

`assets/modelo-alteracao-investida.md`, preenchido por `gerar_holding.py`:

```
[N]ª ALTERAÇÃO CONTRATUAL DA SOCIEDADE EMPRESÁRIA LIMITADA [INVESTIDA]
CNPJ | NIRE

  qualificação de TODOS os sócios atuais (cedentes e não cedentes)
  identificação da investida + Junta
  a holding como cessionária e interveniente (em constituição, ou já registrada)

  CLÁUSULA PRIMEIRA – transferência de quotas para integralização de capital
        (um parágrafo por sócio cedente + parágrafo único com a menção do DREI)
  CLÁUSULA SEGUNDA  – anuência e renúncia ao direito de preferência
  CLÁUSULA TERCEIRA – ingresso da holding; saída ou redução dos cedentes
  CLÁUSULA QUARTA   – nova redação da cláusula do capital, com o quadro
  [sócia única]     – se a holding fica com 100%
  [administração]   – se o sócio administrador sai e segue como não sócio
  [desenquadramento] – se a investida era ME/EPP
  ...               – responsabilidade do cedente (arts. 1.003 e 1.057, p.ú.)
  ...               – manutenção das demais cláusulas
  [consolidação]    – se marcado no .json

  local, data, assinaturas: todos os sócios + holding representada
```

## 3. Variantes que o gerador trata

| Situação | O que muda na minuta |
|---|---|
| Sócio confere **todas** as quotas | "a totalidade de suas N quotas" + "retira-se da sociedade" |
| Sócio confere **parte** | "N das suas M quotas" + "permanece na sociedade, titular de R quotas" (DREI 4.3.5, II) |
| Há sócio que **não** entra na holding | é qualificado no preâmbulo, assina como anuente e permanece no quadro |
| Holding fica com **100%** | cláusula da sócia única (art. 1.052, §§ 1º e 2º) + ALERTA para consolidar |
| Sócio **administrador** sai | administração continua com ele, como **não sócio** (art. 1.061), com a declaração de desimpedimento; CONFERIR se o contrato permite |
| Investida **ME/EPP / Simples** | cláusula de desenquadramento (LC 123, art. 3º, § 4º, I) |
| Rota **conjunta** (padrão) | holding "em constituição", contrato "levado a arquivamento conjuntamente" |
| Rota **posterior** | holding qualificada com CNPJ e NIRE já registrados |

## 4. O que o gerador **não** decide — e você precisa decidir

1. **Quem administra a investida depois.** O padrão é o mesmo administrador, agora não sócio, como na Fourmaq Soluções. A alternativa é a holding indicar outro. Pergunte ao cliente.
2. **Se o contrato da investida permite administrador não sócio.** Leia o capítulo da administração. Se não permitir, acrescente uma cláusula: "Altera-se a Cláusula [X], que passa a vigorar com a seguinte redação: '... podendo a administração ser exercida por sócio ou por não sócio, designado no contrato ou em ato separado...'"
3. **Cláusulas da investida incompatíveis com sócia pessoa jurídica.** Exemplos: falecimento de sócio, divórcio, pró-labore de sócio. Com a holding como sócia, falecimento vira "extinção, dissolução ou liquidação da sócia pessoa jurídica" (veja a cláusula 11ª da Fourmaq Soluções). Ajuste na consolidação.
4. **Consolidar ou não.** Não é obrigatório. É recomendável sempre que a investida vira unipessoal ou quando o contrato vigente está espalhado em várias alterações.

## 5. Consolidação

Marcando `"consolidar": true`, a minuta abre a cláusula de consolidação e deixa o marcador `[CONSOLIDAÇÃO — ...]`. Monte o texto consolidado assim:

1. Parta do **último consolidado arquivado** e de cada alteração posterior, nunca de minuta do contador.
2. Transcreva o contrato inteiro, aplicando as modificações deste instrumento: nova cláusula do capital, sócia única, administração.
3. Na qualificação do preâmbulo do consolidado, **só os sócios que permanecem** e a holding representada.
4. Mantenha a numeração da investida. Se renumerar, diga isso numa cláusula do corpo e varra as remissões internas.
5. Tempo verbal no presente: "O capital social **é** de", nunca "passará a ser".
6. Rode `conferir_minuta.py` no resultado.

## 6. Assinaturas

- Todos os sócios atuais da investida: cedentes e anuentes.
- A holding, representada pelos administradores que o contrato dela nomeia. Na rota conjunta, a holding ainda não tem CNPJ. O DREI só exige a **menção** de que as quotas se destinam à constituição. **Confirme com a JUCETINS** se aceita a holding em constituição como interveniente.
- Assinatura eletrônica: certificado ICP-Brasil ou gov.br (prata/ouro), conforme a Junta.
