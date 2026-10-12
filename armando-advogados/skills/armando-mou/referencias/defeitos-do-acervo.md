# Defeitos dos quatro MOUs-modelo

Censo feito em 12/10/2026, com a leitura integral de Megga, M21, Mulinari e Agroboi. Serve para duas coisas:

- dizer **o que o `conferir_mou.py` pega e por quê**: cada regra do script nasceu de um achado daqui;
- dizer **o que só o olho humano pega**: a última coluna "manual" da tabela.

A taxonomia vem primeiro, porque é ela que justifica as travas.

## Taxonomia: onde o MOU erra

| Família | Modelos com o defeito | Ocorrências | Trava |
|---|---|---|---|
| Numeração e remissão | **4 de 4** | 9 | script (ERRO) |
| Sobra de outro modelo ("Contrato", "INTERESSADOS", "sócios" para quem não é sócio) | **4 de 4** | 9 | script (ALERTA), exceto "sócios" (manual) |
| Parte qualificada que não assina | 2 de 4 | 6 | script (ERRO) |
| Qualificação incompleta ou contraditória | 3 de 4 | 7 | script (ALERTA) e manual |
| Dado em aberto ("?", "____", "não indicada", anexo ausente) | 3 de 4 | 9 | script (ALERTA; ERRO com `--final`) |
| Digitação | 4 de 4 | 9 | script (ALERTA) |
| Ponto jurídico frágil | **4 de 4** | 13 | script (ALERTA/CONFERIR) e manual |
| Aritmética (fração, percentual, total) | 2 de 4 | 4 | script em parte; percentual × base é manual |

**Leitura:** os defeitos não são de doutrina, são de **montagem**. O MOU é feito copiando o anterior e adaptando, e o que sobra do caso anterior é o erro mais frequente: número, nome, termo, cláusula que não se aplica. Daí as duas peças da skill:

- o **montador** torna impossível numerar e remeter errado;
- o **conferidor** acusa a sobra.

## Achados, um a um

`S` = o script acusa; `M` = conferência manual (está na lista da SKILL.md, §4).

### Megga (09/08/2024)
| # | Onde | Defeito | Trava |
|---|---|---|---|
| 1 | cap. 1 | "16\." no lugar de 1.6, número solto | S |
| 2 | 1.1 | "divócio" | S |
| 3 | 10.2 | "revestidos e reembolsados" (revertidos) | S |
| 4 | 11.4 | "deste Contrato", três vezes num Memorando | S |
| 5 | 11.3 | "Os INTERESSADOS" (termo não definido) e renúncia a "qualquer reclamação presente ou futura" | S |
| 6 | cons. (ii), 3.1, 4.1 | "Anexo Único" citado e não juntado ao arquivo | S |
| 7 | 9.1 | garantia descrita só como "Gado", sem quantidade, marca, local nem forma de constituição | M |
| 8 | 6.4 | 12 × R$ 416.666,67 = R$ 5.000.000,04, não R$ 5.000.000,00 | M |
| 9 | 2.2 × 6.3 | a 2.2 diz pagamentos "anualmente"; o cronograma de 2024 é mensal | M |

### M21 (28/01/2025)
| # | Onde | Defeito | Trava |
|---|---|---|---|
| 1 | cap. 5 | 5.3 duas vezes | S |
| 2 | cap. 11 | de 11.2 para 11.4 | S |
| 3 | 10.3 | remete "à cláusula 10.3", a si mesma | S |
| 4 | cap. 6, par. único | remete à "cláusula 5.2" (reversão) para falar do planejamento patrimonial (cap. 6) | M |
| 5 | qualificação das PJs | "RAIMUNDO NONATO BRAISLEIRO" duas vezes; "RAIMUNDO NONATO BRASILEIRO" sem o sobrenome final; "SAO JOSE" × "SÃO JOSÉ" | S |
| 6 | 5.1, 9.1, 10.3, 13.2 | "nu-propriedade", "divórico", "providenciais iniciais", "revestidos" | S |
| 7 | 14.3, 14.4 | "INTERESSADOS", renúncia genérica e "deste Contrato" | S |
| 8 | 6.2 | atribui ao art. 1.831 do CC a "sucessão legítima e testamentária" (é o direito real de habitação) | S |
| 9 | 5.1 × 6.4 | 1/4 a cada um de quatro sucessores na 5.1; ⅓ "a cada" dos mesmos quatro na 6.4 | M |
| 10 | 11.4 | testamentos "revogados ou alterados mediante manifestação expressa de ambos" (o testamento é personalíssimo: arts. 1.858, 1.863 e 1.969) | M |
| 11 | cons. (ii) × 3.1 | os "3%" de Rafael são 3% das quotas de Raimundo (R$ 153.000,00 de R$ 5.100.000,00), ou seja, 2,25% do capital; e os "72%" de Raimundo são 72,75%. Percentual e base trocados | M |
| 12 | 6.1 | jazigo no quadro de imóveis a integralizar (em regra é concessão, sem matrícula) | M |

