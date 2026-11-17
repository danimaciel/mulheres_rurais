# Levantamento geral de cooperativas e associações rurais

Esta base é separada das bases de organizações de mulheres. No site ela só aparece no mapa de organizações (ver a seção no fim), nunca nas listas de organizações de mulheres das cadeias. Serve de inventário amplo do associativismo rural por cadeia, para uso em outras frentes e como ponto de partida para achar grupos de mulheres que ainda não estão nas bases da plataforma. Nada daqui vai automaticamente para `dados/organizacoes/`: uma organização só passa para lá depois de verificada pelo critério descrito em `docs/organizacoes.md`.

## De onde vem

Da base aberta de CNPJ da Receita Federal, mês mais recente publicado. O workflow `levantar_organizacoes_geral.yml` (manual) baixa os arquivos de empresas e estabelecimentos e roda `scripts/levantar_organizacoes_geral.py`. Os arquivos ficam em cache do GitHub Actions por mês, com a mesma chave usada pela busca de CNPJ das organizações de mulheres, então os dois workflows não baixam a base duas vezes no mesmo mês.

Entram cooperativas (natureza jurídica 2143) e associações privadas (3999) com situação ativa, suspensa ou inapta. Baixadas e nulas ficam de fora, assim como cooperativas de crédito, saúde, transporte e ensino.

## Como uma organização entra numa cadeia

Pelo CNAE principal ou por qualquer CNAE secundário da cadeia, ou por um termo no nome. A coluna `criterio` diz se pesou o CNAE, o nome ou os dois.

Os termos do nome são de dois tipos. Os que já indicam a atividade (cafeicultores, cacauicultores, fruticultura, hortifrutigranjeiros, laticínio, produtores de leite, extrativistas, quebradeiras, seringueiros) bastam sozinhos. O nome do produto puro (café, cacau, laranja, buriti, leite) aparece muito em nome de lugar, como Cafelândia, Laranjeiras, Castanhal ou Santo Antônio do Leite, então só conta quando o nome também traz um termo rural (produtores, agricultores, assentamento, rural) ou o CNAE é agropecuário. Mesmo assim sobra algum ruído nas linhas que entraram só pelo nome.

| Cadeia | CNAEs | Exemplos de termos no nome |
|---|---|---|
| café | 0134-2/00, 1081-3/01, 1081-3/02, 1082-1/00, 4621-4/00, 4637-1/01 | cafeicultores, produtores de café, café |
| cacau | 0135-1/00, 1093-7/01 | cacauicultores, cacaueira, chocolate, cacau |
| frutas | 0131-8/00, 0132-6/00, 0133-4 (todas), 1031-7/00, 1033-3/01, 1033-3/02 | fruticultores, citricultores, vitivinicultores, polpa de fruta, açaí, banana, caju, cupuaçu |
| hortaliças | 0121-1/01, 0121-1/02 | horticultores, hortifrutigranjeiros, olericultura, horta, verduras |
| bovinos e leite | 0151-2/01 a 03, 1051-1/00, 1052-0/00, 4631-1/00 | laticínio, produtores de leite, criadores de gado, pecuaristas |
| extrativismo | 0220-9 (todas), 0230-6/00 | extrativistas, quebradeiras, seringueiros, castanheiros, babaçu, andiroba, pequi |

Uma organização pode estar em mais de uma cadeia. Além das cadeias, a base guarda as organizações rurais sem cadeia definida: CNAE das divisões 01 a 03 ou de comércio e beneficiamento de produto agropecuário, ou nome com termos como rural, agricultores, produtores, assentamento, agroecologia, pescadores, apicultores.

A maior parte das associações rurais está registrada com CNAE genérico (9499-5/00, 9430-8/00), sem atividade agropecuária declarada. Por isso o nome continua necessário, e por isso muitas associações de agricultores aparecem em `rural_total` sem cadeia.

## Arquivos

Em `dados/organizacoes_geral/`:

- `organizacoes_rurais.csv.gz`: todos os estabelecimentos selecionados.
- `cafe.csv`, `cacau.csv`, `frutas.csv`, `hortalicas.csv`, `bovinos_leite.csv`, `extrativismo.csv`: recorte por cadeia.
- `resumo.csv`: contagem por cadeia, UF e natureza, com quantas são ativas, quantas entraram só pelo nome, quantas têm nome de organização de mulheres e quantas já estão nas bases de mulheres.

Só campos institucionais: CNPJ, razão social, nome fantasia, natureza, matriz ou filial, situação, datas, CNAEs, UF e município. Endereço, telefone, e-mail e quadro de sócios não entram.

## Cruzamento com as bases de mulheres

`base_mulheres` traz o id da organização em `dados/organizacoes/` (café, cacau, Amazônia) quando o CNPJ é o mesmo. Como boa parte dessas bases ainda não tem CNPJ conferido, o cruzamento por enquanto é parcial. `nome_mulheres` marca nomes com termos como mulheres, feminino, agricultoras, produtoras ou trabalhadoras, para triagem de organizações que podem entrar nas bases da plataforma.

Quando as bases de mulheres ganham CNPJ novo, dá para refazer só as duas colunas de cruzamento, sem baixar a Receita de novo: `python scripts/levantar_organizacoes_geral.py --refazer-marcas`. A marca `nome_mulheres` não conta o par "agricultores e agricultoras", que é o jeito comum de nomear organização mista.

## No mapa de organizações do site

A página `#organizacoes` mostra esta base junto com as bases de mulheres. Quem monta os dados é `scripts/montar_organizacoes.py`, chamado pelo `montar_site.py` na publicação, e a saída é `organizacoes.json`, carregado só quando alguém abre a página.

O que entra da base geral: só a sede (matriz) e só situação ativa. Filiais, inaptas e suspensas ficam fora. Organizações que já estão nas bases de mulheres (mesmo CNPJ) aparecem uma vez só, com os dados da base de mulheres.

Ruído das linhas que entraram só pelo nome: sai sempre o que é claramente de outro ramo (associação de pais e mestres, APM, caixa escolar, conselho escolar, catadores de material reciclável, coleta seletiva). Clube, igreja, condomínio, cultura, esporte, eventos, escola e parecidos saem quando o nome não traz também um termo agropecuário (agricultores, produtores, pecuária, extrativismo, pescadores, assentamento e afins), porque "associação dos agricultores do condomínio rural" é do campo e "condomínio rural Portal do Vale" não é. Na rodada de 2026-11 isso tirou cerca de 2,6 mil linhas. A regra está nas expressões `RUIDO_SEMPRE`, `RUIDO_SEM_AGRO` e `AGRO` do script.

Organização de mulheres no mapa tem dois níveis. As das bases de mulheres da plataforma, conferidas uma a uma. E as da Receita cujo nome indica organização de mulheres, por uma marca mais estrita que a coluna `nome_mulheres`: palavra como mulheres ou feminino basta (desde que o nome não fale também em homens); atividade no feminino (agricultoras, pescadoras, marisqueiras, quebradeiras) só conta quando o masculino da mesma palavra não aparece no nome. Essas aparecem como não conferidas.

Localização: sede do município, pela tabela `config/municipios.csv` (código IBGE, nome, UF, latitude e longitude, a partir de github.com/kelvins/municipios-brasileiros). Os nomes da Receita são casados pelo nome sem acento dentro da UF, com uma lista curta de grafias antigas no script (Assu, Parati, Eldorado dos Carajás e outras). Organizações de mulheres de atuação estadual, regional ou nacional, sem município, ficam na lista e não no mapa.
