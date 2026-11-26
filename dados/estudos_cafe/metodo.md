# Estudos de cafeicultura da Embrapa: como o recorte foi montado

*Recorte feito em 25/11/2026 a partir da exportação do Redape de novembro de 2026 (processada em 16/11/2026),
já tratada numa análise anterior das bases da Embrapa. Status: proposta metodológica, em validação.*

## O que entra

Publicações (contadas por obra: quando várias unidades depositam a mesma publicação, ela conta uma vez),
projetos e soluções tecnológicas cujo assunto é a cafeicultura: a planta e a lavoura de café (*Coffea arabica*,
*C. canephora*: conilon e robusta), melhoramento e recursos genéticos, pragas e doenças, solo, clima e
geotecnologias aplicadas ao café, colheita, pós-colheita, qualidade do grão e da bebida, mercado, cadeia
produtiva, gestão da pesquisa em café e quem produz café.

Ficaram de fora os trabalhos em que o café aparece só como ingrediente ou insumo de outra coisa (casca de café
na ração de ovinos, óleo ou borra de café em filmes, bioplásticos e fertilizantes, bebidas mistas com soja),
os que citam o café numa lista de várias culturas sem tratá-lo, e os homônimos: "café da manhã", "mancha-café"
do feijão e da soja, café-do-mato, cafeína de guaraná e erva-mate, *Grevillea robusta*.

## As três vias

1. **Tema** — dos 146 temas automáticos da análise anterior (BERTopic sobre vetores SBERT), um tem rótulo e
   termos de café: **T002 Café** (2.563 documentos). Nenhum outro tema tem café no rótulo nem nos termos
   principais. Os demais temas que aparecem no recorte estão em `temas_cafe.csv`.
2. **Termo** — busca sem acento e sem diferença de maiúsculas, por palavra inteira, em título, resumo e
   palavras-chave. Termos fortes: cafeeiro(s), cafeeira, cafeicultura, cafeicultor(a/es), cafezal, cafezais,
   *Coffea*, conilon, canephora/canéfora, broca-do-café, ferrugem do cafeeiro, bicho-mineiro, *Hemileia*,
   *Hypothenemus*, *Leucoptera coffeella*. Termos fracos: café(s), coffee, arábica, robusta. Antes da busca,
   o nome da unidade "Embrapa Café" é apagado do texto e expressões como "café da manhã", "coffee break",
   "cor de café", "goma arábica", "café com leite", "mancha-café" e "café-do-mato" são removidas.
3. **Semântica** — três frases buscadas nos vetores SBERT (multilingual-e5-base), 4.000 resultados por frase,
   dos quais entram como candidatos os 500 primeiros de cada uma:
   - "cafeicultura: produção de café, manejo do cafeeiro, cultivares de Coffea arabica e Coffea canephora (conilon e robusta)";
   - "pragas e doenças do cafeeiro: broca-do-café, ferrugem do cafeeiro, bicho-mineiro e nematoides em lavouras de café";
   - "qualidade da bebida, pós-colheita, secagem e mercado do café produzido por cafeicultores".

   As frases sozinhas trouxeram muito ruído (trigo, cevada, algodão nas primeiras posições). Por isso a via
   semântica também usa os documentos já confirmados: (a) o centroide dos vetores dos documentos aceitos pelos
   termos, com os 3.500 mais próximos; e (b) os documentos semelhantes já calculados pela análise anterior (10 por tipo),
   entrando quem tem 5 ou mais vizinhos confirmados.

## Números de cada etapa (documentos: publicações por obra + projetos + soluções)

| Etapa | Documentos |
|---|---:|
| Via tema (T002) | 2.563 |
| Via termo: algum termo em qualquer campo | 3.762 |
| Via termo: termo no título ou nas palavras-chave | 3.259 |
| Via termo: aceitos depois da revisão | 3.169 |
| Via semântica: candidatos (frases, centroide ou vizinhos) | 4.626 |
| União dos candidatos das três vias | 5.102 |
| **Recorte final** | **3.183** |

Recorte final por tipo: **3.125 publicações, 41 projetos, 17 soluções tecnológicas** (anos de 1956 a 2026).
Por combinação de vias: tema + termo + semântica 2.538; termo + semântica 605; termo 25; semântica 10;
tema + semântica 5.

## Validação

- **Termo forte no título ou nas palavras-chave (2.483):** aceitos. Numa amostra de 60 fora do tema T002,
  58 eram cafeicultura e 2 marginais (café numa lista de culturas).
