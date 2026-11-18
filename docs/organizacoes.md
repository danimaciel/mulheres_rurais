# Organizações de mulheres por cadeia

A plataforma mostra, em cada cadeia, as organizações de mulheres que atuam nela. Entram dois tipos: organizações formadas por mulheres (associações, cooperativas, grupos produtivos, coletivos e redes) e organizações mistas que têm um grupo, núcleo ou coletivo de mulheres reconhecido dentro delas. Cooperativas e associações mistas sem estrutura própria das mulheres ficam de fora, mesmo quando têm mulheres na diretoria. O quadro geral de quem é associado a cooperativas e entidades de classe vem do Censo Agro (tabela 8943, por sexo de quem dirige o estabelecimento), não desta base.

Marcas de chocolate ou empresas de uma pessoa ou de uma família também não entram. Um grupo de empresárias só entra se for uma associação formal ligada à produção rural.

## Esquema

Todas as bases usam o mesmo esquema da base de organizações do café e da base da Amazônia, para que possam ser lidas juntas: nome, sigla, tipo, município, estado, bioma, ano de fundação, cadeia, número de associadas, público, produtos, existência de núcleo feminino, CNPJ, site institucional, fonte, endereço da fonte, trecho que resume o que a fonte diz, data da coleta, observações, grau de verificação, situação do CNPJ, data da fonte e localização.

Os registros são montados só com informação institucional: o que a própria organização publica e o que sai em órgãos públicos, institutos de pesquisa, organizações parceiras e imprensa. Nomes, telefones e contatos pessoais de lideranças não entram em nenhum campo. O campo `site` guarda apenas o endereço da organização (página ou perfil institucional).

Cada registro traz pelo menos uma fonte com endereço e data. O grau de verificação usa a mesma escala da base da Amazônia (Alto, Médio, Baixo-médio, Baixo), com este critério:

- Alto: duas ou mais fontes independentes e recentes que confirmam nome, município e atuação na cadeia.
- Médio: uma fonte confiável, ou fontes que divergem em algum dado (nome por extenso, número de associadas, forma jurídica).
- Baixo-médio e Baixo: fonte única lida só em parte, nome próprio não localizado ou informação antiga sem confirmação.

A localização usa a sede municipal, com coordenada aproximada, quando a fonte não traz endereço. Isso é marcado em `precisao_geo` e `nota_geo`. O CNPJ é conferido na base aberta de CNPJ da Receita Federal com `scripts/buscar_cnpj.py`, que roda no workflow `buscar_cnpj` e grava os candidatos em `dados/organizacoes/cnpj_candidatos.csv`. O script filtra associações e cooperativas com termos ligados a mulheres, cacau e chocolate no nome, e o casamento com cada registro é feito por nome, município e estado. Quando a razão social difere do nome usado pelas fontes, ela fica em `observacoes`. O ano de fundação das fontes é mantido; a data de abertura na Receita só preenche o campo quando ele estava vazio.

## Cacau

`dados/organizacoes/cacau.csv` tem a primeira rodada do levantamento, feita em novembro de 2026 em notícias de órgãos estaduais (Agência Pará, Governo do Espírito Santo, Ministério da Agricultura), de institutos e projetos (Imaflora, Instituto Mamirauá, PRS Amazônia) e de veículos especializados no cacau.

São 14 organizações em cinco estados. No Espírito Santo, o projeto Mulheres do Cacau do Incaper deu origem a associações municipais (Linhares, Rio Bananal, Colatina e uma conjunta de Santa Teresa e São Roque do Canaã) e a uma central que reúne todas. No Pará aparecem associações e cooperativas de mulheres na Transamazônica e no Xingu (São Félix do Xingu, Medicilândia, Altamira) e no Acará, perto de Belém. Há ainda um grupo de produtoras orgânicas em Tefé (AM) e uma associação de chocolateiras em Teixeirópolis (RO).

