%% =========================================================================
%% MÓDULOS DO MOU — NPPS / Armando Advogados
%%
%% Cada módulo é um ou mais capítulos prontos para colar no ponto ">>> MÓDULOS
%% DO CASO AQUI <<<" do esqueleto. Quando usar cada um, de que modelo veio e o
%% que decidir: referencias/catalogo-de-modulos.md.
%%
%% As chaves {..} são únicas no documento inteiro. Se colar o mesmo módulo
%% duas vezes (duas holdings patrimoniais, por exemplo), troque o sufixo.
%% Remissão entre módulos só por {ref:chave} -- se o módulo-alvo não for
%% usado, a montagem acusa a chave inexistente e você decide o que fazer.
%% =========================================================================


%%% MÓDULO M01 — HOLDING EMPRESARIAL ========================================
%%% Fonte: Agroboi cap. 3; Mulinari cap. 3; M21 cap. 4.

# CAP empresarial | DO PLANEJAMENTO EMPRESARIAL – CONSTITUIÇÃO DA HOLDING CONTROLADORA

#. {emp-constituicao} Com o objetivo de centralizar o controle empresarial e facilitar a adoção de critérios relacionados à governança e à operacionalização das atividades, será constituída uma Holding Empresarial, responsável pela gestão das empresas operacionais, visando à coordenação e à gestão estratégica das seguintes sociedades:

[[Razão Social Ltda]], inscrita no CNPJ sob o nº [[00.000.000/0000-00]];

[[Razão Social Ltda]], inscrita no CNPJ sob o nº [[00.000.000/0000-00]].

%% Com os valores já levantados (contrato social das investidas): use a
%% versão A. Sem eles, a B. Os valores vêm da armando-holding-empresarial /
%% mapeamento patrimonial -- nunca do que o cliente diz de memória.
%% Versão A:
#. {emp-integralizacao} [[Prenome]] e [[Prenome]] integralizarão, no capital social da Holding Empresarial, a totalidade das quotas de que são titulares nas sociedades operacionais, na seguinte forma:

**[[NOME DO SÓCIO]]**: {rs:0,00}, referente à participação na empresa [[RAZÃO SOCIAL LTDA]], e {rs:0,00}, referente à participação na empresa [[RAZÃO SOCIAL LTDA]], totalizando {rs:0,00};

%% Versão B (apague a A):
%% #. {emp-integralizacao} Os sócios integralizarão o capital social da Holding Empresarial mediante a transferência das quotas por eles atualmente detidas nas empresas operacionais acima mencionadas, cujos percentuais e valores serão definidos e formalizados no respectivo contrato social, à luz da efetiva titularidade hoje registrada perante os órgãos competentes.

#. {emp-acordo} Após a constituição da Holding Empresarial, será elaborado um Acordo de Sócios para regular a administração da sociedade, o exercício do direito de voto, os critérios para cessão e transferência de quotas representativas do capital social, a governança das deliberações internas, bem como as responsabilidades e atribuições de cada sócio no âmbito da sociedade, em conformidade com seus objetivos sociais.

%% Conselho: "poderá" quando ainda não há alinhamento (Mulinari, Agroboi);
%% "será" quando a família já decidiu (M21).
#. {emp-conselho} Poderá ser constituído um Conselho Consultivo, com a função de fornecer orientações e conselhos estratégicos, visando apoiar as decisões da gestão e garantir a boa governança da sociedade, com atribuição de avaliar as principais direções da empresa e oferecer recomendações para a execução do plano de negócios. Não havendo, até o momento, alinhamento definitivo entre as Partes quanto à sua criação, fica desde já registrado que o Conselho Consultivo, caso constituído, poderá futuramente ser transformado em Conselho de Administração, com poderes mais amplos, à medida que a estrutura de governança da empresa assim o exigir.

%% Opcional — nova sociedade operacional controlada pela holding (Mulinari 3.2):
%% #. {emp-nova-operacional} Será constituída, outrossim, sociedade empresária específica para [[a atividade rural atualmente exercida por X]], a qual também será controlada pela Holding Empresarial, [[arrendando, junto à Holding Patrimonial, os imóveis rurais necessários à sua exploração]].

