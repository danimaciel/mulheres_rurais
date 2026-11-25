"""Monta os dados da página da plataforma a partir dos arquivos do repositório.

Lê as tabelas do SIDRA em dados/sidra/, os indicadores em dados/indicadores/
e as bases de organizações em dados/organizacoes/, e grava um único JSON que a
página carrega. Roda no workflow de publicação, depois de cada coleta, então o
site acompanha os dados sem ninguém precisar mexer nele.

Uso, a partir da raiz do repositório:
    python scripts/montar_site.py            # grava em _site/
    python scripts/montar_site.py saida/     # grava em outra pasta

Só usa a biblioteca padrão do Python.
"""

import csv
import gzip
import json
import os
import shutil
import sys
from collections import defaultdict
from datetime import datetime, timezone

import montar_estudos_cafe
import montar_organizacoes

SAIDA = sys.argv[1] if len(sys.argv) > 1 else "_site"

REGIOES = {"1": ("N", "Região Norte"), "2": ("NE", "Região Nordeste"),
           "3": ("SE", "Região Sudeste"), "4": ("S", "Região Sul"),
           "5": ("CO", "Região Centro-Oeste")}
UFS = {"11": "Rondônia", "12": "Acre", "13": "Amazonas", "14": "Roraima", "15": "Pará",
       "16": "Amapá", "17": "Tocantins", "21": "Maranhão", "22": "Piauí", "23": "Ceará",
       "24": "Rio Grande do Norte", "25": "Paraíba", "26": "Pernambuco", "27": "Alagoas",
       "28": "Sergipe", "29": "Bahia", "31": "Minas Gerais", "32": "Espírito Santo",
       "33": "Rio de Janeiro", "35": "São Paulo", "41": "Paraná", "42": "Santa Catarina",
       "43": "Rio Grande do Sul", "50": "Mato Grosso do Sul", "51": "Mato Grosso",
       "52": "Goiás", "53": "Distrito Federal"}

# 6883: sexo do produtor (c12564) na ordem total, homens, mulheres, não se aplica
SEXO = ["41145", "112634", "112635", "41146"]
# 6887: tipo de pessoal ocupado (c12578), pares homens/mulheres
PESSOAL = {
    "fam": ["45961", "45963"],     # com laço de parentesco, 14 anos ou mais
    "fam14": ["45962", "45964"],   # com laço de parentesco, menos de 14 anos
    "perm": ["45967", "45969"],    # permanentes, 14 anos ou mais
    "temp": ["45972", "45974"],    # temporários, 14 anos ou mais
    "parc": ["45977", "45979"],    # parceiros, 14 anos ou mais
}
MIN_MUN = 30  # estabelecimentos para um município entrar na lista


def ler_csv(caminho):
    abrir = gzip.open if caminho.endswith(".gz") else open
    with abrir(caminho, "rt", encoding="utf-8-sig", newline="") as f:
        yield from csv.DictReader(f)


def num(x):
    if x in (None, "", "NA", "X", "-", "..", "..."):
        return None
    try:
        return float(x)
    except ValueError:
        return None


def soma(valores):
    """Soma que fica nula se faltar qualquer parcela (sigilo)."""
    if any(v is None for v in valores):
        return None
    return sum(valores)


def ler_cadeias():
    cadeias = []
    for r in ler_csv("config/site_cadeias.csv"):
        r["codigos"] = r["codigos_12440"].split(";")
        cadeias.append(r)
    return cadeias


def ler_censo():
    """Valores de 6883 e 6887 por (classe, território, variável, categoria).

    As tabelas por classe (levantamento manual) trazem Brasil e UFs de todas as
    classes; as da coleta mensal trazem café, cacau e total. Onde as duas têm o
    mesmo valor, vale a da coleta mensal, lida por último.
    """
    v = {}
    fontes = [
        ("dados/sidra/censo_agro_6883_classes.csv.gz", "sexo_do_produtor_codigo"),
        ("dados/sidra/censo_agro_6887_classes.csv.gz", "tipo_de_pessoal_ocupado_codigo"),
        ("dados/sidra/censo_agro_6883.csv.gz", "sexo_do_produtor_codigo"),
        ("dados/sidra/censo_agro_6887.csv.gz", "tipo_de_pessoal_ocupado_codigo"),
    ]
    mun = defaultdict(dict)
    for caminho, col in fontes:
        if not os.path.exists(caminho):
            print(f"aviso: {caminho} não existe", file=sys.stderr)
            continue
        for r in ler_csv(caminho):
            nivel = r["cod_nivel"]
            if nivel == "6":
                # municípios só da 6883, para a lista dos que têm mais mulheres
                if r["tabela"] == "6883" and r["variavel_codigo"] == "9587":
                    chave = (r["cod_atividade"], r["cod_territorio"])
                    mun[chave]["nome"] = r["territorio"]
                    mun[chave][r[col]] = num(r["valor"])
                continue
            if r.get("utilizacao_das_terras_codigo", "110087") != "110087":
                continue
            if r.get("tipologia_codigo", "46302") != "46302":
                continue
            # Grandes Regiões (n2) usam códigos 1 a 5, que colidem com o Brasil
            terr = REGIOES[r["cod_territorio"]][0] if nivel == "2" else r["cod_territorio"]
            v[(r["cod_atividade"], terr, r["variavel_codigo"], r[col])] = num(r["valor"])
    return v, mun


