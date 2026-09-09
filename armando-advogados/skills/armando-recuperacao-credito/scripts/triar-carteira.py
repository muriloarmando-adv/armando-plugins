#!/usr/bin/env python3
"""Triagem de carteira de inadimplentes — Armando Advogados.

Gemeo em Python do triar-carteira.ps1, para rodar onde nao ha PowerShell:
o ambiente de execucao de codigo do claude.ai (skill subida no painel de
Habilidades) e' Linux com Python. Mesmos filtros, mesma saida, mesmo
codigo de saida.

Automatiza os filtros 1 e 3 da skill armando-recuperacao-credito sobre uma
planilha de inadimplencia: prescricao por vencimento, coerencia do valor
atualizado, classificacao da via cabivel e status sugerido.

NAO substitui a conferencia documental. O filtro 2 (documento habil)
depende de olhar o PDF e ver se ha canhoto assinado — nenhum script faz
isso. E o veredito de prescricao e' provisorio: cabe procurar interrupcao
(art. 202, VI, do CC — pagamento parcial, protesto, reconhecimento
escrito) antes de descartar credito.

Uso:
  python triar-carteira.py carteira.csv
  python triar-carteira.py carteira.csv --data-base 2026-09-09
  python triar-carteira.py carteira.csv --csv saida.csv
"""

import argparse
import csv
import os
import re
import sys
from datetime import date, datetime

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from lib_peca import achado, escrever_relatorio, forcar_utf8, sem_acento  # noqa: E402


# ------------------------------------------------------------------ colunas
def find_coluna(colunas, chaves):
    """Casa nome de coluna por palavra-chave — o nome varia muito entre
       planilhas de cliente, mas o miolo repete."""
    for chave in chaves:
        for c in colunas:
            if not c:
                continue
            limpo = re.sub(r"[^A-Za-z]", "", sem_acento(c))
            if re.search(chave, limpo, re.IGNORECASE):
                return c
    return None


# ------------------------------------------------------------------ parsers
def para_valor(texto):
    if texto is None:
        return None
    t = re.sub(r"(?i)r\$", "", str(texto)).strip()
    t = re.sub(r"[^\d,.\-]", "", t)
    if t in ("", "-"):
        return None
    # Ultimo separador manda: virgula => formato BR; ponto => formato US.
    if t.rfind(",") > t.rfind("."):
        t = t.replace(".", "").replace(",", ".")
    else:
        t = t.replace(",", "")
    try:
        return float(t)
    except ValueError:
        return None


FORMATOS = ("%d/%m/%Y", "%m/%d/%Y", "%Y-%m-%d", "%d-%m-%Y")


def para_vencimento(texto):
    if texto is None:
        return None
    t = str(texto).strip()
    if not t:
        return None
    # Ano isolado: assume 31/12, o cenario mais favoravel ao credor.
    if re.fullmatch(r"(19|20)\d{2}", t):
        return date(int(t), 12, 31)
    for f in FORMATOS:
        try:
            return datetime.strptime(t, f).date()
        except ValueError:
            continue
    return None


def anos_depois(d, n):
    """Soma n anos tratando 29/02 sem estourar."""
    try:
        return d.replace(year=d.year + n)
    except ValueError:
        return d.replace(year=d.year + n, day=28)


def get_via(titulo, tem_nf, assinado, vencimento, data_base):
    """Filtro 3: a especie do titulo define a via. Considera tambem a
       prescricao EXECUTIVA curta das cambiais — que nao mata o credito,
       rebaixa a via (cheque 6 meses; NP e duplicata 3 anos)."""
    t = sem_acento(str(titulo or "")).lower()
    assinado_sim = bool(re.match(r"\s*(s|sim|x|true|1)", str(assinado or ""), re.IGNORECASE))
    nf_sim = bool(re.match(r"\s*(s|sim|x|true|1)", str(tem_nf or ""), re.IGNORECASE))
    tem_venc = vencimento is not None

    if re.search(r"acordo|confiss", t):
        return "Execucao (art. 784, III + 4o)"
    if re.search(r"honorar", t):
        return "Execucao (art. 784, XII + art. 24 EAOAB)"

    if "cheque" in t:
        # Lei 7.357/85: 6 meses do fim do prazo de apresentacao (usa 30 dias).
        if tem_venc:
            limite = vencimento.toordinal() + 30
            limite = date.fromordinal(limite)
            try:
                limite = limite.replace(month=limite.month + 6)
            except ValueError:
                limite = limite.replace(year=limite.year + 1, month=limite.month - 6)
            if limite < data_base:
                return "Monitoria (art. 700) — cheque prescrito, Sum. 299/531 STJ"
        return "Execucao (art. 784, I) — conferir prazo de apresentacao"
    if "promiss" in t:
        # LUG: 3 anos do vencimento.
        if tem_venc and anos_depois(vencimento, 3) < data_base:
            return "Monitoria (art. 700) — NP com execucao prescrita (3 anos)"
        return "Execucao (art. 784, I)"
    if "duplicata" in t:
        # Art. 18 da Lei 5.474/68: 3 anos contra o sacado.
        if tem_venc and anos_depois(vencimento, 3) < data_base:
            return "Monitoria (art. 700) — duplicata com execucao prescrita (3 anos)"
        return "Execucao (art. 784, I) — se aceita"
    if "contrato" in t:
        if assinado_sim:
            return "Execucao (art. 784, III)"
        return "Monitoria (art. 700) — contrato sem testemunhas"
    # O titulo declarado manda sobre a coluna "Possui NF?": no acervo ha
    # linhas marcadas NF=SIM cuja pasta so tem boleto.
    if "boleto" in t:
        return "Nenhuma — so boleto. Notificar e protestar"
    if re.search(r"nota fiscal|fatura", t) or t == "nf" or (t == "" and nf_sim):
        if assinado_sim:
            return "Monitoria (art. 700) — NF com canhoto"
        return "Monitoria fragil — notificar antes para suprir canhoto"
    return "Indefinida — apurar especie do titulo"