%% Opcional — Stock Option e Vesting (M21 4.3):
%% #. {emp-stock} Será implementado Plano de Opção de Compra de Quotas (Stock Option) e Contrato de Vesting, com o objetivo de alinhar os colaboradores-chave aos interesses das empresas [[X e Y]], incentivando o engajamento e a retenção de talentos estratégicos, mediante cronograma de aquisição gradual de direitos vinculado à permanência e ao desempenho.


%%% MÓDULO M02 — SUCESSÃO E ADMINISTRAÇÃO DA HOLDING EMPRESARIAL ===========
%%% Fonte: Agroboi cap. 4; Mulinari cap. 4; M21 cap. 5.
%%% Pressupõe doação de quotas com reserva de usufruto. Leia as decisões
%%% D3 (reversão) e D4 (cláusulas restritivas e colação) antes de usar.

# CAP sucessao-emp | DOS DIREITOS HEREDITÁRIOS, DEVERES DOS SUCESSORES E ADMINISTRAÇÃO DA HOLDING EMPRESARIAL

#. {se-participacao} [[Os herdeiros Prenome e Prenome]] farão jus à participação proporcional de [[{pct:50} cada]] no capital social da Holding Empresarial, tão logo sejam formalizadas as respectivas doações. Tal participação estará vinculada à titularidade das quotas da holding e aos rendimentos provenientes da exploração dos bens e ativos da empresa, sendo, contudo, de natureza de nua-propriedade, com o usufruto vitalício integralmente reservado [[a Prenome / aos doadores Prenome e Prenome]]. O usufruto vitalício confere ao(s) usufrutuário(s) o direito de fruir e administrar os bens da holding, inclusive com poderes decisórios sobre a gestão societária e a distribuição de rendimentos.

%% Só quando os doadores são um casal (Agroboi 4.1.1):
##. {se-acrescer} Com o falecimento de um dos usufrutuários, o usufruto e os direitos políticos se consolidarão integralmente em favor do usufrutuário sobrevivente.

%% D4 — o texto abaixo já traz a justa causa e a colação. Escolha a
%% alternativa da colação com a coordenação e apague a outra.
#. {se-clausulas} As doações de quotas serão gravadas com cláusulas de proteção patrimonial, a saber: (i) reserva de usufruto vitalício em favor do(s) doador(es); (ii) inalienabilidade; (iii) incomunicabilidade; e (iv) impenhorabilidade, tendo por justa causa [[a preservação do controle familiar das empresas e a proteção do patrimônio contra a dispersão decorrente de vínculos conjugais e de dívidas pessoais dos donatários]]. As doações [[serão feitas como adiantamento da legítima, sujeitas à colação / sairão da parte disponível do(s) doador(es), com dispensa de colação, nos termos dos arts. 2.005 e 2.006 do Código Civil]].

%% D3 — reversão. Só em favor do doador (art. 547, parágrafo único, do CC).
#. {se-reversao} Será inserida cláusula de reversão nas doações, nos termos do art. 547 do Código Civil, de modo que, falecendo o donatário antes do doador, as quotas doadas retornarão ao patrimônio do doador, com a finalidade de assegurar a continuidade da gestão e o controle dos ativos da holding, conforme delineado no planejamento sucessório.

#. {se-administracao} A gestão e a administração da Holding Empresarial serão de responsabilidade exclusiva de [[Prenome e Prenome]], que exercerão a função de administradores de forma plena e contínua. Embora [[os demais sucessores]] detenham participação societária, a autoridade para a tomada de decisões estratégicas, operacionais e financeiras, bem como a condução dos negócios da holding, será atribuída exclusivamente aos administradores enquanto vigente o usufruto de que trata a {ref:se-participacao}, dispensando-se a aprovação ou a intervenção dos demais sucessores nas deliberações cotidianas da gestão.

%% Só com dois administradores que devem agir juntos (Agroboi 4.5):
%% #. {se-conjunta} As deliberações da sociedade deverão ser tomadas em conjunto por [[Prenome e Prenome]], vedada a prática de atos isolados sem a expressa anuência de ambos.

