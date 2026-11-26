"""Confere os indicadores de trabalho invisível contra as tabelas do SIDRA.

Refaz as contas de dados/indicadores/resumo.csv a partir dos arquivos brutos
de dados/sidra/, com código separado do script em R, e compara número a
número, no Brasil:
  - trabalho familiar (recorte principal): mulheres e homens da família (6887)
    e dirigentes mulheres (6883), somando as classes da cadeia, com a soma
    vazia se qualquer parcela estiver em sigilo ("X");
  - direção invisível: municípios da cadeia (6883 municipal por classe e,
    onde houver, 6955 e PAM) e somas da 6768 no grupo de atividade;
  - dupla jornada (recorte principal): mulheres da família por UF (6887)
    vezes as horas da PNAD 7015;
  - valor da produção: PAM ou PEVS do último ano vezes a participação das
    mulheres na área (6883) e no pessoal ocupado (6887).
Também confere que nenhuma cadeia usa a classe do total de todas as
atividades (110016) e que um indicador vazio no resumo corresponde a um
sigilo ou a um dado que não existe na fonte.

O recorte "onde há" é uma estimativa municipal e não entra aqui; ele foi
conferido com os números do levantamento anterior do café (docs/indicadores.md).

Uso: python scripts/conferir_indicadores.py
Sai com erro se encontrar qualquer diferença.
"""

import csv
import gzip
import os
import re
import sys
from collections import defaultdict

SM = 1621.0
TOL = 0.02  # o resumo é gravado com duas casas


def ler(caminho):
    abrir = gzip.open if caminho.endswith(".gz") else open
    with abrir(caminho, "rt", encoding="utf-8-sig", newline="") as f:
        yield from csv.DictReader(f)


def bruto(v):
    """Número da fonte; None para sigilo ou dado inexistente; '-' é zero."""
    if v in ("X", "..", "...", "", None):
        return None
    return 0.0 if v == "-" else float(v)


def soma(vals):
    return None if any(v is None for v in vals) else sum(vals)


cadeias = list(ler("config/indicadores.csv"))
resumo = defaultdict(dict)
for r in ler("dados/indicadores/resumo.csv"):
    resumo[(r["cadeia"], r["indicador"], r["recorte"])][r["medida"]] = (
        None if r["valor"] == "" else float(r["valor"]))

# 6883 e 6887 por classe, Brasil e UFs
c6883, c6887 = {}, {}
for r in ler("dados/sidra/censo_agro_6883_classes.csv.gz"):
    if r["utilizacao_das_terras_codigo"] != "110087" or r["cod_nivel"] not in ("1", "3"):
        continue
    c6883[(r["cod_atividade"], r["cod_territorio"], r["variavel_codigo"], r["sexo_do_produtor_codigo"])] = bruto(r["valor_bruto"])
for r in ler("dados/sidra/censo_agro_6887_classes.csv.gz"):
    if r["variavel_codigo"] != "185" or r["cod_nivel"] not in ("1", "3"):
        continue
    c6887[(r["cod_atividade"], r["cod_territorio"], r["tipo_de_pessoal_ocupado_codigo"])] = bruto(r["valor_bruto"])


def v6883(cods, terr, var, sexo):
    return soma([c6883.get((c, terr, var, sexo)) for c in cods])


def v6887(cods, terr, tipo):
    return soma([c6887.get((c, terr, tipo)) for c in cods])


ufs = sorted({k[1] for k in c6887 if k[1] != "1"})

# PNAD 7015: horas do último ano por UF
pnad = defaultdict(dict)
anos = set()
for r in ler("dados/sidra/pnad_7015.csv.gz"):
    if r["cod_nivel"] == "3" and not r["variavel"].startswith("Coef"):
        pnad[r["ano"]][(r["cod_territorio"], r["sexo"])] = bruto(r["valor_bruto"])
        anos.add(r["ano"])
horas = pnad[max(anos)]

