# Estudos da Embrapa por cadeia produtiva: como o recorte foi montado

*Recorte feito em 25/11/2026 a partir da exportação do Redape de novembro de 2026 (processada em 16/11/2026),
já tratada pelo Observatório de Pesquisa da Embrapa. Status: proposta metodológica, em validação.*

## O que entra

Publicações (contadas por obra: quando várias unidades depositam a mesma publicação, ela conta uma vez),
projetos e soluções tecnológicas da Embrapa ligados a cada cadeia da plataforma. As cadeias seguem as classes
de atividade do Censo Agropecuário 2017 usadas no resto do site; um documento entra em todas as cadeias de que
trata (um estudo de consórcio milho-feijão está em cereais e em outras lavouras temporárias), por isso os totais
de cadeias diferentes não se somam. São 121.686 documentos distintos; 107.438 em uma só cadeia, 12.545 em duas
e o restante em três ou mais.

O café não foi refeito: entra o recorte já publicado em `dados/estudos_cafe/`, com o mesmo método mais detalhado
(revisão manual dos títulos de todas as vias duvidosas).

## Produtos de cada cadeia

| Cadeia | Produtos |
|---|---|
| Cacau | cacau (cacaueiro, *Theobroma cacao*, chocolate quando citado com cacau) |
| Sociobiodiversidade amazônica | açaí, cupuaçu, castanha-do-brasil, andiroba, copaíba, guaraná, pupunha, buriti, tucumã, bacaba, patauá, camu-camu, bacuri, cumaru e outros produtos da floresta; cacau, babaçu, seringueira, palmito, frutos nativos e extrativismo em geral só quando o documento é da Amazônia |
| Mandioca, feijão e outras temporárias | feijão (comum e caupi), mandioca, abacaxi, melão, melancia, batata, batata-doce, inhame, cebola, alho, ervilha, fava |
| Cereais | arroz, milho, trigo, sorgo, aveia, cevada, centeio, triticale |
| Soja | soja |
| Fumo | fumo e tabaco como lavoura |
| Cana-de-açúcar | cana e setor sucroenergético |
| Oleaginosas, exceto soja | amendoim, girassol, canola, mamona, gergelim, linho, pinhão-manso, crambe |
| Algodão e outras fibras | algodão, juta, malva, rami |
| Hortaliças | tomate, cenoura, alface, repolho e couves, pimentão e pimentas (*Capsicum*), abóbora, chuchu, morango e hortaliças em geral |
| Flores e plantas ornamentais | floricultura, flores de corte, plantas ornamentais, gramados e paisagismo |
| Frutas | citros, uva e vinho, banana, maçã, manga, mamão, maracujá, caju, goiaba, acerola, abacate, frutas de caroço, figo, caqui, anonáceas, oliveira, nozes; açaí, cupuaçu e pupunha também entram aqui como frutas cultivadas |
| Outras lavouras permanentes | erva-mate, pimenta-do-reino, chá, dendê, coqueiro, seringueira, urucum, palmito, sisal, guaraná |
| Sementes e mudas certificadas | produção, certificação, tecnologia e qualidade de sementes e mudas; sementes crioulas e casas de sementes |
| Bovinos (leite e corte) | bovinos, gado de leite e de corte, leite e laticínios bovinos, raças, mastite, carrapato do boi |
| Aves | frangos, galinhas, poedeiras, codornas, ovos de galinha e doenças das aves |
| Suínos | suínos e suinocultura |
| Ovinos e caprinos | ovinos, caprinos, leite de cabra, verminose de pequenos ruminantes |
| Outros animais de grande porte | búfalos, cavalos, jumentos e muares |
| Outros animais | apicultura e meliponicultura, cunicultura, sericicultura, ranicultura, minhocultura |
| Florestas nativas (extrativismo) | manejo florestal, exploração madeireira, produtos florestais não madeireiros, extrativismo e frutos nativos (pequi, umbu, mangaba, baru, buriti), babaçu, carnaúba, licuri, macaúba, castanha, araucária e pinhão |
| Florestas plantadas | eucalipto, pínus, teca, mogno-africano, cedro-australiano, acácia-negra, paricá e silvicultura |
| Pesca | pesca, pescadores, recursos pesqueiros, acordos de pesca, defeso |
| Aquicultura | piscicultura, tilápia, tambaqui e peixes redondos, pirarucu, camarão, ostras e mexilhões, aquaponia |

