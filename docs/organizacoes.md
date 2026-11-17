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

A localização usa a sede municipal, com coordenada aproximada, quando a fonte não traz endereço. Isso é marcado em `precisao_geo` e `nota_geo`. O CNPJ ainda não foi conferido na Receita para nenhum registro do cacau.

## Cacau

`dados/organizacoes/cacau.csv` tem a primeira rodada do levantamento, feita em novembro de 2026 em notícias de órgãos estaduais (Agência Pará, Governo do Espírito Santo, Ministério da Agricultura), de institutos e projetos (Imaflora, Instituto Mamirauá, PRS Amazônia) e de veículos especializados no cacau.

São 14 organizações em cinco estados. No Espírito Santo, o projeto Mulheres do Cacau do Incaper deu origem a associações municipais (Linhares, Rio Bananal, Colatina e uma conjunta de Santa Teresa e São Roque do Canaã) e a uma central que reúne todas. No Pará aparecem associações e cooperativas de mulheres na Transamazônica e no Xingu (São Félix do Xingu, Medicilândia, Altamira) e no Acará, perto de Belém. Há ainda um grupo de produtoras orgânicas em Tefé (AM) e uma associação de chocolateiras em Teixeirópolis (RO).

A Bahia, que é o maior produtor ao lado do Pará, ainda está sub-representada, com três registros. As listas de agroindústrias apoiadas pela CAR (Bahia Produtiva) e as cooperativas da agricultura familiar do Sul e do Baixo Sul são o próximo lugar para procurar grupos de mulheres.

As organizações de mulheres da Amazônia que já trabalham com cacau (por exemplo em Mazagão, AP, e Cotriguaçu, MT) continuam na base da Amazônia e não foram repetidas aqui. O que ficou de fora nesta rodada e por quê:

- Coopessba (Ilhéus, BA): cooperativa mista com diretoria majoritariamente feminina, sem núcleo de mulheres identificado.
- Mulheres da Terra (sul da BA): coletivo de marcas de chocolate lideradas por mulheres, sem associação formal.
- Cacauaré (Mocajuba, PA): empresa familiar, não organização coletiva.
- Associação Dom Oscar Romero (Uruará, PA): associação de mulheres que usa o cacau entre outras frutas nas polpas; a fonte é de 2015. Pode entrar se houver confirmação recente da atuação com cacau.
- Grupo de mulheres do assentamento Terra Vista (Arataca, BA): beneficia frutas e plantas, sem produto de cacau citado.
