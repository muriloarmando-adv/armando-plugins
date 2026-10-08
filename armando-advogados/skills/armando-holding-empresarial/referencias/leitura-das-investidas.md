# Leitura das investidas — o apanhado das empresas antes de redigir

A holding empresarial não se redige a partir dela mesma. Ela se redige a partir das **sociedades cujas quotas recebe**. Cada número da cláusula do capital (quantas quotas, de quem, por quanto) vem do contrato vigente de uma investida. Cada alteração contratual de investida depende do que aquele contrato permite.

Não é fusão. As investidas **continuam existindo**, com o mesmo CNPJ e o mesmo patrimônio. Só muda quem é o titular das quotas: sai a pessoa física, entra a holding. Fusão (CC, art. 1.119) e incorporação (art. 1.116) extinguem sociedades. Aqui nenhuma se extingue. O nome técnico da operação, no Manual do DREI (item 4.3.5), é **integralização de capital com quotas de outra sociedade**. A investida é a "empresa **compartilhadora**" e a holding, a "empresa **receptora**".

---

## 1. Documentos a pedir ao cliente

Peça tudo de uma vez.

**Por sócio da holding:**
- documento de identidade (RG ou CNH) e CPF;
- comprovante de endereço;
- certidão de casamento, com o regime de bens, ou a escritura de união estável;
- **declaração de IRPF mais recente**, com a ficha de bens e direitos: dá o custo de cada participação;
- se for casado no regime da comunhão universal ou da separação obrigatória com **outro sócio**, pare: o art. 977 do CC proíbe a sociedade entre eles.

**Por investida:**
- **último contrato consolidado arquivado e todas as alterações posteriores**, com a chancela da Junta. Não serve minuta nem versão do contador;
- **certidão simplificada** recente da Junta: confirma NIRE, capital, quadro atual e se há ato pendente;
- cartão CNPJ e QSA;
- **último balanço ou balancete**: dá o patrimônio líquido para conferir o valor atribuído às quotas;
- se é optante do **Simples Nacional** ou enquadrada como ME/EPP.

Para PDF, use a skill `armando-pdf-markdown` antes de ler. Contrato digitalizado sem camada de texto devolve só a folha de rosto: peça o arquivo pesquisável ou a certidão de inteiro teor do ato.

No Drive, busque a pasta do cliente:

```
search_files: title contains '[nome da investida]'
search_files: fullText contains '[CNPJ da investida]'
```

---

## 2. A ficha de cada investida

Monte uma ficha por investida **antes** de preencher o `.json`. Ela é o "apanhado" e vai junto na entrega, como anexo de trabalho.

| Campo | Onde achar | Vai para o `.json` |
|---|---|---|
| Denominação exata (grafia da Junta) | certidão simplificada | `denominacao` |
| CNPJ / NIRE / Junta / UF | certidão e cartão CNPJ | `cnpj`, `nire`, `junta`, `uf` |
| Sede completa | último instrumento | `sede` |
| Capital social e valor nominal da quota | cláusula do capital | `capital`, `valorQuota` |
| **Capital totalmente integralizado?** | cláusula do capital | `capitalIntegralizado` |
| Quadro atual: sócio × quotas | cláusula do capital + certidão | `quadro[]` |
| Quem administra, e se o contrato **permite administrador não sócio** | capítulo da administração | `quadro[].administrador`, `permiteAdmNaoSocio` |
| Regra de cessão: preferência, anuência, quórum, prazo | capítulo das quotas/cessão | `clausulaPreferencia`, mais a nota |
| Número da **última** alteração arquivada | título do último instrumento | `numeroAlteracao` = última + 1 |
| Número da cláusula do capital no texto vigente | último consolidado | `clausulaCapital` |
| Quotas gravadas (penhora, usufruto, alienação fiduciária, caução) | certidão; contrato; pergunta ao cliente | nota de impedimento |
| Simples / ME / EPP | cartão CNPJ; contador | `simples` |
| Patrimônio líquido | balanço | `patrimonioLiquido` |
| Custo das quotas na DIRPF de cada sócio | IRPF | `participacoes[].valorDirpf` |

---

