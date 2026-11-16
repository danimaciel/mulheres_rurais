# Levanta a tabela 6883 do Censo Agro 2017 para todas as classes de
# atividade (classificação 12440), no Brasil e nas UFs, com estabelecimentos
# e área por sexo de quem dirige. Serve para decidir quais cadeias entram na
# plataforma: dá o tamanho de cada classe e quantos estabelecimentos são
# dirigidos por mulheres.
#
# Não entra na coleta mensal. Roda à mão pelo workflow levantar_classes.yml
# ou, localmente, com Rscript R/levantar_classes.R

source("R/sidra.R")
source("R/comum.R")

arquivo <- "dados/sidra/censo_agro_6883_classes.csv.gz"

coleta <- tryCatch({
  partes <- lapply(c("n1", "n3"), function(nivel) {
    message(sprintf("nível %s", nivel))
    consultar_nivel("6883", nivel, "c12564/all", codigos_recorte = "all")
  })
  dados <- tratar_valor(do.call(rbind, partes))
  cbind(tabela = "6883", dados)
}, error = function(e) e)

if (inherits(coleta, "error")) {
  resultado <- list(situacao = "mantida versão anterior",
                    detalhe = conditionMessage(coleta), linhas = 0L)
} else {
  resultado <- salvar_se_valido(coleta, arquivo,
                                c("cod_territorio", "cod_atividade", "atividade", "valor"))
}
registrar_situacao("sidra_6883_classes", arquivo, resultado)
message(sprintf("%s (%s linhas) %s", resultado$situacao, resultado$linhas, resultado$detalhe))
if (inherits(coleta, "error")) quit(status = 1)