#. {se-extincao} Extinto o usufruto, a administração passará a ser exercida por [[Prenome e Prenome]], de forma conjunta, podendo ser sujeita a alteração no decorrer do planejamento sucessório.

#. {se-excepcional} Em situações excepcionais, nas quais a decisão possa impactar significativamente a estrutura da holding, a matéria será submetida à deliberação dos sócios, observado o quórum previsto no Contrato Social e na legislação aplicável, assegurados o direito de voto e a participação na decisão.

#. {se-continuidade} O planejamento sucessório será conduzido com o objetivo de assegurar a continuidade da gestão e a preservação do patrimônio familiar ao longo das gerações. A nomeação de novos sucessores, bem como qualquer alteração na estrutura de governança, será realizada de forma transparente, mediante a concordância de todos os sócios, respeitando tanto os desejos dos envolvidos quanto as necessidades estratégicas da gestão das empresas.


%%% MÓDULO M03 — HOLDING PATRIMONIAL =========================================
%%% Fonte: Agroboi cap. 6 (holding única); M21 cap. 6 (uma por sócio);
%%% Mulinari cap. 5 (do patriarca + individuais por herdeiro).
%%% O quadro de imóveis sai do quadro da armando-mapeamento-cit: matrícula,
%%% cartório e município da CIT, proprietário do registro. No MOU a descrição
%%% é RESUMIDA; a literal vai no contrato social (armando-holding-patrimonial).

# CAP patrimonial | DO PLANEJAMENTO PATRIMONIAL

%% Variante "holding única" (Agroboi). Para "uma por sócio" ou "do patriarca
%% + individuais", ver catalogo-de-modulos.md, M03.
#. {pat-constituicao} Será constituída uma Holding Patrimonial com o objetivo de centralizar a propriedade e a gestão dos bens imóveis pertencentes [[aos sócios Prenome e Prenome]] e não vinculados às empresas operacionais, a qual será responsável pela administração e titularidade dos respectivos ativos.

#. {pat-quadro} Os bens imóveis serão integralizados ao capital social da Holding Patrimonial, com o devido registro nas respectivas matrículas, sem prejuízo da inclusão de outros imóveis que venham a ser indicados no ato de constituição. Segue o detalhamento das matrículas a serem integralizadas:

| Ordem | Matrícula | Cartório | Descrição resumida | Município - UF | Proprietário(s) |
| 1 | [[nº]] | [[Cartório de Registro de Imóveis de X]] | [[Lote nn, Quadra nn, área]] | [[Cidade - UF]] | [[Prenome e Prenome]] |

%% Imóvel rural arrendado à operacional (Mulinari 5.6.2):
%% #. {pat-arrendamento} Os imóveis de natureza rural relacionados no quadro da {ref:pat-quadro} serão integralizados na Holding Patrimonial, que manterá sua titularidade e os arrendará à [[sociedade operacional]], a qual explorará a atividade agropecuária em nome próprio, de modo a manter separados o patrimônio imobiliário e o risco da atividade operacional.

#. {pat-doacoes} Integralizados os bens, a sucessão será realizada por meio de doação de quotas da Holding Patrimonial a [[Prenome e Prenome]], gravadas com as cláusulas de proteção patrimonial e de reversão previstas [[nas cláusulas {num:se-clausulas} e {num:se-reversao}]], com reserva de usufruto vitalício em favor [[do(s) doador(es)]].


%%% MÓDULO M04 — SUCESSÃO E ADMINISTRAÇÃO DA HOLDING PATRIMONIAL ===========
%%% Fonte: Agroboi cap. 7; Mulinari cap. 6; M21 cap. 7.

# CAP sucessao-pat | DOS DIREITOS HEREDITÁRIOS, DEVERES DOS SUCESSORES E ADMINISTRAÇÃO DA HOLDING PATRIMONIAL

#. {sp-governanca} Visando garantir a boa governança e a continuidade da administração dos bens da Holding Patrimonial, os sucessores reconhecem a importância de uma gestão compartilhada e responsável. Este capítulo estabelece as diretrizes e os procedimentos a serem observados para assegurar que as decisões sejam tomadas de forma estruturada, respeitando os interesses e os princípios previamente acordados entre as Partes.

