"""Monta os dados da página de estudos da Embrapa por cadeia.

Lê dados/estudos/estudos.csv.gz (um documento por linha, com as cadeias em
que entra) e dados/estudos/resumo_genero.json (agregados de gênero por cadeia).
Grava estudos.json, com os totais de todas as cadeias, e um arquivo por cadeia
em estudos/<cadeia>.json com a lista de estudos, para a página só baixar a
lista da cadeia que a pessoa escolher. Sem o recorte por cadeia, usa o do café
em dados/estudos_cafe/.

Os números de gênero passam como estão no resumo; aqui só se confere que os
totais do resumo cabem na base de estudos.
"""

import csv
import gzip
import json
import os
import sys

PASTA = "dados/estudos"
PASTA_CAFE = "dados/estudos_cafe"

# nome atual de cada unidade, pela sigla usada no Redape
UNIDADES = {
    "CENARGEN": "Recursos Genéticos e Biotecnologia", "CNAT": "Alimentos e Territórios",
    "CNPA": "Algodão", "CNPAB": "Agrobiologia", "CNPAE": "Agroenergia", "CNPAF": "Arroz e Feijão",
    "CNPASA": "Pesca e Aquicultura", "CNPAT": "Agroindústria Tropical", "CNPC": "Caprinos e Ovinos",
    "CNPCA": "Café", "CNPDIA": "Instrumentação", "CNPF": "Florestas", "CNPGC": "Gado de Corte",
    "CNPGL": "Gado de Leite", "CNPH": "Hortaliças", "CNPM": "Territorial", "CNPMA": "Meio Ambiente",
    "CNPMF": "Mandioca e Fruticultura", "CNPMS": "Milho e Sorgo", "CNPS": "Solos",
    "CNPSA": "Suínos e Aves", "CNPSO": "Soja", "CNPT": "Trigo", "CNPTIA": "Agricultura Digital",
    "CNPUV": "Uva e Vinho", "CPAA": "Amazônia Ocidental", "CPAC": "Cerrados",
    "CPACT": "Clima Temperado", "CPAF-AC": "Acre", "CPAF-AP": "Amapá", "CPAF-RO": "Rondônia",
    "CPAF-RR": "Roraima", "CPAMN": "Meio-Norte", "CPAMT": "Agrossilvipastoril",
    "CPAO": "Agropecuária Oeste", "CPAP": "Pantanal", "CPATC": "Tabuleiros Costeiros",
    "CPATSA": "Semiárido", "CPATU": "Amazônia Oriental", "CPPSE": "Pecuária Sudeste",
    "CPPSUL": "Pecuária Sul", "CTAA": "Agroindústria de Alimentos", "SEDE": "Sede",
}

# grupos de subtipo para o filtro da base
GRUPOS = [
    ("Artigo de periódico", "Artigo em periódico"),
    ("Artigo em anais", "Artigo em anais"),
    ("Resumo em anais", "Resumo em anais"),
    ("Parte de livro", "Livro ou capítulo"), ("Livros", "Livro ou capítulo"),
    ("Teses", "Tese ou dissertação"),
    ("Folhetos", "Publicação técnica"), ("Folders", "Publicação técnica"),
    ("Manuais", "Publicação técnica"), ("Fascículos", "Publicação técnica"),
]


def grupo(r):
    if r["tipo"] == "projeto":
        return "Projeto"
    if r["tipo"] == "tecnologia":
        return "Solução tecnológica"
    for ini, g in GRUPOS:
        if r["subtipo"].startswith(ini):
            return g
    return "Outras publicações"


def nome_unidade(sigla):
    return "Embrapa " + UNIDADES[sigla] if sigla in UNIDADES else sigla


def ler_csv(caminho):
    abrir = gzip.open if caminho.endswith(".gz") else open
    with abrir(caminho, "rt", encoding="utf-8") as f:
        return list(csv.DictReader(f))


def ler_base():
    """Devolve linhas, resumo por cadeia, Embrapa toda e metadados."""
    if os.path.exists(os.path.join(PASTA, "estudos.csv.gz")):
        linhas = ler_csv(os.path.join(PASTA, "estudos.csv.gz"))
        with open(os.path.join(PASTA, "resumo_genero.json"), encoding="utf-8") as f:
            r = json.load(f)
        return linhas, r["cadeias"], r["embrapa_toda"], r["metadados"]
    linhas = ler_csv(os.path.join(PASTA_CAFE, "estudos.csv"))
    for x in linhas:
        x["cadeias"] = "cafe"
    with open(os.path.join(PASTA_CAFE, "resumo_genero.json"), encoding="utf-8") as f:
        r = json.load(f)
    cafe = dict(r["cafeicultura"], cadeia="Café",
                serie_anual=r["serie_anual"]["cafeicultura"],
                por_tipo_documento=r["por_tipo_documento"]["cafeicultura"],
                por_tema=r["por_tema"]["cafeicultura"],
                por_unidade=r["por_unidade"]["cafeicultura"])
    return linhas, {"cafe": cafe}, r["embrapa_toda"], r["metadados"]


