#!/usr/bin/env python3
"""Confere digito verificador de CPF, CNPJ e numero CNJ.

Equivalente ao validar-identificadores.ps1, para ambiente com Python (Claude na
nuvem, Cowork, Linux, Mac), onde o PowerShell e inerte.

Dois modos:
    --numero  valida um identificador avulso.
    --path    varre a peca e valida todos os CPF, CNPJ e numeros de processo.

Um CPF digitado errado na qualificacao passa por qualquer leitura humana e e
pego por aritmetica. Mesmo vale para o numero CNJ, cujo digito verificador
(modulo 97, ISO 7064) detecta troca ou transposicao de algarismos.

Exemplos:
    python3 validar-identificadores.py --numero 590.619.018-04
    python3 validar-identificadores.py --path inicial.docx
"""

import argparse
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from lib_peca import (achado, escrever_relatorio, forcar_utf8,  # noqa: E402
                      resultado, texto_da_peca)


def so_digitos(s):
    return re.sub(r"\D", "", s)


def testa_cpf(valor):
    d = so_digitos(valor)
    if len(d) != 11:
        return False
    if re.match(r"^(.)\1{10}$", d):        # 111.111.111-11 etc.
        return False
    n = [int(c) for c in d]

    soma = sum(n[i] * (10 - i) for i in range(9))
    r = soma % 11
    dv1 = 0 if r < 2 else 11 - r
    if n[9] != dv1:
        return False

    soma = sum(n[i] * (11 - i) for i in range(10))
    r = soma % 11
    dv2 = 0 if r < 2 else 11 - r
    return n[10] == dv2


def testa_cnpj(valor):
    d = so_digitos(valor)
    if len(d) != 14:
        return False
    if re.match(r"^(.)\1{13}$", d):
        return False
    n = [int(c) for c in d]

    p1 = [5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2]
    soma = sum(n[i] * p1[i] for i in range(12))
    r = soma % 11
    dv1 = 0 if r < 2 else 11 - r
    if n[12] != dv1:
        return False

    p2 = [6, 5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2]
    soma = sum(n[i] * p2[i] for i in range(13))
    r = soma % 11
    dv2 = 0 if r < 2 else 11 - r
    return n[13] == dv2


RX_CNJ = re.compile(r"(\d{7})-(\d{2})\.(\d{4})\.(\d)\.(\d{2})\.(\d{4})")


def testa_cnj(valor):
    """NNNNNNN-DD.AAAA.J.TR.OOOO - Resolucao CNJ 65/2008.
       DV = 98 - ((NNNNNNN AAAA J TR OOOO) * 100 mod 97)"""
    m = RX_CNJ.search(valor)
    if not m:
        return None
    nnn, dd, aaaa, j, tr, oooo = m.groups()
    base = int(nnn + aaaa + j + tr + oooo + "00")
    esperado = "%02d" % (98 - (base % 97))
    return {"ok": esperado == dd, "informado": dd, "esperado": esperado}


def modo_avulso(numero):
    print("")
    d = so_digitos(numero)

    if RX_CNJ.search(numero):
        r = testa_cnj(numero)
        extra = "" if r["ok"] else "(digito informado %s, esperado %s)" % (
            r["informado"], r["esperado"])
        resultado("CNJ", numero, r["ok"], extra)
        print("")
        return 0 if r["ok"] else 1
    if len(d) == 11:
        ok = testa_cpf(numero)
        resultado("CPF", numero, ok)
        print("")
        return 0 if ok else 1
    if len(d) == 14:
        ok = testa_cnpj(numero)
        resultado("CNPJ", numero, ok)
        print("")
        return 0 if ok else 1

    print("  Formato nao reconhecido: %s" % numero)
    print("  Esperado CPF (11), CNPJ (14) ou CNJ (NNNNNNN-DD.AAAA.J.TR.OOOO).")
    print("")
    return 2


def modo_arquivo(path):
    texto = texto_da_peca(path)
    achados = []

    print("")
    print("=== Identificadores: %s ===" % os.path.basename(path))
    print("")

    # Marcacao Markdown no meio da mascara esconde o identificador do regex. Um
    # numero escrito 0001219-15.**2023**.4.01.3901 - para destacar o digito
    # trocado - passava batido, e era justamente o unico invalido da peca.
    texto = re.sub(r"(\*\*|\*|__|_|`|~~)", "", texto)

    cpfs = sorted({m.group(0) for m in
                   re.finditer(r"\b\d{3}\.\d{3}\.\d{3}-\d{2}\b", texto)})
    cnpjs = sorted({m.group(0) for m in
                    re.finditer(r"\b\d{2}\.\d{3}\.\d{3}/\d{4}-\d{2}\b", texto)})
    cnjs = sorted({m.group(0) for m in
                   re.finditer(r"\b\d{7}-\d{2}\.\d{4}\.\d\.\d{2}\.\d{4}\b", texto)})

    for v in cpfs:
        ok = testa_cpf(v)
        resultado("CPF", v, ok)
        if not ok:
            achados.append(achado(
                "ALTA", "CPF",
                "Digito verificador invalido — erro de digitacao na qualificacao", v))
    for v in cnpjs:
        ok = testa_cnpj(v)
        resultado("CNPJ", v, ok)
        if not ok:
            achados.append(achado(
                "ALTA", "CNPJ",
                "Digito verificador invalido — erro de digitacao na qualificacao", v))
    for v in cnjs:
        r = testa_cnj(v)
        extra = "" if r["ok"] else "(informado %s, esperado %s)" % (
            r["informado"], r["esperado"])
        resultado("CNJ", v, r["ok"], extra)
        if not r["ok"]:
            # Sequencia de um digito so (1111111-11.1111.1.11.1111) nao e numero
            # errado: e ruido de OCR ou de codigo de barras, e a analise e
            # obrigada a registra-lo como tal. Marcar ALTA aqui bloqueava a
            # entrega por citacao deliberada.
            if re.match(r"^(.)\1{19}$", so_digitos(v)):
                achados.append(achado(
                    "BAIXA", "Processo",
                    "Sequencia de digito unico: ruido de OCR ou de codigo de "
                    "barras, nao numero de processo", v))
            else:
                achados.append(achado(
                    "ALTA", "Processo",
                    "Numero CNJ com digito verificador invalido "
                    "(informado %s, esperado %s)" % (r["informado"], r["esperado"]),
                    v))

    total = len(cpfs) + len(cnpjs) + len(cnjs)
    if total == 0:
        print("  Nenhum CPF, CNPJ ou numero CNJ localizado na peca.")
        print("  Se a peca qualifica partes, isso por si so ja e um problema.")

    return escrever_relatorio(
        achados, "Resumo (%d identificador(es) conferido(s))" % total)


def main():
    forcar_utf8()
    ap = argparse.ArgumentParser(
        description="Confere digito verificador de CPF, CNPJ e numero CNJ.")
    g = ap.add_mutually_exclusive_group(required=True)
    g.add_argument("--numero", help="validar um identificador avulso")
    g.add_argument("--path", help="varrer uma peca (.docx, .md, .txt, .htm)")
    args = ap.parse_args()

    if args.numero:
        return modo_avulso(args.numero)
    return modo_arquivo(args.path)


if __name__ == "__main__":
    sys.exit(main())