#. {sp-administracao} A gestão e a administração da Holding Patrimonial serão de responsabilidade exclusiva de [[Prenome e Prenome]] enquanto perdurar o usufruto, a quem caberão as decisões estratégicas, operacionais e financeiras e a condução dos negócios da holding. [[Em caso de falecimento de um deles, o usufruto será consolidado integralmente no usufrutuário sobrevivente.]] Extinto o usufruto, a administração será assumida, de forma conjunta, por [[Prenome e Prenome]].

%% Venda de bens depois do usufruto (M21 7.3–7.4). Opcional.
%% #. {sp-venda} Extinto o usufruto, a alienação de bem relevante da Holding Patrimonial dependerá de deliberação dos sócios em reunião convocada para esse fim, com o quórum de [[unanimidade / três quartos do capital social]], lavrada em ata.

%% Aplicações financeiras na holding (M21 7.5). Opcional.
%% #. {sp-rendimentos} Os rendimentos de aplicações financeiras integrantes do patrimônio da holding serão distribuídos aos sócios na proporção de suas participações, observado o usufruto vigente.

#. {sp-conflitos} Em caso de desentendimentos ou conflitos entre os sucessores, todos os envolvidos comprometem-se a envidar seus melhores esforços na busca de soluções consensuais, com vistas à preservação da harmonia familiar e à continuidade das atividades da holding, de forma a não comprometer a gestão e a administração dos bens societários.


%%% MÓDULO M05 — VEDAÇÃO DE CÔNJUGES E EX-CÔNJUGES ==========================
%%% Fonte: Mulinari cap. 7 (versão unificada, a mais recente); Agroboi caps.
%%% 8 e 9 e M21 caps. 8 e 9 (versão em dois capítulos).

# CAP conjuges | DA VEDAÇÃO À PARTICIPAÇÃO DE CÔNJUGES E EX-CÔNJUGES

#. {cj-vedacao} Fica vedada a admissão de cônjuges, companheiros(as), ex-cônjuges ou ex-companheiros(as) dos sucessores no quadro societário e na administração [[da Holding Empresarial e da Holding Patrimonial]], tendo em vista que a estrutura ora idealizada tem por finalidade preservar o patrimônio familiar na linha sucessória direta [[de Prenome]], evitando sua diluição por vínculos conjugais supervenientes.

#. {cj-divorcio} Em caso de divórcio ou dissolução de união estável de qualquer dos sucessores, fica vedada a admissão do ex-cônjuge ou ex-companheiro(a) no quadro societário das holdings, independentemente da forma de partilha de bens definida judicialmente ou por acordo, permanecendo as quotas integralmente com o herdeiro titular, resguardadas pelas cláusulas de incomunicabilidade e impenhorabilidade previstas neste instrumento.

#. {cj-transferencia} Qualquer transferência de participação societária em favor de terceiros somente poderá ocorrer mediante formalização adequada e consentimento expresso e unânime dos sócios.

#. {cj-espelho} As vedações deste capítulo serão reproduzidas no Contrato Social de cada holding, nas cláusulas de cessão de quotas e de sucessão por falecimento, e no Acordo de Sócios.

%% Holdings individuais dos herdeiros (Mulinari 7.4). Opcional:
%% #. {cj-individuais} A vedação da {ref:cj-vedacao} não se aplica às Holdings Patrimoniais individuais de [[Prenome e Prenome]], cuja composição fica a critério exclusivo do respectivo titular, ressalvado que, em caso de divórcio ou dissolução de união estável, é vedada a entrada do ex-cônjuge ou ex-companheiro(a) na sociedade.


%%% MÓDULO M06 — INCAPACIDADE OU FALECIMENTO DOS ADMINISTRADORES ============
%%% Fonte: M21 cap. 10 (corrigida a autorremissão da 10.3).

# CAP incapacidade | DA ADMINISTRAÇÃO EM CASO DE INCAPACIDADE OU FALECIMENTO DOS ADMINISTRADORES

