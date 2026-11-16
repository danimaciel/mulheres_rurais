# Indicadores de trabalho invisível das mulheres, por cadeia.
#
# São quatro, calculados para cada cadeia de config/indicadores.csv a partir
# dos arquivos de dados/sidra/ (nada é baixado aqui):
#
#   1. trabalho familiar não reconhecido: mulheres da família que trabalham no
#      estabelecimento e não aparecem como produtoras, e quanto valeria esse
#      trabalho pago a salário mínimo;
#   2. direção invisível: estabelecimentos dirigidos pelo casal em que só o
#      homem ficou registrado como produtor;
#   3. dupla jornada: valor das horas de afazeres domésticos e cuidados das
#      mulheres da família;
#   4. valor da produção ligado às mulheres, em duas leituras aproximadas.
#
# Cada indicador sai em dois recortes quando os dados permitem. "principal" é
# o dado direto do Censo para os estabelecimentos cuja atividade principal é
# a cadeia (6883 e 6887). "onde_ha" inclui também quem tem o produto como
# atividade secundária (6955) e é uma estimativa, explicada em
# docs/indicadores.md. A direção invisível usa o grupo de atividade da 6768
# nos municípios da cadeia, que é um terceiro recorte.
#
# Uso, a partir da raiz do repositório:
#   Rscript R/indicadores_trabalho_invisivel.R
#
# Saídas em dados/indicadores/: um arquivo por indicador e resumo.csv com os
# números do Brasil.

SALARIO_MINIMO <- 1621          # mensal, 2026
HORAS_MES <- 220
DEDICACAO <- c(baixo = 0.25, medio = 0.5, alto = 1)  # fração de um ano de trabalho
MIN_ESTAB_MUNICIPIO <- 10       # abaixo disso o percentual municipal fica vazio
MIN_ESTAB_UF <- 500             # idem para UF

PASTA <- "dados/sidra"
SAIDA <- "dados/indicadores"
dir.create(SAIDA, recursive = TRUE, showWarnings = FALSE)

cadeias <- read.csv("config/indicadores.csv", colClasses = "character", encoding = "UTF-8")

UF_SIGLA <- c("11" = "RO", "12" = "AC", "13" = "AM", "14" = "RR", "15" = "PA", "16" = "AP",
              "17" = "TO", "21" = "MA", "22" = "PI", "23" = "CE", "24" = "RN", "25" = "PB",
              "26" = "PE", "27" = "AL", "28" = "SE", "29" = "BA", "31" = "MG", "32" = "ES",
              "33" = "RJ", "35" = "SP", "41" = "PR", "42" = "SC", "43" = "RS", "50" = "MS",
              "51" = "MT", "52" = "GO", "53" = "DF")

ler <- function(nome) {
  arq <- file.path(PASTA, nome)
  if (!file.exists(arq)) return(NULL)
  read.csv(gzfile(arq), encoding = "UTF-8", colClasses = c(cod_territorio = "character"))
}

# Transforma linhas (território x categoria) em colunas, uma por categoria.
# Mantém NA onde o IBGE pôs sigilo.
larga <- function(d, coluna, categorias) {
  d <- d[d[[coluna]] %in% names(categorias), ]
  chave <- unique(d[, c("cod_nivel", "cod_territorio", "territorio")])
  for (cod in names(categorias)) {
    sub <- d[d[[coluna]] == cod, ]
    chave[[categorias[[cod]]]] <- sub$valor[match(chave$cod_territorio, sub$cod_territorio)]
  }
  chave
}

z <- function(x) ifelse(is.na(x), 0, x)
div <- function(a, b) ifelse(!is.na(b) & b > 0, a / b, NA_real_)
nivel_nome <- function(cod) c("1" = "Brasil", "3" = "UF", "6" = "Município")[as.character(cod)]
uf_de <- function(cod) unname(UF_SIGLA[substr(cod, 1, 2)])

t6883 <- ler("censo_agro_6883.csv.gz")
t6887 <- ler("censo_agro_6887.csv.gz")
t6768 <- ler("censo_agro_6768_direcao.csv.gz")
t6955 <- ler("censo_agro_6955_produtos.csv.gz")
pam <- ler("pam_5457.csv.gz")
pnad <- ler("pnad_7015.csv.gz")

if (is.null(t6768)) message("Sem censo_agro_6768_direcao.csv.gz: direção invisível e dirigentes estimadas ficam de fora")
if (is.null(t6955)) message("Sem censo_agro_6955_produtos.csv.gz: o recorte onde_ha fica de fora")

