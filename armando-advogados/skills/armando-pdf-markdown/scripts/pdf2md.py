#!/usr/bin/env python3
"""PDF -> Markdown enxuto.

Versao para ambiente com Python (Claude na nuvem, Cowork, Linux, Mac).
Equivalente ao pdf2md.ps1, que roda no Claude Code em Windows.

Mesma ideia: remonta os paragrafos justificados, marca titulos e remove
cabecalho, rodape e carimbo de assinatura que se repetem em toda pagina.

Uso:
    python pdf2md.py processo.pdf
    python pdf2md.py pasta/ --out saida/
    python pdf2md.py doc.pdf --manter-repetidos --sem-marcas-de-pagina
"""

import argparse
import os
import re
import sys
from collections import Counter, defaultdict

# ----------------------------------------------------------------- extracao


def _mk_line(words):
    """Junta as palavras de uma mesma linha num registro unico."""
    text = " ".join(w["text"] for w in words).strip()
    text = re.sub(r"\s{2,}", " ", text)
    sizes = Counter()
    bold_chars = 0
    total_chars = 0
    for w in words:
        n = len(w["text"])
        sizes[round(float(w.get("size") or 10), 1)] += n
        total_chars += n
        if "bold" in str(w.get("fontname", "")).lower():
            bold_chars += n
    return {
        "text": text,
        "x0": min(w["x0"] for w in words),
        "x1": max(w["x1"] for w in words),
        "top": min(w["top"] for w in words),
        "size": sizes.most_common(1)[0][0] if sizes else 10.0,
        "bold": total_chars > 0 and bold_chars * 2 >= total_chars,
    }


def _group_words(words):
    """Agrupa palavras em linhas pela coordenada vertical."""
    if not words:
        return []
    ws = sorted(words, key=lambda w: (round(w["top"], 1), w["x0"]))
    lines, cur, cur_top = [], [], None
    for w in ws:
        tol = max(1.2, float(w.get("size") or 10) * 0.4)
        if cur_top is None:
            cur, cur_top = [w], w["top"]
        elif abs(w["top"] - cur_top) <= tol:
            cur.append(w)
        else:
            lines.append(_mk_line(cur))
            cur, cur_top = [w], w["top"]
    if cur:
        lines.append(_mk_line(cur))
    return [ln for ln in lines if ln["text"]]


def extract_pdfplumber(path):
    """Extracao boa: da a posicao de cada palavra. Devolve (paginas, None)."""
    import pdfplumber  # noqa: F401  (falha tratada por quem chama)

    pages = []
    with pdfplumber.open(path) as pdf:
        for i, page in enumerate(pdf.pages, 1):
            try:
                words = page.extract_words(extra_attrs=["size", "fontname"])
            except TypeError:  # pdfplumber antigo, sem extra_attrs
                words = page.extract_words()
            pages.append(
                {
                    "n": i,
                    "w": float(page.width or 595),
                    "h": float(page.height or 842),
                    "lines": _group_words(words),
                }
            )
    return pages


def extract_pypdf(path):
    """Plano B: so o texto, sem posicao. A saida fica pior."""
    try:
        from pypdf import PdfReader
    except ImportError:
        from PyPDF2 import PdfReader  # type: ignore

    pages = []
    reader = PdfReader(path)
    for i, page in enumerate(reader.pages, 1):
        raw = page.extract_text() or ""
        lines = []
        # sem coordenada real: empilha as linhas e finge uma margem constante
        for k, t in enumerate(ln.strip() for ln in raw.splitlines()):
            if t:
                lines.append(
                    {
                        "text": t,
                        "x0": 0.0,
                        "x1": float(len(t)),
                        "top": float(k),
                        "size": 10.0,
                        "bold": False,
                    }
                )
        pages.append({"n": i, "w": 595.0, "h": 842.0, "lines": lines})
    return pages