def brl(v):
    """Formata no padrao BR — ponto de milhar, virgula decimal — igual ao
       ToString('N2') do gemeo em PowerShell."""
    if v is None:
        return ""
    return ("{:,.2f}".format(v)).replace(",", "@").replace(".", ",").replace("@", ".")


def main():
    forcar_utf8()
    ap = argparse.ArgumentParser(description="Triagem de carteira de inadimplentes")
    ap.add_argument("path", help="CSV da carteira (separador ; ou ,)")
    ap.add_argument("--data-base", help="Data de referencia AAAA-MM-DD (padrao: hoje)")
    ap.add_argument("--csv", dest="saida", help="Grava o resultado neste CSV")
    args = ap.parse_args()

    if not os.path.isfile(args.path):
        print("Arquivo nao encontrado: %s" % args.path, file=sys.stderr)
        return 2

    data_base = date.today()
    if args.data_base:
        data_base = datetime.strptime(args.data_base, "%Y-%m-%d").date()

    with open(args.path, "r", encoding="utf-8-sig", newline="") as fh:
        primeira = fh.readline()
        delim = ";" if primeira.count(";") > primeira.count(",") else ","
        fh.seek(0)
        linhas = list(csv.DictReader(fh, delimiter=delim))

    if not linhas:
        print("Planilha vazia ou sem cabecalho.", file=sys.stderr)
        return 2

    colunas = [c for c in linhas[0].keys() if c]
    c_devedor = find_coluna(colunas, ["devedor", "cliente", "nome", "razao"])
    c_venc = find_coluna(colunas, ["vencimento", "venc", "datavenc", "ano"])
    c_principal = find_coluna(colunas, ["principal", "valorprincipal", "nominal", "valor"])
    c_atualizado = find_coluna(colunas, ["atualizado", "comjuros", "juros"])
    c_titulo = find_coluna(colunas, ["titulo", "especie", "documento", "doc"])
    c_nf = find_coluna(colunas, ["possuinf", "nf", "notafiscal"])
    c_assinado = find_coluna(colunas, ["assinado", "canhoto", "docsassinados"])

    achados = []
    if not c_devedor:
        achados.append(achado("ALTA", "Planilha", "Coluna de devedor nao identificada"))
    if not c_venc:
        achados.append(achado("ALTA", "Planilha",
                              "Coluna de vencimento nao identificada — sem ela nao ha calculo de prescricao"))
    if not c_principal:
        achados.append(achado("MEDIA", "Planilha", "Coluna de valor principal nao identificada"))
    if not c_assinado:
        achados.append(achado("MEDIA", "Planilha",
                              "Coluna de documento assinado (canhoto) ausente — o filtro 2 fica inteiramente manual"))

    if not c_devedor or not c_venc:
        return escrever_relatorio(achados, "Triagem de carteira")

    resultado = []
    sem_data = 0

    for linha in linhas:
        devedor = (linha.get(c_devedor) or "").strip()
        if not devedor:
            continue

        venc = para_vencimento(linha.get(c_venc))
        principal = para_valor(linha.get(c_principal)) if c_principal else None
        atualizado = para_valor(linha.get(c_atualizado)) if c_atualizado else None
        titulo = linha.get(c_titulo) if c_titulo else ""
        tem_nf = linha.get(c_nf) if c_nf else ""
        assinado = linha.get(c_assinado) if c_assinado else ""

        via = get_via(titulo, tem_nf, assinado, venc, data_base)

        if venc is None:
            sem_data += 1
            resultado.append(dict(
                Devedor=devedor, Vencimento="", Meses="", Principal=principal,
                Atualizado=atualizado, Status="Triagem", Via=via,
                Observacao="Vencimento nao interpretado — prescricao nao calculada"))
            continue

        limite = anos_depois(venc, 5)
        meses = int((limite - data_base).days // 30.44)

        if limite < data_base:
            status = "Prescrito"
            obs = ("Prescrito em %s, ha %d mes(es) — conferir interrupcao "
                   "(art. 202, VI, do CC) antes de descartar"
                   % (limite.strftime("%d/%m/%Y"), abs(meses)))
        elif meses <= 12:
            status = "Ajuizar"
            obs = "URGENTE: prescreve em %d mes(es), em %s" % (meses, limite.strftime("%d/%m/%Y"))
        elif re.search(r"Nenhuma|fragil|Indefinida", via):
            status = "Triagem" if "Indefinida" in via else "Notificar"
            obs = "Prazo em curso, falta documento habil"
        else:
            status = "Ajuizar"
            obs = "Prazo em curso — prescreve em %s" % limite.strftime("%d/%m/%Y")

        if principal is not None and atualizado is not None and atualizado < principal:
            achados.append(achado(
                "ALTA", "Dado corrompido",
                "%s: valor atualizado menor que o principal — atualizacao nao reduz divida" % devedor,
                "principal %s / atualizado %s" % (brl(principal), brl(atualizado))))
            obs += " | ATUALIZADO < PRINCIPAL: refazer calculo"

        resultado.append(dict(
            Devedor=devedor, Vencimento=limite and venc.strftime("%d/%m/%Y"),
            Meses=meses, Principal=principal, Atualizado=atualizado,
            Status=status, Via=via, Observacao=obs))

    if not resultado:
        print("Nenhuma linha com devedor identificavel.", file=sys.stderr)
        return 2

    # ------------------------------------------------------------- relato
    print("")
    print("=== Triagem de carteira ===")
    print("Arquivo: %s" % os.path.basename(args.path))
    print("Data-base: %s   Registros: %d" % (data_base.strftime("%d/%m/%Y"), len(resultado)))
    print("")

    cab = ("Devedor", "Vencimento", "Meses", "Principal", "Atualizado", "Status", "Via")
    linhas_tab = [(
        r["Devedor"][:34],
        r["Vencimento"],
        "VENCIDO" if isinstance(r["Meses"], int) and r["Meses"] < 0 else str(r["Meses"]),
        brl(r["Principal"]), brl(r["Atualizado"]), r["Status"], r["Via"],
    ) for r in resultado]
    larg = [max(len(cab[i]), max((len(l[i]) for l in linhas_tab), default=0)) for i in range(len(cab))]
    fmt = "  ".join("%-" + str(w) + "s" for w in larg)
    print(fmt % cab)
    print(fmt % tuple("-" * w for w in larg))
    for l in linhas_tab:
        print(fmt % l)

    # ---------------------------------------------------------- agregados
    soma_p = sum(r["Principal"] for r in resultado if r["Principal"] is not None)
    prescritos = [r for r in resultado if r["Status"] == "Prescrito"]
    soma_presc = sum(r["Principal"] for r in prescritos if r["Principal"] is not None)

    print("")
    print("--- Agregados ---")
    for s in ("Ajuizar", "Notificar", "Triagem", "Prescrito"):
        grupo = [r for r in resultado if r["Status"] == s]
        if not grupo:
            continue
        soma = sum(r["Principal"] for r in grupo if r["Principal"] is not None)
        print("  %-10s %4d devedor(es)   R$ %14s" % (s, len(grupo), brl(soma)))
    print("  %-10s %4d                R$ %14s" % ("TOTAL", len(resultado), brl(soma_p)))

    if soma_p > 0 and soma_presc > 0:
        print("")
        pct = ("%0.1f" % (100.0 * soma_presc / soma_p)).replace(".", ",")
        print("PRESCRITO: R$ %s — %s%% do principal da carteira." % (brl(soma_presc), pct))

    urgentes = [r for r in resultado if isinstance(r["Meses"], int) and 0 <= r["Meses"] <= 12]
    if urgentes:
        achados.append(achado(
            "ALTA", "Prescricao iminente",
            "%d devedor(es) prescrevem em 12 meses ou menos — priorizar" % len(urgentes),
            "; ".join(r["Devedor"] for r in urgentes[:8])))
    if sem_data:
        achados.append(achado("MEDIA", "Planilha",
                              "%d linha(s) com vencimento nao interpretado — prescricao nao calculada" % sem_data))
    indef = len([r for r in resultado if "Indefinida" in r["Via"]])
    if indef:
        achados.append(achado("MEDIA", "Filtro 3",
                              "%d linha(s) sem especie de titulo declarada — via indefinida" % indef))

    if args.saida:
        campos = ("Devedor", "Vencimento", "Meses", "Principal", "Atualizado",
                  "Status", "Via", "Observacao")
        with open(args.saida, "w", encoding="utf-8", newline="") as fh:
            w = csv.DictWriter(fh, fieldnames=campos, delimiter=";")
            w.writeheader()
            for r in resultado:
                w.writerow({k: r.get(k, "") for k in campos})
        print("")
        print("Resultado gravado em: %s" % args.saida)

    codigo = escrever_relatorio(achados, "Achados da triagem")
    print("Lembrete: o filtro 2 (canhoto assinado) exige olhar o documento — nenhum script cobre.")
    print('Antes de aceitar "Prescrito", procure pagamento parcial, protesto ou reconhecimento escrito.')
    print("")
    return codigo


if __name__ == "__main__":
    sys.exit(main())