# 6768 por grupo, municípios
dir6768 = defaultdict(dict)
if os.path.exists("dados/sidra/censo_agro_6768_direcao.csv.gz"):
    for r in ler("dados/sidra/censo_agro_6768_direcao.csv.gz"):
        if r["cod_nivel"] != "6":
            continue
        chave = (r["direcao_dos_trabalhos_do_estabelecimento_agropecuario_codigo"],
                 r["sexo_da_pessoa_que_dirige_o_estabelecimento_produtor_ou_administrador_codigo"])
        dir6768[(r["grupos_de_atividade_economica_codigo"], r["cod_territorio"])][chave] = bruto(r["valor_bruto"])

mun_classe = defaultdict(float)
if os.path.exists("dados/sidra/censo_agro_6883_classes_mun.csv.gz"):
    for r in ler("dados/sidra/censo_agro_6883_classes_mun.csv.gz"):
        if r["variavel_codigo"] == "9587" and r.get("utilizacao_das_terras_codigo", "110087") == "110087":
            mun_classe[(r["cod_atividade"], r["cod_territorio"])] += bruto(r["valor_bruto"]) or 0.0

com_produto = defaultdict(float)
if os.path.exists("dados/sidra/censo_agro_6955_produtos.csv.gz"):
    prod6955 = [(r["cod_territorio"], r["produto"], bruto(r["valor_bruto"]))
                for r in ler("dados/sidra/censo_agro_6955_produtos.csv.gz")
                if r["cod_nivel"] == "6" and r["variavel_codigo"] == "9504"]
else:
    prod6955 = []

pam_mun = []
if os.path.exists("dados/sidra/pam_5457.csv.gz"):
    pam_mun = [(r["cod_territorio"], r["produto"], r["ano"], bruto(r["valor_bruto"]))
               for r in ler("dados/sidra/pam_5457.csv.gz")
               if r["cod_nivel"] == "6" and r["variavel"] == "Quantidade produzida"]

valor_fonte = {"PAM": [], "PEVS": []}
if os.path.exists("dados/sidra/pam_5457_ultimo_ano.csv.gz"):
    valor_fonte["PAM"] = [(r["produto"], r["ano"], bruto(r["valor_bruto"]))
                          for r in ler("dados/sidra/pam_5457_ultimo_ano.csv.gz")
                          if r["cod_nivel"] == "1" and r["variavel"] == "Valor da produção"]
valor_fonte["PEVS"] = [(r["produto"], r["ano"], bruto(r["valor_bruto"]))
                       for r in ler("dados/sidra/pevs_289.csv.gz")
                       if r["cod_nivel"] == "1" and r["variavel"] == "Valor da produção na extração vegetal"]

conta = defaultdict(int)
erros = []


def confere(cad, ind, rec, medida, esperado):
    publicado = resumo.get((cad, ind, rec), {}).get(medida)
    if esperado is None and publicado is None:
        conta["vazio_na_fonte"] += 1
    elif esperado is not None and publicado is not None and abs(esperado - publicado) <= TOL + 1e-9 * abs(esperado):
        conta["igual"] += 1
    else:
        erros.append((cad, ind, rec, medida, esperado, publicado))


