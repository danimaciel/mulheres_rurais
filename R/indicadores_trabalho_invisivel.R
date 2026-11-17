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
# atividade secundária (6955) e é uma estimativa; hoje só existe para café e
# cacau. A direção invisível usa o grupo de atividade da 6768 nos municípios
# da cadeia, que é um terceiro recorte. O método está em docs/indicadores.md.
#
# Quando uma cadeia soma mais de uma classe de atividade (frutas), a soma fica
# vazia se qualquer parcela estiver em sigilo, como na página.
#
# Uso, a partir da raiz do repositório:
#   Rscript R/indicadores_trabalho_invisivel.R
#
# Saídas em dados/indicadores/: um arquivo por indicador, resumo.csv com os
# números do Brasil e disponibilidade.csv, que diz para cada cadeia o que foi
# calculado e por que algo ficou de fora.

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

z <- function(x) ifelse(is.na(x), 0, x)
div <- function(a, b) ifelse(!is.na(a) & !is.na(b) & b > 0, a / b, NA_real_)
nivel_nome <- function(cod) unname(c("1" = "Brasil", "3" = "UF", "6" = "Município")[as.character(cod)])
uf_de <- function(cod) unname(UF_SIGLA[substr(cod, 1, 2)])

# Só as linhas de total nas classificações que a página não abre.
so_totais <- function(d) {
  if (is.null(d)) return(NULL)
  if ("utilizacao_das_terras_codigo" %in% names(d)) d <- d[d$utilizacao_das_terras_codigo == 110087, ]
  if ("tipologia_codigo" %in% names(d)) d <- d[d$tipologia_codigo == 46302, ]
  d
}

# Brasil e UFs vêm do levantamento por classe (todas as classes); municípios,
# da coleta mensal, que só tem algumas cadeias.
juntar <- function(classes, mensal, coluna) {
  cols <- c("cod_nivel", "cod_territorio", "territorio", "variavel_codigo", "cod_atividade", coluna, "valor")
  partes <- list()
  if (!is.null(classes)) partes$a <- classes[classes$cod_nivel %in% c(1, 3), cols]
  if (!is.null(mensal)) partes$b <- mensal[mensal$cod_nivel == 6, cols]
  if (is.null(classes) && !is.null(mensal)) partes$b <- mensal[, cols]
  do.call(rbind, partes)
}

t6883 <- juntar(so_totais(ler("censo_agro_6883_classes.csv.gz")), so_totais(ler("censo_agro_6883.csv.gz")),
                "sexo_do_produtor_codigo")
t6887 <- juntar(so_totais(ler("censo_agro_6887_classes.csv.gz")), so_totais(ler("censo_agro_6887.csv.gz")),
                "tipo_de_pessoal_ocupado_codigo")
mun_classes <- so_totais(ler("censo_agro_6883_classes_mun.csv.gz"))
t6768 <- ler("censo_agro_6768_direcao.csv.gz")
t6955 <- ler("censo_agro_6955_produtos.csv.gz")
pam_mun <- ler("pam_5457.csv.gz")
pam_uf <- ler("pam_5457_ultimo_ano.csv.gz")
pevs <- ler("pevs_289.csv.gz")
pnad <- ler("pnad_7015.csv.gz")

for (f in c("censo_agro_6768_direcao", "censo_agro_6955_produtos", "censo_agro_6883_classes_mun", "pam_5457_ultimo_ano"))
  if (!file.exists(file.path(PASTA, paste0(f, ".csv.gz")))) message("Sem ", f, ".csv.gz: o que depende dele fica de fora")

# Soma as classes da cadeia por território e categoria. Fica NA se alguma
# classe estiver em sigilo ou faltar.
somar_classes <- function(d, codigos, coluna) {
  d <- d[d$cod_atividade %in% codigos, ]
  chave <- paste(d$cod_nivel, d$cod_territorio, d$variavel_codigo, d[[coluna]], sep = "|")
  n <- tapply(d$valor, chave, length)
  s <- tapply(d$valor, chave, sum)
  s[n < length(codigos)] <- NA
  primeiro <- !duplicated(chave)
  out <- d[primeiro, c("cod_nivel", "cod_territorio", "territorio", "variavel_codigo", coluna)]
  out$valor <- unname(s[chave[primeiro]])
  out
}

