#!/usr/bin/env python3
"""Biblioteca da skill armando-mou.

Extenso (copiado da lib_holding.py da armando-holding-empresarial, com as
correcoes de 08/10/2026 -- "um milhao de reais", "um milhao e setenta e seis
mil"), formatacao brasileira e leitura de .docx/.md/.txt preservando tabelas.

Ao corrigir o extenso aqui, confira as outras copias (ver memoria do plugin).
So biblioteca padrao: roda no chat (python3) e no Windows (python).
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

_W = "{http://schemas.openxmlformats.org/wordprocessingml/2006/main}"


def _texto_par(p):
    partes = []
    for el in p.iter():
        if el.tag == _W + "t" and el.text:
            partes.append(el.text)
        elif el.tag == _W + "tab":
            partes.append("\t")
        elif el.tag in (_W + "br", _W + "cr"):
            partes.append("\n")
    return "".join(partes)


def linhas_do_docx(caminho):
    """Linhas do .docx na ordem do corpo. Tabela vira linhas '| a | b |', uma
    por linha da tabela, como no Markdown -- a conferencia trata os dois
    formatos do mesmo jeito."""
    import xml.etree.ElementTree as ET
    with zipfile.ZipFile(caminho) as z:
        raiz = ET.fromstring(z.read("word/document.xml"))
    corpo = raiz.find(_W + "body")
    saida = []

    def tabela(tbl):
        for tr in tbl.findall(_W + "tr"):
            celulas = []
            for tc in tr.findall(_W + "tc"):
                txt = " ".join(_texto_par(p).strip() for p in tc.iter(_W + "p"))
                celulas.append(re.sub(r"\s+", " ", txt).strip())
            saida.append("| " + " | ".join(celulas) + " |")

    for el in corpo:
        if el.tag == _W + "p":
            saida.extend(_texto_par(el).split("\n"))
        elif el.tag == _W + "tbl":
            tabela(el)
        elif el.tag == _W + "sdt":
            for p in el.iter(_W + "p"):
                saida.append(_texto_par(p))
    return saida


def linhas_do_arquivo(caminho):
    """Linhas de .docx, .md ou .txt."""
    if caminho.lower().endswith(".docx"):
        return linhas_do_docx(caminho)
    with io.open(caminho, encoding="utf-8-sig") as f:
        return f.read().split("\n")


def sem_markdown(s):
    """Tira negrito/italico e escapes do Markdown, para comparar texto."""
    s = s.replace("\\", "")
    s = re.sub(r"\*{1,3}|(?<!_)__(?=[^\s_])|(?<=[^\s_])__(?!_)", "", s)
    return s


def norm(s):
    """Maiusculas sem acento e com espaco simples -- chave para comparar nomes."""
    s = sem_acento(sem_markdown(s or "")).upper()
    return re.sub(r"\s+", " ", re.sub(r"[^A-Z0-9&.\- ]", " ", s)).strip()


# ------------------------------------------------------- documentos (DV) ---

def cpf_valido(cpf):
    d = re.sub(r"\D", "", cpf)
    if len(d) != 11 or d == d[0] * 11:
        return False
    for k in (9, 10):
        soma = sum(int(d[i]) * (k + 1 - i) for i in range(k))
        dv = (soma * 10) % 11 % 10
        if dv != int(d[k]):
            return False
    return True


def cnpj_valido(cnpj):
    d = re.sub(r"\D", "", cnpj)
    if len(d) != 14 or d == d[0] * 14:
        return False
    pesos1 = [5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2]
    pesos2 = [6] + pesos1
    for pesos, k in ((pesos1, 12), (pesos2, 13)):
        soma = sum(int(d[i]) * pesos[i] for i in range(k))
        r = soma % 11
        dv = 0 if r < 2 else 11 - r
        if dv != int(d[k]):
            return False
    return True


# ------------------------------------------------------------------ frações ---

FRACOES_UNICODE = {"½": (1, 2), "⅓": (1, 3), "⅔": (2, 3), "¼": (1, 4), "¾": (3, 4),
                   "⅕": (1, 5), "⅙": (1, 6), "⅛": (1, 8)}
_DENOM = {2: "meio", 3: "terço", 4: "quarto", 5: "quinto", 6: "sexto", 7: "sétimo",
          8: "oitavo", 9: "nono", 10: "décimo"}


def fracao_extenso(num, den):
    """'um terço', 'dois quintos', 'metade' aceito para 1/2 na comparação."""
    if den in _DENOM:
        nome = _DENOM[den]
    else:
        nome = inteiro_extenso(den) + " avos"
        return f"{inteiro_extenso(num)} {nome}"
    if num > 1:
        nome += "s"
    return f"{inteiro_extenso(num)} {nome}"