def geo_cadeia(v, codigos):
    def val(terr, var, cat):
        partes = [v.get((c, terr, var, cat)) for c in codigos]
        return soma(partes)

    def bloco(terr):
        b = {"est": [val(terr, "9587", s) for s in SEXO],
             "area": [val(terr, "184", s) for s in SEXO],
             "pess": val(terr, "185", "112967")}
        for k, (h, m) in PESSOAL.items():
            b[k] = [val(terr, "185", h), val(terr, "185", m)]
        return b

    geo = {}
    br = bloco("1")
    br["nome"] = "Brasil"
    geo["1"] = br
    for cod, nome in UFS.items():
        b = bloco(cod)
        if b["est"][0] is None and all(x is None for x in b["est"]):
            continue
        b["nome"] = nome
        geo[cod] = b
    # regiões: o dado publicado pelo IBGE para a Grande Região (n2); se a
    # fonte ainda não tem o nível regional, a soma dos estados, que fica nula
    # se algum estado está em sigilo
    for dig, (sig, nome) in REGIOES.items():
        membros = [geo[c] for c in UFS if c.startswith(dig) and c in geo]
        if not membros:
            continue
        # Com o dado regional na fonte, vale ele, inclusive o X: somar os
        # estados onde o IBGE pôs sigilo na região revelaria o valor omitido.
        tem_n2 = any((c, sig, "9587", SEXO[0]) in v for c in codigos)
        r = {"nome": nome, "inc": False}
        if tem_n2:
            r.update(bloco(sig))
        else:
            for k in ["est", "area"] + list(PESSOAL):
                n = len(membros[0][k])
                r[k] = [soma([m[k][i] for m in membros]) for i in range(n)]
            r["pess"] = soma([m["pess"] for m in membros])
        if any(x is None for k in ["est", "area"] + list(PESSOAL) for x in r[k]):
            r["inc"] = True
        if not r["inc"]:
            del r["inc"]
        geo[sig] = r
    return geo


def lista_municipios(mun, codigo):
    linhas = []
    for (cls, cod), d in mun.items():
        if cls != codigo:
            continue
        t, h, m = d.get(SEXO[0]), d.get(SEXO[1]), d.get(SEXO[2])
        if t is None or h is None or m is None or t < MIN_MUN:
            continue
        linhas.append([int(cod), d["nome"], t, m, h])
    linhas.sort(key=lambda x: (-x[3], -x[2]))
    return linhas


def ler_indicadores():
    caminho = "dados/indicadores/resumo.csv"
    if not os.path.exists(caminho):
        return {}
    ind = defaultdict(lambda: defaultdict(dict))
    for r in ler_csv(caminho):
        ind[r["cadeia"]][f'{r["indicador"]}.{r["recorte"]}'][r["medida"]] = num(r["valor"])
    # horas médias da dupla jornada, ponderadas pelas mulheres de cada UF
    caminho = "dados/indicadores/dupla_jornada.csv"
    if os.path.exists(caminho):
        acc = defaultdict(lambda: [0.0, 0.0, 0.0, None])
        for r in ler_csv(caminho):
            if r["recorte"] != "principal" or r["cod_uf"] == "1":
                continue
            w, hm, hh = num(r["mulheres"]), num(r["horas_m"]), num(r["horas_h"])
            if None in (w, hm, hh):
                continue
            a = acc[r["cadeia"]]
            a[0] += w
            a[1] += w * hm
            a[2] += w * hh
            a[3] = r["ano_pnad"]
        for cad, (w, sm, sh, ano) in acc.items():
            if w > 0:
                ind[cad]["dupla_jornada.horas"] = {
                    "horas_m": round(sm / w, 1), "horas_h": round(sh / w, 1), "ano_pnad": num(ano)}
    # grupo de atividade da direção invisível e produtos do valor da produção
    grupos = {"111519": "lavoura temporária", "111520": "horticultura e floricultura",
              "111521": "lavoura permanente", "111522": "produção de sementes e mudas",
              "111523": "pecuária e criação de outros animais", "111524": "florestas plantadas",
              "111525": "florestas nativas", "114349": "pesca", "111526": "aquicultura"}
    if os.path.exists("config/indicadores.csv"):
        for r in ler_csv("config/indicadores.csv"):
            if r["cadeia"] in ind:
                ind[r["cadeia"]]["grupo"] = grupos.get(r["grupo_6768"], "")
    caminho = "dados/indicadores/valor_producao.csv"
    if os.path.exists(caminho):
        for r in ler_csv(caminho):
            if r["nivel"] == "Brasil" and r["cadeia"] in ind:
                ind[r["cadeia"]]["valor_producao.principal"]["fonte"] = r["fonte"]
                ind[r["cadeia"]]["produtos"] = r["produtos"]
    return {k: dict(x) for k, x in ind.items()}