#. {inc-remanescente} Em caso de falecimento, incapacidade temporária ou impossibilidade de atuação de qualquer dos administradores, [[Prenome ou Prenome]], a administração das empresas será exercida integralmente pelo administrador remanescente, que assumirá todas as responsabilidades gerenciais e manterá a continuidade das funções administrativas, com o dever de prestar contas regularmente aos demais sucessores sobre as atividades e a situação financeira das empresas.

#. {inc-interino} Na ausência definitiva e simultânea de [[Prenome e Prenome]], será nomeado administrador interino, por unanimidade dos sucessores ou, na falta de consenso, na forma prevista no Contrato Social, o qual exercerá a gestão até a nomeação de novo administrador.

#. {inc-medidas} Até a formalização da nomeação de que trata a {ref:inc-interino}, os sucessores poderão adotar as medidas imediatas necessárias à continuidade da administração e à preservação dos bens das holdings, como a convocação de reunião extraordinária de sócios e a adoção de planos de contingência.

%% Procurações cruzadas (M21 3.5–3.6). Opcional:
%% #. {inc-procuracao} [[Prenome e Prenome]] outorgarão, reciprocamente e em nome das empresas, procuração pública com poderes de administração, para que, na ausência ou impossibilidade de um, o outro possa praticar os atos de gestão necessários.


%%% MÓDULO M07 — TESTAMENTO ===================================================
%%% Fonte: M21 cap. 11; Mulinari 9.3. Corrigido: testamento é personalíssimo e
%%% revogável só pelo testador (arts. 1.858 e 1.969 do CC); testamento
%%% conjuntivo é vedado (art. 1.863). Um testamento por pessoa.

# CAP testamento | DO TESTAMENTO

#. {test-intencao} [[Prenome]] manifesta a intenção de lavrar testamento no qual expressará sua vontade quanto à conclusão do planejamento sucessório empresarial e patrimonial, [[destinando a totalidade da parte disponível de maneira igualitária entre os herdeiros]], observadas as diretrizes deste Memorando.

#. {test-revogacao} O testamento é ato personalíssimo e poderá ser revogado ou alterado a qualquer tempo pelo testador, na forma da lei. Alteração que repercuta no planejamento sucessório ou na administração das holdings será comunicada aos sucessores e incorporada ao plano sucessório de forma documentada.

#. {test-interpretacao} Havendo dúvida na interpretação das disposições testamentárias, os sucessores, assistidos por advogados, buscarão a solução que melhor preserve a continuidade da administração das holdings.


%%% MÓDULO M08 — OTIMIZAÇÃO TRIBUTÁRIA E DISTRIBUIÇÃO DE LUCROS ==============
%%% Fonte: Mulinari cap. 8. Texto genérico de propósito: a regra muda
%%% (Lei 15.270/2025) e o detalhe vai em orientação à parte.

# CAP tributario | DA OTIMIZAÇÃO TRIBUTÁRIA E DA DISTRIBUIÇÃO DE LUCROS

#. {trib-finalidade} A estrutura ora delineada também tem por finalidade viabilizar, de forma organizada e planejada, a distribuição de lucros das empresas operacionais aos sócios, otimizando os efeitos da tributação hoje incidente sobre tais distribuições, observados os limites e requisitos da legislação tributária em vigor.

#. {trib-orientacao} A forma e a periodicidade das distribuições serão objeto de orientação específica por ocasião da constituição e regularização das holdings, considerando a situação fiscal de cada uma das empresas operacionais.


%%% MÓDULO M09 — HERDEIRO VULNERÁVEL (CURATELADO OU MENOR) ===================
%%% Fonte: Mulinari cap. 9. Dado de saúde é dado sensível (LGPD, art. 5º, II):
%%% só o que a sentença diz e o planejamento precisa. Nunca "incapacidade
%%% absoluta" para maior de 16 anos (art. 3º do CC, Lei 13.146/2015).

# CAP vulneravel | DA PROTEÇÃO PATRIMONIAL E SUCESSÓRIA DE [[NOME DO HERDEIRO]]

