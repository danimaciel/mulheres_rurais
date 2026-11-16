# Coleta as tabelas do Censo Agropecuário 2017 listadas em
# config/tabelas_censo_agro.csv, recortadas pelas classes de atividade de
# config/cadeias.csv.
#
# Uso, a partir da raiz do repositório:
#   Rscript R/coletar_censo_agro.R            todas as tabelas
#   Rscript R/coletar_censo_agro.R 6883 6887  só as indicadas

source("R/sidra.R")
source("R/comum.R")

cadeias <- read.csv("config/cadeias.csv", colClasses = "character", encoding = "UTF-8")
tabelas <- read.csv("config/tabelas_censo_agro.csv", colClasses = "character", encoding = "UTF-8")

pedidas <- commandArgs(trailingOnly = TRUE)
if (length(pedidas) > 0) tabelas <- tabelas[tabelas$tabela %in% pedidas, , drop = FALSE]

COLUNAS_OBRIGATORIAS <- c("tabela", "nivel", "cod_territorio", "territorio",
                          "cadeia", "valor", "valor_bruto", "sigilo")

# Liga cada linha à cadeia de config/cadeias.csv. Tabelas sem a classe de
# atividade só podem ser lidas como "todas as atividades" e recebem esse
# rótulo, nunca o de uma cadeia.
marcar_cadeia <- function(dados, meta) {
  if (tem_classe_atividade(meta)) {
    pos <- match(dados$cod_atividade, cadeias$codigo_12440)
    dados$cadeia <- cadeias$cadeia[pos]
    dados$cadeia_rotulo <- cadeias$rotulo[pos]
  } else {
    dados$cadeia <- "total"
    dados$cadeia_rotulo <- "Todas as atividades (tabela sem recorte por atividade)"
  }
  dados
}

coletar_tabela <- function(tabela, niveis) {
  meta <- metadados_tabela(tabela)
  classificacoes <- trecho_classificacoes(meta, cadeias$codigo_12440)
  extras <- colunas_atividade(meta)

  disponiveis <- tolower(unlist(meta$nivelTerritorial))
  niveis <- intersect(niveis, disponiveis)
  if (length(niveis) == 0) stop("nenhum dos níveis pedidos existe na tabela")

  partes <- lapply(niveis, function(nivel) {
    message(sprintf("  nível %s", nivel))
    consultar_nivel(tabela, nivel, classificacoes, extras)
  })
  dados <- do.call(rbind, partes)
  dados <- tratar_valor(dados)
  dados <- marcar_cadeia(dados, meta)
  dados <- cbind(tabela = tabela, dados)

  list(dados = dados, nome = meta$nome)
}

catalogo <- list()

for (i in seq_len(nrow(tabelas))) {
  tabela <- tabelas$tabela[i]
  niveis <- strsplit(tabelas$niveis[i], ";", fixed = TRUE)[[1]]
  arquivo <- sprintf("dados/sidra/censo_agro_%s.csv", tabela)
  message(sprintf("Tabela %s", tabela))

  coleta <- tryCatch(coletar_tabela(tabela, niveis), error = function(e) e)

  if (inherits(coleta, "error")) {
    resultado <- list(situacao = "mantida versão anterior",
                      detalhe = conditionMessage(coleta), linhas = 0L)
  } else {
    resultado <- salvar_se_valido(coleta$dados, arquivo, COLUNAS_OBRIGATORIAS)
    catalogo[[tabela]] <- data.frame(tabela = tabela, nome = coleta$nome,
                                     arquivo = arquivo, nota = tabelas$nota[i])
  }
  registrar_situacao(paste0("sidra_", tabela), arquivo, resultado)
  message(sprintf("  %s (%s linhas) %s", resultado$situacao, resultado$linhas, resultado$detalhe))
}

# Catálogo com o nome oficial de cada tabela, como o IBGE publica.
if (length(catalogo) > 0) {
  novo <- do.call(rbind, catalogo)
  arquivo_catalogo <- "dados/metadados/tabelas_sidra.csv"
  if (file.exists(arquivo_catalogo)) {
    antigo <- read.csv(arquivo_catalogo, colClasses = "character", encoding = "UTF-8")
    novo <- rbind(antigo[!antigo$tabela %in% novo$tabela, , drop = FALSE], novo)
  }
  novo <- novo[order(novo$tabela), , drop = FALSE]
  write.csv(novo, arquivo_catalogo, row.names = FALSE, na = "", fileEncoding = "UTF-8")
}
