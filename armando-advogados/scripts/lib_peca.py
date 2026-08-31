#!/usr/bin/env python3
"""Funcoes comuns aos scripts de revisao de peca, em Python.

Equivalente ao lib-peca.ps1. Carregado por extenso.py e
validar-identificadores.py.

Existe porque os scripts em PowerShell sao inertes fora do Windows: na nuvem,
no Cowork e em Linux as secoes 2 e 9 da armando-analise-processo ficavam
inteiramente sem efeito.
"""

import io
import os
import re
import sys
import unicodedata
import zipfile

ORDEM_SEV = {"ALTA": 0, "MEDIA": 1, "BAIXA": 2}


def texto_da_peca(path):
    """Le .docx, .md, .txt ou .htm e devolve o texto corrido.

    No .docx, cada </w:p> vira quebra de linha, para preservar paragrafos.
    """
    if not os.path.exists(path):
        raise IOError("Arquivo nao encontrado: %s" % path)

    ext = os.path.splitext(path)[1].lower()

    if ext == ".docx":
        with zipfile.ZipFile(path) as z:
            if "word/document.xml" not in z.namelist():
                raise IOError("docx sem word/document.xml: %s" % path)
            xml = z.read("word/document.xml").decode("utf-8", "replace")
        xml = xml.replace("</w:p>", "\n")
        xml = re.sub(r"<w:br[^>]*/>", "\n", xml)
        xml = re.sub(r"<w:tab[^>]*/>", "\t", xml)
        txt = re.sub(r"<[^>]+>", "", xml)
        for a, b in (("&amp;", "&"), ("&lt;", "<"), ("&gt;", ">"),
                     ("&quot;", '"'), ("&apos;", "'")):
            txt = txt.replace(a, b)
        return txt

    with io.open(path, encoding="utf-8-sig", errors="replace") as fh:
        return fh.read()


def sem_acento(s):
    """Tira acento e cedilha, preservando a caixa."""
    if not s:
        return ""
    d = unicodedata.normalize("NFD", s)
    return "".join(c for c in d if unicodedata.category(c) != "Mn")


def achado(severidade, categoria, mensagem, trecho=""):
    """Constroi um achado padronizado. Severidade: ALTA, MEDIA, BAIXA."""
    return {"severidade": severidade, "categoria": categoria,
            "mensagem": mensagem, "trecho": trecho}


def resultado(tipo, valor, ok, extra=""):
    """Linha OK/ERRO de um identificador conferido."""
    print("  %-5s %-6s %s %s" % ("OK" if ok else "ERRO", tipo, valor, extra))


def escrever_relatorio(achados, titulo="Revisao"):
    """Imprime os achados agrupados por severidade e devolve o codigo de saida
       sugerido: 1 se houver ALTA, 0 nos demais casos."""
    print("")
    print("=== %s ===" % titulo)

    if not achados:
        print("Nenhum problema encontrado.")
        print("")
        return 0

    for sev in ("ALTA", "MEDIA", "BAIXA"):
        do_nivel = [a for a in achados if a["severidade"] == sev]
        if not do_nivel:
            continue
        print("")
        print("[%s] %d achado(s)" % (sev, len(do_nivel)))
        for a in do_nivel:
            print("  - %s: %s" % (a["categoria"], a["mensagem"]))
            if a["trecho"]:
                print("      > %s" % a["trecho"])

    altas = len([a for a in achados if a["severidade"] == "ALTA"])
    print("")
    if altas:
        print("NAO PROTOCOLAR: %d item(ns) de severidade ALTA." % altas)
        print("")
        return 1
    print("Sem impeditivo de severidade ALTA. Confira os demais itens.")
    print("")
    return 0


def forcar_utf8():
    """Windows console engole acento; na nuvem nao ha problema. Uniformiza."""
    for fluxo in (sys.stdout, sys.stderr):
        try:
            fluxo.reconfigure(encoding="utf-8", errors="replace")
        except Exception:
            pass