#. {vul-premissa} Em razão de sua condição de pessoa sob curatela, nos termos da sentença proferida nos autos do processo nº [[número]] ([[Vara]]), [[com trânsito em julgado em dd/mm/aaaa]], sendo [[Prenome]] seu curador [[definitivo]], o planejamento relativo a [[Prenome do herdeiro]] observará proteção reforçada e diferenciada em relação aos demais herdeiros.

#. {vul-legitima} As Partes deliberaram por não incluir [[Prenome do herdeiro]], nesta etapa, como sócio das holdings. Fica resguardado que sua legítima não poderá ser reduzida, suprimida ou diluída por liberalidade em favor de terceiros ou dos demais herdeiros, cabendo a [[Prenome]], no testamento a ser lavrado, assegurar-lhe renda, proteção patrimonial e cuidados adequados, sem prejuízo da parte disponível destinada aos demais.

#. {vul-testamento} O testamento contemplará, quanto a [[Prenome do herdeiro]]: (i) a destinação de sua legítima, com as cláusulas de proteção patrimonial cabíveis e a respectiva justa causa (art. 1.848 do Código Civil); (ii) a nomeação de curador especial para os bens a ele destinados (arts. 1.733, § 2º, e 1.781 do Código Civil); (iii) a indicação de curador substituto para a hipótese de impossibilidade superveniente do atual curador; (iv) disposições quanto a alimentos, sustento e cuidados continuados; e (v) as diretrizes de cuidado que [[Prenome]] desejar registrar.

#. {vul-compromisso} [[Prenome e Prenome]] reconhecem, para além de qualquer obrigação legal de alimentos, o compromisso moral e familiar de zelar pelo bem-estar de [[Prenome do herdeiro]], comprometendo-se a colaborar para a continuidade de seus cuidados e sustento.

#. {vul-reavaliacao} As Partes poderão, no futuro, reavaliar a inclusão de [[Prenome do herdeiro]] como sócio das holdings, hipótese em que o ato será precedido de nomeação de curador especial, de manifestação do Ministério Público e de cláusulas de proteção patrimonial reforçadas.

#. {vul-inegociavel} A proteção de [[Prenome do herdeiro]] constitui premissa essencial e inegociável de todo o planejamento, de modo que nenhuma etapa de constituição, alteração ou registro das holdings será concluída em desacordo com este capítulo.


%%% MÓDULO M10 — ESTRUTURA SOCIETÁRIA E EMPRESAS FORA DO PLANEJAMENTO =======
%%% Fonte: Agroboi cap. 5. O organograma é o item 10 do NPPS (Canva hoje).

# CAP estrutura | DA ESTRUTURA SOCIETÁRIA E DAS EMPRESAS NÃO INTEGRANTES DA HOLDING

#. {est-organograma} Para melhor visualização e compreensão do planejamento patrimonial e sucessório, as Partes apresentam a seguir o organograma representativo da estrutura societária consolidada, contemplando [[a Holding Patrimonial, a Holding Empresarial e as sociedades operacionais]], bem como as empresas que permanecem fora do presente planejamento.

[[ORGANOGRAMA — inserir a imagem]]

#. {est-fora} As Partes reconhecem e concordam que [[RAZÃO SOCIAL LTDA, responsável por X]], permanecerá enquadrada no regime tributário atualmente adotado, não sendo alcançada pela presente reorganização societária.


%%% MÓDULO M11 — REORGANIZAÇÃO PRÉVIA DE QUOTAS ENTRE OS SÓCIOS ============
%%% Fonte: M21 cap. 3. Para ajustes de participação ANTES da holding (cessão
%%% entre sócios, sócio que sai, igualação). Números da Junta, não do cliente.

# CAP reorganizacao | DA TRANSFERÊNCIA DE QUOTAS DA [[RAZÃO SOCIAL LTDA]]

#. {reo-historico} [[Prenome]], titular de {pct:75} do capital social da [[Razão Social Ltda]], correspondente a {qt:5100000} quotas de {rs:1,00} cada, totalmente subscritas e integralizadas, cedeu [[nº]] quotas a [[Prenome]], conforme alteração contratual arquivada na Junta Comercial [[do Estado do Tocantins]] em [[dd/mm/aaaa]].

