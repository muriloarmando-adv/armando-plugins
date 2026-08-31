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
    python pdf2md.py autos.pdf --paginas 1-100
"""

import argparse
import gc
import os
import re
import sys
from collections import Counter, defaultdict

# Paginas por lote interno. Cada lote e extraido, reduzido a linhas e liberado
# antes do seguinte: em processo de 844 paginas / 69 MB o script carregava todas
# as palavras de todas as paginas de uma vez e era morto pelo SO com 4 GB de RAM.
LOTE_PADRAO = 100


# ------------------------------------------------------------------- imunes

# Padroes que NUNCA sao descartados pela remocao de repetidos, mesmo repetindo
# em toda pagina. O carimbo de folha repete por definicao - e por isso era
# engolido junto com o cabecalho: num extrato e-STJ de 844 paginas, das 855
# ocorrencias de "(e-STJ Fl.N)" sobravam poucas centenas, e a ultima folha
# visivel no .md era a 822 quando a real era a 830. Sem o carimbo, as ancoras 2
# e 3 da secao 3 da armando-analise-processo mentem, e citar peca por folha
# fica impossivel.
RX_IMUNES = [
    re.compile(r"\(e-STJ\s*Fl\.", re.I),        # e-STJ / STJ
    re.compile(r"\bFl\.?\s*\d", re.I),          # foliacao "Fl. 830"
    re.compile(r"\bfls\.", re.I),               # "fls. 145/336"
    re.compile(r"\bID\s+[0-9A-Za-z]", re.I),    # PJe: "ID 037030e"
    re.compile(r"\bEvento\s+\d", re.I),         # eproc: "Evento 12"
    re.compile(r"\bNum\.\s*\d", re.I),          # PJe-JT: "Num. 3c1f2a9"
]


def imune(texto):
    """Diz se a linha carrega identificador que nao pode ser perdido."""
    for rx in RX_IMUNES:
        if rx.search(texto):
            return True
    return False


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


def data_criacao(meta):
    """CreationDate do PDF -> 'dd/mm/aaaa hh:mm'.

    E a quinta ancora de atualidade da armando-analise-processo: diz quando o
    PDF foi tirado, nao quando o processo se moveu - mas num caso real era o
    unico marcador recente do arquivo, e sem ele a analise erraria 13 meses.
    """
    if not meta:
        return None
    try:
        bruto = str(meta.get("CreationDate") or meta.get("ModDate") or "")
    except Exception:
        return None
    m = re.search(r"D?:?\s*(\d{4})(\d{2})(\d{2})(\d{2})?(\d{2})?", bruto)
    if not m:
        return None
    aa, mm, dd = m.group(1), m.group(2), m.group(3)
    hh, mi = m.group(4) or "00", m.group(5) or "00"
    try:
        if not (1 <= int(mm) <= 12 and 1 <= int(dd) <= 31):
            return None
    except ValueError:
        return None
    return "%s/%s/%s %s:%s" % (dd, mm, aa, hh, mi)


def _lote_pdfplumber(pdfplumber, path, ini, fim, st):
    """Extrai UM lote de paginas, com handle proprio do pdfplumber."""
    buf = []
    with pdfplumber.open(path) as pdf:
        for n in range(ini, fim + 1):
            page = pdf.pages[n - 1]
            try:
                words = page.extract_words(
                    extra_attrs=["size", "fontname", "upright"])
            except TypeError:          # pdfplumber antigo, sem extra_attrs
                words = page.extract_words()
            # A marca d agua vertical do e-STJ ("Para verificar a assinatura
            # acesse...") sai rodada e picada, uma letra por linha, interpolada
            # no meio dos paragrafos: chegava a 30-40% das linhas do .md. Texto
            # rotacionado tem upright=False. Descartar aqui e o maior ganho de
            # qualidade da cadeia inteira.
            antes = len(words)
            words = [w for w in words if w.get("upright", True)]
            st["nao_upright"] += antes - len(words)

            buf.append({
                "n": n,
                "w": float(page.width or 595),
                "h": float(page.height or 842),
                "lines": _group_words(words),
            })
            del words
            try:
                page.close()           # devolve o cache de objetos da pagina
            except Exception:
                pass
    return buf


def lotes_pdfplumber(path, lote, faixa, st):
    """Extracao boa: da a posicao de cada palavra. Gera lotes de paginas.

    Cada lote abre o PDF por conta propria, reduz as paginas a linhas e fecha:
    o pdfminer acumula cache de fonte e de objeto que nem page.close() nem
    gc.collect() devolvem, e num arquivo de 844 paginas / 69 MB isso levava o
    processo a mais de 6 GB - na nuvem, com 4 GB, ele era morto pelo SO.
    Fechando o arquivo a cada lote, o pico passa a ser o do lote mais pesado, e
    --lote vira o dial de memoria: 100 e o padrao, 50 num ambiente apertado.
    """
    import pdfplumber

    with pdfplumber.open(path) as pdf:
        st["criado_em"] = data_criacao(pdf.metadata)
        total = len(pdf.pages)
    st["paginas_pdf"] = total
    ini, fim = faixa if faixa else (1, total)
    ini = max(1, ini)
    fim = min(total, fim if fim else total)
    st["faixa"] = (ini, fim)

    n = ini
    while n <= fim:
        ate = min(fim, n + lote - 1)
        yield _lote_pdfplumber(pdfplumber, path, n, ate, st)
        gc.collect()
        n = ate + 1


def lotes_pypdf(path, lote, faixa, st):
    """Plano B: so o texto, sem posicao. A saida fica pior."""
    try:
        from pypdf import PdfReader
    except ImportError:
        from PyPDF2 import PdfReader  # type: ignore

    reader = PdfReader(path)
    st["criado_em"] = data_criacao(getattr(reader, "metadata", None))
    total = len(reader.pages)
    st["paginas_pdf"] = total
    ini, fim = faixa if faixa else (1, total)
    ini = max(1, ini)
    fim = min(total, fim if fim else total)
    st["faixa"] = (ini, fim)
    st["upright_nao_aplicado"] = True

    buf = []
    for n in range(ini, fim + 1):
        raw = reader.pages[n - 1].extract_text() or ""
        lines = []
        # sem coordenada real: empilha as linhas e finge uma margem constante
        for k, t in enumerate(ln.strip() for ln in raw.splitlines()):
            if t:
                lines.append({
                    "text": t, "x0": 0.0, "x1": float(len(t)),
                    "top": float(k), "size": 10.0, "bold": False,
                })
        buf.append({"n": n, "w": 595.0, "h": 842.0, "lines": lines})
        if len(buf) >= lote:
            yield buf
            buf = []
            gc.collect()
    if buf:
        yield buf


def _consumir(gerador):
    """Consome o gerador de lotes. So as linhas ficam retidas; as palavras e o
       cache do pdfplumber ja foram liberados lote a lote."""
    paginas = []
    for lote in gerador:
        paginas.extend(lote)
    return paginas


def carregar(path, lote, faixa, st):
    """Devolve (paginas, aviso). As paginas ja vem reduzidas a linhas."""
    try:
        return _consumir(lotes_pdfplumber(path, lote, faixa, st)), None
    except ImportError:
        pass
    except Exception as e:            # PDF quebrado, protegido por senha etc.
        return [], "pdfplumber falhou: %s" % e
    try:
        st["nao_upright"] = 0
        return _consumir(lotes_pypdf(path, lote, faixa, st)), (
            "pdfplumber nao esta instalado; usei pypdf, sem posicao de texto. "
            "A remontagem de paragrafo e a remocao de carimbo ficam piores, e o "
            "filtro de texto rotacionado (marca d agua vertical) NAO se aplica."
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
    """Tira cabecalho, rodape e carimbo que se repetem na maioria das paginas.

    O que casar em RX_IMUNES fica, mesmo repetindo: e identificador de folha,
    de documento ou de evento, e sem ele nao se cita peca nenhuma.
    """
    total = len(pages)
    dropped = 0
    salvos = 0
    blocked, blocked_pre = set(), set()

    if enabled and total >= 3:
        seen, seen_pre = defaultdict(set), defaultdict(set)
        for p in pages:
            for ln in p["lines"]:
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
            repetida = enabled and (
                k in blocked or (len(k) >= 60 and k[:60] in blocked_pre))
            if repetida:
                if imune(t):
                    salvos += 1
                else:
                    dropped += 1
                    continue
            band = ln["top"] < 0.13 * p["h"] or ln["top"] > 0.87 * p["h"]
            if band and RX_PAGENUM.match(t) and not imune(t):
                dropped += 1
                continue
            kept.append(ln)
        p["lines"] = kept
    return dropped, salvos


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


def render_page(p, body, page_marks, first_page):
    """Blocos de markdown de UMA pagina.

    A remontagem de paragrafo ja nao atravessava pagina (o original dava flush
    ao fim de cada uma), entao renderizar pagina a pagina e escrever direto no
    arquivo nao muda a saida - e permite nao guardar o .md inteiro em memoria.
    """
    lines = p["lines"]
    if not lines:
        return []

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
        blocks.append("[p. %d]" % p["n"])

    for ln in lines:
        t = ln["text"].strip()
        if not t:
            continue
        level, _ = heading_level(t, ln, body)
        is_list = level == 0 and RX_LIST.match(t) and not RX_NUM.match(t)
        is_num = level == 0 and RX_NUM.match(t)

        gap = (ln["top"] - prev["top"]) if prev else 0
        brk = False
        if prev is None:
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
        prev = ln
    flush()
    return blocks


def cabecalho(source, st, dropped, salvos):
    """Primeira linha do .md, em comentario HTML."""
    ini, fim = st.get("faixa") or (1, st.get("paginas_pdf") or 0)
    n = fim - ini + 1
    h = "<!-- %s | %d pag." % (source, n)
    if st.get("paginas_pdf") and n != st["paginas_pdf"]:
        h += " (paginas %d-%d de %d do PDF)" % (ini, fim, st["paginas_pdf"])
    if st.get("criado_em"):
        h += " | PDF criado em %s" % st["criado_em"]
    if dropped:
        h += " | %d linhas de cabecalho/rodape removidas" % dropped
    if salvos:
        h += " | %d preservadas por carregarem folha/ID" % salvos
    if st.get("upright_nao_aplicado"):
        h += " | filtro de texto rotacionado NAO aplicado (pypdf)"
    elif st.get("nao_upright"):
        h += " | %d palavras rotacionadas descartadas" % st["nao_upright"]
    return h + " -->"


# ------------------------------------------------------------------ CLI


def convert(src, dst, args):
    st = {"nao_upright": 0, "criado_em": None, "paginas_pdf": 0,
          "faixa": None, "upright_nao_aplicado": False}
    pages, warn = carregar(src, args.lote, args.paginas, st)
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

    dropped, salvos = strip_repeated(pages, not args.manter_repetidos)
    body = body_size(pages)
    page_marks = not args.sem_marcas_de_pagina

    # Escrita incremental: renderiza pagina a pagina e larga a pagina em seguida,
    # de modo que nem as linhas nem o markdown do documento inteiro ficam retidos.
    chars = 0
    with open(dst, "w", encoding="utf-8") as fh:
        head = cabecalho(os.path.basename(src), st, dropped, salvos)
        fh.write(head + "\n")
        chars += len(head) + 1
        primeira = True
        pendente_nl = True
        for i, p in enumerate(pages):
            blocos = [b for b in render_page(p, body, page_marks, primeira)
                      if b.strip()]
            if blocos:
                primeira = False
                pedaco = ("\n" if pendente_nl else "\n\n") + "\n\n".join(blocos)
                pedaco = re.sub(r"[ \t]+\n", "\n", pedaco)
                fh.write(pedaco)
                chars += len(pedaco)
                pendente_nl = False
            p["lines"] = []
            if i % LOTE_PADRAO == LOTE_PADRAO - 1:
                gc.collect()
        fh.write("\n")
        chars += 1

    kb = os.path.getsize(src) // 1024
    print("  -> %s" % os.path.basename(dst))
    print("     %d pag. | %d KB de PDF -> %d caracteres (~%d tokens)"
          % (len(pages), kb, chars, round(chars / 3.5)))
    if dropped:
        print("     %d linhas repetidas de cabecalho/rodape removidas" % dropped)
    if salvos:
        print("     %d linhas repetidas PRESERVADAS (carregam folha/ID/evento)" % salvos)
    if st.get("upright_nao_aplicado"):
        print("     AVISO: sem pdfplumber o filtro de texto rotacionado nao se")
        print("            aplica - a marca d agua vertical continua no .md.")
    elif st.get("nao_upright"):
        print("     %d palavras rotacionadas (marca d agua) descartadas"
              % st["nao_upright"])
    if st.get("criado_em"):
        print("     PDF criado em %s (5a ancora de atualidade)" % st["criado_em"])
    if pages and chars / len(pages) < 200:
        print("     AVISO: quase nao ha texto por pagina - PDF provavelmente digitalizado.")
        print("            o .md so tem o carimbo. Para o conteudo, precisa de OCR.")
    return dst


def parse_faixa(s):
    """'1-100' -> (1, 100); '200-' -> (200, ate o fim); '50' -> (50, 50)."""
    if not s:
        return None
    m = re.match(r"^\s*(\d+)\s*(?:([-:])\s*(\d+)?)?\s*$", s)
    if not m:
        raise argparse.ArgumentTypeError(
            "faixa invalida: %s. Use 1-100, 200- ou 50." % s)
    ini = int(m.group(1))
    if not m.group(2):
        return (ini, ini)
    return (ini, int(m.group(3)) if m.group(3) else 0)


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
    ap.add_argument("--paginas", type=parse_faixa, default=None, metavar="1-100",
                    help="converter so esta faixa de paginas do PDF")
    ap.add_argument("--lote", type=int, default=LOTE_PADRAO, metavar="N",
                    help="paginas por lote interno (padrao %d)" % LOTE_PADRAO)
    args = ap.parse_args()
    if args.lote < 1:
        args.lote = LOTE_PADRAO

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
        gc.collect()
    if len(files) > 1:
        print("\n%d de %d arquivos convertidos." % (done, len(files)))
    return 0 if done else 1


if __name__ == "__main__":
    sys.exit(main())