for c in cadeias:
    cad = c["cadeia"]
    cods = c["codigos_12440"].split(";")
    if "110016" in cods:
        erros.append((cad, "config", "", "usa a classe do total de todas as atividades", None, None))

    # 1. trabalho familiar
    fm, fh = v6887(cods, "1", "45963"), v6887(cods, "1", "45961")
    dm = v6883(cods, "1", "9587", "112635")
    nd = None if fm is None or dm is None else max(fm - dm, 0)
    rec = (cad, "trabalho_familiar", "principal")
    confere(*rec, "mulheres_familia_14mais", fm)
    confere(*rec, "dirigentes_m", dm)
    confere(*rec, "mulheres_nao_dirigentes", nd)
    confere(*rec, "pct_mulheres_familia", None if fm is None or fh is None else 100 * fm / (fm + fh))
    confere(*rec, "valor_medio", None if nd is None else nd * SM * 12 * 0.5)

    # 2. direção invisível
    if dir6768 and mun_classe:
        filtro6955 = c["produtos_6955"]
        tem = defaultdict(float)
        if filtro6955:
            for terr, prod, v in prod6955:
                if re.search(filtro6955, prod, re.I):
                    tem[terr] += v or 0.0
        prod_t = defaultdict(float)
        if c["fonte_valor"] == "PAM" and c["min_producao_pam_t"] and pam_mun:
            ult = max(a for _, p, a, _ in pam_mun if re.search(c["produto_valor"], p))
            for terr, p, a, v in pam_mun:
                if a == ult and re.search(c["produto_valor"], p):
                    prod_t[terr] += v or 0.0
        lim = lambda x: float(x) if x else float("inf")
        tot = defaultdict(float)
        n = 0
        for (grupo, terr), d in dir6768.items():
            if grupo != c["grupo_6768"]:
                continue
            principal = sum(mun_classe.get((k, terr), 0.0) for k in cods)
            if not (principal >= lim(c["min_estab_principal"]) or tem[terr] >= lim(c["min_estab_com_produto"])
                    or prod_t[terr] >= lim(c["min_producao_pam_t"])):
                continue
            n += 1
            for nome, chave in [("t", ("41149", "46500")), ("m", ("41149", "112644")),
                                ("ch", ("40592", "112643")), ("cm", ("40592", "112644"))]:
                tot[nome] += d.get(chave) or 0.0
        rec = (cad, "direcao_invisivel", "grupo_nos_municipios")
        confere(*rec, "municipios", n if n else None)
        if n:
            confere(*rec, "estab_grupo", tot["t"])
            confere(*rec, "casal_h", tot["ch"])
            confere(*rec, "pct_invisivel", 100 * tot["ch"] / (tot["m"] + tot["ch"]) if tot["m"] + tot["ch"] else None)
            confere(*rec, "pct_casal_homem_registrado",
                    100 * tot["ch"] / (tot["ch"] + tot["cm"]) if tot["ch"] + tot["cm"] else None)

    # 3. dupla jornada, recorte principal: UFs em sigilo ficam fora
    val, fora = 0.0, 0
    for uf in ufs:
        m = v6887(cods, uf, "45963")
        hm = horas.get((uf, "Mulheres"))
        if m is None:
            fora += 1
            continue
        if m > 0 and hm is not None:
            val += m * hm * 52 * SM / 220
    rec = (cad, "dupla_jornada", "principal")
    confere(*rec, "valor", val if val > 0 else None)
    confere(*rec, "ufs_em_sigilo", fora if val > 0 else None)

    # 4. valor da produção: último ano da fonte ("principal") e 2017, ano do Censo ("censo")
    linhas = [(p, a, v) for p, a, v in valor_fonte.get(c["fonte_valor"], []) if re.search(c["produto_valor"], p)] \
        if c["fonte_valor"] else []
    am, ah = v6883(cods, "1", "184", "112635"), v6883(cods, "1", "184", "112634")
    pa = None if am is None or ah is None else am / (am + ah)
    mulheres = soma([v6887(cods, "1", t) for t in ("45963", "45964", "45969", "45974", "45979")])
    pt = v6887(cods, "1", "112967")
    po = None if mulheres is None or not pt else mulheres / pt
    for recorte in ("principal", "censo"):
        rec = (cad, "valor_producao", recorte)
        ano = (max(a for _, a, _ in linhas) if linhas else None) if recorte == "principal" else "2017"
        doano = [v for _, a, v in linhas if a == ano]
        if doano:
            total = sum(v or 0.0 for v in doano)
            confere(*rec, "valor_mil_reais", total)
            confere(*rec, "valor_a_mil_reais", None if pa is None else total * pa)
            confere(*rec, "valor_b_mil_reais", None if po is None else total * po)
        else:
            confere(*rec, "valor_mil_reais", None)

print(f"{conta['igual']} números iguais à conta refeita da fonte, "
      f"{conta['vazio_na_fonte']} vazios que são sigilo ou dado inexistente na fonte, "
      f"{len(erros)} diferenças")
for e in erros[:60]:
    print("diferença:", e)
sys.exit(1 if erros else 0)