#. {reo-retirante} O sócio retirante, [[NOME]], permanecerá no quadro societário até [[mês/aaaa]], quando suas quotas, correspondentes a {pct:25} do capital social, serão cedidas a [[Prenome]], nas condições ajustadas entre as Partes.

#. {reo-igualacao} Em momento posterior à cessão de que trata a {ref:reo-retirante}, as participações de [[Prenome e Prenome]] serão igualadas em {pct:50} para cada um, por nova cessão de quotas ou aumento de capital, com a respectiva alteração contratual e registro na Junta Comercial.


%%% MÓDULO M12 — PARTILHA APÓS DIVÓRCIO PELA VIA DAS HOLDINGS ==============
%%% Fonte: Megga caps. 1 (1.4–1.6), 3, 4 e 5. Caso raro e de alto risco
%%% tributário: leia o catálogo (M12) antes de usar.

# CAP divorcio | DA HOMOLOGAÇÃO DO DIVÓRCIO E DA PARTILHA DE BENS

#. {div-homologacao} O divórcio consensual das Partes foi homologado pelo Juízo da [[Vara]], nos autos do processo nº [[número]], por sentença proferida em [[dd/mm/aaaa]], tendo sido ajustados pensão alimentícia, guarda e regime de convivência, e designada a partilha de bens para momento oportuno.

#. {div-metodo} A partilha de bens será efetuada pela constituição de [[duas holdings — uma para as participações societárias e outra para os imóveis comuns]] e posterior cessão, por [[Prenome]] a [[Prenome]], da totalidade de suas quotas, como desdobramento natural da partilha.

#. {div-valor} As Partes declaram que o patrimônio comum e as participações societárias objeto deste Memorando foram avaliados de comum acordo em {rs:0,00}, cabendo a cada ex-cônjuge {pct:50} desse valor, que servirá de parâmetro único para o pagamento das quotas e de todos os direitos patrimoniais de cada um, considerados os ativos e passivos das empresas e os demais bens comuns.

#. {div-excluido} O imóvel de matrícula nº [[nº]] não integrará a holding: [[Prenome]] quitará o financiamento e o transferirá a [[Prenome]] até o término dos pagamentos previstos no {cap:pagamento}.


%%% MÓDULO M13 — CESSÃO DE QUOTAS E FORMA DE PAGAMENTO =======================
%%% Fonte: Megga cap. 6. O TOTAL da tabela é conferido pelo script.

# CAP pagamento | DA CESSÃO E TRANSFERÊNCIA DE QUOTAS E DA FORMA DE PAGAMENTO

#. {pag-cessao} A totalidade das quotas pertencentes a [[Prenome]] nas holdings será cedida e transferida a [[Prenome]], que assumirá a totalidade das participações societárias.

#. {pag-cronograma} O preço da cessão será pago conforme o cronograma abaixo:

| Data | Valor | Forma |
| [[dd/mm/aaaa]] | R$ [[0,00]] | Moeda corrente |
| [[mês/aaaa]] | R$ [[0,00]] | Moeda corrente, atualizada pelo IPCA |
| TOTAL | R$ [[0,00]] | |

#. {pag-atualizacao} As parcelas anuais serão atualizadas pelo Índice Nacional de Preços ao Consumidor Amplo – IPCA, desde [[a data de assinatura deste Memorando]] até a do efetivo pagamento.

%% Pagamento em imóveis (Megga 6.4). Confira valor unitário × quantidade.
%% #. {pag-imoveis} Parte do preço, no valor de {rs:0,00}, será paga mediante cessão de direitos sobre [[nº]] unidades do [[empreendimento]], com entrega prevista para [[mês/aaaa]], admitida tolerância de [[seis]] meses. Não havendo entrega até o fim da tolerância, o valor será pago em dinheiro, à razão de {rs:0,00} por unidade.

#. {pag-quitacao} Concluídos os pagamentos do cronograma da {ref:pag-cronograma}, [[Prenome]] dará plena quitação quanto aos direitos patrimoniais decorrentes da partilha, inclusive participações societárias e imóveis mencionados neste instrumento.