### Família Mulinari (2026)
| # | Onde | Defeito | Trava |
|---|---|---|---|
| 1 | todos os capítulos | títulos numerados "1." pela lista automática do Google Docs (o número real não está no texto) | S (avisa) |
| 2 | cap. 5 | de 5.4 para 5.6 | S |
| 3 | 5.1 | remete à "Seção 5.1" para o quadro que está na 5.6.1 | M |
| 4 | assinaturas | as três PJs e a interveniente anuente qualificadas e sem linha de assinatura | S |
| 5 | fecho | sem local e data | S |
| 6 | cons. (iii), 9.1 | "incapacidade absoluta" de herdeiro maior (art. 3º do CC desde a Lei 13.146/2015) | S |
| 7 | 9.3 | art. 1.693, III, do CC (poder familiar) aplicado a curatelado | M |
| 8 | 4.4 | quotas "transferidas exclusivamente aos filhos do donatário, sem comunicação com o cônjuge" (art. 547, parágrafo único; arts. 1.829, I, e 1.845) | S |
| 9 | 5.6.1 | "Matrícula nº R-03-M-308" (é o registro 3 da matrícula 308) e "Matrícula não indicada no IRPF" | S |
| 10 | 4.3 | cláusulas restritivas sem justa causa e sem tratar de colação | S (CONFERIR) |
| 11 | qualificação | "na na Quadra" | S |
| 12 | caps. 11 e 12 | "sócios" para as Partes, quando há PJs e herdeiros que ainda não são sócios | M |

### Agroboi (17/08/2026)
| # | Onde | Defeito | Trava |
|---|---|---|---|
| 1 | cap. 1 | 1.1 a 1.4 como "1." de lista automática | S (avisa) |
| 2 | cap. 3 | de 3.3 para 3.5 | S |
| 3 | 3.2 | "atribuições atribuições" | S |
| 4 | interveniente | "(____), brasileiro, casado sob regime de ____ com Gabriela", que está qualificada como **solteira** | S |
| 5 | qualificação | Beatriz "casada" e Adilton "casado" sem regime de bens; o cônjuge de Beatriz não anui | S |
| 6 | assinaturas | as duas PJs qualificadas e sem linha de assinatura | S |
| 7 | 6.2 | cinco imóveis com matrícula "?"; tabela com três colunas vazias | S |
| 8 | 4.2 × 4.3 | reversão ao doador (4.2) e, na sequência, destino "exclusivamente aos filhos da donatária" (4.3) | S |
| 9 | cons. (i) × qualificação | "SOUZA & BORGES" × "SOUZA E BORGES" | M |
| 10 | 10.1.2 | "das empresa operacional" (também na Mulinari) | S |
| 11 | fecho | "os SÓCIOS declaram", quando as herdeiras ainda não são sócias | M |

## O que nenhum modelo faz e a skill passou a pedir

- **Colação.** Os três modelos com doação a herdeiro (M21, Mulinari e Agroboi) não dizem se a doação adianta a legítima ou sai da parte disponível. A diferença decide o inventário (arts. 544, 2.002 e 2.005 do CC).
- **Justa causa** das cláusulas restritivas sobre bem que integra a legítima (art. 1.848). Nenhum modelo declara.
- **Espelho no contrato social** da vedação de cônjuges. O MOU não obriga o cônjuge futuro, que não assina; quem o barra é a cláusula de cessão e de sucessão do contrato social, junto com a incomunicabilidade na doação.
