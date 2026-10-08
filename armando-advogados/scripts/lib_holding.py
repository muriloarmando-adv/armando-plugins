#!/usr/bin/env python3
"""Biblioteca da skill armando-holding-empresarial.

Extenso (masculino para reais, feminino para quotas), formatacao brasileira,
leitura de .docx/.md/.txt e o motor de modelos com numeracao automatica de
clausulas e capitulos.

So biblioteca padrao: roda no chat (Linux, python3) e no Windows (python).
"""

import io
import re
import sys
import unicodedata
import zipfile
from decimal import Decimal, ROUND_HALF_UP


def forcar_utf8():
    for nome in ("stdout", "stderr"):
        fluxo = getattr(sys, nome)
        if hasattr(fluxo, "reconfigure"):
            try:
                fluxo.reconfigure(encoding="utf-8")
            except Exception:
                pass


# ----------------------------------------------------------------- extenso ---

_UNI_M = ["", "um", "dois", "três", "quatro", "cinco", "seis", "sete", "oito", "nove",
          "dez", "onze", "doze", "treze", "quatorze", "quinze", "dezesseis",
          "dezessete", "dezoito", "dezenove"]
_UNI_F = ["", "uma", "duas"] + _UNI_M[3:]
_DEZ = ["", "", "vinte", "trinta", "quarenta", "cinquenta", "sessenta", "setenta",
        "oitenta", "noventa"]
_CEN_M = ["", "cento", "duzentos", "trezentos", "quatrocentos", "quinhentos",
          "seiscentos", "setecentos", "oitocentos", "novecentos"]
_CEN_F = ["", "cento", "duzentas", "trezentas", "quatrocentas", "quinhentas",
          "seiscentas", "setecentas", "oitocentas", "novecentas"]
_ESCALAS = [("", ""), ("mil", "mil"), ("milhão", "milhões"), ("bilhão", "bilhões"),
            ("trilhão", "trilhões")]


def _grupo(n, fem):
    """1 a 999 por extenso."""
    if n == 0:
        return ""
    if n == 100:
        return "cem"
    uni = _UNI_F if fem else _UNI_M
    cen = _CEN_F if fem else _CEN_M
    c, r = divmod(n, 100)
    partes = []
    if c:
        partes.append(cen[c])
    if r:
        if r < 20:
            partes.append(uni[r])
        else:
            d, u = divmod(r, 10)
            partes.append(_DEZ[d] + (" e " + uni[u] if u else ""))
    return " e ".join(partes)


def inteiro_extenso(n, fem=False):
    """Inteiro por extenso. fem=True concorda com substantivo feminino
    ("duzentas e uma mil quotas"); milhao/bilhao continuam masculinos."""
    n = int(n)
    if n < 0:
        return "menos " + inteiro_extenso(-n, fem)
    if n == 0:
        return "zero"
    grupos = []
    while n:
        n, g = divmod(n, 1000)
        grupos.append(g)
    if len(grupos) > len(_ESCALAS):
        raise ValueError("valor fora da faixa do extenso")
    partes = []
    for i in range(len(grupos) - 1, -1, -1):
        v = grupos[i]
        if not v:
            continue
        # Grupos de unidade e de milhar concordam com o substantivo; os de
        # milhao em diante concordam com "milhao" (masculino).
        g_fem = fem and i <= 1
        if i == 0:
            txt = _grupo(v, g_fem)
        elif i == 1:
            txt = "mil" if v == 1 else _grupo(v, g_fem) + " mil"
        else:
            sing, plur = _ESCALAS[i]
            txt = ("um " + sing) if v == 1 else (_grupo(v, False) + " " + plur)
        partes.append((txt, v))
    saida = partes[0][0]
    for k in range(1, len(partes)):
        txt, v = partes[k]
        ultimo = k == len(partes) - 1
        if ultimo and (v < 100 or v % 100 == 0):
            saida += " e " + txt
        else:
            saida += ", " + txt
    return saida


def reais_extenso(valor):
    """Valor em reais por extenso: "dez milhões de reais", "um real",
    "mil e quinhentos reais e dez centavos"."""
    v = Decimal(str(valor)).quantize(Decimal("0.01"), rounding=ROUND_HALF_UP)
    neg = v < 0
    v = abs(v)
    inteiro = int(v)
    cent = int((v - inteiro) * 100)
    partes = []
    if inteiro or not cent:
        ext = inteiro_extenso(inteiro)
        if inteiro == 1:
            unid = "real"
        elif inteiro >= 1_000_000 and inteiro % 1_000_000 == 0:
            unid = "de reais"
        else:
            unid = "reais"
        partes.append(ext + " " + unid)
    if cent:
        partes.append(inteiro_extenso(cent) + (" centavo" if cent == 1 else " centavos"))
    r = " e ".join(partes)
    return ("menos " + r) if neg else r