%%% MÓDULO M14 — SAÍDA DE SÓCIO ==============================================
%%% Fonte: Megga cap. 7.

# CAP saida | DOS PROCEDIMENTOS DE SAÍDA DE SÓCIO

#. {sai-momento} A cessão das quotas de [[Prenome]] ocorrerá após a constituição das holdings, a efetivação do controle sobre as empresas operacionais e a integralização dos imóveis, mediante contrato de cessão e transferência de quotas e a respectiva alteração contratual.

#. {sai-prazo} [[Prenome]] compromete-se a retirar-se das sociedades até [[dd/mm/aaaa]] e a conceder as autorizações necessárias à conclusão da integralização do capital das holdings, ainda que posteriores à sua saída.


%%% MÓDULO M15 — RESPONSABILIDADE POR PASSIVOS APÓS A SAÍDA =================
%%% Fonte: Megga cap. 8.

# CAP passivos | DAS RESPONSABILIDADES

#. {pas-ressarcimento} Após a efetiva saída de [[Prenome]] das sociedades, qualquer passivo exigível que venha a ser debitado de suas contas ou cobrado em seu nome será integralmente ressarcido por [[Prenome]] no prazo de {n:30} dias, contados da notificação da cobrança, mediante depósito em conta bancária por ela indicada.


%%% MÓDULO M16 — GARANTIAS ===================================================
%%% Fonte: Megga cap. 9 ("Gado", sem identificação -- corrigido).

# CAP garantias | DAS GARANTIAS

#. {gar-bem} Em garantia do pagamento previsto no {cap:pagamento}, [[Prenome]] constituirá em favor de [[Prenome]] [[penhor pecuário]] sobre [[quantidade, espécie, marca e idade dos animais]], localizados [[na Fazenda X, matrícula nº nn, Município - UF]].

#. {gar-forma} A garantia será formalizada em instrumento próprio, registrado no Cartório de Registro de Imóveis da circunscrição em que estiverem os bens (art. 1.438 do Código Civil), o qual definirá as condições de substituição, retirada e excussão em caso de inadimplemento.

#. {gar-cooperacao} [[Prenome]] cooperará para a efetivação da garantia, permitindo o acesso aos bens e fornecendo a documentação necessária à sua identificação e verificação.


%%% MÓDULO M17 — CUSTOS DA OPERAÇÃO ==========================================
%%% Fonte: Megga 5.9; M21 cap. 6, parágrafo único. Cláusula avulsa: cole no
%%% fim do capítulo de obrigações.

#. {custos} Todos os custos, despesas e encargos decorrentes da constituição das holdings e das operações subsequentes, incluindo, mas não se limitando a, alterações societárias, integralização de bens, emolumentos de cartório, tributos, taxas e honorários advocatícios, serão suportados por [[RAZÃO SOCIAL LTDA, CNPJ nº 00.000.000/0000-00 / cada sócio, quanto à sua holding patrimonial]].


%%% MÓDULO M18 — PRAZO CERTO ==================================================
%%% Fonte: Megga 2.2. Cláusula avulsa: substitui {encerramento} na vigência.

#. {prazo-certo} A transferência integral do patrimônio objeto deste Memorando deverá ser concluída até [[dd/mm/aaaa]], e os pagamentos previstos no {cap:pagamento} serão realizados entre [[mês/aaaa]] e [[mês/aaaa]].


%%% MÓDULO M19 — NATUREZA DO INSTRUMENTO [DECISÃO D1] =========================
%%% Não está em nenhum modelo. Use só com a palavra da coordenação: define o
%%% que obriga e o que é intenção. Cole como último capítulo antes de
%%% DISPOSIÇÕES GERAIS.

# CAP natureza | DA NATUREZA DO INSTRUMENTO

#. {nat-vinculo} Vinculam as Partes desde a assinatura as obrigações [[de confidencialidade, de cooperação e de custeio]] previstas neste Memorando. As demais disposições registram a intenção das Partes quanto à estrutura e serão exigíveis na forma dos instrumentos definitivos de que trata a {ref:vig-documentos}.
