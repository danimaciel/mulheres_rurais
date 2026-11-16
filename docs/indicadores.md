# Indicadores de trabalho invisível

Os quatro indicadores vieram do Atlas das Mulheres do Café e foram reescritos para rodar em qualquer cadeia listada em `config/indicadores.csv`. O script é `R/indicadores_trabalho_invisivel.R`, que lê só os arquivos de `dados/sidra/` e grava os resultados em `dados/indicadores/`. Ele roda no fim da coleta mensal, então os números acompanham os dados.

Todos usam dados públicos do IBGE. O Censo Agropecuário é de 2017, o mais recente com esse detalhe. Os valores em reais usam o salário mínimo de 2026 (R$ 1.621), o último ano da PAM e o último ano da PNAD Contínua disponíveis na coleta. Isso mistura anos, e é bom que quem for apresentar os números diga isso.

## Recortes

Quase tudo sai em dois recortes, e eles não devem ser confundidos.

`principal` é o dado direto do Censo para os estabelecimentos que têm a cadeia como atividade principal (tabelas 6883 e 6887, classe de atividade 12440). É um número observado, mas subconta a cadeia: no café, são 136,6 mil estabelecimentos.

`onde_ha` inclui também quem tem o produto como atividade secundária, contado na tabela 6955 (estabelecimentos com 50 pés ou mais). No café são 264,4 mil. O IBGE não publica pessoal ocupado por sexo para esses estabelecimentos, então esse recorte é estimado. Em cada município, soma-se o dado direto ao número de estabelecimentos com o produto como atividade secundária multiplicado pela média municipal de mulheres (e de homens) da família por estabelecimento, em todas as atividades. Onde o município está em sigilo, vale a média da UF. No café, a 6955 conta arábica e canéfora separadamente, e quem tem os dois entra duas vezes; o recorte pode estar um pouco inflado no ES e em RO.

A direção invisível usa um terceiro recorte, explicado abaixo.

## 1. Trabalho familiar não reconhecido

Mulheres de 14 anos ou mais que trabalham no estabelecimento por terem laço de parentesco com quem o dirige (6887), menos as mulheres que aparecem como produtoras (6883). A diferença é o número de mulheres da família que trabalham e não aparecem como produtoras. O valor desse trabalho é calculado em três cenários de dedicação: três meses por ano, meio período e tempo integral, sempre a salário mínimo.

No recorte `onde_ha`, as dirigentes também são estimadas: estabelecimentos com o produto vezes a proporção de mulheres entre quem dirige os estabelecimentos do município (6768, todas as atividades), o mesmo método do painel Café em Números.

Arquivo: `trabalho_familiar.csv`, com Brasil, UF e município.

## 2. Direção invisível

A tabela 6768 diz quem dirige os trabalhos do estabelecimento e, quando é o casal, registra o sexo de quem respondeu. O Censo registra um só produtor por estabelecimento, e todas as tabelas por sexo usam esse registro. Quando o casal dirige junto e quem respondeu foi o homem, supomos que a mulher divide a direção, mas ela não aparece nas estatísticas por sexo.

A 6768 não tem a classe de atividade, só o grupo de atividade (classificação 12517). Por isso o recorte é o grupo da cadeia (lavoura permanente para café e cacau) somado nos municípios da cadeia. Um município entra quando tem pelo menos 20 estabelecimentos com a cadeia como atividade principal, ou 50 com o produto, ou 100 toneladas na PAM; esses limites ficam em `config/indicadores.csv`. É um recorte mais largo que a cadeia, e o texto que acompanhar o número precisa dizer isso.

As medidas são a participação das mulheres como dirigentes principais, a participação ampliada (somando o casal declarado pelo homem), a parcela invisível (casal declarado pelo homem dividido pelo total de mulheres na direção) e, entre os casais, a parcela em que só o homem ficou registrado. Percentuais ficam vazios em municípios com menos de 10 estabelecimentos e em UFs com menos de 500.