def chave_extenso(s):
    """Normaliza extenso para comparar valor: sem acento, sem pontuacao, sem
    "e", e com o feminino rebaixado ao masculino."""
    s = sem_acento(s or "").lower()
    s = re.sub(r"[^a-z0-9]+", " ", s)
    trocas = {"uma": "um", "duas": "dois", "duzentas": "duzentos", "trezentas": "trezentos",
              "quatrocentas": "quatrocentos", "quinhentas": "quinhentos",
              "seiscentas": "seiscentos", "setecentas": "setecentos",
              "oitocentas": "oitocentos", "novecentas": "novecentos", "de": ""}
    toks = [trocas.get(t, t) for t in s.split() if t != "e"]
    return " ".join(t for t in toks if t)


# -------------------------------------------------------------- formatacao ---

def fmt_real(v):
    v = Decimal(str(v)).quantize(Decimal("0.01"), rounding=ROUND_HALF_UP)
    inteiro, dec = f"{v:.2f}".split(".")
    neg = inteiro.startswith("-")
    inteiro = inteiro.lstrip("-")
    grupos = []
    while inteiro:
        grupos.insert(0, inteiro[-3:])
        inteiro = inteiro[:-3]
    return ("-" if neg else "") + ".".join(grupos) + "," + dec


def fmt_int(n):
    return fmt_real(n).split(",")[0]


def fmt_pct(p):
    p = Decimal(str(p)).quantize(Decimal("0.01"), rounding=ROUND_HALF_UP)
    if p == p.to_integral():
        return f"{int(p)}%"
    return f"{p:.2f}".replace(".", ",") + "%"


def rs(v):
    """'R$ 1.000,00 (mil reais)'."""
    return f"R$ {fmt_real(v)} ({reais_extenso(v)})"


def qt(n, fem=True):
    """'10.025.500 (dez milhões, vinte e cinco mil e quinhentas)'."""
    return f"{fmt_int(n)} ({inteiro_extenso(n, fem=fem)})"


def para_decimal(v):
    if v is None or v == "":
        return None
    if isinstance(v, (int, float, Decimal)):
        return Decimal(str(v))
    s = str(v).strip().replace("R$", "").strip()
    if "," in s:
        s = s.replace(".", "").replace(",", ".")
    return Decimal(s)


_ORD = ["", "PRIMEIRA", "SEGUNDA", "TERCEIRA", "QUARTA", "QUINTA", "SEXTA", "SÉTIMA",
        "OITAVA", "NONA", "DÉCIMA", "DÉCIMA PRIMEIRA", "DÉCIMA SEGUNDA", "DÉCIMA TERCEIRA",
        "DÉCIMA QUARTA", "DÉCIMA QUINTA", "DÉCIMA SEXTA", "DÉCIMA SÉTIMA", "DÉCIMA OITAVA",
        "DÉCIMA NONA", "VIGÉSIMA"]


def ordinal_extenso(n):
    return _ORD[n] if 0 < n < len(_ORD) else f"{n}ª"


def romano(n):
    tab = [(1000, "M"), (900, "CM"), (500, "D"), (400, "CD"), (100, "C"), (90, "XC"),
           (50, "L"), (40, "XL"), (10, "X"), (9, "IX"), (5, "V"), (4, "IV"), (1, "I")]
    s = ""
    for v, r in tab:
        while n >= v:
            s += r
            n -= v
    return s


def de_romano(s):
    val = {"I": 1, "V": 5, "X": 10, "L": 50, "C": 100, "D": 500, "M": 1000}
    total, ant = 0, 0
    for ch in reversed(s.upper()):
        v = val.get(ch, 0)
        total = total - v if v < ant else total + v
        ant = max(ant, v)
    return total


def sem_acento(s):
    return "".join(c for c in unicodedata.normalize("NFD", s)
                   if unicodedata.category(c) != "Mn")


def slug(s):
    s = sem_acento(s).lower()
    s = re.sub(r"[^a-z0-9]+", "-", s).strip("-")
    return s[:60] or "sem-nome"


# ------------------------------------------------------------------ leitura ---

def texto_do_arquivo(caminho):
    """Texto de .docx (paragrafos e celulas de tabela), .md ou .txt."""
    if caminho.lower().endswith(".docx"):
        with zipfile.ZipFile(caminho) as z:
            xml = z.read("word/document.xml").decode("utf-8")
        xml = re.sub(r"<w:tab/>", "\t", xml)
        xml = re.sub(r"<w:br[^>]*/>", "\n", xml)
        xml = re.sub(r"</w:p>", "\n", xml)
        xml = re.sub(r"</w:tc>", " | ", xml)
        txt = re.sub(r"<[^>]+>", "", xml)
        import html
        return html.unescape(txt)
    with io.open(caminho, encoding="utf-8-sig") as f:
        return f.read()


