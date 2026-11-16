# Importa a base de organizações de mulheres da Amazônia a partir do
# repositório organizacoes_mulheres_amazonia. A base fica embutida no
# index.html de lá, num bloco <script id="orgs-data">, e é lida direto da
# branch main. Nada é copiado à mão: a correção de qualquer registro deve ser
# feita no repositório de origem.
#
# Uso: Rscript R/importar_organizacoes.R

library(httr)
library(jsonlite)
source("R/comum.R")

REPO_ORIGEM <- "danimaciel/organizacoes_mulheres_amazonia"
URL_ORIGEM <- sprintf("https://raw.githubusercontent.com/%s/main/index.html", REPO_ORIGEM)
URL_COMMIT <- sprintf("https://api.github.com/repos/%s/commits/main", REPO_ORIGEM)
ARQUIVO <- "dados/organizacoes/amazonia.csv"

COLUNAS_OBRIGATORIAS <- c("id", "nome", "tipo", "municipio", "estado",
                          "cadeia_produtiva", "fonte", "grau_verificacao")

extrair_base <- function(html) {
  achado <- regmatches(html, regexec(
    '<script id="orgs-data" type="application/json">(.*?)</script>', html))[[1]]
  if (length(achado) < 2) stop("bloco orgs-data não encontrado no index.html")
  fromJSON(achado[2], simplifyVector = TRUE)
}

# Campos de texto com várias entradas separadas por ";" ficam como estão; a
# separação é feita na hora de montar os filtros da plataforma.
importar <- function() {
  resp <- GET(URL_ORIGEM, timeout(60))
  stop_for_status(resp)
  html <- content(resp, as = "text", encoding = "UTF-8")
  base <- extrair_base(html)

  versao <- tryCatch({
    commit <- content(GET(URL_COMMIT, timeout(30)), as = "parsed")
    if (is.character(commit$sha)) substr(commit$sha, 1, 7) else ""
  }, error = function(e) "")

  base$bioma_base <- "Amazônia"
  base$origem <- REPO_ORIGEM
  base$versao_origem <- versao
  base
}

base <- tryCatch(importar(), error = function(e) e)

if (inherits(base, "error")) {
  resultado <- list(situacao = "mantida versão anterior",
                    detalhe = conditionMessage(base), linhas = 0L)
} else {
  resultado <- salvar_se_valido(base, ARQUIVO, COLUNAS_OBRIGATORIAS)
}
registrar_situacao("organizacoes_amazonia", ARQUIVO, resultado)
message(sprintf("Organizações da Amazônia: %s (%s linhas) %s",
                resultado$situacao, resultado$linhas, resultado$detalhe))
