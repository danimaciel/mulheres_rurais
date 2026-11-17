# Mulheres Rurais

Plataforma de dados sobre mulheres rurais no Brasil, organizada por cadeia produtiva. A ideia é que quem acessa escolha uma cadeia e veja, para ela, os números do Censo Agropecuário sobre quem dirige, quem trabalha e quem gera valor nos estabelecimentos, sempre com mulheres e homens lado a lado, junto com as organizações de mulheres que atuam naquela cadeia.

O piloto começa com duas frentes: café, que já tem o trabalho acumulado do Atlas das Mulheres do Café, e Amazônia, pela sociobiodiversidade, com cacau como primeira cadeia de recorte. Leite, horticultura e fruticultura entram depois, num primeiro momento só com dados do IBGE. As organizações são incorporadas cadeia por cadeia, à medida que cada base é levantada e validada.

Este repositório ainda não tem a interface. Por enquanto ele guarda a coleta dos dados e a configuração que define o que é coletado.

## Como está organizado

```
config/        o que coletar: cadeias e tabelas do SIDRA
R/             scripts de coleta e de indicadores
dados/sidra/   tabelas do Censo Agro 2017, uma por arquivo (.csv.gz)
dados/indicadores/ indicadores de trabalho invisível por cadeia
dados/organizacoes/
dados/metadados/   situação da última coleta
docs/          notas de método
.github/workflows/ atualização mensal
```

`config/cadeias.csv` liga cada cadeia ao código da classe de atividade econômica no SIDRA (classificação 12440). Hoje estão lá café (112888), cacau (112889) e o total de todas as atividades (110016), que serve de referência para comparar. `config/tabelas_censo_agro.csv` lista as tabelas, os níveis territoriais de cada uma (n1 é Brasil, n3 são as UFs e n6 os municípios), se há recorte por atividade e quais classificações entram abertas. `config/tabelas_series.csv` faz o mesmo para as séries anuais: PAM (5457), PEVS (289), PPM (74) e PNAD Contínua (7015).

## Coleta

Os dados do IBGE vêm da API do SIDRA. Para cada tabela, a configuração diz se ela tem a classe de atividade e quais classificações devem vir abertas por categoria (sexo do produtor, tipo de pessoal ocupado etc.); as que não estão listadas vêm só no total, o que mantém o tamanho das consultas sob controle. Tabelas marcadas como "a confirmar" são testadas com o recorte por atividade e, se a API recusar, coletadas sem ele, com o registro disso na situação da coleta. Consultas municipais são feitas estado por estado e cadeia por cadeia, porque a API recusa respostas com mais de 100 mil valores.

Na PAM, na PEVS e na PPM o recorte é por produto. Os produtos são escolhidos pelo nome, com um filtro na configuração (na PAM, por exemplo, café, cacau, açaí, guaraná e urucum), e os códigos são lidos da própria API a cada coleta. PEVS e PPM entram com todos os produtos. Brasil e UFs vêm com os dez últimos anos publicados e os municípios com os cinco últimos, para manter os arquivos num tamanho razoável.

O serviço de metadados do IBGE não responde aos servidores do GitHub, por isso a coleta não depende dele e usa só a API de valores.