Os termos, sinônimos e agrupamentos são proposta metodológica, em validação. Os nomes de produto seguem a
taxonomia de 104 produtos do Observatório, construída sobre as categorias oficiais do IBGE (PAM 5457, PPM,
PEVS), acrescida, para este recorte, de nomes científicos, pragas e doenças típicas e dos nomes em inglês.

## As três vias

1. **Tema** — os temas automáticos do Observatório (146 temas, BERTopic sobre vetores SBERT) cujo rótulo e termos
   principais são do produto: por exemplo T006 Mandioca, T009 e T041 soja, T025 e T071 gado, T101 Eucalipto,
   T022 Abelhas. A lista por cadeia, com contagens, está em `temas_cadeias.csv` (coluna `usado_como_via`).
   Cacau, fumo, flores, sementes e outros animais de grande porte não têm tema próprio.
2. **Termo** — dois níveis:
   - *forte*: o produto marcado como principal (no título ou nas palavras-chave) pela taxonomia de produtos do
     Observatório, ou um termo forte da cadeia (nome comum, científico, praga ou doença típica, nome em inglês) no
     título ou nas palavras-chave. Entra.
   - *fraco*: termo genérico (por exemplo "leite", "gado", "frutas", "ornamental", "abelhas", "madeira") no título
     ou nas palavras-chave. Só entra se o documento também está no tema da cadeia; em cereais, soja, frutas,
     outras temporárias, hortaliças, algodão, cacau, flores e aquicultura vale também o apoio da via semântica.
   - Termos só no resumo não bastam: nas amostras quase sempre eram menção de passagem (o produto citado numa
     lista ou como exemplo).
3. **Semântica** — vetores SBERT (multilingual-e5-base) do Observatório: o centroide dos documentos confirmados
   pelos termos fortes de cada cadeia (o documento entra como candidato se estiver entre os mais próximos,
   até 115% do número de confirmados), uma frase descritiva por cadeia (300 mais próximos) e os documentos
   semelhantes já calculados pelo Observatório (5 ou mais vizinhos confirmados). A semântica serve de apoio aos
   termos fracos; documentos sem nenhum termo do produto não entram, porque nas amostras eram de outro assunto.

Antes da busca são apagados do texto os nomes de unidades da Embrapa (Embrapa Soja, Embrapa Suínos e Aves, Embrapa
Pesca e Aquicultura…) e homônimos conhecidos (amendoim forrageiro, feijão-de-porco, pimenta-longa, cama de frango,
negro de fumo, cipó-guaraná, açoita-cavalo, fumo-bravo, café da manhã e outros).

**Uso como insumo.** Nas cadeias de lavoura, saem os documentos em que o produto aparece só como ração ou
suplemento de animais (temas de alimentação animal, ou título de ensaio com animais que fala em farelo, torta,
casca, silagem, bagaço etc. do produto) e os que usam resíduos do produto em bioprocessos e biomateriais.
O processamento do próprio produto (farinha de mandioca, suco, vinho, laticínios) continua na cadeia.

**Vetos.** Quando a marca vem só da taxonomia de produtos e o título indica outro assunto, o documento sai:
leite de cabra, de búfala ou vegetal fora de bovinos; pimenta-do-reino e pimenta-longa fora de hortaliças;
amendoim forrageiro fora de oleaginosas; cama de frango como adubo fora de aves; óleos e extratos de eucalipto
fora de florestas plantadas; tabaco como planta-modelo de laboratório fora de fumo.

## Números de cada etapa

Colunas: documentos com termo forte (antes de tirar o uso como insumo); retirados por uso como insumo;
termo fraco (candidatos → aceitos); descartados só com termo no resumo / só no tema; total final
(publicações / projetos / tecnologias); acertos na amostra de validação.

