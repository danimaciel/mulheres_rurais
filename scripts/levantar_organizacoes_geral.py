"""Levantamento geral de cooperativas e associações rurais por cadeia produtiva.

Base separada das bases de organizações de mulheres (dados/organizacoes/).
Não entra no site. Lê a base aberta de CNPJ da Receita Federal e separa
cooperativas (natureza jurídica 2143) e associações privadas (3999) ligadas
à agropecuária, ao extrativismo ou a uma das cadeias acompanhadas.

Uma organização entra na cadeia quando o CNAE principal ou algum CNAE
secundário é da cadeia, ou quando o nome traz um termo da cadeia. A coluna
criterio diz qual dos dois pesou, porque casar só pelo nome traz mais ruído.

Só campos institucionais: CNPJ, razão social, nome fantasia, natureza,
situação, datas, CNAEs, UF e município. Telefone, e-mail, endereço e
quadro de sócios ficam de fora. Estabelecimentos baixados ou nulos não entram.

A coluna base_mulheres aponta o id da organização nas bases de mulheres
quando o CNPJ é o mesmo, e nome_mulheres marca nomes que indicam
organização de mulheres (para triagem, não para entrar automaticamente
nas bases da plataforma).

Uso: CNPJ_PASTA=/tmp/cnpj CNPJ_MES=2026-11 python scripts/levantar_organizacoes_geral.py
Saída: dados/organizacoes_geral/
"""

import csv
import gzip
import io
import os
import re
import sys
import zipfile

PASTA = os.environ.get("CNPJ_PASTA", "/tmp/cnpj")
MES = os.environ.get("CNPJ_MES", "")
SAIDA = "dados/organizacoes_geral"

NATUREZAS = {"2143": "Cooperativa", "3999": "Associação"}

# CNAE 2.3, subclasses sem pontuação.
# Em cada cadeia, "forte" são termos que sozinhos já indicam a atividade
# (cafeicultores, laticínio, quebradeiras). "fraco" é o nome do produto, que
# também aparece em nome de lugar (Cafelândia, Laranjeiras, Buriti, Castanhal);
# esse só conta se o nome também tiver um termo rural (NOME_RURAL abaixo).
CADEIAS = {
    "cafe": {
        "cnae": {"0134200", "1081301", "1081302", "1082100", "4621400", "4637101"},
        "forte": r"CAFEICUL|CAFEEIR|PRODUTORES DE CAFE|CAFES? ESPECIA",
        "fraco": r"\bCAFES?\b",
    },
    "cacau": {
        "cnae": {"0135100", "1093701"},
        "forte": r"CACAUICUL|CACAUEIR|CACAUCUL|CHOCOLAT|PRODUTORES DE CACAU",
        "fraco": r"\bCACAU\b",
    },
    "frutas": {
        "cnae": {"0131800", "0132600", "0133401", "0133402", "0133403", "0133404",
                 "0133405", "0133406", "0133407", "0133408", "0133409", "0133410",
                 "0133411", "0133499", "1031700", "1033301", "1033302"},
        "forte": r"FRUTICUL|FRUTICOL|HORTIFRUT|CITRICUL|VITICUL|VITIVIN|BANANICUL|"
                 r"CAJUCUL|POLPAS? DE FRUTA|PRODUTORES DE FRUTA",
        "fraco": r"\bFRUTAS?\b|\bPOLPAS?\b|\bACAI\b|\bBANANAS?\b|\bLARANJAS?\b|"
                 r"\bCITRICOS?\b|\bMARACUJA\b|\bUVAS?\b|\bCAJU\b|\bCOCOS?\b|\bMANGAS?\b|"
                 r"\bABACAXI\b|\bGOIABAS?\b|\bCUPUACU\b",
    },
    "hortalicas": {
        "cnae": {"0121101", "0121102"},
        "forte": r"HORTICUL|HORTIFRUT|HORTIGRANJ|OLERIC|OLERICUL",
        "fraco": r"\bHORTAS?\b|HORTALI|VERDURA|LEGUMES?\b",
    },
    "bovinos_leite": {
        "cnae": {"0151201", "0151202", "0151203", "1051100", "1052000", "4631100"},
        "forte": r"LATICIN|BOVINOCUL|PECUARISTAS? DE LEITE|PRODUTORES DE LEITE|"
                 r"LEITEIR|CRIADORES DE GADO|PECUARIA LEITEIRA",
        "fraco": r"\bLEITE\b|\bBOVIN|\bGADO\b|\bQUEIJ|PECUARIST",
    },
    "extrativismo": {
        "cnae": {"0220901", "0220902", "0220903", "0220904", "0220905", "0220906",
                 "0220999", "0230600"},
        "forte": r"EXTRATIV|QUEBRADEIR|SERINGUEI|CASTANHEIR|SOCIOBIO|CATADORES DE|"
                 r"COLETORES DE|PEQUIZEIR",
        "fraco": r"\bCASTANHAS?\b|BABACU|ANDIROBA|COPAIBA|\bPEQUI\b|\bBURITI\b|\bACAI\b",
    },
}
for c in CADEIAS.values():
    c["forte"] = re.compile(c["forte"])
    c["fraco"] = re.compile(c["fraco"])