# ------------------------------------------------------- motor de modelos ---
#
# Sintaxe dos arquivos em assets/:
#   %% comentario                      -> ignorado
#   # CAPITULO chave | TITULO          -> abre capitulo (numerado em romano)
#   # CLAUSULA chave                   -> abre clausula (numeracao continua)
#   [[se:cond]] ... [[senao]] ... [[fim]]  -> bloco condicional (em linha propria)
#   {VAR}                              -> variavel calculada pelo gerador
#   {ref:chave}                        -> "Cláusula 14ª"
#   {cap:chave}                        -> "Capítulo XVII"
#
# A numeracao nunca e digitada: remissao quebrada e capitulo pulado, os dois
# defeitos do modelo de origem, ficam impossiveis por construcao.

class ErroModelo(Exception):
    pass


def _aplicar_condicionais(linhas, conds):
    saida, pilha = [], []  # pilha de (ativo_pai, cond_verdadeira, no_senao)
    ativo = True
    for ln in linhas:
        s = ln.strip()
        m = re.fullmatch(r"\[\[se:(!?)([\w-]+)\]\]", s)
        if m:
            neg, nome = m.group(1) == "!", m.group(2)
            if nome not in conds:
                raise ErroModelo(f"condição desconhecida no modelo: {nome}")
            val = bool(conds[nome]) != neg
            pilha.append((ativo, val))
            ativo = ativo and val
            continue
        if s == "[[senao]]":
            if not pilha:
                raise ErroModelo("[[senao]] sem [[se]]")
            pai, val = pilha[-1]
            ativo = pai and not val
            continue
        if s == "[[fim]]":
            if not pilha:
                raise ErroModelo("[[fim]] sem [[se]]")
            ativo = pilha.pop()[0]
            continue
        if ativo:
            saida.append(ln)
    if pilha:
        raise ErroModelo("[[se]] sem [[fim]]")
    return saida


def renderizar(modelo, variaveis, conds, rotulo_clausula="CLÁUSULA {n}ª –",
               formato_ref="Cláusula {n}ª"):
    """Devolve (markdown, mapa_clausulas, mapa_capitulos)."""
    linhas = [l for l in modelo.splitlines() if not l.lstrip().startswith("%%")]
    linhas = _aplicar_condicionais(linhas, conds)

    # 1a passada: numerar
    num_cl, num_cap = {}, {}
    n_cl = n_cap = 0
    for ln in linhas:
        m = re.match(r"#\s*CLAUSULA\s+([\w-]+)\s*$", ln)
        if m:
            n_cl += 1
            if m.group(1) in num_cl:
                raise ErroModelo(f"cláusula duplicada no modelo: {m.group(1)}")
            num_cl[m.group(1)] = n_cl
            continue
        m = re.match(r"#\s*CAPITULO\s+([\w-]+)\s*\|\s*(.+)$", ln)
        if m:
            n_cap += 1
            num_cap[m.group(1)] = n_cap

    def resolver(texto):
        def r_ref(m):
            k = m.group(1)
            if k not in num_cl:
                raise ErroModelo(f"remissão a cláusula inexistente: {k}")
            n = num_cl[k]
            return formato_ref.format(n=n, ext=ordinal_extenso(n).title())

        def r_cap(m):
            k = m.group(1)
            if k not in num_cap:
                raise ErroModelo(f"remissão a capítulo inexistente: {k}")
            return f"Capítulo {romano(num_cap[k])}"

        texto = re.sub(r"\{ref:([\w-]+)\}", r_ref, texto)
        texto = re.sub(r"\{cap:([\w-]+)\}", r_cap, texto)

        def r_var(m):
            k = m.group(1)
            if k not in variaveis:
                raise ErroModelo(f"variável sem valor: {k}")
            return str(variaveis[k])

        return re.sub(r"\{([A-Z][A-Z0-9_]*)\}", r_var, texto)

    # 2a passada: montar
    out, prefixo = [], None
    for ln in linhas:
        m = re.match(r"#\s*CLAUSULA\s+([\w-]+)\s*$", ln)
        if m:
            prefixo = "**" + rotulo_clausula.format(n=num_cl[m.group(1)],
                                                    ext=ordinal_extenso(num_cl[m.group(1)])) + "** "
            continue
        m = re.match(r"#\s*CAPITULO\s+([\w-]+)\s*\|\s*(.+)$", ln)
        if m:
            out.append("")
            out.append(f"**CAPÍTULO {romano(num_cap[m.group(1)])}**  ")
            out.append(f"**{resolver(m.group(2).strip())}**")
            out.append("")
            continue
        txt = resolver(ln)
        if prefixo and txt.strip():
            txt = prefixo + txt.lstrip()
            prefixo = None
        out.append(txt)
    md = "\n".join(out)
    md = re.sub(r"\n{3,}", "\n\n", md).strip() + "\n"
    return md, num_cl, num_cap
