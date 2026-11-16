# Descobre quais classificações uma tabela do SIDRA aceita, testando códigos
# numa faixa pela API de valores (Brasil, último período). Serve quando nem o
# serviço de metadados nem a página de descrição respondem aos servidores do
# GitHub. Para cada código aceito grava o nome da classificação e as
# categorias com seus códigos.
#
# Uso: Rscript R/sondar_classificacoes.R 8943 12500 12700
# Saída: dados/metadados/descricao_sidra/<tabela>_classificacoes.csv

library(httr)
library(jsonlite)

args <- commandArgs(trailingOnly = TRUE)
if (length(args) < 3) stop("uso: tabela codigo_inicial codigo_final [codigos avulsos...]")
tabela <- args[1]
codigos <- c(seq(as.integer(args[2]), as.integer(args[3])),
             as.integer(args[-(1:3)]))

consultar <- function(codigo) {
  url <- sprintf("https://apisidra.ibge.gov.br/values/t/%s/n1/all/v/allxp/p/last%%201/c%d/all?formato=json",
                 tabela, codigo)
  resp <- tryCatch(GET(url, timeout(60), user_agent("mulheres-rurais-coleta"),
                       config(connecttimeout = 30, ipresolve = 1L)),
                   error = function(e) NULL)
  if (is.null(resp) || status_code(resp) != 200) return(NULL)
  bruto <- tryCatch(fromJSON(content(resp, as = "text", encoding = "UTF-8")),
                    error = function(e) NULL)
  if (!is.data.frame(bruto) || nrow(bruto) < 2 || !"D4C" %in% names(bruto)) return(NULL)
  cat_ <- unique(bruto[-1, c("D4C", "D4N")])
  data.frame(tabela = tabela, classificacao = codigo,
             nome_classificacao = bruto$D4N[1],
             cod_categoria = cat_$D4C, categoria = cat_$D4N)
}

achados <- list()
for (codigo in codigos) {
  r <- consultar(codigo)
  if (!is.null(r)) {
    message(sprintf("c%d: %s (%d categorias)", codigo, r$nome_classificacao[1], nrow(r)))
    achados[[length(achados) + 1]] <- r
  }
  Sys.sleep(0.2)
}

pasta <- "dados/metadados/descricao_sidra"
dir.create(pasta, recursive = TRUE, showWarnings = FALSE)
if (length(achados) > 0) {
  write.csv(do.call(rbind, achados), file.path(pasta, sprintf("%s_classificacoes.csv", tabela)),
            row.names = FALSE, fileEncoding = "UTF-8")
} else {
  message("nenhuma classificação encontrada na faixa")
}