# O que conta como rural mesmo sem cadeia definida.
CNAE_RURAL = re.compile(r"^(01|02|03)")
CNAE_RURAL_APOIO = {"4621400", "4622200", "4623101", "4623102", "4623103", "4623104",
                    "4623105", "4623106", "4623107", "4623108", "4623109", "4623199",
                    "4633801", "1061901", "1061902", "1031700", "1052000"}
NOME_RURAL = re.compile(
    r"\bRURA|AGRICULT|AGRICOLA|AGROPEC|AGROINDUST|AGROECOL|AGROEXTRAT|AGROFLOREST|"
    r"ASSENTAD|ASSENTAMENT|LAVRADOR|CAMPONES|PRODUTORES|PRODUTORAS|PECUARI|"
    r"EXTRATIV|PESCADOR|APICULT|PISCICULT|SERINGUEI|QUEBRADEIR|COLONOS|"
    r"AGRICULTURA FAMILIAR"
)
# Cooperativa de crédito, saúde, transporte e afins ficam fora mesmo com nome rural.
CNAE_FORA = re.compile(r"^(64|65|66|86|49|85)")

# Palavra no feminino só conta quando não vem no par "agricultores e
# agricultoras", que é o jeito comum de nomear organização mista.
NOME_MULHERES = re.compile(
    r"MULHER|FEMININ|QUEBRADEIRAS|MARGARIDAS|CHOCOLATEIRAS|"
    r"(?<!ES E )(?<!ES E DAS )"
    r"\b(AGRICULTORAS|PRODUTORAS|TRABALHADORAS|ARTESAS|CAFEICULTORAS)\b"
)

SITUACAO = {"02": "Ativa", "03": "Suspensa", "04": "Inapta"}


def linhas_zip(nome):
    with zipfile.ZipFile(os.path.join(PASTA, nome)) as z:
        with z.open(z.namelist()[0]) as f:
            for linha in io.TextIOWrapper(f, encoding="latin-1", newline=""):
                yield linha


def campos(linha):
    return next(csv.reader([linha], delimiter=";"))


def so_digitos(s):
    return re.sub(r"\D", "", s or "")


def bases_mulheres():
    """CNPJ -> ids nas bases de mulheres da plataforma (só leitura)."""
    achados = {}
    for arquivo, prefixo in [("cafe.csv", "cafe"), ("cacau.csv", "cacau"),
                             ("amazonia.csv", "amazonia")]:
        caminho = os.path.join("dados/organizacoes", arquivo)
        if not os.path.exists(caminho):
            continue
        with open(caminho, encoding="utf-8-sig", newline="") as f:
            for r in csv.DictReader(f):
                cnpj = so_digitos(r.get("cnpj"))
                if len(cnpj) == 14:
                    achados.setdefault(cnpj, []).append(f"{prefixo}:{r['id']}")
    return achados


def main():
    if not os.path.isdir(PASTA):
        sys.exit("pasta da Receita não encontrada: " + PASTA)
    mulheres = bases_mulheres()
    print("CNPJs nas bases de mulheres:", len(mulheres), flush=True)

    municipios = {}
    for linha in linhas_zip("Municipios.zip"):
        c = campos(linha)
        municipios[c[0]] = c[1]

    empresas = {}
    for i in range(10):
        for linha in linhas_zip(f"Empresas{i}.zip"):
            c = campos(linha)
            if len(c) > 2 and c[2] in NATUREZAS:
                empresas[c[0]] = (c[1], c[2])
        print(f"  empresas {i}: {len(empresas)} cooperativas e associações", flush=True)

    linhas = []
    for i in range(10):
        for linha in linhas_zip(f"Estabelecimentos{i}.zip"):
            basico = linha[1:9]
            if basico not in empresas:
                continue
            c = campos(linha)
            situacao = SITUACAO.get(c[5])
            if not situacao:
                continue
            razao, natureza = empresas[basico]
            principal = c[11]
            if CNAE_FORA.match(principal):
                continue
            secundarios = [s for s in c[12].split(",") if s]
            todos = [principal] + secundarios
            nome = (razao + " " + c[4]).upper()

            rural_cnae = any(CNAE_RURAL.match(x) or x in CNAE_RURAL_APOIO for x in todos)
            rural_nome = bool(NOME_RURAL.search(nome))

            cadeias, criterio = [], set()
            for cadeia, regra in CADEIAS.items():
                por_cnae = any(x in regra["cnae"] for x in todos)
                por_nome = bool(regra["forte"].search(nome)) or (
                    (rural_nome or rural_cnae) and bool(regra["fraco"].search(nome)))
                if por_cnae or por_nome:
                    cadeias.append(cadeia)
                    criterio.add("cnae" if por_cnae else "nome")
            if not (cadeias or rural_cnae or rural_nome):
                continue
            if rural_cnae:
                criterio.add("cnae")
            elif rural_nome:
                criterio.add("nome")

            cnpj = c[0] + c[1] + c[2]
            linhas.append({
                "cnpj": cnpj,
                "razao_social": razao,
                "nome_fantasia": c[4],
                "natureza": NATUREZAS[natureza],
                "matriz": "sim" if c[3] == "1" else "não",
                "situacao": situacao,
                "data_situacao": c[6],
                "data_inicio": c[10],
                "cnae_principal": principal,
                "cnaes_secundarios": ",".join(secundarios),
                "uf": c[19],
                "municipio": municipios.get(c[20], c[20]),
                "cadeias": ";".join(cadeias),
                "criterio": "+".join(sorted(criterio)),
                "nome_mulheres": "sim" if NOME_MULHERES.search(nome) else "",
                "base_mulheres": ";".join(mulheres.get(cnpj, [])),
                "mes_base_receita": MES,
            })
        print(f"  estabelecimentos {i}: {len(linhas)} linhas até aqui", flush=True)

    gravar(linhas)


