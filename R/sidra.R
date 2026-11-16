# Funções de acesso à API SIDRA do IBGE (apisidra.ibge.gov.br).
#
# O serviço de metadados do IBGE (servicodados.ibge.gov.br) não responde aos
# servidores do GitHub, então as classificações de cada tabela ficam
# declaradas em config/tabelas_censo_agro.csv e tudo passa só pela API de
# valores.

library(httr)
library(jsonlite)

URL_VALORES <- "https://apisidra.ibge.gov.br/values"

# Códigos das UFs, usados para quebrar consultas municipais por estado
# (a API recusa respostas acima de 100 mil valores).
CODIGOS_UF <- c(11:17, 21:29, 31:33, 35, 41:43, 50:53)

# Erro de consulta (HTTP 4xx): a API entendeu o pedido e recusou, então não
# adianta tentar de novo.
erro_consulta <- function(msg) {
  structure(class = c("erro_consulta", "error", "condition"),
            list(message = msg, call = NULL))
}

baixar_json <- function(url, tentativas = 4, espera = 10) {
  for (i in seq_len(tentativas)) {
    resp <- tryCatch(
      GET(url, timeout(180), user_agent("mulheres-rurais-coleta"),
          config(connecttimeout = 60, ipresolve = 1L)),
      error = function(e) e
    )
    if (!inherits(resp, "error")) {
      codigo <- status_code(resp)
      texto <- content(resp, as = "text", encoding = "UTF-8")
      if (codigo == 200) return(fromJSON(texto, simplifyVector = TRUE))
      if (codigo >= 400 && codigo < 500 && codigo != 429) {
        stop(erro_consulta(sprintf("HTTP %d: %s", codigo, trimws(substr(texto, 1, 300)))))
      }
      motivo <- sprintf("HTTP %d", codigo)
    } else {
      motivo <- conditionMessage(resp)
    }
    message(sprintf("  tentativa %d de %d falhou: %s", i, tentativas, motivo))
    if (i < tentativas) Sys.sleep(espera * i)
  }
  stop("não foi possível baixar ", url)
}

url_valores <- function(tabela, territorio, classificacoes, periodo = "all") {
  partes <- c(URL_VALORES, "t", tabela, territorio, "v", "allxp", "p", periodo,
              classificacoes[nzchar(classificacoes)])
  utils::URLencode(paste0(paste(partes, collapse = "/"), "?formato=json"))
}

# A API devolve uma lista em que a primeira linha traz os rótulos das colunas.
# Aqui viram nomes de coluna em snake_case. A primeira dimensão (D1) é sempre
# o território e o rótulo dela muda conforme o nível ("Brasil",
# "Município"...), por isso recebe nome fixo. Quando há uma classificação de
# recorte (atividade no Censo, produto na PAM, PPM e PEVS), ela entra primeiro
# na URL e vem logo depois de variável (D2) e ano (D3).
ler_resposta <- function(bruto, nomes_recorte = character()) {
  if (!is.data.frame(bruto) || nrow(bruto) < 2) {
    stop("resposta vazia ou em formato inesperado")
  }
  fixos <- c(NC = "cod_nivel", NN = "nivel", MC = "cod_unidade",
             MN = "unidade", V = "valor", D1C = "cod_territorio",
             D1N = "territorio")
  if (length(nomes_recorte) == 2) fixos <- c(fixos, D4C = nomes_recorte[1], D4N = nomes_recorte[2])
  rotulos <- normalizar_nome(unlist(bruto[1, ], use.names = FALSE))
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

# Consulta um nível territorial. No nível municipal a consulta é quebrada por
# UF e, quando há recorte, também por categoria do recorte, para ficar abaixo
# do limite de valores por resposta.
consultar_nivel <- function(tabela, nivel, classificacoes, codigos_recorte = character(),
                            classe_recorte = "12440",
                            nomes_recorte = c("cod_atividade", "atividade"),
                            periodo = "all") {
  com_recorte <- length(codigos_recorte) > 0
  territorios <- if (nivel == "n6") sprintf("n6/in n3 %d", CODIGOS_UF) else paste0(nivel, "/all")
  grupos <- if (!com_recorte) list("") else
    if (nivel == "n6") as.list(codigos_recorte) else list(codigos_recorte)

  pedidos <- expand.grid(t = seq_along(territorios), g = seq_along(grupos))
  pedacos <- lapply(seq_len(nrow(pedidos)), function(i) {
    recorte <- grupos[[pedidos$g[i]]]
    classes <- c(if (com_recorte) sprintf("c%s/%s", classe_recorte, paste(recorte, collapse = ",")),
                 classificacoes)
    url <- url_valores(tabela, territorios[pedidos$t[i]], classes, periodo)
    ler_resposta(baixar_json(url), if (com_recorte) nomes_recorte else character())
  })
  do.call(rbind, pedacos)
}

# Lista as categorias de uma classificação a partir de uma consulta pequena
# (Brasil, último período). Serve para escolher produtos pelo nome sem
# depender do serviço de metadados.
categorias <- function(tabela, classe) {
  url <- url_valores(tabela, "n1/all", sprintf("c%s/all", classe), "last 1")
  dados <- ler_resposta(baixar_json(url), c("codigo", "nome"))
  unique(dados[, c("codigo", "nome")])
}