| Cadeia | Termo forte | Insumo | Termo fraco | Só resumo / só tema | Final (pub / proj / tec) | Total | Amostra |
|---|---:|---:|---:|---:|---:|---:|---:|
| Café | recorte próprio | — | — | — | 3.125 / 41 / 17 | 3.183 | ver estudos_cafe |
| Cacau | 249 | 18 | 33 → 2 | 347 / 0 | 231 / 1 / 1 | 233 | 18/20 |
| Sociobiodiversidade amazônica | 7.073 | 0 | 4 → 0 | 1.137 / 848 | 6.923 / 107 / 43 | 7.073 | 16/20 |
| Mandioca, feijão e outras lavouras temporárias | 15.290 | 313 | 120 → 95 | 1.643 / 1.441 | 14.779 / 165 / 128 | 15.072 | 15/20 |
| Cereais | 22.022 | 1.396 | 602 → 349 | 2.833 / 604 | 20.695 / 165 / 115 | 20.975 | 17/20 |
| Soja | 9.329 | 641 | 219 → 90 | 1.679 / 548 | 8.603 / 86 / 89 | 8.778 | 15/20 |
| Fumo | 39 | 3 | 15 → 0 | 102 / 0 | 33 / 2 / 1 | 36 | 12/20 |
| Cana-de-açúcar | 2.676 | 347 | 31 → 2 | 646 / 70 | 2.243 / 74 / 14 | 2.331 | 15/20 |
| Oleaginosas, exceto soja | 4.154 | 446 | 227 → 6 | 608 / 144 | 3.646 / 49 / 19 | 3.714 | 17/20 |
| Algodão e outras fibras | 3.169 | 131 | 14 → 9 | 489 / 16 | 2.967 / 57 / 23 | 3.047 | 19/20 |
| Hortaliças | 5.983 | 60 | 7 → 4 | 1.073 / 770 | 5.745 / 144 / 38 | 5.927 | 16/20 |
| Flores e plantas ornamentais | 809 | 0 | 232 → 77 | 385 / 0 | 870 / 6 / 10 | 886 | 16/20 |
| Frutas | 22.103 | 452 | 276 → 270 | 2.583 / 1.487 | 21.373 / 317 / 231 | 21.921 | 17/20 |
| Outras lavouras permanentes | 6.102 | 279 | 8 → 2 | 746 / 184 | 5.681 / 90 / 54 | 5.825 | 17/20 |
| Sementes e mudas certificadas | 1.215 | 0 | 1.004 → 0 | 1.748 / 0 | 1.190 / 23 / 2 | 1.215 | 20/20 |
| Bovinos (leite e corte) | 12.241 | 0 | 4.742 → 664 | 4.723 / 1.549 | 12.598 / 220 / 87 | 12.905 | 18/20 |
| Aves | 1.493 | 0 | 2 → 1 | 402 / 1.419 | 1.433 / 50 / 11 | 1.494 | 15/20 |
| Suínos | 2.284 | 0 | 5 → 0 | 493 / 1.515 | 2.200 / 73 / 11 | 2.284 | 17/20 |
| Ovinos e caprinos | 5.927 | 0 | 62 → 54 | 575 / 1.560 | 5.846 / 98 / 37 | 5.981 | 17/20 |
| Outros animais de grande porte | 1.037 | 0 | 98 → 0 | 275 / 0 | 1.019 / 9 / 9 | 1.037 | 18/20 |
| Outros animais | 939 | 0 | 430 → 296 | 279 / 197 | 1.196 / 27 / 12 | 1.235 | 10/20 |
| Florestas nativas (extrativismo) | 5.151 | 0 | 2.111 → 74 | 2.212 / 1.010 | 5.075 / 95 / 55 | 5.225 | 16/20 |
| Florestas plantadas | 4.109 | 0 | 1.391 → 101 | 2.045 / 258 | 4.097 / 75 / 38 | 4.210 | 11/20 |
| Pesca | 425 | 0 | 389 → 0 | 328 / 1.901 | 412 / 8 / 5 | 425 | 12/20 |
| Aquicultura | 2.413 | 0 | 732 → 660 | 429 / 357 | 2.918 / 121 / 34 | 3.073 | 15/20 |

## Validação

Foram lidos os títulos de amostras aleatórias em três rodadas (cerca de 1.000 títulos): 20 documentos por cadeia
entre os aceitos por termo forte *fora* do tema da cadeia (a parte mais incerta) e 8 de cada via duvidosa (termo
fraco, termo só no resumo). A coluna "Amostra" mostra os acertos na última rodada de cada cadeia; dentro dos temas
da cadeia a precisão é maior. A cada rodada as regras foram corrigidas (vetos, homônimos, termos fracos), e as
cadeias que mudaram foram amostradas de novo.

