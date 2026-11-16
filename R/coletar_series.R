# Coleta as séries anuais do IBGE listadas em config/tabelas_series.csv:
# PAM (agricultura), PEVS (extração vegetal), PPM (pecuária) e PNAD Contínua.
#
# Nas pesquisas de produção a tabela é recortada por produto. A coluna filtro
# escolhe os produtos pelo nome (expressão regular, sem diferenciar
# maiúsculas); vazia, entram todos. Os códigos são lidos da própria API a cada
# coleta, então um produto novo ou renomeado pelo IBGE aparece sozinho.
#
# periodo vale para Brasil e UFs; periodo_municipio, quando preenchido, vale
# para os municípios, que pesam muito mais. "last 10" são os dez últimos anos
# publicados.
#
# Uso, a partir da raiz do repositório:
#   Rscript R/coletar_series.R           todas as tabelas
#   Rscript R/coletar_series.R 5457      só as indicadas

source("R/sidra.R")
source("R/comum.R")

series <- read.csv("config/tabelas_series.csv", colClasses = "character",
                   encoding = "UTF-8", na.strings = character())

pedidas <- commandArgs(trailingOnly = TRUE)
if (length(pedidas) > 0) series <- series[series$tabela %in% pedidas, , drop = FALSE]

COLUNAS_OBRIGATORIAS <- c("tabela", "fonte", "nivel", "cod_territorio",
                          "territorio", "ano", "valor", "valor_bruto", "sigilo")

coletar_serie <- function(s, classificacoes) {
  niveis <- strsplit(s$niveis, ";", fixed = TRUE)[[1]]
  codigos <- character()
  if (nzchar(s$produto)) {
    cats <- categorias(s$tabela, s$produto)
    if (nzchar(s$filtro)) cats <- cats[grepl(s$filtro, cats$nome, ignore.case = TRUE), , drop = FALSE]
    if (nrow(cats) == 0) stop("nenhum produto corresponde ao filtro")
    message(sprintf("  %d produtos: %s", nrow(cats), paste(head(cats$nome, 8), collapse = "; ")))
    codigos <- cats$codigo
  }
  partes <- lapply(niveis, function(nivel) {
    periodo <- if (nivel == "n6" && nzchar(s$periodo_municipio)) s$periodo_municipio else s$periodo
    message(sprintf("  nível %s, período %s", nivel, periodo))
    consultar_nivel(s$tabela, nivel, classificacoes, codigos,
                    classe_recorte = s$produto,
                    nomes_recorte = c("cod_produto", "produto"),
                    periodo = periodo)
  })
  dados <- tratar_valor(do.call(rbind, partes))
  cbind(tabela = s$tabela, fonte = s$fonte, dados)
}

for (i in seq_len(nrow(series))) {
  s <- series[i, ]
  arquivo <- sprintf("dados/sidra/%s.csv.gz", s$arquivo)
  classificacoes <- strsplit(s$classificacoes, ";", fixed = TRUE)[[1]]
  detalhe <- ""
  message(sprintf("%s, tabela %s", s$fonte, s$tabela))

  coleta <- tryCatch(coletar_serie(s, classificacoes), error = function(e) e)

  # Se a API recusar uma classificação declarada, a tabela é coletada sem ela
  # e o motivo fica anotado, para corrigir a configuração depois.
  if (inherits(coleta, "erro_consulta") && length(classificacoes) > 0) {
    recusa <- conditionMessage(coleta)
    message("  a API recusou as classificações, coletando sem elas")
    coleta <- tryCatch(coletar_serie(s, character()), error = function(e) e)
    detalhe <- paste("sem", paste(classificacoes, collapse = ", "), ";", recusa)
  }

  if (inherits(coleta, "error")) {
    resultado <- list(situacao = "mantida versão anterior",
                      detalhe = conditionMessage(coleta), linhas = 0L)
  } else {
    resultado <- salvar_se_valido(coleta, arquivo, COLUNAS_OBRIGATORIAS)
    if (nzchar(detalhe)) resultado$detalhe <- detalhe
  }
  registrar_situacao(paste0(tolower(gsub("[^A-Za-z]", "", s$fonte)), "_", s$tabela), arquivo, resultado)
  message(sprintf("  %s (%s linhas) %s", resultado$situacao, resultado$linhas, resultado$detalhe))
}
