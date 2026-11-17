# Levantamento geral de cooperativas e associações rurais

Esta base é separada das bases de organizações de mulheres e não entra no site. Serve de inventário amplo do associativismo rural por cadeia, para uso em outras frentes e como ponto de partida para achar grupos de mulheres que ainda não estão nas bases da plataforma. Nada daqui vai automaticamente para `dados/organizacoes/`: uma organização só passa para lá depois de verificada pelo critério descrito em `docs/organizacoes.md`.

## De onde vem

Da base aberta de CNPJ da Receita Federal, mês mais recente publicado. O workflow `levantar_organizacoes_geral.yml` (manual) baixa os arquivos de empresas e estabelecimentos e roda `scripts/levantar_organizacoes_geral.py`. Os arquivos ficam em cache do GitHub Actions por mês, com a mesma chave usada pela busca de CNPJ das organizações de mulheres, então os dois workflows não baixam a base duas vezes no mesmo mês.

Entram cooperativas (natureza jurídica 2143) e associações privadas (3999) com situação ativa, suspensa ou inapta. Baixadas e nulas ficam de fora, assim como cooperativas de crédito, saúde, transporte e ensino.

## Como uma organização entra numa cadeia

Pelo CNAE principal ou por qualquer CNAE secundário da cadeia, ou por um termo no nome. A coluna `criterio` diz se pesou o CNAE, o nome ou os dois. Casar só pelo nome traz mais ruído (por exemplo "Coco" ou "Manga" como nome de lugar), então vale olhar essas linhas com mais cuidado.

| Cadeia | CNAEs | Termos no nome |
|---|---|---|
| café | 0134-2/00, 1081-3/01, 1081-3/02, 1082-1/00, 4621-4/00, 4637-1/01 | café, cafeicultura |
| cacau | 0135-1/00, 1093-7/01 | cacau, chocolate |
| frutas | 0131-8/00, 0132-6/00, 0133-4 (todas), 1031-7/00, 1033-3/01, 1033-3/02 | fruta, polpa, açaí, banana, laranja, uva, caju, coco, manga |
| hortaliças | 0121-1/01, 0121-1/02 | horti, hortaliça, olericultura, verdura, legume |
| bovinos e leite | 0151-2/01 a 03, 1051-1/00, 1052-0/00, 4631-1/00 | leite, laticínio, bovino, gado, queijo |
| extrativismo | 0220-9 (todas), 0230-6/00 | extrativista, castanha, babaçu, quebradeira, seringueiro, andiroba, copaíba, pequi, buriti, açaí |

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
