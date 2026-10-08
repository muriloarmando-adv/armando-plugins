# Notas ao modelo — o que a skill mudou no contrato da Dra. Náira, e por quê

**Modelo de origem:** `Contrato holding empresarial.docx`, Dra. Náira Wolney (coordenação do NPPS), Drive `174LuBg7KX_pVgPs0DOyEhaH3v8cTR_Wv`, pasta `3. Holding Empresarial`, carregado em 06/10/2026.

**Regra desta skill:** seguir o modelo. Ele é a redação da casa, e o texto de `assets/modelo-contrato-holding.md` o reproduz cláusula por cláusula. Desvio só por um destes três motivos, sempre listados abaixo:

- **(a)** erro objetivo de forma: numeração, remissão, CNAE, digitação;
- **(b)** contradição interna, entre duas cláusulas do próprio modelo;
- **(c)** incompatibilidade com a lei ou com o Manual do DREI.

Nada foi acrescentado por gosto.

> **Pendente de validação.** A ata de alinhamento de 06/10/2026 (item 2.2) registra que a coordenadora faria a leitura crítica das minutas-modelo **antes** de virarem base de skill. Se ela já revisou e mandou uma versão nova, **substitua o texto de `assets/modelo-contrato-holding.md`** e reavalie esta lista. Os itens marcados **[DECISÃO]** pedem a palavra dela.

`scripts/conferir_minuta.py`, rodado sobre o `.docx` original, aponta 6 ERROS e 6 ALERTAS. É a prova de que esta lista não é teórica.

---

## 1. Desvios aplicados

| # | Onde (numeração do modelo) | No modelo | Na skill | Motivo |
|---|---|---|---|---|
| 1 | Cláusulas | pula a **57ª** e a **67ª** | numeração contínua, 1ª a 68ª, gerada por script | (a) toda alteração futura remete por número |
| 2 | Capítulos | pula o **XV**; o foro vem rotulado "**CLÁUSULA XX** DO FORO" | capítulos I a XIX contínuos; "CAPÍTULO XIX — DO FORO" | (a) |
| 3 | Cl. 47, § 2º | "observada a restrição constante na **Cláusula 10ª**" | remete à cláusula de **cessão de quotas** (13ª) | (a) a 10ª trata de aumento de capital |
| 4 | Cl. 13 | "Será **vedada** a cessão [...] a terceiros, seja a que título for" | "...sem o prévio e expresso consentimento dos demais sócios, observado o direito de preferência regulado na Cláusula 14ª" | (b) a 7ª admite a transferência **com** consentimento, e a 14ª regula a oferta; vedação absoluta tornaria as duas inúteis |
| 5 | Cl. 33 | decisão por "documento assinado por sócios que representem **maioria** do capital social" | documento assinado por **todos** os sócios (art. 1.072, § 3º) | (c) a dispensa de reunião exige todos os sócios (CC, art. 1.072, § 3º; Manual DREI, item 3.1, II). A deliberação majoritária sem reunião só existe para ME/EPP (LC 123, art. 70), e a holding não pode ser ME/EPP (art. 3º, § 4º, VII) **[DECISÃO]** |
| 6 | Cl. 36, IV × Cl. 59 | a 36 aprova a **dissolução** por 50% + 1; a 59 diz que a sociedade "se dissolverá **somente por deliberação de todos** os sócios" | mantida a unanimidade da 59; a 36, IV, ressalva a dissolução | (b) duas regras para a mesma matéria **[DECISÃO]**: se a coordenadora preferir maioria, inverta |
| 7 | Cl. 3 | "6462-**00**/00 Holding de instituições não financeiras" | "6462-0/00 – Holdings de instituições não-financeiras" | (a) notação CNAE é NNNN-N/NN |
| 8 | Cl. 5 | integralização afirmada sem amarra ao ato das investidas; parágrafo único: "apresentar o ato de alteração das empresas compartilhadoras no prazo de 30 (trinta) dias" | cada alínea indica o ato da investida (1º Ato); § 2º: os 1º Atos são arquivados **conjuntamente** | (c) Manual DREI, item 4.3.5, b, e Nota I: o 2º Ato indica o 1º, e os processos da mesma UF tramitam juntos. **A redação dos 30 dias continua disponível** (`"rota": "posterior"`) **[DECISÃO]** |
| 9 | Cl. 5 | sem cláusula do art. 1.055, § 1º | § 1º: solidariedade pela exata estimação das quotas conferidas, por 5 anos | (c) a responsabilidade existe por lei; dizê-la no contrato é o que o cliente lê |
| 10 | Cl. 5, tabela | linha TOTAL com quotas em formato de dinheiro: "20.051.000,00" | "20.051.000" | (a) |
| 11 | Cl. 5 | "20.051.000 (vinte milhões, cinquenta e **um** mil) quotas" | "(vinte milhões e cinquenta e **uma** mil) quotas" | (a) concordância: quota é feminino; o modelo já fazia certo em "quinhentas" |
| 12 | Preâmbulo | "nascido em (___), na cidade de **Passos-MG**", em todos os sócios | naturalidade vem da qualificação de cada sócio | (a) resíduo do caso de onde o modelo saiu |
| 13 | Cl. 24 | "Os administradores deverão assinar **em conjunto**" | com administrador único: prévia aprovação dos sócios (mesmo quórum) | (b) impossível assinar em conjunto sozinho |
| 14 | Cl. 69 | "vinculado ao Acordo de Sócios **assinado**" | sem acordo: "que vier a ser celebrado" | (c) afirmar acordo inexistente é declaração falsa em registro público |
| 15 | Cl. 47, § 3º; Cl. 53 | "o sócio remanescente" | com 3 ou mais sócios: "os sócios remanescentes, na proporção de suas participações" | (a) |
| 16 | Fecho | sem visto de advogado | "Visto do advogado", com nome e OAB | (c) holding não é ME/EPP: o visto é obrigatório (Lei 8.906/1994, art. 1º, § 2º) |
| 17 | Cl. 28 | "serão definidos necessariamente em reunião de sócios" | acrescido "ressalvada a hipótese da Cláusula 27ª" | (b) a 27ª dispensa a reunião com decisão unânime escrita |
| 18 | Cl. 19 | "Será excluído da sociedade aquele sócio que..." | "...na forma do Capítulo XVI" | (b) exclusão sem o procedimento do art. 1.085 seria nula; a remissão amarra |
| 19 | Cl. 23, i | "Submeter à **Assembleia Geral**" | "Submeter à **reunião de sócios**" | (a) Assembleia Geral é órgão de S.A. |
| 20 | Cl. 26 | "quórum definido pelo **novo** Código Civil" | "pelo Código Civil e por este contrato social" | (a) |
| 21 | Digitação | "coorporativa"; "o sócio que **pôr** em risco"; "**à** um sócio"; "vedada novas operações"; "(III) o término"; "da incapacidade"; "agravar de ônus"; "Configura exclusão" | corrigidos | (a) |