## 3. As armadilhas, na ordem em que aparecem

1. **Capital da investida não integralizado.** O Manual DREI (4.3.5) exige capital "totalmente integralizado". Se não estiver, primeiro integralize, ou reduza o capital, numa alteração própria. O gerador acusa ERRO.
2. **Quadro do cliente ≠ quadro arquivado.** O cliente diz "é meio a meio", e o último instrumento diz 60/40, ou ainda lista um sócio que "já saiu" sem alteração arquivada. **Vale o arquivado.** O gerador confere a soma do quadro contra o capital.
3. **Cláusula de cessão restritiva.** A holding é **terceira** em relação à investida. Sem cláusula própria, a cessão a estranho depende de não haver oposição de titulares de mais de 1/4 do capital (CC, art. 1.057). Com cláusula que exige unanimidade, preferência com prazo ou notificação prévia, a alteração precisa da **anuência expressa e da renúncia à preferência** de todos. O modelo já traz as duas. Se houver sócio que não integra a holding e não vai assinar, pare e trate antes.
4. **Sócio administrador que sai.** Se o sócio pessoa física transfere todas as quotas e é o administrador, ele vira **administrador não sócio**. Isso exige:
   - (i) contrato que **permita** administrador não sócio (art. 1.061);
   - (ii) aprovação de mais da metade do capital, se integralizado (unanimidade não é exigida, mas na prática todos assinam).
   
   Se o contrato não permitir, a alteração inclui a cláusula que permite. Foi o desenho da Fourmaq Soluções (11ª Alteração).
5. **Investida que vira sócia única.** Quando todos os sócios conferem tudo, a holding passa a ser a única sócia, e a investida segue como limitada unipessoal (art. 1.052, §§ 1º e 2º). Consolide o contrato e ajuste as cláusulas que pressupõem vários sócios.
6. **Simples Nacional.** Com sócia pessoa jurídica, a investida **perde** o enquadramento de ME/EPP (LC 123, art. 3º, § 4º, I). A holding também não pode ser ME/EPP (inciso VII). Avise o cliente e o contador antes de assinar: muda a carga tributária da investida.
7. **Quotas gravadas.** Penhora, usufruto, alienação fiduciária ou caução impedem ou condicionam a transferência. Contrato que "veda caucionar quotas" (Fourmaq) não resolve gravame já existente.
8. **Investida em outra UF.** Não há tramitação conjunta (a Nota I do 4.3.5 só fala em mesma UF). Arquive primeiro a alteração da investida, mencionando a holding em constituição, e junte-a ao processo da holding. Ou use a rota "posterior". Confirme com as duas Juntas.
9. **Conferência por valor diferente do custo.** Ver `registro-e-tributos.md`, §3. Acima do custo declarado na DIRPF, há ganho de capital. Acima do patrimônio real, há risco do art. 1.055, § 1º.
10. **Cônjuge.** Quotas não são imóvel: a transferência **não** exige outorga do cônjuge (art. 1.647, I, fala em imóveis). Mas, se as quotas são bem comum do casal e o cônjuge não é sócio, a anuência dele em declaração à parte evita discussão de meação depois. Recomende, sem tratar como requisito de registro.

---

## 4. Como a ficha vira o `.json`

Um exemplo completo e comentado está em `scripts/exemplo-holding.json`, com os números do próprio modelo: R$ 20.051.000,00, dois sócios e três investidas. Regras:

- **`quadro[].socio`** liga a linha do quadro da investida ao `id` do sócio da holding. Sócio da investida que **não** entra na holding vai com `nome` e `qualificacao` próprios.
- **`participacoes[].quotas`** é quanto daquela investida o sócio confere. Pode ser menos do que ele tem: o gerador escreve "X das suas Y quotas" e mantém o saldo no quadro.
- **`participacoes[].valor`** só se a conferência for diferente do valor nominal. Sem ele, o valor é quotas × valor nominal, como no modelo.
- **`dinheiro`** no sócio, se ele também aporta em moeda.
- Campo desconhecido fica **vazio**, e o diagnóstico o lista como pendência. **Nunca invente** CNPJ, NIRE, CPF, número de alteração ou de cláusula.