- **Termo fraco no título ou nas palavras-chave, fora do tema T002 (270):** todos os títulos lidos;
  173 aceitos e 97 descartados (insumo ou ingrediente, lista de culturas, homônimos). Os 509 dentro do
  tema T002 foram aceitos. Quando "arábica" ou "robusta" aparecem sem nenhuma outra palavra de café (84),
  não entram pela via de termo.
- **Termo só no resumo (503):** em amostras de 25 por grupo, quase todos citavam o café de passagem. Só entram
  se a via semântica também os aponta e a leitura confirma (11 no recorte final).
- **Tema T002 sem nenhum termo (19):** a maioria trata de cafeína em outras plantas, cacau ou erva-mate;
  ficou 1 (classificação de grãos de café).
- **Semântica fora das outras vias (1.482):** amostra aleatória de 50 sem nenhum termo: 1 era café (uma
  cultivar Icatu). Lidos também os 145 com termo no resumo e os 21 com 10+ vizinhos confirmados.
  Entraram 15 documentos (por exemplo ferrugem, *Colletotrichum kahawae*, genoma do café, robustas amazônicos,
  regiões cafeeiras).

## Comparação com recortes de café anteriores

- **Recorte de café anterior** (Redape de outubro de 2026; termos da taxonomia de produtos, SBERT e
  classificador; 3.225 documentos): 3.111 em comum. 114 estão só lá, 73 deles descartados aqui na revisão
  (insumo ou ingrediente, listas de culturas); o restante cita café no resumo. 72 publicações estão só aqui,
  quase todas sobre a lavoura de café que o classificador de lá deixou de fora, mais 5 de 2026.
- **Levantamento do painel do café** (Redape de fevereiro de 2026; termos em título, resumo e palavras-chave;
  3.235 registros, ou 3.202 obras): 2.854 obras em comum, 348 só lá (sobretudo menções de passagem no resumo e
  "café da manhã") e 271 só aqui (publicações novas desde março e termos que não estavam no dicionário, como
  conilon, canephora, bicho-mineiro e broca).

## Gênero (só agregados)

Os números estão em `resumo_genero.json`, cada bloco com fonte, filtro e exportação. Regras:

- só pessoas identificadas pela análise anterior com nível A (determinístico) ou B (desambiguado); autores externos
  ou não identificados ficam fora;
- gênero vindo do cargo ou da função escritos no portal da Embrapa (página Equipe, coleta de novembro de 2026)
  e, sem isso, estimado pelo primeiro nome com genderBR 1.4.0 (Censo 2010; feminino com probabilidade a partir
  de 0,9, masculino até 0,1); o resto fica como indefinido, à parte;
- percentuais de mulheres calculados entre mulheres e homens;
- unidades, temas e tipos de documento só aparecem quando têm 5 ou mais pessoas identificadas; nenhuma lista
  liga nome a gênero;
- as soluções tecnológicas não trazem autoria pessoal no Redape e ficam fora desses números;
- a comparação com a Embrapa toda usa as mesmas regras na mesma exportação.

## Arquivos

- `estudos.csv` — um documento por linha: id do documento (`OB:` publicação, `P:` projeto, `T:` solução),
  tipo, subtipo, título, ano, unidades (siglas de todas as participações: depositante, líder, responsável e
  afiliação de autores), tema, macrotema, via, palavras-chave, resumo cortado em 400 caracteres, autores como
  constam no Redape (para projetos, o líder) e link (Alice ou Infoteca para publicações; página do projeto
  ou da solução no portal).
- `temas_cafe.csv` — temas presentes no recorte, com o total de cada tema na Embrapa e se foi usado como via.
- `resumo_genero.json` — agregados de gênero.

## Fontes

EMBRAPA. *Publicações da Embrapa*. Redape, DOI 10.48432/TRBT0S. Exportação de novembro de 2026.
EMBRAPA. *Projetos da Embrapa*. Redape, DOI 10.48432/EZDXWF. Exportação de novembro de 2026.
EMBRAPA. *Soluções tecnológicas da Embrapa*. Redape, DOI 10.48432/ZQE5FV. Exportação de novembro de 2026.
Análise anterior das bases da Embrapa no Redape: obras, temas, pessoas identificadas.
MEIRELES, F. *genderBR*: predict gender from Brazilian first names. Versão 1.4.0.
