# Coleta as tabelas do Censo Agropecuário 2017 listadas em
# config/tabelas_censo_agro.csv, recortadas pelas classes de atividade de
# config/cadeias.csv.
#
# Na configuração, a coluna atividade diz se a tabela tem a classe de
# atividade (classificação 12440). "sim" aplica o recorte, "nao" coleta sem
# ele e "a confirmar" tenta com o recorte e, se a API recusar, coleta sem.
# A coluna classificacoes lista as classificações abertas por categoria; as
# que não aparecem vêm só no total.
#
# Uso, a partir da raiz do repositório:
#   Rscript R/coletar_censo_agro.R            todas as tabelas
#   Rscript R/coletar_censo_agro.R 6883 6887  só as indicadas

source("R/sidra.R")
source("R/comum.R")

cadeias <- read.csv("config/cadeias.csv", colClasses = "character", encoding = "UTF-8")
tabelas <- read.csv("config/tabelas_censo_agro.csv", colClasses = "character",
                    encoding = "UTF-8", na.strings = character())

pedidas <- commandArgs(trailingOnly = TRUE)
if (length(pedidas) > 0) tabelas <- tabelas[tabelas$tabela %in% pedidas, , drop = FALSE]

COLUNAS_OBRIGATORIAS <- c("tabela", "nivel", "cod_territorio", "territorio",
                          "cadeia", "valor", "valor_bruto", "sigilo")

# Liga cada linha à cadeia de config/cadeias.csv. Tabelas sem a classe de
# atividade só podem ser lidas como "todas as atividades" e recebem esse
# rótulo, nunca o de uma cadeia.
marcar_cadeia <- function(dados, com_atividade) {
  if (com_atividade) {
    pos <- match(dados$cod_atividade, cadeias$codigo_12440)
    dados$cadeia <- cadeias$cadeia[pos]
    dados$cadeia_rotulo <- cadeias$rotulo[pos]
  } else {
    dados$cadeia <- "total"
    dados$cadeia_rotulo <- "Todas as atividades (tabela sem recorte por atividade)"
  }
  dados
}

coletar_tabela <- function(tabela, niveis, classificacoes, com_atividade) {
  atividades <- if (com_atividade) cadeias$codigo_12440 else character()
  partes <- lapply(niveis, function(nivel) {
    message(sprintf("  nível %s", nivel))
    consultar_nivel(tabela, nivel, classificacoes, atividades)
  })
  dados <- tratar_valor(do.call(rbind, partes))
  dados <- marcar_cadeia(dados, com_atividade)
  cbind(tabela = tabela, dados)
}

# Se duas tabelas seguidas falharem por falta de conexão, o IBGE
# provavelmente está fora do ar. As demais são puladas para não gastar tempo
# de execução, e todas ficam com a versão anterior.
falhas_conexao <- 0

for (i in seq_len(nrow(tabelas))) {
  tabela <- tabelas$tabela[i]
  niveis <- strsplit(tabelas$niveis[i], ";", fixed = TRUE)[[1]]
  classificacoes <- strsplit(tabelas$classificacoes[i], ";", fixed = TRUE)[[1]]
  atividade <- tabelas$atividade[i]
  arquivo <- sprintf("dados/sidra/censo_agro_%s.csv", tabela)
  detalhe <- ""
  message(sprintf("Tabela %s", tabela))

  coleta <- if (falhas_conexao >= 2) {
    simpleError("pulada: IBGE inacessível nesta execução")
  } else {
    tryCatch(coletar_tabela(tabela, niveis, classificacoes, atividade != "nao"),
             error = function(e) e)
  }

  if (atividade == "a confirmar" && inherits(coleta, "erro_consulta")) {
    message("  a API recusou o recorte por atividade, coletando sem ele")
    recusa <- conditionMessage(coleta)
    coleta <- tryCatch(coletar_tabela(tabela, niveis, classificacoes, FALSE),
                       error = function(e) e)
    detalhe <- paste("sem recorte por atividade;", recusa)
  }

  falhas_conexao <- if (inherits(coleta, "error") && !inherits(coleta, "erro_consulta"))
    falhas_conexao + 1 else 0

  if (inherits(coleta, "error")) {
    resultado <- list(situacao = "mantida versão anterior",
                      detalhe = conditionMessage(coleta), linhas = 0L)
  } else {
    resultado <- salvar_se_valido(coleta, arquivo, COLUNAS_OBRIGATORIAS)
    if (nzchar(detalhe)) resultado$detalhe <- detalhe
  }
  registrar_situacao(paste0("sidra_", tabela), arquivo, resultado)
  message(sprintf("  %s (%s linhas) %s", resultado$situacao, resultado$linhas, resultado$detalhe))
}
