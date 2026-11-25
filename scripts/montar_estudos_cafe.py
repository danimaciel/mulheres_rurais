"""Monta os dados da página de estudos de cafeicultura da Embrapa.

Lê dados/estudos_cafe/estudos.csv (um documento por linha) e
dados/estudos_cafe/resumo_genero.json (agregados de gênero) e grava
estudos_cafe.json ao lado da página. A página só carrega esse arquivo quando
alguém abre a seção de estudos.

Os números de gênero passam como estão no resumo; aqui só se confere que os
totais do resumo batem com a base de estudos.
"""

import csv
import json
import os
import sys

PASTA = "dados/estudos_cafe"

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


def main(saida):
    with open(os.path.join(PASTA, "estudos.csv"), encoding="utf-8") as f:
        linhas = list(csv.DictReader(f))
    with open(os.path.join(PASTA, "resumo_genero.json"), encoding="utf-8") as f:
        resumo = json.load(f)

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
        ])
    docs.sort(key=lambda d: (-(d[4] or 0), d[3]))

    # conferência: os totais do resumo têm de sair da mesma base
    tipos = {t: sum(1 for r in linhas if r["tipo"] == t) for t in ("publicação", "projeto", "tecnologia")}
    lid = resumo["cafeicultura"]["projetos_liderados"]["projetos_com_lider_identificado"]
    if lid > tipos["projeto"]:
        sys.exit(f"resumo fala de {lid} projetos e a base tem {tipos['projeto']}")
    if resumo["cafeicultura"]["primeira_autoria"]["publicacoes"] > tipos["publicação"]:
        sys.exit("resumo tem mais publicações que a base")
    ids = [r["id"] for r in linhas]
    if len(set(ids)) != len(ids):
        sys.exit("há documentos repetidos em estudos.csv")

    serie = {}
    for d in docs:
        if d[4]:
            serie.setdefault(d[4], [0, 0, 0])
            serie[d[4]][0 if grupos[d[1]] == "Projeto" else 2 if grupos[d[1]] == "Solução tecnológica" else 1] += 1

    temas_csv = []
    with open(os.path.join(PASTA, "temas_cafe.csv"), encoding="utf-8") as f:
        for t in csv.DictReader(f):
            temas_csv.append([t["tema"], int(t["n_recorte"]), int(t["n_tema_total"])])

    out = {
        "meta": resumo["metadados"],
        "tipos": tipos,
        "anos": [min(d[4] for d in docs if d[4]), max(d[4] for d in docs if d[4])],
        "unidades": [[s, nome_unidade(s)] for s in siglas],
        "temas": temas,
        "grupos": grupos,
        "docs": docs,
        "docs_ano": sorted([a, *v] for a, v in serie.items()),
        "temas_recorte": temas_csv,
        "g": {
            "cafe": resumo["cafeicultura"],
            "embrapa": resumo["embrapa_toda"],
            "serie": resumo["serie_anual"]["cafeicultura"],
            "tipo": resumo["por_tipo_documento"]["cafeicultura"],
            "tema": resumo["por_tema"]["cafeicultura"],
            "unidade": [dict(u, nome=nome_unidade(u["grupo"])) for u in resumo["por_unidade"]["cafeicultura"]],
        },
    }
    os.makedirs(saida, exist_ok=True)
    with open(os.path.join(saida, "estudos_cafe.json"), "w", encoding="utf-8") as f:
        json.dump(out, f, ensure_ascii=False, separators=(",", ":"))
    print(f"{len(docs)} estudos de cafeicultura -> {saida}/estudos_cafe.json")


if __name__ == "__main__":
    main(sys.argv[1] if len(sys.argv) > 1 else "_site")