def limpar(x):
    x = (x or "").strip()
    return "" if x.lower() in ("não localizado", "nao localizado", "na", "nan") else x


def primeiro_link(*campos):
    for c in campos:
        for parte in limpar(c).replace(";", " ").split():
            if parte.startswith("http"):
                return parte
    return ""


def ler_orgs(caminho, filtro=None):
    if not os.path.exists(caminho):
        return []
    saida = []
    for r in ler_csv(caminho):
        if filtro and not filtro(r):
            continue
        uf = limpar(r.get("estado")) or ("Nacional" if r.get("escopo") == "Brasil" else "")
        lat, lon = num(r.get("lat")), num(r.get("lon"))
        saida.append({
            "nome": limpar(r.get("nome")), "sigla": limpar(r.get("sigla")),
            "tipo": limpar(r.get("tipo")), "mun": limpar(r.get("municipio")), "uf": uf,
            "cad": limpar(r.get("cadeia_produtiva")),
            "site": primeiro_link(r.get("site"), r.get("instagram_redes")),
            "nm": limpar(r.get("num_mulheres")), "ano": limpar(r.get("ano_fundacao")),
            "lat": lat, "lon": lon,
        })
    return saida


def data_coleta():
    caminho = "dados/metadados/situacao_coleta.csv"
    if not os.path.exists(caminho):
        return None
    datas = [r["verificado_em"] for r in ler_csv(caminho) if r.get("verificado_em")]
    return max(datas)[:10] if datas else None


def main():
    cadeias = ler_cadeias()
    v, mun = ler_censo()
    dados = {"cad": {}, "meta": {}, "orgs": {}}
    for c in cadeias:
        geo = geo_cadeia(v, c["codigos"])
        if geo["1"]["est"][0] is None:
            print(f"aviso: sem dado de {c['cadeia']}", file=sys.stderr)
            continue
        m = lista_municipios(mun, c["codigos"][0]) if c["cadeia"] in ("cafe", "cacau") else []
        dados["cad"][c["cadeia"]] = {"geo": geo, "mun": m}
        if c["cadeia"] not in ("cafe", "cacau", "total"):
            dados["meta"][c["cadeia"]] = {"nome": c["nome"], "grupo": c["grupo"]}

    dados["ind"] = ler_indicadores()
    dados["orgs"]["cafe"] = ler_orgs("dados/organizacoes/cafe.csv",
                                     lambda r: r.get("escopo", "Brasil") == "Brasil")
    dados["orgs"]["amazonia"] = ler_orgs("dados/organizacoes/amazonia.csv")
    dados["orgs"]["cacau"] = ler_orgs("dados/organizacoes/cacau.csv")
    for chave, arquivo in [("outras-temporarias", "outras_temporarias"), ("cereais", "cereais"), ("frutas", "frutas")]:
        dados["orgs"][chave] = ler_orgs(f"dados/organizacoes/{arquivo}.csv")
    dados["atualizado"] = {
        "coleta": data_coleta(),
        "site": datetime.now(timezone.utc).strftime("%Y-%m-%d"),
    }

    # copia a página e grava os dados ao lado dela
    if os.path.abspath(SAIDA) != os.path.abspath("site"):
        shutil.copytree("site", SAIDA, dirs_exist_ok=True)
    with open(os.path.join(SAIDA, "dados.json"), "w", encoding="utf-8") as f:
        json.dump(dados, f, ensure_ascii=False, separators=(",", ":"))
    montar_organizacoes.montar(SAIDA)
    montar_estudos_cafe.main(SAIDA)
    print(f"{len(dados['cad'])} cadeias, "
          f"{sum(len(x) for x in dados['orgs'].values())} organizações, "
          f"{len(dados['ind'])} cadeias com indicadores -> {SAIDA}/dados.json")


if __name__ == "__main__":
    main()
