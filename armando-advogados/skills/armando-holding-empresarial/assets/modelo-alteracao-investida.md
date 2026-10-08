%% =====================================================================
%% MODELO DA ALTERAÇÃO CONTRATUAL DA SOCIEDADE INVESTIDA ("1º Ato")
%% NPPS / Armando Advogados
%%
%% Fonte normativa: Manual de Registro de Sociedade Limitada (Anexo IV da IN
%% DREI 81/2020), item 4.3.5, na redação da IN DREI/ME 88/2022:
%%   a) Empresa compartilhadora (1º Ato): cláusula dizendo que o capital do
%%      sócio será utilizado para integralizar o capital da sociedade
%%      receptora (qualificação completa), com a saída do sócio (ou redução
%%      de sua participação) e o ingresso da receptora; se a receptora estiver
%%      em constituição, mencionar que as quotas serão utilizadas para a
%%      constituição da sociedade.
%% Estrutura de cláusulas no padrão das alterações da casa (Fourmaq
%% Participações, 1ª e 2ª Alterações; Fourmaq Soluções, 11ª Alteração).
%%
%% Os blocos variáveis ({CESSOES}, {QUADRO} etc.) são montados pelo script.
%% =====================================================================

**{NUM_ALTERACAO} ALTERAÇÃO CONTRATUAL DA SOCIEDADE EMPRESÁRIA LIMITADA**  
**{DENOM_INV}**  
**CNPJ nº {CNPJ_INV} | NIRE nº {NIRE_INV}**

Pelo presente instrumento particular e na melhor forma de direito, os abaixo assinados:

{PREAMBULO_INV}

Únicos sócios componentes da sociedade empresária limitada denominada **{DENOM_INV}**, com sede na {SEDE_INV}, inscrita no CNPJ sob o nº {CNPJ_INV}, com seus atos constitutivos registrados na {JUNTA_INV} sob o NIRE nº {NIRE_INV};

e, na qualidade de cessionária e interveniente, **{DENOM_HOLDING}**, {QUALIF_HOLDING};

resolvem, de comum acordo, alterar o contrato social da sociedade, mediante as cláusulas e condições seguintes:

# CLAUSULA transferencia
DA TRANSFERÊNCIA DE QUOTAS PARA INTEGRALIZAÇÃO DE CAPITAL SOCIAL

{CESSOES}

[[se:holding_em_constituicao]]
Parágrafo único. As quotas ora transferidas são utilizadas para a **constituição** da sociedade {DENOM_HOLDING}, cujo contrato social é levado a arquivamento conjuntamente com o presente instrumento, nos termos do item 4.3.5 do Manual de Registro de Sociedade Limitada (Anexo IV da Instrução Normativa DREI nº 81/2020).
[[senao]]
Parágrafo único. As quotas ora transferidas são utilizadas para integralização do capital social da sociedade {DENOM_HOLDING}, conforme o ato desta levado a arquivamento conjuntamente com o presente instrumento, nos termos do item 4.3.5 do Manual de Registro de Sociedade Limitada (Anexo IV da Instrução Normativa DREI nº 81/2020).
[[fim]]

# CLAUSULA anuencia
DA ANUÊNCIA E DA RENÚNCIA AO DIREITO DE PREFERÊNCIA

Todos os sócios, neste ato, consentem expressamente com as transferências de quotas descritas na {ref:transferencia} e com o ingresso da cessionária no quadro social, renunciando, cada qual, ao direito de preferência que lhes assegura o contrato social{PREF_CLAUSULA} sobre as quotas transferidas, para todos os fins do art. 1.057 do Código Civil.

# CLAUSULA ingresso
DO INGRESSO DA SÓCIA

Ingressa na sociedade, na qualidade de sócia, **{DENOM_HOLDING}**, já qualificada, que declara conhecer e aderir integralmente ao contrato social, sub-rogando-se em todos os direitos e obrigações inerentes às quotas recebidas.

{SAIDAS}

# CLAUSULA capital
DO CAPITAL SOCIAL E DO QUADRO SOCIETÁRIO

Em razão das transferências acima, a {CL_CAPITAL} do contrato social passa a vigorar com a seguinte redação:

"{CAPITAL_NOVO}

{QUADRO}

Parágrafo único. A responsabilidade de cada sócio é restrita ao valor de suas quotas, mas todos respondem solidariamente pela integralização do capital social, nos termos do art. 1.052 do Código Civil."

[[se:unipessoal]]
# CLAUSULA unipessoal
DA SÓCIA ÚNICA

Com a presente alteração, a sociedade passa a ter sócia única, prosseguindo como sociedade limitada unipessoal, nos termos do art. 1.052, §§ 1º e 2º, do Código Civil, aplicando-se às decisões da sócia única, no que couber, as disposições do contrato social sobre deliberações dos sócios.
[[fim]]

[[se:saida_adm]]
# CLAUSULA administracao
DA ADMINISTRAÇÃO

{ADM_TEXTO}
[[fim]]

[[se:simples]]
# CLAUSULA enquadramento
DO DESENQUADRAMENTO

Em razão do ingresso de sócia pessoa jurídica, a sociedade deixa de se enquadrar como microempresa ou empresa de pequeno porte, nos termos do art. 3º, § 4º, inciso I, da Lei Complementar nº 123/2006, devendo ser promovido o respectivo desenquadramento perante a Junta Comercial e a Receita Federal do Brasil.
[[fim]]

# CLAUSULA cedente
DA RESPONSABILIDADE DO CEDENTE

{RESP_CEDENTE}

# CLAUSULA manutencao
DAS DISPOSIÇÕES QUE PERMANECEM

Permanecem inalteradas as demais cláusulas do contrato social e de suas alterações anteriores que não tenham sido expressamente modificadas pelo presente instrumento.

[[se:consolidar]]
# CLAUSULA consolidacao
DA CONSOLIDAÇÃO

Em razão das modificações acima, resolvem os sócios consolidar o contrato social, que passa a vigorar com a redação a seguir.

{CONSOLIDACAO}
[[fim]]

E, por estarem assim justos e contratados, assinam o presente instrumento particular de alteração contratual, para que produza seus efeitos legais.

{LOCAL_DATA}

{ASSINATURAS}