A Bahia, que é o maior produtor ao lado do Pará, continua com três registros. A segunda rodada passou pela relação de agroindústrias apoiadas pela CAR (Bahia Produtiva) e pelas cooperativas da agricultura familiar do Sul e do Baixo Sul. Na relação da CAR, as organizações de mulheres das regiões cacaueiras trabalham com outros produtos (hortifrúti, beiju, mandioca), e a de Duas Barras do Fojo, em Mutuípe, já estava na base. As cooperativas de cacau do Sul e do Baixo Sul (Coopfesba, Coopessba, Coopafbasul, Cabruca, Cooperativa Cacau Mata Atlântica) são mistas e não têm grupo de mulheres identificado nas fontes.

Oito das 14 organizações têm CNPJ ativo na Receita (base de novembro de 2026). A conferência confirmou o nome da associação conjunta de Santa Teresa e São Roque do Canaã e a sede da Associação Juruna Tubyá em Altamira. O CNPJ da associação de Colatina tem abertura em 2012, o que não bate com as notícias de 2023 que tratam a associação como em formação. Ficaram sem CNPJ a central do Espírito Santo, a associação de Rio Bananal, a Só Cacau, o Coletivo Mulheres Pretas do Chocolate, as Guardiãs do Cacau e o grupo de Tefé, que é informal.

A busca na Receita trouxe também organizações que ainda não estão na base e precisam de uma fonte institucional antes de entrar:

- Associação das Mulheres Agricultoras Chocolateiras de Tarilândia (Jaru, RO), ativa desde 2015.
- Associação de Agricultoras Familiares do Distrito de Santa Júlia, com nome fantasia Mulheres do Canaã (São Roque do Canaã, ES), ativa desde 2016; pode ter relação com o projeto Mulheres do Cacau.
- Uma associação de mulheres da Ilha do Murucutum (Belém, PA), aberta em 2024, que leva "cacau" no nome por causa da comunidade; não há sinal de que trabalhe com cacau.

A Associação das Mulheres Produtoras de Cacau do Assentamento Nova Esperança (Arataca, BA) aparece com CNPJ baixado em 2006 e não entra.

As organizações de mulheres da Amazônia que já trabalham com cacau (por exemplo em Mazagão, AP, e Cotriguaçu, MT) continuam na base da Amazônia e não foram repetidas aqui. O que ficou de fora nesta rodada e por quê:

- Coopessba (Ilhéus, BA): cooperativa mista com diretoria majoritariamente feminina, sem núcleo de mulheres identificado.
- Coopfesba, Coopafbasul, Cabruca e Cooperativa Cacau Mata Atlântica (sul e Baixo Sul da BA): cooperativas mistas de cacau sem grupo de mulheres identificado.
- Organizações de mulheres da relação da CAR em Valença, Taperoá, Gongogi e Jequié (BA): trabalham com outros produtos ou não citam cacau.
- Mulheres da Terra (sul da BA): coletivo de marcas de chocolate lideradas por mulheres, sem associação formal.
- Cacauaré (Mocajuba, PA): empresa familiar, não organização coletiva.
- Associação Dom Oscar Romero (Uruará, PA): associação de mulheres que usa o cacau entre outras frutas nas polpas; a fonte é de 2015. Pode entrar se houver confirmação recente da atuação com cacau.
- Grupo de mulheres do assentamento Terra Vista (Arataca, BA): beneficia frutas e plantas, sem produto de cacau citado.

## Mandioca, feijão e outras lavouras temporárias, cereais e frutas

Depois do cacau, o levantamento seguiu pelas cadeias com mais estabelecimentos dirigidos por mulheres no Censo Agro: mandioca, feijão e outras lavouras temporárias (`outras_temporarias.csv`), cereais (`cereais.csv`) e frutas (`frutas.csv`). A primeira rodada foi feita em novembro de 2026 e usa o mesmo esquema e a mesma régua de verificação das outras bases.