def extract(path):
    """Devolve (paginas, aviso)."""
    try:
        return extract_pdfplumber(path), None
    except ImportError:
        pass
    except Exception as e:  # PDF quebrado, protegido por senha etc.
        return [], "pdfplumber falhou: %s" % e
    try:
        return extract_pypdf(path), (
            "pdfplumber nao esta instalado; usei pypdf, sem posicao de texto. "
            "A remontagem de paragrafo e a remocao de carimbo ficam piores."
        )
    except Exception as e:
        return [], "nao consegui ler o PDF: %s" % e


# ------------------------------------------------------------ pos-processo


def norm_key(t):
    k = t.lower()
    k = re.sub(r"[0-9a-f]{8,}", "#", k)
    k = re.sub(r"\d+", "#", k)
    return re.sub(r"\s+", " ", k).strip()


def pct(values, p):
    if not values:
        return 0.0
    s = sorted(values)
    i = int((len(s) - 1) * p)
    return s[max(0, min(len(s) - 1, i))]


RX_HEAD = re.compile(
    r"^\s*(CL[ÁA]USULA|CAP[ÍI]TULO|SE[ÇC][ÃA]O|T[ÍI]TULO|ANEXO|AP[ÊE]NDICE|"
    r"PRE[ÂA]MBULO|CONSIDERANDO|D[OA]S?\s+[A-ZÁÉÍÓÚÂÊÔÃÕÇ]{3,})\b"
)
RX_LIST = re.compile(
    r"^\s*([•▪●◦·\-–—\*]|\(?[a-z]\)|"
    r"\(?[ivxlIVXL]{1,5}\)|\d{1,3}(\.\d{1,3})*\s*[\.\)\-–])\s+"
)
RX_NUM = re.compile(r"^\s*\d{1,3}(\.\d{1,3})+\.?\s")
RX_BULLET = re.compile(r"^\s*[•▪●◦·\-–—\*]\s+")
RX_PAGENUM = re.compile(r"^(p(a|á)g(ina)?\.?\s*)?\d{1,4}(\s*(/|de)\s*\d{1,4})?$", re.I)


