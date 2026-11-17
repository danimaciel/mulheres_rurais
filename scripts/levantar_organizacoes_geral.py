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
CADEIAS = {
    "cafe": {
        "cnae": {"0134200", "1081301", "1081302", "1082100", "4621400", "4637101"},
        "nome": r"\bCAFE|CAFEICUL|CAFEEIR",
    },
    "cacau": {
        "cnae": {"0135100", "1093701"},
        "nome": r"CACAU|CHOCOLAT",
    },
    "frutas": {
        "cnae": {"0131800", "0132600", "0133401", "0133402", "0133403", "0133404",
                 "0133405", "0133406", "0133407", "0133408", "0133409", "0133410",
                 "0133411", "0133499", "1031700", "1033301", "1033302"},
        "nome": r"FRUT|POLPA|\bACAI|BANANA|LARANJ|CITRIC|MARACUJA|\bUVA|VITIVIN|\bCAJU|\bCOCO\b|MANGA\b",
    },
    "hortalicas": {
        "cnae": {"0121101", "0121102"},
        "nome": r"HORTI|HORTALI|OLERIC|VERDURA|LEGUME",
    },
    "bovinos_leite": {
        "cnae": {"0151201", "0151202", "0151203", "1051100", "1052000", "4631100"},
        "nome": r"LEITE|LATICIN|BOVIN|PECUARIST|GADO|QUEIJ",
    },
    "extrativismo": {
        "cnae": {"0220901", "0220902", "0220903", "0220904", "0220905", "0220906",
                 "0220999", "0230600"},
        "nome": r"EXTRATIV|CASTANH|BABACU|QUEBRADEIR|SERINGUEI|SOCIOBIO|ANDIROBA|"
                r"COPAIBA|PEQUI|BURITI|\bACAI",
    },
}
for c in CADEIAS.values():
    c["nome"] = re.compile(c["nome"])

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

NOME_MULHERES = re.compile(r"MULHER|FEMININ|AGRICULTORAS|PRODUTORAS|TRABALHADORAS|"
                           r"QUEBRADEIRAS|ARTESAS|MARGARIDAS")

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

            cadeias, criterio = [], set()
            for cadeia, regra in CADEIAS.items():
                por_cnae = any(x in regra["cnae"] for x in todos)
                por_nome = bool(regra["nome"].search(nome))
                if por_cnae or por_nome:
                    cadeias.append(cadeia)
                    criterio.add("cnae" if por_cnae else "nome")

            rural_cnae = any(CNAE_RURAL.match(x) or x in CNAE_RURAL_APOIO for x in todos)
            rural_nome = bool(NOME_RURAL.search(nome))
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


if __name__ == "__main__":
    main()
