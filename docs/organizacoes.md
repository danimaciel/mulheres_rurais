# Organizações de mulheres por cadeia

A plataforma mostra, em cada cadeia, as organizações de mulheres que atuam nela. Entram dois tipos: organizações formadas por mulheres (associações, cooperativas, grupos produtivos, coletivos e redes) e organizações mistas que têm um grupo, núcleo ou coletivo de mulheres reconhecido dentro delas. Cooperativas e associações mistas sem estrutura própria das mulheres ficam de fora, mesmo quando têm mulheres na diretoria. O quadro geral de quem é associado a cooperativas e entidades de classe vem do Censo Agro (tabela 8943, por sexo de quem dirige o estabelecimento), não desta base.

Marcas de chocolate ou empresas de uma pessoa ou de uma família também não entram. Um grupo de empresárias só entra se for uma associação formal ligada à produção rural.

## Esquema

Todas as bases usam o mesmo esquema das organizações do Atlas das Mulheres do Café e da base da Amazônia, para que possam ser lidas juntas: nome, sigla, tipo, município, estado, bioma, ano de fundação, cadeia, número de associadas, público, produtos, existência de núcleo feminino, CNPJ, site institucional, fonte, endereço da fonte, trecho que resume o que a fonte diz, data da coleta, observações, grau de verificação, situação do CNPJ, data da fonte e localização.

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