def strip_repeated(pages, enabled):
    """Tira cabecalho, rodape e carimbo que se repetem na maioria das paginas."""
    total = len(pages)
    all_lines = [(p, ln) for p in pages for ln in p["lines"]]
    dropped = 0
    blocked, blocked_pre = set(), set()

    if enabled and total >= 3:
        seen, seen_pre = defaultdict(set), defaultdict(set)
        for p, ln in all_lines:
            k = norm_key(ln["text"])
            if len(k) < 2:
                continue
            band = ln["top"] < 0.13 * p["h"] or ln["top"] > 0.87 * p["h"]
            if band or len(k) >= 40:
                seen[k].add(p["n"])
            # o carimbo muda nome e codigo a cada pagina: casa pelo inicio
            if len(k) >= 60:
                seen_pre[k[:60]].add(p["n"])
        limit = max(3, -(-total // 2))
        blocked = {k for k, v in seen.items() if len(v) >= limit}
        blocked_pre = {k for k, v in seen_pre.items() if len(v) >= limit}

    for p in pages:
        kept = []
        for ln in p["lines"]:
            t = ln["text"].strip()
            k = norm_key(t)
            if enabled and (k in blocked or (len(k) >= 60 and k[:60] in blocked_pre)):
                dropped += 1
                continue
            band = ln["top"] < 0.13 * p["h"] or ln["top"] > 0.87 * p["h"]
            if band and RX_PAGENUM.match(t):
                dropped += 1
                continue
            kept.append(ln)
        p["lines"] = kept
    return dropped


def body_size(pages):
    w = Counter()
    for p in pages:
        for ln in p["lines"]:
            w[round(ln["size"], 1)] += len(ln["text"])
    return w.most_common(1)[0][0] if w else 11.0


def heading_level(t, ln, body):
    letters = re.sub(r"[\W\d_]", "", t, flags=re.UNICODE)
    upper = "".join(c for c in t if c.isupper())
    is_caps = len(letters) >= 3 and len(upper) >= len(letters) * 0.9
    short = len(t) <= 100
    ratio = ln["size"] / body if body else 1.0

    if ratio >= 1.5 and short:
        return 1, is_caps
    if ratio >= 1.28 and short:
        return 2, is_caps
    if ratio >= 1.12 and short and (ln["bold"] or is_caps) and not re.search(r"[.,;]$", t):
        return 3, is_caps
    if is_caps and short and (ln["bold"] or RX_HEAD.match(t)) and not re.search(r"[.,;]$", t):
        return 2, is_caps
    if RX_HEAD.match(t) and short and (ln["bold"] or is_caps):
        return 2, is_caps
    return 0, is_caps


def to_markdown(pages, source, page_marks, dropped):
    body = body_size(pages)
    blocks, buf = [], []
    buf_level = 0
    prev = None

    def flush():
        nonlocal buf, buf_level
        if buf:
            txt = ""
            for piece in buf:
                if not txt:
                    txt = piece
                elif txt.endswith("-"):      # hifen de quebra de linha
                    txt += piece
                else:
                    txt += " " + piece
            txt = re.sub(r"\s{2,}", " ", txt).strip()
            if txt:
                # titulo que virou paragrafo inteiro nao e titulo
                if buf_level > 0 and len(txt) <= 150:
                    txt = "#" * buf_level + " " + txt
                blocks.append(txt)
        buf, buf_level = [], 0

    first_page = True
    for p in pages:
        lines = p["lines"]
        if not lines:
            continue
        right = pct([ln["x1"] for ln in lines], 0.92)
        left = pct([ln["x0"] for ln in lines], 0.08)
        width = max(1.0, right - left)

        # margem direita por nivel de recuo: citacao recuada tem margem propria
        buckets = defaultdict(list)
        for ln in lines:
            buckets[int(round(ln["x0"] / 12))].append(ln["x1"])
        edge = {b: (pct(v, 0.92) if len(v) >= 2 else right) for b, v in buckets.items()}

        gaps = [
            lines[i]["top"] - lines[i - 1]["top"]
            for i in range(1, len(lines))
            if 0.5 < lines[i]["top"] - lines[i - 1]["top"] < 100
        ]
        med_gap = pct(gaps, 0.5) if gaps else body * 1.3

        if page_marks and not first_page:
            flush()
            blocks.append("[p. %d]" % p["n"])
        first_page = False

        for ln in lines:
            t = ln["text"].strip()
            if not t:
                continue
            level, _ = heading_level(t, ln, body)
            is_list = level == 0 and RX_LIST.match(t) and not RX_NUM.match(t)
            is_num = level == 0 and RX_NUM.match(t)

            gap = (ln["top"] - prev["top"]) if (prev and prev["page"] == p["n"]) else 0
            brk = False
            if prev is None or prev["page"] != p["n"]:
                brk = True
            elif level > 0 or buf_level > 0:
                # titulos: so quebram por mudanca de nivel ou espaco vertical
                brk = level != buf_level or gap > 1.6 * med_gap
            else:
                p_right = edge.get(int(round(prev["x0"] / 12)), right)
                deficit = p_right - prev["x1"]
                fecha = re.search(r"[.!?:;\"”»)]\s*$", prev["text"]) is not None
                if gap > 1.45 * med_gap:
                    brk = True
                if deficit > 0.06 * width and fecha:
                    brk = True
                if deficit > 0.30 * width:
                    brk = True
                if ln["x0"] > prev["x0"] + 0.02 * width:   # recuo de 1a linha
                    brk = True
                if abs(prev["size"] - ln["size"]) > 0.7:
                    brk = True
                if is_list or is_num:
                    brk = True

            if brk:
                flush()
            if is_list:
                t = "- " + RX_BULLET.sub("", t)
            if not buf:
                buf_level = level
            buf.append(t)
            prev = dict(ln, page=p["n"])
        flush()
    flush()

    head = "<!-- %s | %d pag." % (source, len(pages))
    if dropped:
        head += " | %d linhas de cabecalho/rodape removidas" % dropped
    head += " -->"
    out = head + "\n\n" + "\n\n".join(b for b in blocks if b.strip())
    out = re.sub(r"\n{3,}", "\n\n", out)
    return re.sub(r"[ \t]+\n", "\n", out)


# ------------------------------------------------------------------ CLI


def convert(src, dst, args):
    pages, warn = extract(src)
    if warn:
        print("     aviso: %s" % warn)
    if not pages or not any(p["lines"] for p in pages):
        print("  ! Sem camada de texto (PDF digitalizado). Precisa de OCR.")
        return None

    if args.linhas:
        tsv = os.path.splitext(dst)[0] + ".linhas.tsv"
        with open(tsv, "w", encoding="utf-8") as fh:
            for p in pages:
                for ln in p["lines"]:
                    fh.write(
                        "%d\t%.1f\t%.1f\t%.1f\t%.2f\t%s\t%s\n"
                        % (p["n"], ln["top"], ln["x0"], ln["x1"], ln["size"],
                           ln["bold"], ln["text"])
                    )
        print("     diagnostico: %s" % os.path.basename(tsv))

    dropped = strip_repeated(pages, not args.manter_repetidos)
    md = to_markdown(pages, os.path.basename(src), not args.sem_marcas_de_pagina, dropped)
    with open(dst, "w", encoding="utf-8") as fh:
        fh.write(md)

    kb = os.path.getsize(src) // 1024
    print("  -> %s" % os.path.basename(dst))
    print("     %d pag. | %d KB de PDF -> %d caracteres (~%d tokens)"
          % (len(pages), kb, len(md), round(len(md) / 3.5)))
    if dropped:
        print("     %d linhas repetidas de cabecalho/rodape removidas" % dropped)
    if pages and len(md) / len(pages) < 200:
        print("     AVISO: quase nao ha texto por pagina - PDF provavelmente digitalizado.")
        print("            o .md so tem o carimbo. Para o conteudo, precisa de OCR.")
    return dst


def main():
    ap = argparse.ArgumentParser(description="Converte PDF em Markdown enxuto.")
    ap.add_argument("path", nargs="+", help="PDFs ou pastas")
    ap.add_argument("--out", help="arquivo .md (1 PDF) ou pasta de saida")
    ap.add_argument("--manter-repetidos", action="store_true",
                    dest="manter_repetidos",
                    help="nao remover cabecalho/rodape/carimbo repetidos")
    ap.add_argument("--sem-marcas-de-pagina", action="store_true",
                    dest="sem_marcas_de_pagina", help="sair sem as marcas [p. N]")
    ap.add_argument("--linhas", action="store_true",
                    help="gerar tambem o .linhas.tsv de diagnostico")
    args = ap.parse_args()

    files = []
    for p in args.path:
        if os.path.isdir(p):
            files += [os.path.join(p, f) for f in sorted(os.listdir(p))
                      if f.lower().endswith(".pdf")]
        elif os.path.isfile(p):
            files.append(p)
        else:
            print("Nao encontrado: %s" % p)
    if not files:
        print("Nenhum PDF para converter.")
        return 1

    out_is_dir = bool(args.out) and (
        os.path.isdir(args.out) or len(files) > 1 or not os.path.splitext(args.out)[1]
    )
    if out_is_dir and not os.path.isdir(args.out):
        os.makedirs(args.out, exist_ok=True)

    done = 0
    for f in files:
        print(os.path.basename(f))
        if not args.out:
            dst = os.path.splitext(f)[0] + ".md"
        elif out_is_dir:
            dst = os.path.join(args.out,
                               os.path.splitext(os.path.basename(f))[0] + ".md")
        else:
            dst = args.out
        try:
            if convert(f, dst, args):
                done += 1
        except Exception as e:
            print("  ! Erro: %s" % e)
    if len(files) > 1:
        print("\n%d de %d arquivos convertidos." % (done, len(files)))
    return 0 if done else 1


if __name__ == "__main__":
    sys.exit(main())