SEXO_6883 <- c("41145" = "t", "112634" = "h", "112635" = "m")
estab_area <- function(classe) {
  d <- t6883[t6883$cod_atividade == classe, ]
  e <- larga(d[d$variavel_codigo == 9587, ], "sexo_do_produtor_codigo", SEXO_6883)
  a <- larga(d[d$variavel_codigo == 184, ], "sexo_do_produtor_codigo", SEXO_6883)
  names(e)[4:6] <- paste0("estab_", names(e)[4:6])
  e[paste0("area_", c("t", "h", "m"))] <- a[match(e$cod_territorio, a$cod_territorio), 4:6]
  e
}

PESSOAL <- c("112967" = "pessoal_total", "45961" = "familia_h", "45963" = "familia_m",
             "45964" = "familia_m_menos14", "45969" = "permanentes_m", "45974" = "temporarias_m",
             "45979" = "parceiras_m")
pessoal <- function(classe) {
  d <- t6887[t6887$cod_atividade == classe & t6887$variavel_codigo == 185, ]
  larga(d, "tipo_de_pessoal_ocupado_codigo", PESSOAL)
}

# 6768 em formato largo: total e casal, por sexo de quem dirige, num grupo
# de atividade. 113601 é o total dos grupos.
SEXO_6768 <- c("46500" = "t", "112643" = "h", "112644" = "m")
direcao <- function(grupo) {
  d <- t6768[t6768$grupos_de_atividade_economica_codigo == grupo, ]
  col_dir <- "direcao_dos_trabalhos_do_estabelecimento_agropecuario_codigo"
  col_sexo <- "sexo_da_pessoa_que_dirige_o_estabelecimento_produtor_ou_administrador_codigo"
  partes <- lapply(c(tot = "41149", casal = "40592"), function(cod) {
    x <- larga(d[d[[col_dir]] == cod, ], col_sexo, SEXO_6768)
    x
  })
  out <- partes$tot
  names(out)[4:6] <- paste0("dir_", names(out)[4:6])
  out[paste0("casal_", c("t", "h", "m"))] <- partes$casal[match(out$cod_territorio, partes$casal$cod_territorio), 4:6]
  out
}

# Estabelecimentos que têm o produto (6955), somando os produtos da cadeia.
# No café, quem tem arábica e canéfora entra duas vezes.
com_produto <- function(filtro) {
  d <- t6955[t6955$variavel_codigo == 9504 & grepl(filtro, t6955$produto, ignore.case = TRUE), ]
  if (nrow(d) == 0) return(NULL)
  s <- aggregate(valor ~ cod_nivel + cod_territorio, data = transform(d, valor = z(valor)), FUN = sum)
  names(s)[3] <- "estab_com_produto"
  s
}

pam_ultimo <- function(filtro) {
  d <- pam[grepl(filtro, pam$produto), ]
  ano <- max(d$ano)
  d <- d[d$ano == ano, ]
  v <- d[d$variavel == "Valor da produção", c("cod_nivel", "cod_territorio", "territorio", "valor")]
  q <- d[d$variavel == "Quantidade produzida", c("cod_territorio", "valor")]
  v$producao_t <- q$valor[match(v$cod_territorio, q$cod_territorio)]
  names(v)[4] <- "valor_pam_mil_reais"
  v$ano_pam <- ano
  v
}

horas_pnad <- function() {
  d <- pnad[pnad$cod_nivel == 3 & !startsWith(pnad$variavel, "Coef"), ]
  d <- d[d$ano == max(d$ano), ]
  data.frame(
    cod_uf = unique(d$cod_territorio),
    ano_pnad = max(d$ano),
    horas_m = d$valor[d$sexo == "Mulheres"][match(unique(d$cod_territorio), d$cod_territorio[d$sexo == "Mulheres"])],
    horas_h = d$valor[d$sexo == "Homens"][match(unique(d$cod_territorio), d$cod_territorio[d$sexo == "Homens"])]
  )
}

valor_anual <- function(pessoas, fracao) pessoas * SALARIO_MINIMO * 12 * fracao
valor_horas <- function(pessoas, horas_semana) pessoas * horas_semana * 52 * SALARIO_MINIMO / HORAS_MES