def gravar(linhas):
    linhas.sort(key=lambda r: (r["uf"], r["municipio"], r["razao_social"]))
    os.makedirs(SAIDA, exist_ok=True)
    campos_saida = list(linhas[0].keys())

    with gzip.open(os.path.join(SAIDA, "organizacoes_rurais.csv.gz"), "wt",
                   encoding="utf-8", newline="") as f:
        w = csv.DictWriter(f, fieldnames=campos_saida)
        w.writeheader()
        w.writerows(linhas)

    for cadeia in CADEIAS:
        sel = [r for r in linhas if cadeia in r["cadeias"].split(";")]
        with open(os.path.join(SAIDA, f"{cadeia}.csv"), "w", encoding="utf-8",
                  newline="") as f:
            w = csv.DictWriter(f, fieldnames=campos_saida)
            w.writeheader()
            w.writerows(sel)
        print(f"  {cadeia}: {len(sel)}", flush=True)

    resumo = {}
    for r in linhas:
        for cadeia in (r["cadeias"].split(";") if r["cadeias"] else []) + ["rural_total"]:
            k = (cadeia, r["uf"], r["natureza"])
            d = resumo.setdefault(k, {"total": 0, "ativas": 0, "so_por_nome": 0,
                                      "nome_mulheres": 0, "nas_bases_mulheres": 0})
            d["total"] += 1
            d["ativas"] += r["situacao"] == "Ativa"
            d["so_por_nome"] += r["criterio"] == "nome"
            d["nome_mulheres"] += r["nome_mulheres"] == "sim"
            d["nas_bases_mulheres"] += bool(r["base_mulheres"])
    with open(os.path.join(SAIDA, "resumo.csv"), "w", encoding="utf-8", newline="") as f:
        w = csv.writer(f)
        w.writerow(["cadeia", "uf", "natureza", "total", "ativas", "so_por_nome",
                    "nome_mulheres", "nas_bases_mulheres", "mes_base_receita"])
        for (cadeia, uf, nat), d in sorted(resumo.items()):
            w.writerow([cadeia, uf, nat, d["total"], d["ativas"], d["so_por_nome"],
                        d["nome_mulheres"], d["nas_bases_mulheres"], MES])
    print("gravado", SAIDA, len(linhas), "estabelecimentos")


def refazer_marcas():
    """Recalcula nome_mulheres e base_mulheres sobre o levantamento já gravado,
    sem baixar a base da Receita. Serve para quando as bases de mulheres
    ganham CNPJ novo."""
    mulheres = bases_mulheres()
    with gzip.open(os.path.join(SAIDA, "organizacoes_rurais.csv.gz"), "rt",
                   encoding="utf-8", newline="") as f:
        linhas = list(csv.DictReader(f))
    for r in linhas:
        nome = (r["razao_social"] + " " + r["nome_fantasia"]).upper()
        r["nome_mulheres"] = "sim" if NOME_MULHERES.search(nome) else ""
        r["base_mulheres"] = ";".join(mulheres.get(r["cnpj"], []))
    global MES
    MES = linhas[0]["mes_base_receita"]
    gravar(linhas)


if __name__ == "__main__":
    if len(sys.argv) > 1 and sys.argv[1] == "--refazer-marcas":
        refazer_marcas()
    else:
        main()
