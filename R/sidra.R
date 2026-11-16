# Funções de acesso à API SIDRA do IBGE.
#
# Duas fontes: os metadados das tabelas vêm de servicodados.ibge.gov.br e os
# valores de apisidra.ibge.gov.br. Os metadados são lidos a cada coleta para
# não depender de códigos de classificação escritos à mão.

library(httr)
library(jsonlite)

URL_METADADOS <- "https://servicodados.ibge.gov.br/api/v3/agregados/%s/metadados"
URL_VALORES <- "https://apisidra.ibge.gov.br/values"

# Códigos das UFs, usados para quebrar consultas municipais por estado
# (a API recusa respostas acima de 100 mil valores).
CODIGOS_UF <- c(11:17, 21:29, 31:33, 35, 41:43, 50:53)

baixar_json <- function(url, tentativas = 4, espera = 10) {
  for (i in seq_len(tentativas)) {
    resp <- tryCatch(
      GET(url, timeout(180), user_agent("mulheres-rurais-coleta"),
          config(connecttimeout = 60, ipresolve = 1L)),
      error = function(e) e
    )
    if (!inherits(resp, "error") && status_code(resp) == 200) {
      texto <- content(resp, as = "text", encoding = "UTF-8")
      return(fromJSON(texto, simplifyVector = TRUE))
    }
    motivo <- if (inherits(resp, "error")) conditionMessage(resp) else
      paste("HTTP", status_code(resp), substr(content(resp, as = "text", encoding = "UTF-8"), 1, 200))
    message(sprintf("  tentativa %d de %d falhou: %s", i, tentativas, motivo))
    if (i < tentativas) Sys.sleep(espera * i)
  }
  stop("não foi possível baixar ", url)
}

metadados_tabela <- function(tabela) {
  baixar_json(sprintf(URL_METADADOS, tabela))
}

# Monta o trecho de classificações da URL. A classe de atividade (c12440) é
# recortada pelas categorias de config/cadeias.csv; as demais vêm completas,
# com o total incluído.
trecho_classificacoes <- function(meta, codigos_atividade) {
  classes <- meta$classificacoes
  if (is.null(classes) || NROW(classes) == 0) return("")
  partes <- vapply(seq_len(NROW(classes)), function(i) {
    id <- classes$id[i]
    if (id == 12440) {
      sprintf("c12440/%s", paste(codigos_atividade, collapse = ","))
    } else {
      sprintf("c%s/all", id)
    }
  }, character(1))
  paste(partes, collapse = "/")
}

tem_classe_atividade <- function(meta) {
  !is.null(meta$classificacoes) && 12440 %in% meta$classificacoes$id
}

url_valores <- function(tabela, territorio, classificacoes) {
  partes <- c(URL_VALORES, "t", tabela, territorio, "v", "allxp", "p", "all")
  url <- paste(partes, collapse = "/")
  if (nzchar(classificacoes)) url <- paste(url, classificacoes, sep = "/")
  utils::URLencode(paste0(url, "?formato=json"))
}

# A API devolve uma lista em que a primeira linha traz os rótulos das colunas.
# Aqui viram nomes de coluna em snake_case, mantendo os códigos ao lado dos
# nomes. A primeira dimensão (D1) é sempre o território, e o rótulo dela muda
# conforme o nível ("Brasil", "Município"...), por isso recebe nome fixo.
ler_resposta <- function(bruto, extras = character()) {
  if (!is.data.frame(bruto) || nrow(bruto) < 2) {
    stop("resposta vazia ou em formato inesperado")
  }
  rotulos <- unlist(bruto[1, ], use.names = FALSE)
  fixos <- c(NC = "cod_nivel", NN = "nivel", MC = "cod_unidade",
             MN = "unidade", V = "valor", D1C = "cod_territorio",
             D1N = "territorio", extras)
  rotulos <- normalizar_nome(rotulos)
  troca <- match(names(bruto), names(fixos))
  rotulos[!is.na(troca)] <- fixos[troca[!is.na(troca)]]
  dados <- bruto[-1, , drop = FALSE]
  names(dados) <- rotulos
  rownames(dados) <- NULL
  dados
}

normalizar_nome <- function(x) {
  x <- iconv(x, from = "UTF-8", to = "ASCII//TRANSLIT")
  x <- tolower(gsub("[^A-Za-z0-9]+", "_", x))
  x <- gsub("^_|_$", "", x)
  make.unique(x, sep = "_")
}

# Símbolos do IBGE: "X" é dado omitido por sigilo, "-" é zero absoluto,
# ".." e "..." são não aplicável ou não disponível. O valor original fica em
# valor_bruto e valor recebe só o número.
tratar_valor <- function(dados) {
  dados$valor_bruto <- dados$valor
  dados$sigilo <- dados$valor_bruto == "X"
  num <- dados$valor_bruto
  num[num == "-"] <- "0"
  num[num %in% c("X", "..", "...")] <- NA
  dados$valor <- suppressWarnings(as.numeric(num))
  dados
}

# Posição da classe de atividade na resposta: D1 é território, D2 variável,
# D3 ano e as classificações seguem a ordem em que entraram na URL.
colunas_atividade <- function(meta) {
  if (!tem_classe_atividade(meta)) return(character())
  k <- 3 + match(12440, meta$classificacoes$id)
  setNames(c("cod_atividade", "atividade"), paste0("D", k, c("C", "N")))
}

consultar_nivel <- function(tabela, nivel, classificacoes, extras = character()) {
  territorios <- if (nivel == "n6") sprintf("n6/in n3 %d", CODIGOS_UF) else paste0(nivel, "/all")
  pedacos <- lapply(territorios, function(territorio) {
    ler_resposta(baixar_json(url_valores(tabela, territorio, classificacoes)), extras)
  })
  do.call(rbind, pedacos)
}
