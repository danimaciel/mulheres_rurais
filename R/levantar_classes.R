# Levanta as tabelas 6883 e 6887 do Censo Agro 2017 para todas as classes de
# atividade (classificação 12440), no Brasil e nas UFs. A 6883 traz
# estabelecimentos e área por sexo de quem dirige; a 6887, o pessoal ocupado
# por tipo de vínculo e sexo. Serve para comparar as cadeias candidatas e
# alimentar as páginas das cadeias que ainda não têm coleta municipal.
#
# Não entra na coleta mensal. Roda à mão pelo workflow levantar_classes.yml
# ou, localmente, com Rscript R/levantar_classes.R

source("R/sidra.R")
source("R/comum.R")

tabelas <- list(
  "6883" = "c12564/all",
  "6887" = "c12578/all"
)
erros <- 0

for (tabela in names(tabelas)) {
  arquivo <- sprintf("dados/sidra/censo_agro_%s_classes.csv.gz", tabela)
  message(sprintf("Tabela %s", tabela))
  coleta <- tryCatch({
    partes <- lapply(c("n1", "n3"), function(nivel) {
      message(sprintf("  nível %s", nivel))
      consultar_nivel(tabela, nivel, tabelas[[tabela]], codigos_recorte = "all")
    })
    cbind(tabela = tabela, tratar_valor(do.call(rbind, partes)))
  }, error = function(e) e)

  if (inherits(coleta, "error")) {
    erros <- erros + 1
    resultado <- list(situacao = "mantida versão anterior",
                      detalhe = conditionMessage(coleta), linhas = 0L)
  } else {
    resultado <- salvar_se_valido(coleta, arquivo,
                                  c("cod_territorio", "cod_atividade", "atividade", "valor"))
  }
  registrar_situacao(sprintf("sidra_%s_classes", tabela), arquivo, resultado)
  message(sprintf("  %s (%s linhas) %s", resultado$situacao, resultado$linhas, resultado$detalhe))
}
if (erros > 0) quit(status = 1)