# Linhas (território x categoria) viram colunas, uma por categoria.
larga <- function(d, coluna, categorias) {
  d <- d[d[[coluna]] %in% names(categorias), ]
  chave <- unique(d[, c("cod_nivel", "cod_territorio", "territorio")])
  for (cod in names(categorias)) {
    sub <- d[d[[coluna]] == cod, ]
    chave[[categorias[[cod]]]] <- sub$valor[match(chave$cod_territorio, sub$cod_territorio)]
  }
  chave
}

SEXO_6883 <- c("41145" = "t", "112634" = "h", "112635" = "m")
estab_area <- function(codigos) {
  d <- somar_classes(t6883, codigos, "sexo_do_produtor_codigo")
  e <- larga(d[d$variavel_codigo == 9587, ], "sexo_do_produtor_codigo", SEXO_6883)
  a <- larga(d[d$variavel_codigo == 184, ], "sexo_do_produtor_codigo", SEXO_6883)
  names(e)[4:6] <- paste0("estab_", names(e)[4:6])
  e[paste0("area_", c("t", "h", "m"))] <- a[match(e$cod_territorio, a$cod_territorio), 4:6]
  e
}

PESSOAL <- c("112967" = "pessoal_total", "45961" = "familia_h", "45963" = "familia_m",
             "45964" = "familia_m_menos14", "45969" = "permanentes_m", "45974" = "temporarias_m",
             "45979" = "parceiras_m")
pessoal <- function(codigos) {
  d <- somar_classes(t6887[t6887$variavel_codigo == 185, ], codigos, "tipo_de_pessoal_ocupado_codigo")
  larga(d, "tipo_de_pessoal_ocupado_codigo", PESSOAL)
}

# Estabelecimentos com a cadeia como atividade principal em cada município.
# Sigilo conta como zero: o município só não entra pelo critério da cadeia.
estab_municipio <- function(codigos, ea) {
  if (!is.null(mun_classes)) {
    d <- mun_classes[mun_classes$cod_atividade %in% codigos & mun_classes$variavel_codigo == 9587, ]
    if (nrow(d) > 0) return(tapply(z(d$valor), d$cod_territorio, sum))
  }
  m <- ea[ea$cod_nivel == 6, ]
  if (nrow(m) == 0) return(NULL)
  setNames(z(m$estab_t), m$cod_territorio)
}

# 6768 em formato largo: total e casal, por sexo de quem dirige, num grupo
# de atividade. 113601 é o total dos grupos.
SEXO_6768 <- c("46500" = "t", "112643" = "h", "112644" = "m")
NOME_GRUPO <- c("111519" = "lavoura temporária", "111520" = "horticultura e floricultura",
                "111521" = "lavoura permanente", "111522" = "produção de sementes e mudas",
                "111523" = "pecuária e criação de outros animais", "111524" = "florestas plantadas",
                "111525" = "florestas nativas", "114349" = "pesca", "111526" = "aquicultura")
direcao <- function(grupo) {
  d <- t6768[t6768$grupos_de_atividade_economica_codigo == grupo, ]
  col_dir <- "direcao_dos_trabalhos_do_estabelecimento_agropecuario_codigo"
  col_sexo <- "sexo_da_pessoa_que_dirige_o_estabelecimento_produtor_ou_administrador_codigo"
  partes <- lapply(c(tot = "41149", casal = "40592"), function(cod) larga(d[d[[col_dir]] == cod, ], col_sexo, SEXO_6768))
  out <- partes$tot
  names(out)[4:6] <- paste0("dir_", names(out)[4:6])
  out[paste0("casal_", c("t", "h", "m"))] <- partes$casal[match(out$cod_territorio, partes$casal$cod_territorio), 4:6]
  out
}

# Estabelecimentos que têm o produto (6955), somando os produtos da cadeia.
# No café, quem tem arábica e canéfora entra duas vezes.
com_produto <- function(filtro) {
  if (is.null(t6955) || !nzchar(filtro)) return(NULL)
  d <- t6955[t6955$variavel_codigo == 9504 & grepl(filtro, t6955$produto, ignore.case = TRUE), ]
  if (nrow(d) == 0) return(NULL)
  s <- aggregate(valor ~ cod_nivel + cod_territorio, data = transform(d, valor = z(valor)), FUN = sum)
  names(s)[3] <- "estab_com_produto"
  s
}

