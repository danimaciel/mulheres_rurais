# Grava a descrição de tabelas do SIDRA (nome, variáveis e classificações com
# os códigos de cada categoria), lida da página desctabapi.aspx do próprio
# apisidra. É o jeito de conferir códigos de classificação sem o serviço de
# metadados, que não responde aos servidores do GitHub.
#
# Uso: Rscript R/descrever_tabelas.R 8943 6779
# Os textos ficam em dados/metadados/descricao_sidra/<tabela>.txt

library(httr)

args <- commandArgs(trailingOnly = TRUE)
tabelas <- unlist(strsplit(args, "[ ,]+"))
tabelas <- tabelas[nzchar(tabelas)]
if (length(tabelas) == 0) stop("informe ao menos uma tabela")

pasta <- "dados/metadados/descricao_sidra"
dir.create(pasta, recursive = TRUE, showWarnings = FALSE)

limpar_html <- function(html) {
  texto <- gsub("(?i)<br\\s*/?>|</(p|tr|div|h[1-6]|li|table)>", "\n", html, perl = TRUE)
  texto <- gsub("<[^>]+>", " ", texto)
  texto <- gsub("&nbsp;", " ", texto, fixed = TRUE)
  texto <- gsub("&amp;", "&", texto, fixed = TRUE)
  linhas <- trimws(gsub("[ \t]+", " ", strsplit(texto, "\n")[[1]]))
  paste(linhas[nzchar(linhas)], collapse = "\n")
}

for (tabela in tabelas) {
  url <- sprintf("https://apisidra.ibge.gov.br/desctabapi.aspx?c=%s", tabela)
  resp <- tryCatch(GET(url, timeout(120), user_agent("mulheres-rurais-coleta"),
                       config(connecttimeout = 60, ipresolve = 1L)),
                   error = function(e) e)
  if (inherits(resp, "error")) {
    message(sprintf("%s: falhou (%s)", tabela, conditionMessage(resp)))
    next
  }
  if (status_code(resp) != 200) {
    message(sprintf("%s: falhou (HTTP %d)", tabela, status_code(resp)))
    next
  }
  texto <- limpar_html(content(resp, as = "text", encoding = "UTF-8"))
  if (!grepl("Tabela", texto)) {
    message(sprintf("%s: resposta sem descrição", tabela))
    next
  }
  writeLines(texto, file.path(pasta, paste0(tabela, ".txt")), useBytes = TRUE)
  message(sprintf("%s: %s", tabela, substr(sub("\n.*", "", texto), 1, 150)))
}
