"""Procura CNPJ de organizações na base aberta da Receita Federal.

Lê os arquivos de Empresas e Estabelecimentos do mês mais recente
publicado em arquivos.receitafederal.gov.br, sem gravar os zips inteiros
em disco, e separa associações e cooperativas cujo nome bate com os termos
de busca. Serve para achar o CNPJ das organizações levantadas e conferir
situação cadastral, data de abertura e município.

Só entram campos institucionais (CNPJ, razão social, nome fantasia,
natureza jurídica, situação, data de início, CNAE, UF e município).
Telefone, e-mail e endereço ficam de fora.

Uso: python scripts/buscar_cnpj.py
Saída: dados/organizacoes/cnpj_candidatos.csv
"""

import csv
import io
import re
import sys
import urllib.request
import zipfile

BASE = "https://arquivos.receitafederal.gov.br/dados/cnpj/dados_abertos_cnpj/"
SAIDA = "dados/organizacoes/cnpj_candidatos.csv"

# Associação privada, cooperativa e organização religiosa ficam de fora desta
# última; fundações privadas entram porque algumas redes são registradas assim.
NATUREZAS = {"3999", "2143", "3069"}

TERMOS = re.compile(
    r"MULHER|FEMININ|AGRICULTORAS|PRODUTORAS|CHOCOLAT|CACAU|"
    r"JURUNA|TUBYA|TRANSAMAZONICA|COOPATRANS|POLPAS? DE FRUTA"
)
# Fora destas UFs só entram nomes com cacau ou chocolate.
UFS = {"BA", "ES", "PA", "AM", "RO", "MT", "AP", "AC", "RR", "TO", "MA", "MG", "RJ"}
CACAU = re.compile(r"CACAU|CHOCOLAT")


def abrir(url):
    req = urllib.request.Request(url, headers={"User-Agent": "mulheres-rurais-coleta"})
    return urllib.request.urlopen(req, timeout=600)


def mes_mais_recente():
    html = abrir(BASE).read().decode("utf-8", "replace")
    meses = sorted(set(re.findall(r'href="(\d{4}-\d{2})/?"', html)))
    if not meses:
        sys.exit("não achei a lista de meses em " + BASE)
    return meses[-1]


def linhas_zip(url):
    """Baixa um zip para a memória e devolve as linhas do csv de dentro."""
    print("baixando", url, flush=True)
    dados = abrir(url).read()
    with zipfile.ZipFile(io.BytesIO(dados)) as z:
        nome = z.namelist()[0]
        with z.open(nome) as f:
            for linha in io.TextIOWrapper(f, encoding="latin-1", newline=""):
                yield linha


def campos(linha):
    return next(csv.reader([linha], delimiter=";"))


def main():
    mes = mes_mais_recente()
    pasta = BASE + mes + "/"
    print("mês:", mes, flush=True)

    municipios = {}
    for linha in linhas_zip(pasta + "Municipios.zip"):
        c = campos(linha)
        municipios[c[0]] = c[1]

    empresas = {}
    for i in range(10):
        for linha in linhas_zip(f"{pasta}Empresas{i}.zip"):
            c = campos(linha)
            if len(c) < 3 or c[2] not in NATUREZAS:
                continue
            if TERMOS.search(c[1].upper()):
                empresas[c[0]] = (c[1], c[2])
        print(f"  empresas {i}: {len(empresas)} candidatas até aqui", flush=True)

    saida = []
    for i in range(10):
        for linha in linhas_zip(f"{pasta}Estabelecimentos{i}.zip"):
            basico = linha[1:9]
            if basico not in empresas:
                continue
            c = campos(linha)
            razao, natureza = empresas[basico]
            uf = c[19]
            texto = (razao + " " + c[4]).upper()
            if uf not in UFS and not CACAU.search(texto):
                continue
            saida.append({
                "cnpj": c[0] + c[1] + c[2],
                "razao_social": razao,
                "nome_fantasia": c[4],
                "natureza_juridica": natureza,
                "matriz": "sim" if c[3] == "1" else "não",
                "situacao": {"01": "Nula", "02": "Ativa", "03": "Suspensa",
                             "04": "Inapta", "08": "Baixada"}.get(c[5], c[5]),
                "data_situacao": c[6],
                "data_inicio": c[10],
                "cnae_principal": c[11],
                "uf": uf,
                "municipio": municipios.get(c[20], c[20]),
                "mes_base_receita": mes,
            })
        print(f"  estabelecimentos {i}: {len(saida)} linhas até aqui", flush=True)

    saida.sort(key=lambda r: (r["uf"], r["municipio"], r["razao_social"]))
    with open(SAIDA, "w", newline="", encoding="utf-8") as f:
        w = csv.DictWriter(f, fieldnames=list(saida[0].keys()))
        w.writeheader()
        w.writerows(saida)
    print("gravado", SAIDA, len(saida), "linhas")


if __name__ == "__main__":
    main()