# Produção municipal da PAM (coleta geral), só para o critério de município.
producao_municipio <- function(cfg) {
  if (is.null(pam_mun) || cfg$fonte_valor != "PAM" || !nzchar(cfg$min_producao_pam_t)) return(NULL)
  d <- pam_mun[grepl(cfg$produto_valor, pam_mun$produto) & pam_mun$cod_nivel == 6 &
                 pam_mun$variavel == "Quantidade produzida", ]
  if (nrow(d) == 0) return(NULL)
  d <- d[d$ano == max(d$ano), ]
  tapply(z(d$valor), d$cod_territorio, sum)
}

# Valor da produção do último ano, Brasil e UFs, somando os produtos da cadeia.
valor_producao <- function(cfg) {
  if (cfg$fonte_valor == "PAM") {
    # Só a PAM com todos os produtos: a coleta geral traz uma seleção, e uma
    # cadeia de vários produtos sairia com parte deles.
    if (is.null(pam_uf)) return(NULL)
    fonte <- pam_uf
    d <- fonte[fonte$cod_nivel %in% c(1, 3) & fonte$variavel == "Valor da produção" &
                 grepl(cfg$produto_valor, fonte$produto), ]
  } else if (cfg$fonte_valor == "PEVS") {
    if (is.null(pevs)) return(NULL)
    d <- pevs[pevs$cod_nivel %in% c(1, 3) & pevs$variavel == "Valor da produção na extração vegetal" &
                grepl(cfg$produto_valor, pevs$produto), ]
  } else return(NULL)
  if (nrow(d) == 0) return(NULL)
  ano <- max(d$ano)
  d <- d[d$ano == ano, ]
  v <- aggregate(valor ~ cod_nivel + cod_territorio, data = transform(d, valor = z(valor)), FUN = sum)
  v$territorio <- d$territorio[match(v$cod_territorio, d$cod_territorio)]
  names(v)[names(v) == "valor"] <- "valor_mil_reais"
  v$ano <- ano
  v$fonte <- cfg$fonte_valor
  v$produtos <- paste(sort(unique(d$produto)), collapse = "; ")
  v
}

horas_pnad <- function() {
  d <- pnad[pnad$cod_nivel == 3 & !startsWith(pnad$variavel, "Coef"), ]
  d <- d[d$ano == max(d$ano), ]
  ufs <- unique(d$cod_territorio)
  m <- d[d$sexo == "Mulheres", ]
  h <- d[d$sexo == "Homens", ]
  data.frame(cod_uf = ufs, ano_pnad = max(d$ano),
             horas_m = m$valor[match(ufs, m$cod_territorio)],
             horas_h = h$valor[match(ufs, h$cod_territorio)])
}

valor_anual <- function(pessoas, fracao) pessoas * SALARIO_MINIMO * 12 * fracao
valor_horas <- function(pessoas, horas_semana) pessoas * horas_semana * 52 * SALARIO_MINIMO / HORAS_MES

saidas <- list(trabalho = list(), direcao = list(), jornada = list(), valor = list(),
               resumo = list(), disp = list())
resumir <- function(cadeia, indicador, recorte, medida, valor) {
  saidas$resumo[[length(saidas$resumo) + 1]] <<- data.frame(
    cadeia = cadeia, indicador = indicador, recorte = recorte, medida = medida,
    valor = if (length(valor) == 0) NA else valor)
}
situacao <- function(cadeia, indicador, recorte, calculado, motivo = "") {
  saidas$disp[[length(saidas$disp) + 1]] <<- data.frame(
    cadeia = cadeia, indicador = indicador, recorte = recorte,
    situacao = if (calculado) "calculado" else "não calculável", motivo = motivo)
}

agro_ea <- estab_area("110016")
agro_po <- pessoal("110016")
horas <- if (!is.null(pnad)) horas_pnad() else NULL
dir_total <- if (!is.null(t6768)) direcao("113601") else NULL

