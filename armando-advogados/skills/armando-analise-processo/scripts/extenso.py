#!/usr/bin/env python3
"""Valor por extenso em portugues e conferencia dos pares "R$ X (extenso)".

Equivalente ao extenso.ps1, para ambiente com Python (Claude na nuvem, Cowork,
Linux, Mac), onde o PowerShell e inerte.

Dois modos:
    --valor  gera o extenso de um valor.
    --path   varre a peca e confere se cada "R$ 13.173,13 (treze mil...)" bate.

O padrao do escritorio exige algarismo seguido do extenso entre parenteses em
todo valor. Este script pega o extenso que sobrou de uma versao anterior do
calculo - o erro mais provavel ao reaproveitar peca.

Exemplos:
    python3 extenso.py --valor 13173.13
    python3 extenso.py --path inicial.docx
"""

import argparse
import os
import re
import sys
from decimal import Decimal, ROUND_HALF_UP

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from lib_peca import (achado, escrever_relatorio, forcar_utf8,  # noqa: E402
                      sem_acento, texto_da_peca)

UNI = ["", "um", "dois", "tres", "quatro", "cinco", "seis", "sete", "oito", "nove",
       "dez", "onze", "doze", "treze", "quatorze", "quinze", "dezesseis",
       "dezessete", "dezoito", "dezenove"]
DEZ = ["", "", "vinte", "trinta", "quarenta", "cinquenta", "sessenta", "setenta",
       "oitenta", "noventa"]
CEN = ["", "cento", "duzentos", "trezentos", "quatrocentos", "quinhentos",
       "seiscentos", "setecentos", "oitocentos", "novecentos"]


def extenso_grupo(n):
    """1 a 999 por extenso."""
    if n == 0:
        return ""
    if n == 100:
        return "cem"
    partes = []
    c, resto = divmod(n, 100)
    if c > 0:
        partes.append(CEN[c])
    if resto > 0:
        if resto < 20:
            partes.append(UNI[resto])
        else:
            d, u = divmod(resto, 10)
            partes.append(DEZ[d] if u == 0 else (DEZ[d] + " e " + UNI[u]))
    return " e ".join(partes)


def extenso_inteiro(n):
    """0 a 999.999.999.999 por extenso, sem moeda."""
    if n == 0:
        return "zero"

    escalas = [(1000000000, "bilhao", "bilhoes"),
               (1000000, "milhao", "milhoes"),
               (1000, "mil", "mil")]

    blocos = []
    rest = n
    for valor, sing, plur in escalas:
        q = rest // valor
        if q > 0:
            txt = extenso_grupo(int(q))
            if sing == "mil":
                blocos.append("mil" if q == 1 else (txt + " mil"))
            else:
                blocos.append(("um " + sing) if q == 1 else (txt + " " + plur))
            rest = rest % valor

    if rest > 0:
        blocos.append(extenso_grupo(int(rest)))

    # Regra do "e": liga o ultimo bloco quando ele e menor que 100 ou centena redonda.
    if len(blocos) == 1:
        return blocos[0]
    cabeca = ", ".join(blocos[:-1])
    if rest > 0 and (rest < 100 or rest % 100 == 0):
        return cabeca + " e " + blocos[-1]
    return re.sub(r",\s*$", "", cabeca + ", " + blocos[-1])


def extenso(v, puro=False):
    """Valor monetario por extenso, no formato do escritorio."""
    v = Decimal(v)
    neg = v < 0
    if neg:
        v = -v

    inteiro = int(v)
    cent = int((v - inteiro).scaleb(2).quantize(Decimal("1"), rounding=ROUND_HALF_UP))
    if cent == 100:
        inteiro += 1
        cent = 0

    if puro:
        return extenso_inteiro(inteiro)

    partes = []
    if inteiro > 0 or cent == 0:
        partes.append(extenso_inteiro(inteiro) +
                      (" real" if inteiro == 1 else " reais"))
    if cent > 0:
        partes.append(extenso_inteiro(cent) +
                      (" centavo" if cent == 1 else " centavos"))

    txt = " e ".join(partes)
    return ("menos " + txt) if neg else txt


VARIANTES = [
    (r"\bum mil\b", "mil"),          # "um mil duzentos" == "mil duzentos"
    (r"\bcatorze\b", "quatorze"),
    (r"\bseiscentas\b", "seiscentos"),
    (r"\bduzentas\b", "duzentos"),
    (r"\btrezentas\b", "trezentos"),
    (r"\bquatrocentas\b", "quatrocentos"),
    (r"\bquinhentas\b", "quinhentos"),
    (r"\bsetecentas\b", "setecentos"),
    (r"\boitocentas\b", "oitocentos"),
    (r"\bnovecentas\b", "novecentos"),
    (r"\bduas\b", "dois"),
    (r"\buma\b", "um"),
]


def comparavel(s):
    """Normaliza para comparar: minusculas, sem acento, sem pontuacao."""
    if not s:
        return ""
    t = sem_acento(s.lower())
    t = re.sub(r"[^a-z0-9 ]", " ", t)
    t = re.sub(r"\s+", " ", t)
    for rx, sub in VARIANTES:      # variantes igualmente corretas
        t = re.sub(rx, sub, t)
    return t.strip()


