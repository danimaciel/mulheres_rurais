"""Monta os dados do mapa de organizações do site (organizacoes.json).

Junta duas fontes:

- as bases de organizações de mulheres da plataforma (dados/organizacoes/),
  levantadas e conferidas uma a uma;
- o levantamento geral de cooperativas e associações rurais da Receita
  (dados/organizacoes_geral/organizacoes_rurais.csv.gz).

Da base geral entram só as sedes (matriz) com situação ativa. Linhas que
entraram no levantamento só pelo nome passam por um filtro de ruído: nomes de
associação de pais e mestres, caixa escolar, catadores de material reciclável
e afins saem sempre; clube, igreja, condomínio, cultura, esporte e parecidos
saem quando o nome não traz também um termo de atividade agropecuária.

A localização é a sede do município (tabela config/municipios.csv). Nenhuma
das duas bases tem endereço, e o mapa não deve sugerir mais precisão do que
isso. Organizações de mulheres de atuação estadual, regional ou nacional, sem
município de sede, aparecem na lista mas não no mapa.

Pode rodar sozinho (python scripts/montar_organizacoes.py [pasta]) ou ser
chamado pelo montar_site.py. Só usa a biblioteca padrão do Python.
"""

import csv
import gzip
import json
import os
import re
import sys
import unicodedata
from collections import Counter

GERAL = "dados/organizacoes_geral/organizacoes_rurais.csv.gz"
MUNICIPIOS = "config/municipios.csv"

# Ordem fixa das cadeias no filtro; o índice vira um bit na máscara de cada linha.
CADEIAS = [
    ("cafe", "Café"),
    ("cacau", "Cacau"),
    ("frutas", "Frutas"),
    ("hortalicas", "Hortaliças"),
    ("bovinos_leite", "Bovinos e leite"),
    ("extrativismo", "Extrativismo e sociobiodiversidade"),
    ("outras_temporarias", "Mandioca, feijão e outras temporárias"),
    ("cereais", "Cereais"),
]
BIT = {k: 1 << i for i, (k, _) in enumerate(CADEIAS)}

# Bases de mulheres: arquivo, cadeia em que entra no filtro, rótulo da base.
BASES_MULHERES = [
    ("cafe", "cafe", "Café"),
    ("amazonia", "extrativismo", "Amazônia"),
    ("cacau", "cacau", "Cacau"),
    ("outras_temporarias", "outras_temporarias", "Mandioca e outras temporárias"),
    ("cereais", "cereais", "Cereais"),
    ("frutas", "frutas", "Frutas"),
]

# Nomes de município que a Receita escreve diferente do IBGE.
ALIAS_MUN = {
    ("RN", "ASSU"): "2400208", ("PA", "ELDORADODOSCARAJAS"): "1502954",
    ("PA", "SANTAISABELDOPARA"): "1506500", ("RN", "CAMPOGRANDE"): "2401305",
    ("PE", "SAOCAITANO"): "2613107", ("TO", "COUTODEMAGALHAES"): "1706001",
    ("RJ", "PARATI"): "3303807", ("MG", "BRASOPOLIS"): "3108909",
    ("SE", "GRACCHOCARDOSO"): "2802601", ("TO", "SAOVALERIODANATIVIDADE"): "1720499",
    ("RN", "BOASAUDE"): "2405306", ("MG", "DONAEUZEBIA"): "3122900",
    ("MG", "SAOTOMEDASLETRAS"): "3165206", ("MG", "AMPARODASERRA"): "3102506",
    ("MG", "BARAODOMONTEALTO"): "3105509", ("SC", "BALNEARIODEPICARRAS"): "4212809",
    ("SP", "FLORINEA"): "3516101",
}