for (i in seq_len(nrow(cadeias))) {
  cfg <- cadeias[i, ]
  cadeia <- cfg$cadeia
  codigos <- strsplit(cfg$codigos_12440, ";", fixed = TRUE)[[1]]
  message("Cadeia ", cadeia)
  ea <- estab_area(codigos)
  po <- pessoal(codigos)
  if (nrow(ea) == 0 || nrow(po) == 0) {
    message("  sem dados da 6883 ou da 6887 para ", cfg$codigos_12440)
    situacao(cadeia, "todos", "", FALSE, "sem dados da 6883 ou 6887 para a classe")
    next
  }

  # ---- 1. Trabalho familiar, recorte principal (direto) --------------------
  tf <- merge(po, ea[, c("cod_territorio", "estab_t", "estab_m")], by = "cod_territorio", all.x = TRUE)
  tf$dirigentes_m <- tf$estab_m
  tf$pct_mulheres_familia <- 100 * div(tf$familia_m, tf$familia_m + tf$familia_h)
  tf$mulheres_nao_dirigentes <- pmax(tf$familia_m - tf$dirigentes_m, 0)
  for (k in names(DEDICACAO)) tf[[paste0("valor_", k)]] <- valor_anual(tf$mulheres_nao_dirigentes, DEDICACAO[[k]])
  tf <- tf[order(tf$cod_nivel, tf$cod_territorio), ]
  trabalho_principal <- data.frame(
    cadeia = cadeia, recorte = "principal", nivel = nivel_nome(tf$cod_nivel),
    cod_territorio = tf$cod_territorio, territorio = tf$territorio,
    estab = tf$estab_t, mulheres_familia = tf$familia_m, homens_familia = tf$familia_h,
    pct_mulheres_familia = tf$pct_mulheres_familia, dirigentes_m = tf$dirigentes_m,
    mulheres_nao_dirigentes = tf$mulheres_nao_dirigentes,
    valor_baixo = tf$valor_baixo, valor_medio = tf$valor_medio, valor_alto = tf$valor_alto)
  saidas$trabalho[[length(saidas$trabalho) + 1]] <- trabalho_principal
  br <- tf[tf$cod_nivel == 1, ]
  ok_tf <- !is.na(br$mulheres_nao_dirigentes)
  situacao(cadeia, "trabalho_familiar", "principal", ok_tf,
           if (ok_tf) "" else "mulheres da família ou dirigentes sob sigilo no Brasil")
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
  cp <- com_produto(cfg$produtos_6955)
  mun_po <- po[po$cod_nivel == 6, ]
  if (is.null(cp) || nrow(mun_po) == 0) {
    situacao(cadeia, "trabalho_familiar", "onde_ha", FALSE,
             if (!nzchar(cfg$produtos_6955)) "sem produto correspondente na tabela 6955" else
               "faltam a 6955 por produto ou a 6887 municipal da cadeia")
  } else {
    m <- agro_ea[agro_ea$cod_nivel == 6, c("cod_territorio", "territorio", "estab_t")]
    names(m)[3] <- "agro_estab"
    m$cod_uf <- substr(m$cod_territorio, 1, 2)
    m$estab_com_produto <- cp$estab_com_produto[match(m$cod_territorio, cp$cod_territorio)]
    m$estab_principal <- ea$estab_t[match(m$cod_territorio, ea$cod_territorio)]
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

    cols <- c("estab_com_produto", "familia_m_est", "familia_h_est", "dirigentes_m_est")
    agrega <- function(chave) aggregate(m[cols], by = list(chave = chave), FUN = function(x) sum(z(x)))
    nomes_uf <- setNames(agro_ea$territorio[agro_ea$cod_nivel == 3], agro_ea$cod_territorio[agro_ea$cod_nivel == 3])
    a_uf <- agrega(m$cod_uf)
    a_br <- agrega(rep("1", nrow(m)))
    onde <- rbind(
      data.frame(nivel = "Brasil", cod_territorio = "1", territorio = "Brasil", a_br[cols]),
      data.frame(nivel = "UF", cod_territorio = a_uf$chave, territorio = unname(nomes_uf[a_uf$chave]), a_uf[cols]),
      data.frame(nivel = "Município", cod_territorio = m$cod_territorio, territorio = m$territorio, m[cols]))
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
    situacao(cadeia, "trabalho_familiar", "onde_ha", TRUE)
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
  # divide a direção. Municípios em sigilo na 6768 entram como zero, então os
  # totais são um piso; a contagem deles vai para o resumo.
  principal_mun <- estab_municipio(codigos, ea)
  if (is.null(t6768) || is.null(principal_mun)) {
    situacao(cadeia, "direcao_invisivel", "grupo_nos_municipios", FALSE,
             if (is.null(t6768)) "falta a 6768 por sexo e grupo" else "falta a 6883 municipal por classe de atividade")
  } else {
    dg <- direcao(cfg$grupo_6768)
    dg <- dg[dg$cod_nivel == 6, ]
    tem_produto <- if (is.null(cp)) NA else cp$estab_com_produto[match(dg$cod_territorio, cp$cod_territorio)]
    pm <- producao_municipio(cfg)
    producao <- if (is.null(pm)) NA else pm[dg$cod_territorio]
    lim <- function(x) if (nzchar(x)) as.numeric(x) else Inf
    dg$municipio_da_cadeia <- z(principal_mun[dg$cod_territorio]) >= lim(cfg$min_estab_principal) |
      z(tem_produto) >= lim(cfg$min_estab_com_produto) | z(producao) >= lim(cfg$min_producao_pam_t)
    dc <- dg[dg$municipio_da_cadeia, ]
    cols <- c("dir_t", "dir_m", "casal_t", "casal_h", "casal_m")
    sigilo_mun <- sum(apply(is.na(dc[cols]), 1, any))
    if (nrow(dc) == 0) {
      situacao(cadeia, "direcao_invisivel", "grupo_nos_municipios", FALSE, "nenhum município passa o critério da cadeia")
    } else {
      dc$uf <- uf_de(dc$cod_territorio)
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
      situacao(cadeia, "direcao_invisivel", "grupo_nos_municipios", !is.na(b$pct_invisivel),
               sprintf("grupo %s em %d municípios", NOME_GRUPO[cfg$grupo_6768], nrow(dc)))
      resumir(cadeia, "direcao_invisivel", "grupo_nos_municipios", "municipios", nrow(dc))
      resumir(cadeia, "direcao_invisivel", "grupo_nos_municipios", "municipios_com_sigilo", sigilo_mun)
      resumir(cadeia, "direcao_invisivel", "grupo_nos_municipios", "grupo_6768", as.numeric(cfg$grupo_6768))
      for (k in c("estab_grupo", "mulher_dirigente", "casal_t", "casal_h", "casal_m", "pct_dirigente_principal",
                  "pct_participacao_ampliada", "pct_invisivel", "pct_casal_homem_registrado"))
        resumir(cadeia, "direcao_invisivel", "grupo_nos_municipios", k, b[[k]])
    }
  }

  # ---- 3. Dupla jornada ----------------------------------------------------
  # Horas da PNAD por UF (sem corte rural) x mulheres da família da cadeia.
  # UFs em sigilo ficam de fora; a cobertura diz quanto das mulheres do
  # Brasil entrou na conta.
  if (is.null(horas)) {
    situacao(cadeia, "dupla_jornada", "principal", FALSE, "falta a PNAD 7015")
  } else {
    total_br <- c(principal = br$familia_m, onde_ha = if (is.null(onde)) NA else onde$familia_m_est[1])
    recortes <- list(principal = data.frame(cod_uf = tf$cod_territorio[tf$cod_nivel == 3],
                                            mulheres = tf$familia_m[tf$cod_nivel == 3]))
    if (!is.null(onde)) recortes$onde_ha <- data.frame(
      cod_uf = onde$cod_territorio[onde$nivel == "UF"], mulheres = onde$familia_m_est[onde$nivel == "UF"])
    for (r in names(recortes)) {
      dj <- merge(recortes[[r]], horas, by = "cod_uf")
      ufs_sigilo <- sum(is.na(dj$mulheres))
      dj <- dj[!is.na(dj$mulheres) & dj$mulheres > 0, ]
      if (nrow(dj) == 0) {
        situacao(cadeia, "dupla_jornada", r, FALSE, "mulheres da família sob sigilo em todas as UFs")
        next
      }
      dj$valor <- valor_horas(dj$mulheres, dj$horas_m)
      dj$valor_acima_dos_homens <- valor_horas(dj$mulheres, dj$horas_m - dj$horas_h)
      cobertura <- 100 * div(sum(dj$mulheres), total_br[[r]])
      dj <- rbind(
        data.frame(cod_uf = "1", ano_pnad = dj$ano_pnad[1], mulheres = sum(dj$mulheres), horas_m = NA,
                   horas_h = NA, valor = sum(dj$valor), valor_acima_dos_homens = sum(dj$valor_acima_dos_homens)),
        dj[c("cod_uf", "ano_pnad", "mulheres", "horas_m", "horas_h", "valor", "valor_acima_dos_homens")])
      dj$territorio <- ifelse(dj$cod_uf == "1", "Brasil", UF_SIGLA[dj$cod_uf])
      saidas$jornada[[length(saidas$jornada) + 1]] <- cbind(cadeia = cadeia, recorte = r, dj)
      situacao(cadeia, "dupla_jornada", r, TRUE,
               if (ufs_sigilo > 0) sprintf("%d UF em sigilo fora da soma", ufs_sigilo) else "")
      resumir(cadeia, "dupla_jornada", r, "mulheres", dj$mulheres[1])
      resumir(cadeia, "dupla_jornada", r, "cobertura_pct", cobertura)
      resumir(cadeia, "dupla_jornada", r, "ufs_em_sigilo", ufs_sigilo)
      resumir(cadeia, "dupla_jornada", r, "valor", dj$valor[1])
      resumir(cadeia, "dupla_jornada", r, "valor_acima_dos_homens", dj$valor_acima_dos_homens[1])
      tr <- if (r == "onde_ha") saidas$trabalho[[length(saidas$trabalho)]] else trabalho_principal
      resumir(cadeia, "dupla_jornada", r, "valor_somado_trabalho_familiar_medio",
              dj$valor[1] + tr$valor_medio[tr$nivel == "Brasil"])
    }
  }

  # ---- 4. Valor da produção ligado às mulheres -----------------------------
  # A: valor da produção x participação das mulheres na área dos
  #    estabelecimentos da cadeia (6883). B: valor x participação das mulheres
  #    no pessoal ocupado (6887). O IBGE não publica valor da produção por sexo.
  vp <- valor_producao(cfg)
  if (is.null(vp)) {
    situacao(cadeia, "valor_producao", "principal", FALSE,
             if (!nzchar(cfg$fonte_valor)) "sem produto correspondente na PAM ou na PEVS" else
               "falta o arquivo da PAM ou da PEVS")
  } else {
    x <- merge(vp, ea[, c("cod_territorio", "area_h", "area_m")], by = "cod_territorio", all.x = TRUE)
    x <- merge(x, tf[, c("cod_territorio", "pessoal_total", "familia_m", "familia_m_menos14",
                         "permanentes_m", "temporarias_m", "parceiras_m")], by = "cod_territorio", all.x = TRUE)
    x$pct_area_m <- 100 * div(x$area_m, x$area_m + x$area_h)
    # soma nula se alguma parcela estiver em sigilo
    x$mulheres_ocupadas <- rowSums(x[c("familia_m", "familia_m_menos14", "permanentes_m", "temporarias_m", "parceiras_m")])
    x$pct_ocupadas_m <- 100 * div(x$mulheres_ocupadas, x$pessoal_total)
    x$valor_a_mil_reais <- x$valor_mil_reais * x$pct_area_m / 100
    x$valor_b_mil_reais <- x$valor_mil_reais * x$pct_ocupadas_m / 100
    x <- x[x$valor_mil_reais > 0, ]
    x <- x[order(x$cod_nivel, -x$valor_mil_reais), ]
    x$nivel <- nivel_nome(x$cod_nivel)
    saidas$valor[[length(saidas$valor) + 1]] <- cbind(cadeia = cadeia, x[c(
      "nivel", "cod_territorio", "territorio", "fonte", "ano", "valor_mil_reais", "pct_area_m",
      "mulheres_ocupadas", "pessoal_total", "pct_ocupadas_m", "valor_a_mil_reais", "valor_b_mil_reais", "produtos")])
    b <- x[x$cod_nivel == 1, ]
    situacao(cadeia, "valor_producao", "principal", nrow(b) == 1 && !is.na(b$valor_a_mil_reais),
             sprintf("%s %s: %s", b$fonte, b$ano, b$produtos))
    for (k in c("ano", "valor_mil_reais", "pct_area_m", "pct_ocupadas_m", "valor_a_mil_reais", "valor_b_mil_reais"))
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
gravar(saidas$disp, "disponibilidade.csv")