A base de organizações da Amazônia é lida do repositório [organizacoes_mulheres_amazonia](https://github.com/danimaciel/organizacoes_mulheres_amazonia), onde ela é mantida. Qualquer correção de registro deve ser feita lá; aqui ela só é importada, com a versão de origem anotada em cada linha.

As organizações das outras cadeias são levantadas aqui mesmo, uma base por cadeia em `dados/organizacoes/`, com o mesmo esquema. A primeira é a do cacau (`cacau.csv`). O que entra, como cada registro é verificado e o que ficou de fora estão em [docs/organizacoes.md](docs/organizacoes.md).

Uma regra vale para todas as fontes: um arquivo só é substituído quando a versão nova chega completa. Se a API estiver fora do ar, devolver erro ou uma base bem menor que a anterior (queda de mais de 20% nas linhas), o arquivo antigo fica como está e o motivo é registrado em `dados/metadados/situacao_coleta.csv`. Isso evita que uma falha pontual do IBGE apague dados que estavam corretos.

Os arquivos do SIDRA são gravados como CSV comprimido (.csv.gz), porque a tabela 6887 no nível municipal passa de 200 MB em texto puro. O R lê direto com `read.csv`, sem precisar descompactar.

O workflow `atualizar_dados.yml` roda no dia 5 de cada mês e também pode ser disparado manualmente pela aba Actions. Ele só faz commit quando algo mudou.

Para rodar localmente, a partir da raiz do repositório, com os pacotes `httr` e `jsonlite` instalados:

```
Rscript R/coletar_censo_agro.R
Rscript R/coletar_censo_agro.R 6883 6887
Rscript R/coletar_series.R
Rscript R/importar_organizacoes.R
Rscript R/coletar_insumos_indicadores.R
Rscript R/indicadores_trabalho_invisivel.R
```

## Indicadores de trabalho invisível

Os quatro indicadores do Atlas das Mulheres do Café (trabalho familiar não reconhecido, direção invisível, dupla jornada e valor da produção ligado às mulheres) são recalculados para cada cadeia de `config/indicadores.csv` ao fim de cada coleta. Para incluir uma cadeia, basta uma linha nesse arquivo com a classe de atividade, o grupo de atividade da tabela 6768 e os filtros de produto da 6955 e da PAM. O método, as premissas e a conferência com os números do Atlas estão em [docs/indicadores.md](docs/indicadores.md).

## Cuidados na leitura dos dados

Algumas coisas do Censo Agro 2017 precisam estar claras para quem for usar ou apresentar esses números.

As tabelas 6883 e 6887 classificam o estabelecimento só pela atividade principal. Um estabelecimento que produz café como atividade secundária não aparece como café, então essas tabelas subestimam o tamanho real da cadeia.

Das tabelas coletadas hoje, só a 6883 e a 6887 têm recorte por classe de atividade. As demais (6768, 6779, 6851, 6869, 6776, 6955, 6957 e 8943) a API só entrega para o conjunto dos estabelecimentos.

A 8943 é a que mostra quantos estabelecimentos dirigidos por mulheres e por homens têm o produtor associado a cooperativa, sindicato ou entidade de classe, associação ou movimento de produtores e associação de moradores. É o panorama geral do associativismo, e vale para todas as atividades juntas: nenhuma tabela do Censo 2017 cruza a associação com a cadeia produtiva.

O total de todas as atividades é referência, nunca dado de uma cadeia. Quando uma tabela não tem recorte por atividade, as linhas recebem a marca "Todas as atividades (tabela sem recorte por atividade)" e não podem ser apresentadas como dado de café, cacau ou qualquer outra cadeia.

O IBGE omite valores com poucos informantes para proteger o sigilo, e eles aparecem como "X". Esses casos ficam com `sigilo = TRUE` e `valor` vazio, e o símbolo original é mantido em `valor_bruto`. Por causa do sigilo, a soma dos municípios não fecha com o total do estado; para totais, use sempre o dado da UF ou do Brasil. O traço ("-") é zero absoluto e vira 0.

PAM, PEVS e PPM medem a produção do município, sem informação sobre quem produz. Servem para dar a dimensão de cada cadeia no território, mas não podem ser lidas como produção de mulheres. O cruzamento com o Censo Agro, quando for feito, precisa deixar claro que é uma estimativa.

A tabela 7015 da PNAD Contínua traz a média de horas semanais em afazeres domésticos e cuidados, por sexo, de 2016 a 2022, para Brasil e UFs. Ela cobre toda a população de 14 anos ou mais, sem separar a área rural, então serve de contexto para a dupla jornada e não como medida específica das mulheres rurais.

Na contagem de pessoal ocupado, a categoria "com laço de parentesco com o produtor" inclui o próprio produtor ou produtora.

## Próximos passos

Está prevista a aplicação, para cacau e para as próximas cadeias, dos indicadores já calculados para o café: trabalho familiar não reconhecido, direção invisível, dupla jornada e valor da produção feminina. A base do cacau ainda precisa de uma segunda rodada na Bahia e da conferência dos CNPJs. As organizações das próximas cadeias vão entrar por um formulário com fila de validação antes da publicação.

## Fontes

IBGE, Censo Agropecuário 2017, via SIDRA (sidra.ibge.gov.br).
Base de organizações de mulheres da Amazônia, repositório organizacoes_mulheres_amazonia.
Organizações de mulheres do cacau: levantamento próprio, com a fonte de cada registro em `dados/organizacoes/cacau.csv`.