def main(saida):
    linhas, res, embrapa, meta = ler_base()
    ids = [r["id"] for r in linhas]
    if len(set(ids)) != len(ids):
        sys.exit("há documentos repetidos em estudos.csv")

    ordem = [c["cadeia"] for c in ler_csv("config/site_cadeias.csv")] + ["amazonia"]
    nomes = {c["cadeia"]: c["nome"] for c in ler_csv("config/site_cadeias.csv")}
    nomes["amazonia"] = "Sociobiodiversidade amazônica"
    chaves = sorted({c for r in linhas for c in r["cadeias"].split(";") if c},
                    key=lambda c: ordem.index(c) if c in ordem else 99)
    desconhecidas = [c for c in chaves if c not in ordem]
    if desconhecidas:
        sys.exit(f"cadeias fora de config/site_cadeias.csv: {desconhecidas}")

    siglas = sorted({u for r in linhas for u in r["unidades"].split(";") if u})
    temas = sorted({r["tema"] for r in linhas if r["tema"]})
    grupos = sorted({grupo(r) for r in linhas})
    docs = []
    for r in linhas:
        docs.append([
            r["id"], grupos.index(grupo(r)), r["subtipo"], r["titulo"],
            int(r["ano"]) if r["ano"] else None,
            [siglas.index(u) for u in r["unidades"].split(";") if u],
            temas.index(r["tema"]) if r["tema"] else None,
            r["palavras_chave"], r["resumo"], r["autores"], r["link"],
            [chaves.index(c) for c in r["cadeias"].split(";") if c],
        ])
    docs.sort(key=lambda d: (-(d[4] or 0), d[3]))

    cad = {}
    for i, k in enumerate(chaves):
        meus = [d for d in docs if i in d[11]]
        tipos = {t: sum(1 for d in meus if grupos[d[1]] == n) for t, n in
                 (("projeto", "Projeto"), ("tecnologia", "Solução tecnológica"))}
        tipos["publicação"] = len(meus) - tipos["projeto"] - tipos["tecnologia"]
        anos = [d[4] for d in meus if d[4]]
        r = res.get(k)
        if r is None:
            sys.exit(f"sem resumo de gênero para {k}")
        tot = r.get("totais")
        if tot and (tot["publicacao"], tot["projeto"], tot["tecnologia"]) != (tipos["publicação"], tipos["projeto"], tipos["tecnologia"]):
            sys.exit(f"{k}: totais do resumo {tot} diferem da base {tipos}")
        lid = r["projetos_liderados"].get("projetos_com_lider_identificado", 0)
        if lid > tipos["projeto"]:
            sys.exit(f"{k}: resumo fala de {lid} projetos e a base tem {tipos['projeto']}")
        if r["primeira_autoria"]["publicacoes"] > tipos["publicação"]:
            sys.exit(f"{k}: resumo tem mais publicações que a base")
        cad[k] = {
            "nome": nomes.get(k, k), "tipos": tipos, "anos": [min(anos), max(anos)] if anos else None,
            "g": {x: r[x] for x in ("pessoas_distintas_todas", "autorias_publicacoes", "primeira_autoria",
                                    "lideres_de_projeto_pessoas", "projetos_liderados",
                                    "publicacoes_com_autor_identificado", "publicacoes_com_ao_menos_uma_autora",
                                    "pct_publicacoes_com_autora")},
            "serie": r["serie_anual"], "tipo": r["por_tipo_documento"], "tema": r["por_tema"],
            "unidade": [dict(u, nome=nome_unidade(u["grupo"])) for u in r["por_unidade"]],
        }

    out = {"meta": meta, "cadeias": chaves, "cad": cad, "embrapa": embrapa,
           "unidades": [[s, nome_unidade(s)] for s in siglas], "temas": temas, "grupos": grupos}
    os.makedirs(os.path.join(saida, "estudos"), exist_ok=True)
    with open(os.path.join(saida, "estudos.json"), "w", encoding="utf-8") as f:
        json.dump(out, f, ensure_ascii=False, separators=(",", ":"))
    for i, k in enumerate(chaves):
        with open(os.path.join(saida, "estudos", k + ".json"), "w", encoding="utf-8") as f:
            json.dump([d for d in docs if i in d[11]], f, ensure_ascii=False, separators=(",", ":"))
    print(f"{len(docs)} estudos em {len(chaves)} cadeias -> {saida}/estudos.json e {saida}/estudos/")


if __name__ == "__main__":
    main(sys.argv[1] if len(sys.argv) > 1 else "_site")
