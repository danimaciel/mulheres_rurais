# Procura, numa faixa de números de tabela do SIDRA, as que aceitam um
# conjunto de classificações ao mesmo tempo. Usado para saber se algum
# cruzamento existe (por exemplo associação a cooperativa com classe de
# atividade) sem depender do serviço de metadados.
#
# Uso: Rscript R/procurar_tabelas.R 6700 6960 c12598/all c12440/110016
# Saída: dados/metadados/descricao_sidra/procura_<classificações>.csv

library(httr)
library(jsonlite)

args <- commandArgs(trailingOnly = TRUE)
if (length(args) < 3) stop("uso: inicio fim classificacao [classificacao...]")
faixa <- seq(as.integer(args[1]), as.integer(args[2]))
classes <- args[-(1:2)]

achados <- list()
for (tabela in faixa) {
  url <- utils::URLencode(sprintf("https://apisidra.ibge.gov.br/values/t/%d/n1/all/v/allxp/p/last 1/%s?formato=json",
                                  tabela, paste(classes, collapse = "/")))
  resp <- tryCatch(GET(url, timeout(60), user_agent("mulheres-rurais-coleta"),
                       config(connecttimeout = 30, ipresolve = 1L)),
                   error = function(e) NULL)
  if (!is.null(resp) && status_code(resp) == 200) {
    bruto <- tryCatch(fromJSON(content(resp, as = "text", encoding = "UTF-8")),
                      error = function(e) NULL)
    if (is.data.frame(bruto) && nrow(bruto) >= 2) {
      variaveis <- paste(unique(bruto$D2N[-1]), collapse = "; ")
      message(sprintf("%d: %s", tabela, substr(variaveis, 1, 200)))
      achados[[length(achados) + 1]] <- data.frame(tabela = tabela, variaveis = variaveis)
    }
  }
  Sys.sleep(0.2)
}

pasta <- "dados/metadados/descricao_sidra"
dir.create(pasta, recursive = TRUE, showWarnings = FALSE)
nome <- gsub("[^0-9a-z]+", "_", paste(classes, collapse = "_"))
saida <- if (length(achados)) do.call(rbind, achados) else data.frame(tabela = integer(), variaveis = character())
write.csv(saida, file.path(pasta, sprintf("procura_%s.csv", nome)), row.names = FALSE, fileEncoding = "UTF-8")
message(sprintf("%d tabelas aceitam %s", nrow(saida), paste(classes, collapse = " + ")))
