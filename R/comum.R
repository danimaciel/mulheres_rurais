# Rotinas compartilhadas pelos scripts de coleta.
#
# A regra principal: um arquivo de dados só é substituído quando a versão nova
# passa nas checagens. Se a fonte falhar ou vier incompleta, o arquivo
# anterior fica onde está e o problema é registrado em
# dados/metadados/situacao_coleta.csv.

ARQUIVO_SITUACAO <- "dados/metadados/situacao_coleta.csv"

# Quanto a base nova pode encolher em relação à anterior antes de ser
# considerada suspeita. Uma queda maior que essa costuma ser resposta parcial
# da API, não mudança real nos dados.
QUEDA_MAXIMA <- 0.2

validar_base <- function(nova, arquivo, colunas_obrigatorias) {
  if (is.null(nova) || nrow(nova) == 0) return("base nova veio vazia")
  faltando <- setdiff(colunas_obrigatorias, names(nova))
  if (length(faltando) > 0) {
    return(paste("faltam colunas:", paste(faltando, collapse = ", ")))
  }
  if (file.exists(arquivo)) {
    linhas_antes <- nrow(read.csv(arquivo, colClasses = "character", encoding = "UTF-8"))
    if (linhas_antes > 0 && nrow(nova) < linhas_antes * (1 - QUEDA_MAXIMA)) {
      return(sprintf("base nova tem %d linhas, a anterior tinha %d",
                     nrow(nova), linhas_antes))
    }
  }
  NA_character_
}

salvar_se_valido <- function(nova, arquivo, colunas_obrigatorias = character()) {
  problema <- validar_base(nova, arquivo, colunas_obrigatorias)
  if (!is.na(problema)) {
    return(list(situacao = "mantida versão anterior", detalhe = problema,
                linhas = if (is.null(nova)) 0L else nrow(nova)))
  }
  dir.create(dirname(arquivo), recursive = TRUE, showWarnings = FALSE)
  temporario <- paste0(arquivo, ".tmp")
  # Arquivos .csv.gz são gravados comprimidos. As tabelas municipais passam
  # de 100 MB em texto puro, que é o limite de arquivo do GitHub.
  saida <- if (grepl("\\.gz$", arquivo)) gzfile(temporario, "w", encoding = "UTF-8") else
    file(temporario, "w", encoding = "UTF-8")
  write.csv(nova, saida, row.names = FALSE, na = "")
  close(saida)
  mudou <- !file.exists(arquivo) ||
    !identical(unname(tools::md5sum(temporario)), unname(tools::md5sum(arquivo)))
  file.rename(temporario, arquivo)
  list(situacao = if (mudou) "atualizada" else "sem mudança",
       detalhe = "", linhas = nrow(nova))
}

registrar_situacao <- function(fonte, arquivo, resultado) {
  dir.create(dirname(ARQUIVO_SITUACAO), recursive = TRUE, showWarnings = FALSE)
  linha <- data.frame(
    fonte = fonte,
    arquivo = arquivo,
    situacao = resultado$situacao,
    detalhe = resultado$detalhe,
    linhas = resultado$linhas,
    verificado_em = format(Sys.time(), "%Y-%m-%d %H:%M", tz = "America/Sao_Paulo")
  )
  if (file.exists(ARQUIVO_SITUACAO)) {
    antiga <- read.csv(ARQUIVO_SITUACAO, colClasses = "character", encoding = "UTF-8")
    antiga <- antiga[antiga$fonte != fonte, , drop = FALSE]
    linha <- rbind(antiga, linha)
  }
  linha <- linha[order(linha$fonte), , drop = FALSE]
  write.csv(linha, ARQUIVO_SITUACAO, row.names = FALSE, na = "", fileEncoding = "UTF-8")
  if (resultado$situacao == "mantida versão anterior") {
    # Aparece como aviso no resumo do GitHub Actions.
    cat(sprintf("::warning::%s: %s\n", fonte, resultado$detalhe))
  }
  invisible(linha)
}