def formata_br(v):
    s = "{:,.2f}".format(Decimal(v))
    return s.replace(",", "@").replace(".", ",").replace("@", ".")


RX_PAR = re.compile(r"R\$\s*([\d\.]+,\d{2}|\d+)\s*\(([^\)]{3,220})\)")
RX_EH_EXTENSO = re.compile(
    r"(real|reais|centavo|mil|milh|bilh|zero|um|dois|tres|tr[eê]s)", re.I)
RX_GLOSADO = re.compile(r"(real|reais|centavo|mil|milh|bilh)", re.I)


def conferir(path):
    texto = texto_da_peca(path)
    achados = []

    # Pares "R$ 1.234,56 (extenso)" - o extenso pode atravessar quebra de linha.
    plano = re.sub(r"\s+", " ", texto)
    pares = list(RX_PAR.finditer(plano))

    conferidos = 0
    for m in pares:
        num_txt, ext_txt = m.group(1), m.group(2)
        # Ignora parenteses que nao sao extenso (ex.: "R$ 100,00 (doc. 5)").
        if not RX_EH_EXTENSO.search(ext_txt):
            continue
        limpo = num_txt.replace(".", "").replace(",", ".")
        try:
            v = Decimal(limpo)
        except Exception:
            continue
        conferidos += 1

        esperado = extenso(v)
        a, b = comparavel(esperado), comparavel(ext_txt)
        if a != b:
            # Tolera ausencia da conjuncao "e" e virgulas de separacao.
            a2 = re.sub(r"\s+", " ", re.sub(r"\be\b", "", a)).strip()
            b2 = re.sub(r"\s+", " ", re.sub(r"\be\b", "", b)).strip()
            if a2 != b2:
                achados.append(achado(
                    "ALTA", "Extenso",
                    "R$ %s nao confere com o extenso escrito" % num_txt,
                    "escrito:  %s\n      > esperado: %s"
                    % (ext_txt.strip(), esperado)))

    # Valores sem extenso nenhum.
    #
    # Duas ressalvas, aprendidas em uso real:
    #   1. Linha de tabela Markdown (comeca por '|') fica de fora. Extenso em cada
    #      celula de uma tabela "Item | Valor" destroi a tabela, e o padrao da casa
    #      autoriza essa tabela. Em .docx nao ha pipe, entao a peca nao e afetada.
    #   2. O padrao exige o extenso na PRIMEIRA aparicao do valor, nao em todas. Se
    #      o valor ja aparece glosado em algum lugar, a repeticao nua nao e defeito.
    #      Sem isso o achado MEDIA vira permanente e treina o leitor a ignorar.
    # O (?![\d,]) evita casar o pedaco "R$ 983,03" de um valor malformado.
    sem_tabela = " ".join(ln for ln in texto.splitlines()
                          if not re.match(r"^\s*\|", ln))
    sem_tabela = re.sub(r"\s+", " ", sem_tabela)

    ja_glosados = set()
    for m in pares:
        if RX_GLOSADO.search(m.group(2)):
            ja_glosados.add(re.sub(r"\s", "", m.group(1)))

    pendentes = sorted({
        m.group(0) for m in re.finditer(r"R\$\s*([\d\.]+,\d{2})(?![\d,])(?!\s*\()",
                                        sem_tabela)
        if re.sub(r"\s", "", m.group(1)) not in ja_glosados})

    if pendentes:
        achados.append(achado(
            "MEDIA", "Extenso",
            "%d valor(es) sem extenso em nenhuma ocorrencia — o padrao da casa "
            "exige na primeira" % len(pendentes),
            "   ".join(pendentes)))

    # Formato numerico errado: R$ 983,032,00
    for mm in re.finditer(r"R\$\s*\d+,\d{3},\d{2}", plano):
        achados.append(achado(
            "ALTA", "Formato",
            "Valor com virgula no lugar do separador de milhar", mm.group(0)))

    titulo = "Extenso: %s (%d par(es) conferido(s))" % (
        os.path.basename(path), conferidos)
    return escrever_relatorio(achados, titulo)


def main():
    forcar_utf8()
    ap = argparse.ArgumentParser(
        description="Valor por extenso e conferencia dos pares R$ X (extenso).")
    g = ap.add_mutually_exclusive_group(required=True)
    g.add_argument("--valor", help="gerar o extenso deste valor (ex.: 13173.13)")
    g.add_argument("--path", help="conferir os pares R$/extenso desta peca")
    ap.add_argument("--sem-moeda", action="store_true", dest="sem_moeda",
                    help="com --valor, sair sem 'reais'/'centavos'")
    args = ap.parse_args()

    if args.valor is not None:
        try:
            v = Decimal(args.valor.replace(".", "").replace(",", ".")
                        if re.search(r",\d{1,2}$", args.valor) else args.valor)
        except Exception:
            print("Valor invalido: %s" % args.valor)
            return 2
        ext = extenso(v, puro=args.sem_moeda)
        print(ext if args.sem_moeda else "R$ %s (%s)" % (formata_br(v), ext))
        return 0

    return conferir(args.path)


if __name__ == "__main__":
    sys.exit(main())