---

## 2. Pontos mantidos como estão, mas que merecem a leitura crítica da coordenação

Nenhum é ilegal. Todos são escolhas que alguém deve fazer conscientemente.

1. **"50% + 1 (cinquenta por cento mais um)"** (cl. 10 e 36). A lei diz "mais da metade do capital" (art. 1.076, II). Lida como 50% do capital mais uma quota, é igual. Lida como 51%, é mais exigente. A redação legal elimina a dúvida. A skill aceita `"quorum": "mais da metade"` no `.json`.
2. **Sociedade 50/50.** Com dois sócios iguais, todo quórum de maioria vira unanimidade. O contrato não tem mecanismo de desempate, e o lugar dele é o acordo de sócios. O gerador avisa.
3. **Cl. 45: a interdição "conduz, por si só, à exclusão".** O art. 1.030 trata a incapacidade superveniente como causa de exclusão **judicial**. A exclusão automática pela sentença de interdição é construção contratual defensável, mas discutível.
4. **Cl. 41: distribuição desproporcional "facultada".** O DREI (IN 1/2024) admite a distribuição desproporcional por maioria simples. Com a tributação de dividendos da Lei 15.270/2025, convém fixar no acordo de sócios quem a aprova.
5. **Cl. 68: regência supletiva da Lei 6.404/1976.** Permitida (CC, art. 1.053, parágrafo único), mas afasta a sociedade simples como fonte supletiva, inclusive quanto à retirada imotivada do art. 1.029. Escolha da casa, a manter conscientemente.
6. **Cl. 55, parágrafo único: exclusão em reunião com direito de defesa.** Em sociedade de **dois** sócios, o art. 1.085, parágrafo único, dispensa a reunião. O modelo é mais protetivo que a lei. Ótimo, desde que intencional.
7. **Cl. 61: haveres em 24 parcelas, após 60 dias de carência.** Coerente com holding. Repetir o critério no acordo de sócios.
8. **Cl. 30, parágrafo único: instalação com 3/4 em primeira convocação.** É a regra da assembleia (art. 1.074). Mantida.

---

## 3. Precedentes da casa que confirmam ou contrariam o modelo

- **Fourmaq Participações Societárias Ltda**, 1ª Alteração e Consolidação (JUCETINS, registro 09/03/2022; Drive `1CDE7bgyqdqhQOfPdYtYmh9s6vX3ohhlQ`). É holding empresarial real da carteira. **Rota em dois tempos:** constituída com R$ 1.000,00 em dinheiro e, depois, capital aumentado para R$ 10.001.000,00 com quotas da Fourmaq Soluções em Agronegócios Ltda. Ensina duas coisas:
  - o caminho do aumento de capital (art. 1.081) funciona na JUCETINS e resolve o problema da holding ainda sem CNPJ;
  - **o que não fazer.** As cláusulas de subscrição não dizem **quantas quotas da investida** foram conferidas, só quantas quotas da holding foram subscritas. A consolidação descreve a integralização como "em moeda corrente do país e bens móveis". A 2ª Alteração (registro 06/05/2025, Drive `1NTzHjlcXHXPgJmjd9ZFMSzCvDKSRHl-r`) chama a operação de "**incorporação de quotas**", termo de outra figura. O extenso traz "duzentos e vinte **sete**" sem o "e".
- **Fourmaq Soluções em Agronegócios Ltda**, 11ª Alteração (2025; Drive `1gjK5U3h9TsTwiOUw_b888uTjXsQCzFy1`). Mostra o estado final da investida: **holding como sócia única**, qualificada como pessoa jurídica "neste ato representada por seu administrador", e o antigo sócio pessoa física como **administrador não sócio**. É o desenho que o gerador presume quando o sócio administrador transfere todas as quotas.
- **Minuta de ato constitutivo de holding da Dra. Náira**, de 2023 (Drive `14-gm4d-Py5ygS2vMgAKZihNWwc_4UH4D`). É a versão anterior e mais curta do mesmo modelo. Já usava o CNAE certo ("6462-0/00") e "mais de 50%". Também tinha o foro rotulado "CLÁUSULA XXI" e um capítulo "XIX" depois do "XIII".