UF_SIGLA = {"Rondônia": "RO", "Acre": "AC", "Amazonas": "AM", "Roraima": "RR", "Pará": "PA",
            "Amapá": "AP", "Tocantins": "TO", "Maranhão": "MA", "Piauí": "PI", "Ceará": "CE",
            "Rio Grande do Norte": "RN", "Paraíba": "PB", "Pernambuco": "PE", "Alagoas": "AL",
            "Sergipe": "SE", "Bahia": "BA", "Minas Gerais": "MG", "Espírito Santo": "ES",
            "Rio de Janeiro": "RJ", "São Paulo": "SP", "Paraná": "PR", "Santa Catarina": "SC",
            "Rio Grande do Sul": "RS", "Mato Grosso do Sul": "MS", "Mato Grosso": "MT",
            "Goiás": "GO", "Distrito Federal": "DF"}

# Ruído das linhas que entraram só pelo nome.
RUIDO_SEMPRE = re.compile(
    r"RECICL|\bCATADOR(ES|AS)? DE (MATERI|PAPEL|LIXO)|COLETA SELETIVA|"
    r"\bPAIS\s*,?\s*(E\s+)?(MESTRES?|PROFESSORES)|\bAPMF?\b|\bAPP\b|\bAPMC\b|\bCPM\b|"
    r"CAIXA ESCOLAR|CONSELHO ESCOLAR|UNIDADE EXECUTORA|UNIAO ESCOLAR")
RUIDO_SEM_AGRO = re.compile(
    r"\bCONDOMINIO|\bCULTURA(L|IS)\b|\bESPORT|\bFUTEBOL|\bCLUBE\b|\bIGREJA|\bEVANGEL|"
    r"\bPAROQUI|\bIRMANDADE|\bCONGREGA|\bEVENTOS\b|\bMUSIC|\bTEATR|\bCINEMA|AUDIOVISUA|"
    r"\bARTISTIC|\bSERVIDORES\b|\bFUNCIONARIOS\b|\bAPOSENTADOS\b|TAXI\b|\bFEST(A|AS|IVAL)\b|"
    r"\bRODEIO|\bCAVALGADA|\bVAQUEJADA|\bESCOLAS?\b(?! FAMILIA)|\bCOLEGIO\b|\bCRECHE")
AGRO = re.compile(
    r"AGRICULT|PRODUTOR|PECUAR|EXTRATIV|PESCADOR|LAVRADOR|ASSENTAMENT|APICULT|"
    r"CAMPONES|AGROPEC|AGROECOL|CAFEICULT|FRUTICULT|HORTICULT|QUEBRADEIR")

# Marca de organização de mulheres pelo nome, mais estrita que a coluna
# nome_mulheres da base geral (que serve à triagem). Palavra como MULHERES ou
# QUEBRADEIRAS basta, desde que o nome não fale também em HOMENS. Atividade no
# feminino (agricultoras, pescadoras) só conta quando o masculino da mesma
# palavra não aparece no nome, o que tira as mistas "agricultores e
# agricultoras", e quando o nome não é de outro ramo (som, streaming, indústria).
MULHERES_FORTE = re.compile(r"MULHER|FEMININ|MARGARIDAS|CHOCOLATEIRAS")
# feminino -> masculinos que, se aparecem juntos, indicam organização mista
MULHERES_ATIV = {
    "AGRICULTORAS": ["AGRICULTORES"], "PRODUTORAS": ["PRODUTORES"],
    "TRABALHADORAS": ["TRABALHADORES"], "CAFEICULTORAS": ["CAFEICULTORES"],
    "PESCADORAS": ["PESCADORES"], "LAVRADORAS": ["LAVRADORES"], "CAMPONESAS": ["CAMPONESES"],
    "APICULTORAS": ["APICULTORES"], "HORTICULTORAS": ["HORTICULTORES"],
    "FRUTICULTORAS": ["FRUTICULTORES"], "CRIADORAS": ["CRIADORES"],
    "ASSENTADAS": ["ASSENTADOS"], "ARTESAS": ["ARTESAOS"], "BENEFICIADORAS": ["BENEFICIADORES"],
    "QUEBRADEIRAS": ["QUEBRADORES", "QUEBRADEIROS"],
    "MARISQUEIRAS": ["MARISQUEIROS", "PESCADORES"],
}
MULHERES_ATIV_RE = re.compile(r"\b(" + "|".join(MULHERES_ATIV) + r")\b")
MULHERES_FORA = re.compile(r"\bSOM\b|STREAMING|ESPORT|INDUSTRIA|AUDIOVISUA|CULTURA(L|IS)\b|EVENTOS|"
                           r"\bARTES\b|CINEMA|MUSIC|TEATR|FAMILIAS AGRICULTORAS")


