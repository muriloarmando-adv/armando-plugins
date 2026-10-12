#!/usr/bin/env python3
"""Monta o MOU a partir do rascunho com marcadores.

Numera capitulos e clausulas, resolve remissoes e escreve valores com
algarismo e extenso. O rascunho e um .md comum, com estas marcas:

  %% comentario                      -> some na saida
  # CAP chave | TITULO DO CAPITULO   -> "**3. TITULO DO CAPITULO**"
  #. {chave} texto                   -> "**3.1.** texto"     (chave opcional)
  ##. {chave} texto                  -> "**3.1.1.** texto"
  ###. {chave} texto                 -> "**3.1.1.1.** texto"
  (i) texto  -- nos considerandos     -> numerado de novo em romano minusculo

  {ref:chave}  -> "cláusula 3.1"   {Ref:chave} -> "Cláusula 3.1"
  {cap:chave}  -> "Capítulo 3"     {Cap:chave} -> "Capítulo 3"
  {num:chave}  -> "3.1" (ou "3", se a chave for de capitulo)
  {rs:1500000,00}  -> "R$ 1.500.000,00 (um milhão e quinhentos mil reais)"
  {n:60}       -> "60 (sessenta)"      {nf:2} -> "2 (duas)"  (feminino)
  {qt:5100000} -> "5.100.000 (cinco milhões e cem mil)"  (quotas, feminino)
  {pct:50}     -> "50% (cinquenta por cento)"
  {fr:1/4}     -> "1/4 (um quarto)"

Campo que ainda falta vai entre [[ ]] e passa intacto -- a conferencia o
acusa. Com erro de marcador (chave repetida, remissao a chave inexistente),
nada e gravado e a saida e 1.

Uso:  python3 montar_mou.py rascunho.mou.md [--saida mou.md] [--forcar]
"""

import argparse
import io
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from lib_mou import (forcar_utf8, rs, qt, fmt_int, fmt_pct, inteiro_extenso,  # noqa: E402
                     para_decimal, fracao_extenso, romano)

RE_CAP = re.compile(r"^#\s+CAP\s+([\w\-]+)\s*\|\s*(.+?)\s*$")
RE_CLA = re.compile(r"^(#{1,3})\.\s+(?:\{([\w\-]+)\}\s*)?(.*)$")
RE_CONS = re.compile(r"^(\**)\(([ivxlc]+)\)(\**)\s+", re.I)
RE_MARCA = re.compile(r"\{(ref|Ref|cap|Cap|num|rs|n|nf|qt|pct|fr):([^}]+)\}")