Arquivo: `direcao_invisivel.csv`.

## 3. Dupla jornada

A PNAD Contínua (tabela 7015) dá a média de horas semanais em afazeres domésticos e cuidados das pessoas de 14 anos ou mais, por sexo e UF. O valor é o número de mulheres da família da cadeia na UF vezes essas horas, vezes 52 semanas, a salário mínimo por hora (R$ 1.621 ÷ 220). Também sai só a parte que passa da média dos homens.

A PNAD não separa a área rural por UF nessa tabela, e as mulheres rurais costumam dedicar mais horas, então o valor tende a ser conservador. Aqui entram todas as mulheres da família, inclusive as dirigentes.

Arquivo: `dupla_jornada.csv`.

## 4. Valor da produção ligado às mulheres

O IBGE não publica o valor da produção por sexo de quem produz. Há duas leituras aproximadas sobre o valor da PAM:

- A: participação das mulheres na área dos estabelecimentos da cadeia (6883), contando só homens e mulheres no denominador. Supõe produtividade igual por hectare e usa a área total do estabelecimento, não só a da lavoura.
- B: participação das mulheres no pessoal ocupado da cadeia (6887: família, permanentes, temporárias e parceiras). Supõe a mesma contribuição por pessoa ocupada, uma simplificação forte. Serve como ordem de grandeza.

Arquivo: `valor_producao.csv`, Brasil e UF.

## Resumo

`resumo.csv` junta os números do Brasil de cada indicador, por cadeia e recorte, em formato longo. É o arquivo mais prático para a plataforma.

## Conferência com o Atlas do café

Os dados que a coleta baixa do SIDRA foram comparados com as tabelas do Atlas. As tabelas 6883 e 6887 do café batem célula a célula no Brasil, nas UFs e nos 5.563 municípios, assim como o valor da produção da PAM por município e as horas da PNAD por UF. Com os mesmos insumos, o script reproduz os números da nota de método do Atlas:

| | Atlas | Script |
|---|---|---|
| Mulheres 14+ na mão de obra familiar (principal) | 82.158 (29,3%) | 82.158 (29,3%) |
| Mulheres da família que não aparecem como produtoras (principal) | 67.861 | 67.861 |
| Mulheres da família onde há café (estimado) | 150.100 | 150.127 |
| Dirigentes mulheres onde há café (estimado) | 33.700 | 33.685 |
| Trabalho familiar, cenário médio (principal / onde há café) | R$ 0,66 bi / R$ 1,13 bi | R$ 0,66 bi / R$ 1,13 bi |
| Direção: dirigente principal / ampliada | 13,1% / 26,0% | 13,1% / 26,0% |
| Mulheres na direção que ficam fora das estatísticas | 49,8% | 49,8% |
| Casais em que só o homem é registrado | 85% (33.714 de 39.568) | 85,2% (33.714 de 39.568) |
| Dupla jornada (principal / onde há café) | R$ 0,70 bi / R$ 1,26 bi | R$ 0,70 bi / R$ 1,26 bi |
| Valor da produção, leituras A e B | R$ 8,4 bi e R$ 24 bi | R$ 8,4 bi e R$ 24,3 bi |

A direção invisível e o recorte `onde_ha` dependem de duas coletas próprias, a 6768 aberta por sexo e grupo de atividade e a 6955 aberta por produto (`R/coletar_insumos_indicadores.R`). Enquanto esses arquivos não existirem, o script calcula o resto e avisa o que ficou de fora.

## Limites

O Censo não mede horas nem dias trabalhados no estabelecimento, então os cenários de dedicação do indicador 1 são suposições. O salário mínimo é um piso; a diária de colheita costuma ser mais alta. Meninas com menos de 14 anos não entram nos valores dos indicadores 1 e 3. Municípios em sigilo ("X") ficam vazios nos arquivos municipais e, para totais, vale o número do Brasil ou da UF.