O ponto de partida foi a base geral da Receita (`dados/organizacoes_geral/`). Dela saíram as associações e cooperativas ativas com nome de mulheres e com atividade ligada a cada cadeia, pelo CNAE principal ou secundário (cultivo de mandioca, feijão e outras lavouras temporárias, farinha de mandioca; cultivo de arroz, milho e outros cereais, beneficiamento de arroz e derivados de milho; cultivo de laranja, uva e outras frutas, conservas, sucos e polpas) ou pelo nome. São 277 pistas, em `pistas_receita_temporarias_cereais_frutas.csv`. O CNAE é declarado pela própria organização e não prova que ela trabalhe com o produto, então nenhuma pista entra na base sem uma fonte institucional. As fontes foram procuradas em órgãos estaduais (CAR e Secom da Bahia, Agência Minas e Emater-MG), Sebrae, Agência Gov, CNA/Senar, Fundação Banco do Brasil, boletins da Articulação Semiárido Brasileiro, Embrapa e imprensa especializada em cooperativismo.

Como no cacau, as organizações que já estão na base da Amazônia não foram repetidas, mesmo quando trabalham com mandioca ou frutas (Cozinha Iaçá e Associação Emanuela, em Portel e Porto de Moz; mulheres agricultoras do Mosqueiro, em Belém; Amabela, em Belterra; agroextrativistas do Cantão, no Tocantins). Já uma organização pode aparecer em mais de uma cadeia: a associação de polpas de São Félix do Xingu está no cacau e nas frutas.

### Mandioca, feijão e outras lavouras temporárias

São 8 organizações, quase todas de mandioca. Na Bahia estão a associação de mulheres do Assentamento Flor da Terra (Jequié), que tem unidade de derivados de mandioca feita com recursos da CAR; a Coomafes, cooperativa de 102 mulheres em Valença; a Cooafes, de Conceição do Coité, cooperativa mista que nasceu de quatro grupos produtivos de mulheres e hoje tem 80% de mulheres; e a Coomiagro, de Ilhéus, cooperativa de mulheres indígenas que faz farinha. Em Alagoas, a associação de mulheres quilombolas do povoado Sapé (Igreja Nova) faz massa puba, sequilho e beiju. No Espírito Santo entra a associação das produtoras quilombolas de beiju do Sapê do Norte, que conduziu a Indicação de Procedência do beiju reconhecida pelo INPI em 2024. No Pará, a AMPRAVAT, da Resex Tapajós-Arapiuns, é mista, mas a produção de derivados de mandioca é feita por coletivos de mulheres das aldeias. Em Pernambuco, os grupos de mulheres da Copagro, em Ouricuri, fazem sequilhos de goma para a alimentação escolar; a fonte traz dados de 2016 e ainda falta confirmação recente.

Nenhuma organização de mulheres voltada ao feijão apareceu com fonte. O feijão surge nas fontes como lavoura de quintal ou de roça, ao lado de outras, e não como produto de uma organização.

