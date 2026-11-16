# Coleta as tabelas do Censo Agro 2017 que os indicadores de trabalho
# invisível precisam e que não estão na coleta geral, porque pedem outras
# aberturas:
#
# - 6768 com a direção dos trabalhos (total e casal), o sexo de quem dirige e
#   o grupo de atividade econômica. É daqui que sai a direção invisível. A
#   6768 não tem a classe de atividade (12440), só o grupo (12517), então o
#   recorte de cada cadeia é o grupo dela nos municípios onde a cadeia está.
# - 6955 com os produtos da lavoura permanente abertos, para contar os
#   estabelecimentos que têm o produto mesmo quando ele não é a atividade
#   principal. Os produtos são escolhidos pelo nome, com o filtro de
#   config/indicadores.csv.
#
# Uso, a partir da raiz do repositório:
#   Rscript R/coletar_insumos_indicadores.R

source("R/sidra.R")
source("R/comum.R")

cadeias <- read.csv("config/indicadores.csv", colClasses = "character", encoding = "UTF-8")
NIVEIS <- c("n1", "n3", "n6")
CLASSE_PRODUTOS_6955 <- "227"

coletar <- function(tabela, classificacoes, codigos_recorte = character(),
                    classe_recorte = "12440", nomes_recorte = character()) {
  partes <- lapply(NIVEIS, function(nivel) {
    message(sprintf("  nível %s", nivel))
    consultar_nivel(tabela, nivel, classificacoes, codigos_recorte,
                    classe_recorte = classe_recorte, nomes_recorte = nomes_recorte)
  })
  cbind(tabela = tabela, tratar_valor(do.call(rbind, partes)))
}

pedidos <- list(
  list(fonte = "sidra_6768_direcao", arquivo = "dados/sidra/censo_agro_6768_direcao.csv.gz",
       coleta = function() coletar("6768", c("c346/41149,40592", "c12566/46500,112643,112644",
                                              "c12517/all"))),
  list(fonte = "sidra_6955_produtos", arquivo = "dados/sidra/censo_agro_6955_produtos.csv.gz",
       coleta = function() {
         cats <- categorias("6955", CLASSE_PRODUTOS_6955)
         filtro <- paste(cadeias$produtos_6955, collapse = "|")
         cats <- cats[grepl(filtro, cats$nome, ignore.case = TRUE), , drop = FALSE]
         if (nrow(cats) == 0) stop("nenhum produto da 6955 corresponde aos filtros")
         message(sprintf("  produtos: %s", paste(cats$nome, collapse = "; ")))
         coletar("6955", character(), cats$codigo, classe_recorte = CLASSE_PRODUTOS_6955,
                 nomes_recorte = c("cod_produto", "produto"))
       })
)

# Uma falha fica registrada na situação da coleta e o arquivo anterior é
# mantido; o workflow segue para as próximas etapas.
for (p in pedidos) {
  message(p$fonte)
  coleta <- tryCatch(p$coleta(), error = function(e) e)
  if (inherits(coleta, "error")) {
    resultado <- list(situacao = "mantida versão anterior",
                      detalhe = conditionMessage(coleta), linhas = 0L)
  } else {
    resultado <- salvar_se_valido(coleta, p$arquivo, c("cod_territorio", "valor", "sigilo"))
  }
  registrar_situacao(p$fonte, p$arquivo, resultado)
  message(sprintf("  %s (%s linhas) %s", resultado$situacao, resultado$linhas, resultado$detalhe))
}
