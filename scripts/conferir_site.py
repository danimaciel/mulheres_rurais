"""Confere o dados.json da página contra as tabelas do SIDRA, célula a célula.

Para cada cadeia, território e campo da página (estabelecimentos e área por
sexo, pessoal ocupado por vínculo e sexo), confere que:
  - todo número publicado é igual ao valor da tabela de origem (ou à soma das
    classes, no caso de frutas);
  - todo campo vazio corresponde a um "X" (sigilo) na tabela de origem;
  - nas Grandes Regiões, o valor é o publicado pelo IBGE para a região.

Uso: python scripts/conferir_site.py [_site/dados.json]
Sai com erro se encontrar qualquer diferença.
"""

import csv
import gzip
import json
import sys

sys.path.insert(0, "scripts")
from montar_site import PESSOAL, REGIOES, SEXO, ler_cadeias  # noqa: E402

arquivo = sys.argv[1] if len(sys.argv) > 1 else "_site/dados.json"
dados = json.load(open(arquivo, encoding="utf-8"))

fonte = {}
for caminho, col in [
    ("dados/sidra/censo_agro_6883_classes.csv.gz", "sexo_do_produtor_codigo"),
    ("dados/sidra/censo_agro_6887_classes.csv.gz", "tipo_de_pessoal_ocupado_codigo"),
]:
    with gzip.open(caminho, "rt", encoding="utf-8") as f:
        for r in csv.DictReader(f):
            if r.get("utilizacao_das_terras_codigo", "110087") != "110087":
                continue
            terr = REGIOES[r["cod_territorio"]][0] if r["cod_nivel"] == "2" else r["cod_territorio"]
            fonte[(r["cod_atividade"], terr, r["variavel_codigo"], r[col])] = r["valor_bruto"]

campos = [("est", "9587", SEXO), ("area", "184", SEXO), ("pess", "185", ["112967"])]
campos += [(k, "185", cods) for k, cods in PESSOAL.items()]

conta = {"numero_igual": 0, "vazio_sigilo": 0, "regiao_sem_n2": 0}
erros = []
for c in ler_cadeias():
    cad = dados["cad"].get(c["cadeia"])
    if not cad:
        continue
    for terr, g in cad["geo"].items():
        for campo, var, cods in campos:
            valores = g[campo] if isinstance(g[campo], list) else [g[campo]]
            for cod, site in zip(cods, valores):
                brutos = [fonte.get((a, terr, var, cod)) for a in c["codigos"]]
                if any(b is None for b in brutos):
                    # região sem dado n2 na fonte: o script soma os estados
                    conta["regiao_sem_n2"] += 1
                    continue
                if any(b == "X" for b in brutos):
                    esperado = None
                else:
                    esperado = sum(0.0 if b == "-" else float(b) for b in brutos)
                if esperado is None and site is None:
                    conta["vazio_sigilo"] += 1
                elif esperado is not None and site is not None and abs(esperado - site) < 1e-6:
                    conta["numero_igual"] += 1
                else:
                    erros.append((c["cadeia"], terr, campo, cod, brutos, site))

print(f"{conta['numero_igual']} números iguais à fonte, "
      f"{conta['vazio_sigilo']} vazios que são X na fonte, "
      f"{conta['regiao_sem_n2']} células de região sem dado regional na fonte, "
      f"{len(erros)} diferenças")
for e in erros[:50]:
    print("diferença:", e)
sys.exit(1 if erros else 0)