Falsos positivos encontrados e tratados:

- uso do produto como insumo: farelo de soja e milho em rações, casca de coco e fibra de coco como substrato,
  torta de mamona, bagaço de cana em bioprocessos, cama de frango e esterco como adubo;
- homônimos: amendoim forrageiro (*Arachis pintoi*) em oleaginosas, pimenta-do-reino e pimenta-longa (*Piper*)
  em hortaliças, cupuaçu (*Theobroma grandiflorum*) e vassoura-de-bruxa em cacau, cipó-guaraná, açoita-cavalo,
  feijão-de-porco, fumo-bravo, negro de fumo, suínos asselvajados, BRS Mel do Cerrado (maracujá), Senador Nilo
  Coelho (perímetro irrigado), Buriti Vermelho (núcleo rural), Pesqueira (município);
- tabaco usado como planta-modelo em transformação genética;
- leite de outras espécies e leites vegetais marcados como bovinos;
- ovos de insetos em aves; abelhas como polinizadoras de lavouras em outros animais; verminose de bovinos em
  ovinos e caprinos; pirarucu de cultivo em pesca.

Cadeias que pedem cuidado ao ler os números:

- **Fumo**: a Embrapa quase não pesquisa a lavoura de fumo; boa parte do que cita tabaco usa a planta como modelo
  de laboratório. Ficaram 36 documentos, com ruído ainda perceptível.
- **Outros animais**: dentro do tema de abelhas o recorte é bom; fora dele ainda entram estudos sobre abelhas
  nativas e polinização, que não são produção apícola.
- **Florestas plantadas**: entram estudos de integração lavoura-pecuária-floresta com eucalipto e de tecnologia da
  madeira; a fronteira com florestas nativas e com ILPF é difusa.
- **Pesca**: os termos de pesca aparecem também em estudos de aquicultura e de cadeia do pescado; a separação
  entre pesca e aquicultura é aproximada.
- **Sementes**: a classe do Censo é de sementes e mudas certificadas; aqui entram também estudos de qualidade e
  tecnologia de sementes de muitas culturas e sementes crioulas.
- **Sociobiodiversidade amazônica** e **frutas** compartilham açaí, cupuaçu e pupunha.

## Gênero (só agregados)

Os números estão em `resumo_genero.json`, por cadeia e para toda a Embrapa, cada bloco com fonte, filtro e
exportação nos metadados. Regras, as mesmas do recorte do café:

- só pessoas identificadas pelo Observatório com nível A (determinístico) ou B (desambiguado); autores externos
  ou não identificados ficam fora;
- gênero vindo do cargo ou da função escritos no portal da Embrapa (página Equipe, coleta de novembro de 2026)
  e, sem isso, estimado pelo primeiro nome com genderBR 1.4.0 (Censo 2010; feminino com probabilidade a partir
  de 0,9, masculino até 0,1); o resto fica como indefinido, à parte;
- percentuais de mulheres calculados entre mulheres e homens;
- unidades, temas, tipos de documento e anos da série só aparecem com 5 ou mais pessoas identificadas; a liderança
  de projetos por gênero é suprimida quando a cadeia tem menos de 5 líderes (cacau e fumo); nenhuma lista liga
  nome a gênero;
- as soluções tecnológicas não trazem autoria pessoal no Redape e ficam fora desses números.

Pessoas distintas (mulheres / homens / indefinidas), percentual de mulheres entre as pessoas e nas autorias,
publicações com ao menos uma autora e líderes de projeto (mulheres / homens):