def nome_de_mulheres(nome):
    if MULHERES_FORA.search(nome):
        return False
    if MULHERES_FORTE.search(nome):
        return not re.search(r"\bHOMENS\b", nome)
    for m in MULHERES_ATIV_RE.finditer(nome):
        if not any(re.search(r"\b" + x + r"\b", nome) for x in MULHERES_ATIV[m.group(1)]):
            return True
    return False


MINUSCULAS = {"a", "as", "o", "os", "e", "de", "da", "das", "do", "dos", "em", "na", "nas",
              "no", "nos", "para", "por", "com"}


def ler_csv(caminho):
    abrir = gzip.open if caminho.endswith(".gz") else open
    with abrir(caminho, "rt", encoding="utf-8-sig", newline="") as f:
        yield from csv.DictReader(f)


def chave(s):
    s = unicodedata.normalize("NFKD", s or "").encode("ascii", "ignore").decode().upper()
    return re.sub(r"[^A-Z0-9]", "", s)


def so_digitos(s):
    return re.sub(r"\D", "", s or "")


def limpar(x):
    x = (x or "").strip()
    return "" if x.lower() in ("não localizado", "nao localizado", "na", "nan", "-") else x


def titulo(nome):
    """A Receita grava tudo em maiúsculas; a página fica mais legível em caixa
    mista. Siglas curtas sem vogal e trechos entre parênteses não mexe."""
    out = []
    for i, p in enumerate(nome.split()):
        b = p.lower()
        nucleo = re.sub(r"[^a-z]", "", b)
        if i and nucleo in MINUSCULAS:
            out.append(b)
        elif re.fullmatch(r"[ivxl]+", nucleo) and i:
            out.append(p)                      # algarismo romano: Assentamento II
        elif len(nucleo) > 1 and not re.search(r"[aeiou]", nucleo):
            out.append(p)                      # sigla: APL, CPT
        else:
            out.append(re.sub(r"(^|[\s\-/(\"'.])([a-z])", lambda m: m.group(1) + m.group(2).upper(), b))
    return " ".join(out)


def primeiro_link(*campos):
    for c in campos:
        for parte in limpar(c).replace(";", " ").split():
            if parte.startswith("http"):
                return parte
    return ""


def ruido(nome):
    if RUIDO_SEMPRE.search(nome):
        return "sempre"
    if RUIDO_SEM_AGRO.search(nome) and not AGRO.search(nome):
        return "sem_agro"
    return ""