saidas <- list(trabalho = list(), direcao = list(), jornada = list(), valor = list(), resumo = list())
resumir <- function(cadeia, indicador, recorte, medida, valor) {
  saidas$resumo[[length(saidas$resumo) + 1]] <<- data.frame(
    cadeia = cadeia, indicador = indicador, recorte = recorte, medida = medida, valor = valor)
}

agro_ea <- estab_area("110016")
agro_po <- pessoal("110016")
horas <- if (!is.null(pnad)) horas_pnad() else NULL
dir_total <- if (!is.null(t6768)) direcao("113601") else NULL

for (i in seq_len(nrow(cadeias))) {
  cfg <- cadeias[i, ]
  cadeia <- cfg$cadeia
  message("Cadeia ", cadeia)
  ea <- estab_area(cfg$codigo_12440)
  po <- pessoal(cfg$codigo_12440)

  # ---- 1. Trabalho familiar, recorte principal (direto) --------------------
  tf <- merge(po, ea[, c("cod_territorio", "estab_t", "estab_m")], by = "cod_territorio", all.x = TRUE)
  tf$dirigentes_m <- tf$estab_m
  tf$pct_mulheres_familia <- 100 * div(tf$familia_m, tf$familia_m + tf$familia_h)
  tf$mulheres_nao_dirigentes <- pmax(tf$familia_m - tf$dirigentes_m, 0)
  for (k in names(DEDICACAO)) tf[[paste0("valor_", k)]] <- valor_anual(tf$mulheres_nao_dirigentes, DEDICACAO[[k]])
  trabalho_principal <- data.frame(
    cadeia = cadeia, recorte = "principal", nivel = nivel_nome(tf$cod_nivel),
    cod_territorio = tf$cod_territorio, territorio = tf$territorio,
    estab = tf$estab_t, mulheres_familia = tf$familia_m, homens_familia = tf$familia_h,
    pct_mulheres_familia = tf$pct_mulheres_familia, dirigentes_m = tf$dirigentes_m,
    mulheres_nao_dirigentes = tf$mulheres_nao_dirigentes,
    valor_baixo = tf$valor_baixo, valor_medio = tf$valor_medio, valor_alto = tf$valor_alto)
  saidas$trabalho[[length(saidas$trabalho) + 1]] <- trabalho_principal
  br <- tf[tf$cod_nivel == 1, ]
  resumir(cadeia, "trabalho_familiar", "principal", "mulheres_familia_14mais", br$familia_m)
  resumir(cadeia, "trabalho_familiar", "principal", "pct_mulheres_familia", br$pct_mulheres_familia)
  resumir(cadeia, "trabalho_familiar", "principal", "dirigentes_m", br$dirigentes_m)
  resumir(cadeia, "trabalho_familiar", "principal", "mulheres_nao_dirigentes", br$mulheres_nao_dirigentes)
  for (k in names(DEDICACAO)) resumir(cadeia, "trabalho_familiar", "principal", paste0("valor_", k), br[[paste0("valor_", k)]])

  # ---- 1b. Trabalho familiar, recorte onde_ha (estimado) ------------------
  # Em cada município: dado direto da atividade principal + estabelecimentos
  # com o produto como atividade secundária x média municipal de mulheres
  # (e homens) da família por estabelecimento, em todas as atividades. Se o
  # município está em sigilo, usa a média da UF.
  onde <- NULL
  cp <- if (!is.null(t6955)) com_produto(cfg$produtos_6955) else NULL
  if (is.null(cp)) message("  sem estabelecimentos com o produto na 6955, recorte onde_ha fica de fora")
  if (!is.null(cp)) {
    m <- agro_ea[agro_ea$cod_nivel == 6, c("cod_territorio", "territorio", "estab_t")]
    names(m)[3] <- "agro_estab"
    m$cod_uf <- substr(m$cod_territorio, 1, 2)
    m$estab_com_produto <- cp$estab_com_produto[match(m$cod_territorio, cp$cod_territorio)]
    m$estab_principal <- ea$estab_t[match(m$cod_territorio, ea$cod_territorio)]
    mun_po <- po[po$cod_nivel == 6, ]
    agm <- agro_po[agro_po$cod_nivel == 6, ]
    agu <- agro_po[agro_po$cod_nivel == 3, ]
    estab_uf <- tapply(z(m$agro_estab), m$cod_uf, sum)
    m$secundario <- pmax(z(m$estab_com_produto) - z(m$estab_principal), 0)
    for (s in c("m", "h")) {
      col <- paste0("familia_", s)
      razao_mun <- div(agm[[col]][match(m$cod_territorio, agm$cod_territorio)], m$agro_estab)
      razao_uf <- agu[[col]][match(m$cod_uf, agu$cod_territorio)] / estab_uf[m$cod_uf]
      razao <- ifelse(is.na(razao_mun), razao_uf, razao_mun)
      direto <- z(mun_po[[col]][match(m$cod_territorio, mun_po$cod_territorio)])
      m[[paste0("familia_", s, "_est")]] <- direto + m$secundario * z(razao)
    }
    # Dirigentes: estabelecimentos com o produto x proporção de mulheres
    # entre quem dirige os estabelecimentos do município (6768, todas as
    # atividades). É o mesmo método do painel Café em Números.
    if (!is.null(dir_total)) {
      dm <- dir_total[dir_total$cod_nivel == 6, ]
      prop <- div(dm$dir_m, dm$dir_t)[match(m$cod_territorio, dm$cod_territorio)]
      m$dirigentes_m_est <- z(m$estab_com_produto * prop)
    } else m$dirigentes_m_est <- NA_real_
    m <- m[z(m$estab_com_produto) > 0, ]
    m$uf <- uf_de(m$cod_territorio)

    agrega <- function(chave, nomes) {
      cols <- c("estab_com_produto", "familia_m_est", "familia_h_est", "dirigentes_m_est")
      a <- aggregate(m[cols], by = list(chave = chave), FUN = function(x) sum(z(x)))
      a$nome <- nomes[a$chave]
      a
    }
    nomes_uf <- setNames(agro_ea$territorio[agro_ea$cod_nivel == 3], agro_ea$cod_territorio[agro_ea$cod_nivel == 3])
    a_uf <- agrega(m$cod_uf, nomes_uf)
    a_br <- agrega(rep("1", nrow(m)), c("1" = "Brasil"))
    onde <- rbind(
      data.frame(nivel = "Brasil", cod_territorio = a_br$chave, territorio = a_br$nome, a_br[2:5]),
      data.frame(nivel = "UF", cod_territorio = a_uf$chave, territorio = a_uf$nome, a_uf[2:5]),
      data.frame(nivel = "Município", cod_territorio = m$cod_territorio, territorio = m$territorio,
                 m[c("estab_com_produto", "familia_m_est", "familia_h_est", "dirigentes_m_est")]))
    nd <- pmax(onde$familia_m_est - onde$dirigentes_m_est, 0)
    saidas$trabalho[[length(saidas$trabalho) + 1]] <- data.frame(
      cadeia = cadeia, recorte = "onde_ha", nivel = onde$nivel,
      cod_territorio = onde$cod_territorio, territorio = onde$territorio,
      estab = onde$estab_com_produto, mulheres_familia = onde$familia_m_est,
      homens_familia = onde$familia_h_est,
      pct_mulheres_familia = 100 * div(onde$familia_m_est, onde$familia_m_est + onde$familia_h_est),
      dirigentes_m = onde$dirigentes_m_est, mulheres_nao_dirigentes = nd,
      valor_baixo = valor_anual(nd, DEDICACAO[["baixo"]]),
      valor_medio = valor_anual(nd, DEDICACAO[["medio"]]),
      valor_alto = valor_anual(nd, DEDICACAO[["alto"]]))
    b <- onde[1, ]
    resumir(cadeia, "trabalho_familiar", "onde_ha", "estab_com_produto", b$estab_com_produto)
    resumir(cadeia, "trabalho_familiar", "onde_ha", "mulheres_familia_14mais", b$familia_m_est)
    resumir(cadeia, "trabalho_familiar", "onde_ha", "pct_mulheres_familia",
            100 * b$familia_m_est / (b$familia_m_est + b$familia_h_est))
    resumir(cadeia, "trabalho_familiar", "onde_ha", "dirigentes_m", b$dirigentes_m_est)
    resumir(cadeia, "trabalho_familiar", "onde_ha", "mulheres_nao_dirigentes", nd[1])
    for (k in names(DEDICACAO)) resumir(cadeia, "trabalho_familiar", "onde_ha", paste0("valor_", k),
                                        valor_anual(nd[1], DEDICACAO[[k]]))
  }

  # ---- 2. Direção invisível ------------------------------------------------
  # Grupo de atividade da cadeia (6768), somado nos municípios da cadeia.
  # Quando o casal dirige e quem respondeu foi o homem, supõe-se que a mulher
  # divide a direção.
  if (!is.null(t6768)) {
    dg <- direcao(cfg$grupo_6768)
    dg <- dg[dg$cod_nivel == 6, ]
    pm <- if (!is.null(pam)) pam_ultimo(cfg$produto_pam) else NULL
    principal <- ea$estab_t[match(dg$cod_territorio, ea$cod_territorio)]
    tem_produto <- if (is.null(cp)) NA else cp$estab_com_produto[match(dg$cod_territorio, cp$cod_territorio)]
    producao <- if (is.null(pm)) NA else pm$producao_t[match(dg$cod_territorio, pm$cod_territorio)]
    dg$municipio_da_cadeia <- z(principal) >= as.numeric(cfg$min_estab_principal) |
      z(tem_produto) >= as.numeric(cfg$min_estab_com_produto) |
      z(producao) >= as.numeric(cfg$min_producao_pam_t)
    dc <- dg[dg$municipio_da_cadeia, ]
    dc$uf <- uf_de(dc$cod_territorio)
    cols <- c("dir_t", "dir_m", "casal_t", "casal_h", "casal_m")
    soma <- function(by) aggregate(dc[cols], by = list(chave = by), FUN = function(x) sum(z(x)))
    s_br <- soma(rep("Brasil", nrow(dc)))
    s_uf <- soma(dc$uf)
    di <- rbind(
      data.frame(nivel = "Brasil", cod_territorio = "1", territorio = "Brasil", s_br[cols]),
      data.frame(nivel = "UF", cod_territorio = names(UF_SIGLA)[match(s_uf$chave, UF_SIGLA)],
                 territorio = s_uf$chave, s_uf[cols]),
      data.frame(nivel = "Município", cod_territorio = dc$cod_territorio, territorio = dc$territorio, dc[cols]))
    minimo <- ifelse(di$nivel == "Município", MIN_ESTAB_MUNICIPIO, ifelse(di$nivel == "UF", MIN_ESTAB_UF, 0))
    ok <- z(di$dir_t) >= minimo
    di$pct_dirigente_principal <- ifelse(ok, 100 * div(di$dir_m, di$dir_t), NA)
    di$pct_participacao_ampliada <- ifelse(ok, 100 * div(di$dir_m + di$casal_h, di$dir_t), NA)
    di$pct_invisivel <- ifelse(ok, 100 * div(di$casal_h, di$dir_m + di$casal_h), NA)
    di$pct_casal_homem_registrado <- ifelse(ok, 100 * div(di$casal_h, di$casal_h + di$casal_m), NA)
    names(di)[names(di) == "dir_t"] <- "estab_grupo"
    names(di)[names(di) == "dir_m"] <- "mulher_dirigente"
    saidas$direcao[[length(saidas$direcao) + 1]] <- cbind(cadeia = cadeia, grupo_6768 = cfg$grupo_6768, di)
    b <- di[1, ]
    resumir(cadeia, "direcao_invisivel", "grupo_nos_municipios", "municipios", nrow(dc))
    for (k in c("estab_grupo", "mulher_dirigente", "casal_t", "casal_h", "casal_m", "pct_dirigente_principal",
                "pct_participacao_ampliada", "pct_invisivel", "pct_casal_homem_registrado"))
      resumir(cadeia, "direcao_invisivel", "grupo_nos_municipios", k, b[[k]])
  }

  # ---- 3. Dupla jornada ----------------------------------------------------
  # Horas da PNAD por UF (sem corte rural) x mulheres da família da cadeia.
  if (!is.null(horas)) {
    recortes <- list(principal = data.frame(cod_uf = tf$cod_territorio[tf$cod_nivel == 3],
                                            mulheres = z(tf$familia_m[tf$cod_nivel == 3])))
    if (!is.null(onde)) recortes$onde_ha <- data.frame(
      cod_uf = onde$cod_territorio[onde$nivel == "UF"], mulheres = onde$familia_m_est[onde$nivel == "UF"])
    for (r in names(recortes)) {
      dj <- merge(recortes[[r]], horas, by = "cod_uf")
      dj <- dj[dj$mulheres > 0, ]
      dj$valor <- valor_horas(dj$mulheres, dj$horas_m)
      dj$valor_acima_dos_homens <- valor_horas(dj$mulheres, dj$horas_m - dj$horas_h)
      dj <- rbind(
        data.frame(cod_uf = "1", ano_pnad = dj$ano_pnad[1], mulheres = sum(dj$mulheres), horas_m = NA,
                   horas_h = NA, valor = sum(dj$valor), valor_acima_dos_homens = sum(dj$valor_acima_dos_homens)),
        dj[c("cod_uf", "ano_pnad", "mulheres", "horas_m", "horas_h", "valor", "valor_acima_dos_homens")])
      dj$territorio <- ifelse(dj$cod_uf == "1", "Brasil", UF_SIGLA[dj$cod_uf])
      saidas$jornada[[length(saidas$jornada) + 1]] <- cbind(cadeia = cadeia, recorte = r, dj)
      resumir(cadeia, "dupla_jornada", r, "mulheres", dj$mulheres[1])
      resumir(cadeia, "dupla_jornada", r, "valor", dj$valor[1])
      resumir(cadeia, "dupla_jornada", r, "valor_acima_dos_homens", dj$valor_acima_dos_homens[1])
      tr <- trabalho_principal
      if (r == "onde_ha") tr <- saidas$trabalho[[length(saidas$trabalho)]]
      resumir(cadeia, "dupla_jornada", r, "valor_somado_trabalho_familiar_medio",
              dj$valor[1] + tr$valor_medio[tr$nivel == "Brasil"])
    }
  }

  # ---- 4. Valor da produção ligado às mulheres -----------------------------
  # A: valor da PAM x participação das mulheres na área dos estabelecimentos
  #    da cadeia (6883). B: valor da PAM x participação das mulheres no
  #    pessoal ocupado (6887). O IBGE não publica valor da produção por sexo.
  if (!is.null(pam)) {
    pm <- pam_ultimo(cfg$produto_pam)
    pm <- pm[pm$cod_nivel %in% c(1, 3), ]
    x <- merge(pm, ea[, c("cod_territorio", "area_h", "area_m")], by = "cod_territorio", all.x = TRUE)
    x <- merge(x, tf[, c("cod_territorio", "pessoal_total", "familia_m", "familia_m_menos14",
                         "permanentes_m", "temporarias_m", "parceiras_m")], by = "cod_territorio", all.x = TRUE)
    x$pct_area_m <- 100 * div(x$area_m, x$area_m + x$area_h)
    mulheres <- rowSums(x[c("familia_m", "familia_m_menos14", "permanentes_m", "temporarias_m", "parceiras_m")], na.rm = TRUE)
    x$mulheres_ocupadas <- mulheres
    x$pct_ocupadas_m <- 100 * div(mulheres, x$pessoal_total)
    x$valor_a_mil_reais <- x$valor_pam_mil_reais * x$pct_area_m / 100
    x$valor_b_mil_reais <- x$valor_pam_mil_reais * x$pct_ocupadas_m / 100
    x <- x[x$valor_pam_mil_reais > 0 & !is.na(x$valor_pam_mil_reais), ]
    x <- x[order(x$cod_nivel, -x$valor_pam_mil_reais), ]
    x$nivel <- nivel_nome(x$cod_nivel)
    saidas$valor[[length(saidas$valor) + 1]] <- cbind(cadeia = cadeia, x[c(
      "nivel", "cod_territorio", "territorio", "ano_pam", "valor_pam_mil_reais", "pct_area_m",
      "mulheres_ocupadas", "pessoal_total", "pct_ocupadas_m", "valor_a_mil_reais", "valor_b_mil_reais")])
    b <- x[x$cod_nivel == 1, ]
    for (k in c("ano_pam", "valor_pam_mil_reais", "pct_area_m", "pct_ocupadas_m", "valor_a_mil_reais", "valor_b_mil_reais"))
      resumir(cadeia, "valor_producao", "principal", k, b[[k]])
  }
}

gravar <- function(lista, nome) {
  if (length(lista) == 0) return(invisible())
  d <- do.call(rbind, lista)
  num <- vapply(d, is.double, logical(1))
  d[num] <- lapply(d[num], function(v) round(v, 2))
  write.csv(d, file.path(SAIDA, nome), row.names = FALSE, na = "", fileEncoding = "UTF-8")
  message(sprintf("  %s: %d linhas", nome, nrow(d)))
}
gravar(saidas$trabalho, "trabalho_familiar.csv")
gravar(saidas$direcao, "direcao_invisivel.csv")
gravar(saidas$jornada, "dupla_jornada.csv")
gravar(saidas$valor, "valor_producao.csv")
gravar(saidas$resumo, "resumo.csv")
