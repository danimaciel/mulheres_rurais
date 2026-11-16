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

url_valores <- function(tabela, territorio, classificacoes) {
  partes <- c(URL_VALORES, "t", tabela, territorio, "v", "allxp", "p", "all",
              classificacoes[nzchar(classificacoes)])
  utils::URLencode(paste0(paste(partes, collapse = "/"), "?formato=json"))
}

# A API devolve uma lista em que a primeira linha traz os rótulos das colunas.
# Aqui viram nomes de coluna em snake_case. A primeira dimensão (D1) é sempre
# o território e o rótulo dela muda conforme o nível ("Brasil",
# "Município"...), por isso recebe nome fixo. Quando a classe de atividade
# entra na consulta, ela vem logo depois de variável (D2) e ano (D3).
ler_resposta <- function(bruto, com_atividade) {
  if (!is.data.frame(bruto) || nrow(bruto) < 2) {
    stop("resposta vazia ou em formato inesperado")
  }
  fixos <- c(NC = "cod_nivel", NN = "nivel", MC = "cod_unidade",
             MN = "unidade", V = "valor", D1C = "cod_territorio",
             D1N = "territorio")
  if (com_atividade) fixos <- c(fixos, D4C = "cod_atividade", D4N = "atividade")
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
# UF e, quando há recorte de atividade, também por atividade, para ficar
# abaixo do limite de valores por resposta.
consultar_nivel <- function(tabela, nivel, classificacoes, atividades = character()) {
  com_atividade <- length(atividades) > 0
  territorios <- if (nivel == "n6") sprintf("n6/in n3 %d", CODIGOS_UF) else paste0(nivel, "/all")
  grupos_atividade <- if (!com_atividade) list("") else
    if (nivel == "n6") as.list(atividades) else list(atividades)

  pedidos <- expand.grid(t = seq_along(territorios), a = seq_along(grupos_atividade))
  pedacos <- lapply(seq_len(nrow(pedidos)), function(i) {
    recorte <- grupos_atividade[[pedidos$a[i]]]
    classes <- c(if (com_atividade) paste0("c12440/", paste(recorte, collapse = ",")),
                 classificacoes)
    url <- url_valores(tabela, territorios[pedidos$t[i]], classes)
    ler_resposta(baixar_json(url), com_atividade)
  })
  do.call(rbind, pedacos)
}