def montar(linhas):
    erros, avisos = [], []
    chaves = {}          # chave -> ("cap"|"cla", numero str)
    saida_bruta = []     # (tipo, conteudo)
    cap = 0
    pilha = []           # contadores por nivel dentro do capitulo
    em_considerandos = False
    n_cons = 0

    for i, linha in enumerate(linhas, 1):
        if linha.lstrip().startswith("%%"):
            continue
        m = RE_CAP.match(linha)
        if m:
            chave, titulo = m.groups()
            cap += 1
            pilha = [0]
            em_considerandos = False
            if chave in chaves:
                erros.append(f"linha {i}: chave '{chave}' repetida")
            chaves[chave] = ("cap", str(cap))
            saida_bruta.append(("txt", f"**{cap}. {titulo.upper()}**"))
            continue
        m = RE_CLA.match(linha)
        if m:
            nivel = len(m.group(1))
            chave, texto = m.group(2), m.group(3)
            if not cap:
                erros.append(f"linha {i}: cláusula antes do primeiro '# CAP'")
                continue
            if nivel > len(pilha):
                if nivel > len(pilha) + 1 or pilha[-1] == 0:
                    erros.append(f"linha {i}: nível {nivel} sem cláusula-mãe")
                    continue
                pilha.append(0)
            else:
                del pilha[nivel:]
            pilha[nivel - 1] += 1
            numero = ".".join([str(cap)] + [str(x) for x in pilha[:nivel]])
            if chave:
                if chave in chaves:
                    erros.append(f"linha {i}: chave '{chave}' repetida")
                chaves[chave] = ("cla", numero)
            saida_bruta.append(("txt", f"**{numero}.** {texto}".rstrip()))
            continue
        if re.match(r"^\**\s*CONSIDERANDO", linha, re.I):
            em_considerandos = True
            n_cons = 0
        elif em_considerandos and re.match(r"^\**\s*Com base", linha, re.I):
            em_considerandos = False
        if em_considerandos:
            mc = RE_CONS.match(linha)
            if mc:
                n_cons += 1
                linha = (f"{mc.group(1)}({romano(n_cons).lower()}){mc.group(3)} "
                         + linha[mc.end():])
        saida_bruta.append(("txt", linha))

    def resolver(m):
        tipo, arg = m.group(1), m.group(2).strip()
        try:
            if tipo in ("ref", "Ref", "cap", "Cap", "num"):
                if arg not in chaves:
                    erros.append(f"remissão a chave inexistente: {{{tipo}:{arg}}}")
                    return m.group(0)
                k, numero = chaves[arg]
                if tipo == "num":
                    return numero
                if tipo in ("cap", "Cap"):
                    if k != "cap":
                        erros.append(f"{{{tipo}:{arg}}} aponta para cláusula, não capítulo")
                    return "Capítulo " + numero.split(".")[0]
                if k == "cap":
                    avisos.append(f"{{{tipo}:{arg}}} aponta para capítulo; "
                                  "usei 'Capítulo'")
                    return "Capítulo " + numero
                return ("Cláusula " if tipo == "Ref" else "cláusula ") + numero
            if tipo == "rs":
                return rs(para_decimal(arg))
            if tipo in ("n", "nf"):
                v = int(arg.replace(".", ""))
                return f"{fmt_int(v)} ({inteiro_extenso(v, fem=(tipo == 'nf'))})"
            if tipo == "qt":
                return qt(int(arg.replace(".", "")))
            if tipo == "pct":
                p = para_decimal(arg)
                inteiro = int(p)
                if p == inteiro:
                    ext = inteiro_extenso(inteiro)
                else:
                    dec = str(p).split(".")[1].rstrip("0")
                    ext = f"{inteiro_extenso(inteiro)} vírgula {inteiro_extenso(int(dec))}"
                return f"{fmt_pct(p)} ({ext} por cento)"
            if tipo == "fr":
                a, b = [int(x) for x in arg.split("/")]
                return f"{a}/{b} ({fracao_extenso(a, b)})"
        except (ValueError, ArithmeticError) as e:
            erros.append(f"marcador inválido {m.group(0)}: {e}")
            return m.group(0)
        return m.group(0)

    saida = [RE_MARCA.sub(resolver, c) for _, c in saida_bruta]
    # Linhas em branco repetidas viram uma so.
    limpo = []
    for s in saida:
        if s.strip() == "" and limpo and limpo[-1].strip() == "":
            continue
        limpo.append(s)
    sobras = [s for s in limpo if re.search(r"^#{1,3}\.|^#\s+CAP\b", s)]
    for s in sobras:
        erros.append(f"marcador mal formado: {s[:60]}")
    return "\n".join(limpo).strip() + "\n", erros, avisos


def main():
    forcar_utf8()
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("rascunho")
    ap.add_argument("--saida")
    ap.add_argument("--forcar", action="store_true",
                    help="grava mesmo com erro (só para inspecionar)")
    a = ap.parse_args()
    with io.open(a.rascunho, encoding="utf-8-sig") as f:
        linhas = f.read().split("\n")
    texto, erros, avisos = montar(linhas)
    for av in avisos:
        print("AVISO  ", av)
    for e in erros:
        print("ERRO   ", e)
    saida = a.saida or re.sub(r"(\.mou)?\.md$", "", a.rascunho) + ".md"
    if saida == a.rascunho:
        saida = a.rascunho[:-3] + "-montado.md"
    if erros and not a.forcar:
        print(f"\n{len(erros)} erro(s): nada gravado. Corrija o rascunho.")
        return 1
    with io.open(saida, "w", encoding="utf-8") as f:
        f.write(texto)
    print(f"gravado: {saida}")
    print("próximo passo: conferir_mou.py " + saida)
    return 1 if erros else 0


if __name__ == "__main__":
    sys.exit(main())