Pistas que precisam de fonte institucional antes de entrar: Cooperativa de Mulheres da Agricultura Familiar de Irará (BA, aberta em 2026, CNAE principal de farinha de mandioca); cooperativa agroecológica de mulheres do Assentamento Nova Panema (Dias d'Ávila, BA); Coopamaf (Bom Conselho, PE); associação de mulheres produtoras de derivados da mandioca de Lagoa da Canoa (AL); associação de mulheres de Morpara (BA), com nome fantasia Delícias da Mandiocultura; associação de mulheres quilombolas mandiocultoras de Simões (PI); Coopemjaf, cooperativa mista de jovens e mulheres de Aveiro (PA); e o grupo de mulheres do Centro Comunitário Rural Unidos de Araçás (Fátima, BA), que aparece numa notícia da CAR sem nome próprio.

Ficaram de fora: associações mistas de Poções, Santa Terezinha e Santo Amaro (BA) com casas de farinha, sem grupo de mulheres nas fontes; as beijuzeiras de São Cristóvão (SE) e o grupo familiar de tapioca de Cágados (Pindobaçu, BA), que não são organizações; e o coletivo de mulheres de Poço do Juá (Serra Dourada, BA), que produz sobretudo hortaliças e fica para o levantamento das hortaliças.

### Cereais

Só uma organização tem fonte: a associação de mulheres do Sítio Carneirinho, em Caruaru (PE), com 32 associadas e o milho como principal lavoura. O milho aparece muito ligado às mulheres pelas sementes crioulas, mas quase sempre por guardiãs individuais ou por associações e bancos de sementes mistos, que não entram pelo critério. Ficam como pistas, por terem sido lidas só no resumo de um livro da Embrapa de 2023 sobre mulheres na produção agroecológica de milho: o grupo de mulheres de Guaraciaba (SC), as guardiãs de sementes de Ibarama (RS) e a agroindústria Promessa de Futuro, de mulheres do Caxambu, em Pirenópolis (GO), que processa minimilho. Em Ibarama a Receita tem uma Associação das Mulheres Agricultoras de Ibarama, ativa desde 2004, sem fonte que a ligue ao milho. Também ficam como pistas a associação de mulheres de Uibaí (BA), com CNAE principal de cereais, e uma associação de mulheres quilombolas de Barro Alto (GO), com CNAE principal de arroz.

### Frutas

São 9 organizações. No Espírito Santo, a associação de mulheres de Cachoeirinha e Sabão, em Cariacica, transforma banana em doces, chips e banana-passa. No Norte de Minas entram a cooperativa Mulheres do Cerrado (São João da Ponte), o grupo Sabores do Cerrado, da associação de Panelinha (Miravânia), e a associação das agricultoras do Vale do Calindó (Manga), todas com polpas e doces de frutos do Cerrado, em boa parte de coleta. Na Bahia, a AMCAFES, de Palmas de Monte Alto, faz polpas com apoio da CAR. No Pará entra a associação de polpas de São Félix do Xingu; em Alagoas, a casa de beneficiamento das agricultoras da Coopaal (Flexeiras); no Acre, a Coopervida (Capixaba), cuja fonte mais recente é de 2011; e em Pernambuco, o Coletivo Luli, grupo informal de três agricultoras de Serra Talhada.

Pistas: a Abec, associação de beneficiamento de caju de Cícero Dantas (BA), que a CAR apresenta pelas mulheres que a tocam, sem dizer se é só de mulheres; a Associação Bezerra de Moraes (Carolina, MA), de polpas e mel, na mesma situação; a cooperativa de mulheres Dom Oscar Romero (Comdoru Fruits, Uruará, PA), ativa desde 2022, com fonte de 2015 da associação que a originou; a Pracaju, cooperativa de mulheres de Matões (Caucaia, CE), citada em trabalhos acadêmicos; a Comafsi, cooperativa de mulheres da Serra da Ibiapaba (CE); a associação de mulheres beneficiadoras de frutas de Mulungo (Pindaí, BA); e a Cooperelas (Sangão, SC).

Ficaram de fora as cooperativas mistas com maioria de mulheres mas sem grupo de mulheres nas fontes (Coopercuc, Coopeipe, Cooperagil, Copita, Coopaf, CAFC e Cooprima), e organizações de mulheres cujos produtos não são frutas (Apromef, de Cariacica; associação de mulheres de Chopinzinho, PR; Floryá, de Bela Vista de Goiás).

Situação do CNPJ nas três bases: 14 das 18 organizações estão ativas na Receita (base de novembro de 2026). A associação de mulheres quilombolas do povoado Sapé, a de Cariacica e a do Vale do Calindó não apareceram no recorte rural da base geral, e o Coletivo Luli é informal. Nos grupos que pertencem a cooperativas mistas (Copagro, Coopaal, Ascoppa), o CNPJ é o da cooperativa.