| Cadeia | Pessoas | Mulheres | Autorias de mulheres | Publicações com autora | Líderes |
|---|---:|---:|---:|---:|---:|
| Café | 250 / 553 / 19 | 31.1% | 34% | 53.7% | 7 / 24 |
| Cacau | 61 / 138 / 8 | 30.7% | 27.1% | 38.8% | suprimido (< 5) |
| Sociobiodiversidade amazônica | 391 / 946 / 38 | 29.2% | 35.5% | 52.7% | 33 / 33 |
| Mandioca, feijão e outras lavouras temporárias | 824 / 2023 / 82 | 28.9% | 25.2% | 46.1% | 40 / 77 |
| Cereais | 781 / 2313 / 70 | 25.2% | 21.9% | 41.5% | 37 / 76 |
| Soja | 549 / 1413 / 45 | 28% | 22.4% | 40% | 21 / 47 |
| Fumo | 10 / 45 / 0 | 18.2% | 15.4% | 24.1% | suprimido (< 5) |
| Cana-de-açúcar | 287 / 743 / 15 | 27.9% | 26.9% | 44.2% | 13 / 33 |
| Oleaginosas, exceto soja | 334 / 881 / 24 | 27.5% | 26.1% | 45.6% | 7 / 25 |
| Algodão e outras fibras | 222 / 644 / 19 | 25.6% | 23.2% | 44.2% | 10 / 32 |
| Hortaliças | 546 / 1098 / 37 | 33.2% | 33.6% | 54.1% | 30 / 44 |
| Flores e plantas ornamentais | 135 / 276 / 7 | 32.8% | 41.6% | 64.6% | 3 / 2 |
| Frutas | 878 / 2014 / 80 | 30.4% | 29.1% | 46.5% | 73 / 129 |
| Outras lavouras permanentes | 445 / 1100 / 47 | 28.8% | 26.8% | 42.4% | 25 / 38 |
| Sementes e mudas certificadas | 197 / 642 / 11 | 23.5% | 23.8% | 41.5% | 5 / 15 |
| Bovinos (leite e corte) | 563 / 1583 / 50 | 26.2% | 27.5% | 47.7% | 40 / 80 |
| Aves | 157 / 319 / 6 | 33% | 38.9% | 56.1% | 11 / 15 |
| Suínos | 156 / 344 / 11 | 31.2% | 32.6% | 47.5% | 12 / 22 |
| Ovinos e caprinos | 288 / 772 / 17 | 27.2% | 26.4% | 45.3% | 16 / 33 |
| Outros animais de grande porte | 117 / 282 / 11 | 29.3% | 24% | 42.3% | 2 / 4 |
| Outros animais | 127 / 259 / 6 | 32.9% | 44.2% | 58.1% | 9 / 10 |
| Florestas nativas (extrativismo) | 478 / 1087 / 29 | 30.5% | 35.9% | 53.2% | 33 / 34 |
| Florestas plantadas | 343 / 873 / 17 | 28.2% | 21.8% | 35.4% | 15 / 34 |
| Pesca | 78 / 119 / 6 | 39.6% | 38% | 47.7% | 1 / 6 |
| Aquicultura | 235 / 419 / 13 | 35.9% | 41.5% | 57.8% | 31 / 28 |
| **Toda a Embrapa** | 2.474 / 6.000 / 261 | 29.2% | 28.1% | 46% | 467 / 830 |

## Arquivos

- `estudos.csv` — um documento por linha, com as mesmas colunas de `dados/estudos_cafe/estudos.csv` mais
  `cadeias` (chaves separadas por `;`) e `vias` (vias por cadeia, por exemplo `cereais:tema+termo;soja:termo`).
  O arquivo tem cerca de 88 MB.
- `temas_cadeias.csv` — temas presentes em cada cadeia, com contagem e se foram usados como via.
- `resumo_genero.json` — agregados de gênero.

## Fontes

EMBRAPA. *Publicações da Embrapa*. Redape, DOI 10.48432/TRBT0S. Exportação de novembro de 2026.
EMBRAPA. *Projetos da Embrapa*. Redape, DOI 10.48432/EZDXWF. Exportação de novembro de 2026.
EMBRAPA. *Soluções tecnológicas da Embrapa*. Redape, DOI 10.48432/ZQE5FV. Exportação de novembro de 2026.
IBGE. Produção Agrícola Municipal (tabela 5457), Pesquisa da Pecuária Municipal e Produção da Extração Vegetal e
da Silvicultura (SIDRA): categorias de produto. Censo Agropecuário 2017: classes de atividade.
Observatório de Pesquisa da Embrapa (github.com/danimaciel/observatorio_embrapa): obras, temas, produtos e pessoas
identificadas.
MEIRELES, F. *genderBR*: predict gender from Brazilian first names. Versão 1.4.0.