def montar(saida):
    if not os.path.exists(GERAL) or not os.path.exists(MUNICIPIOS):
        print("aviso: sem base geral ou tabela de municípios; mapa de organizações não montado",
              file=sys.stderr)
        return None

    mun_info, por_nome = {}, {}
    for r in ler_csv(MUNICIPIOS):
        mun_info[r["cod_ibge"]] = (r["nome"], r["uf"], float(r["lat"]), float(r["lon"]))
        por_nome[(r["uf"], chave(r["nome"]))] = r["cod_ibge"]

    def achar_mun(uf, nome):
        k = (uf, chave(nome))
        return por_nome.get(k) or ALIAS_MUN.get(k)

    usados = {}

    def idx(cod):
        if cod not in usados:
            usados[cod] = len(usados)
        return usados[cod]

    # bases de mulheres
    mulheres, cnpj_mulheres = {}, set()
    for arquivo, cad, rotulo in BASES_MULHERES:
        caminho = f"dados/organizacoes/{arquivo}.csv"
        if not os.path.exists(caminho):
            continue
        for r in ler_csv(caminho):
            if arquivo == "cafe" and r.get("escopo", "Brasil") != "Brasil":
                continue
            nome = limpar(r.get("nome"))
            uf = UF_SIGLA.get(limpar(r.get("estado")), "")
            mun_txt = limpar(r.get("municipio"))
            cod = limpar(r.get("cod_ibge")).split(".")[0] if r.get("cod_ibge") else ""
            if cod not in mun_info:
                cod = ""
                # municípios múltiplos vêm separados por ; ou , e o primeiro é a sede
                primeiro = re.split(r"[;,/]| e ", mun_txt)[0].strip() if mun_txt else ""
                if uf and primeiro:
                    cod = achar_mun(uf, primeiro) or ""
            if r.get("precisao_geo") in ("nacional", "estado", "regional") and not limpar(r.get("municipio")):
                cod = ""
            cnpj = so_digitos(r.get("cnpj"))
            if len(cnpj) == 14:
                cnpj_mulheres.add(cnpj)
            k = cnpj if len(cnpj) == 14 else (chave(nome), cod or uf)
            if k in mulheres:                  # mesma organização em duas bases
                o = mulheres[k]
                o["c"] |= BIT[cad]
                if rotulo not in o["b"]:
                    o["b"].append(rotulo)
                continue
            mulheres[k] = {
                "n": nome, "s": limpar(r.get("sigla")), "t": limpar(r.get("tipo")) or "Organização",
                "m": idx(cod) if cod else None, "uf": uf,
                "mt": "" if cod else (mun_txt or limpar(r.get("abrangencia")) or ("Nacional" if not uf else "")),
                "c": BIT[cad], "b": [rotulo],
                "u": primeiro_link(r.get("site"), r.get("instagram_redes")),
                "a": limpar(r.get("ano_fundacao")), "p": limpar(r.get("cadeia_produtiva")),
                "nf": limpar(r.get("nucleo_feminino")),
            }

    # base geral da Receita
    geral, cont = [], Counter()
    mes = ""
    for r in ler_csv(GERAL):
        cont["lidas"] += 1
        mes = r.get("mes_base_receita") or mes
        if r["situacao"] != "Ativa":
            cont["nao_ativas"] += 1
            continue
        if r["matriz"] != "sim":
            cont["filiais"] += 1
            continue
        if r["cnpj"] in cnpj_mulheres or r.get("base_mulheres"):
            cont["ja_nas_bases_mulheres"] += 1
            continue
        nome_cru = f"{r['razao_social']} {r['nome_fantasia']}"
        motivo = ruido(nome_cru) if r["criterio"] == "nome" else (
            "sempre" if RUIDO_SEMPRE.search(nome_cru) else "")
        if motivo:
            cont["ruido_" + motivo] += 1
            continue
        cod = achar_mun(r["uf"], r["municipio"])
        if not cod:
            cont["sem_municipio"] += 1
            continue
        mask = 0
        for c in (r["cadeias"] or "").split(";"):
            if c in BIT:
                mask |= BIT[c]
        flags = (1 if r["natureza"] == "Cooperativa" else 0) | (2 if nome_de_mulheres(nome_cru) else 0) \
            | (4 if r["criterio"] == "nome" else 0)
        geral.append([titulo(r["razao_social"].strip()), idx(cod), mask, flags, r["cnpj"],
                      (r["data_inicio"] or "")[:4]])
        cont["no_mapa"] += 1

    mun = [None] * len(usados)
    for cod, i in usados.items():
        nm, uf, lat, lon = mun_info[cod]
        mun[i] = [cod, nm, uf, round(lat, 4), round(lon, 4)]

    dados = {
        "cadeias": [nome for _, nome in CADEIAS],
        "mun": mun,
        "w": list(mulheres.values()),
        "g": geral,
        "meta": {"mes_receita": mes, "contagem": dict(cont)},
    }
    os.makedirs(saida, exist_ok=True)
    with open(os.path.join(saida, "organizacoes.json"), "w", encoding="utf-8") as f:
        json.dump(dados, f, ensure_ascii=False, separators=(",", ":"))
    print(f"mapa de organizações: {len(dados['w'])} de mulheres, {len(geral)} da base geral, "
          f"{len(mun)} municípios; {dict(cont)}")
    return dados


if __name__ == "__main__":
    montar(sys.argv[1] if len(sys.argv) > 1 else "_site")
