#!/usr/bin/env python3
"""Confere a minuta FINAL (depois de editada) do contrato da holding ou da
alteracao de uma investida.

    python3 conferir_minuta.py minuta.docx [outra.docx ...] [--dados dados.json] [--protocolo]

O gerador entrega texto correto por construcao; o risco esta na edicao
manual que vem depois. Esta conferencia pega os defeitos que existiam no
modelo de origem e no acervo da casa:

  - numeracao de clausula que pula ou repete (o modelo pulava a 57a e a 67a);
  - capitulo que pula ou rotulado como "CLÁUSULA XX" (o modelo fazia as duas);
  - remissao a clausula ou capitulo inexistente;
  - extenso que nao bate com o algarismo (reais e quotas), e quotas no masculino;
  - CNAE em notacao invalida ("6462-00/00");
  - deliberacao por escrito da maioria (art. 1.072, § 3o, exige todos);
  - "incorporacao de quotas" (termo de outra operacao);
  - tabela de quadro societario cujo total nao fecha;
  - placeholder esquecido (ERRO com --protocolo; pendencia sem ele);
  - com --dados: quotas, CNPJ e capital divergentes do arquivo de dados.

Sai com codigo 1 se houver ERRO.
"""

import argparse
import io
import json
import os
import re
import sys
from decimal import Decimal

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from lib_holding import (chave_extenso, de_romano, fmt_int, forcar_utf8,  # noqa: E402
                         inteiro_extenso, reais_extenso, sem_acento, texto_do_arquivo)

ORD_PAL = {"PRIMEIRA": 1, "SEGUNDA": 2, "TERCEIRA": 3, "QUARTA": 4, "QUINTA": 5, "SEXTA": 6,
           "SETIMA": 7, "OITAVA": 8, "NONA": 9, "DECIMA": 10, "VIGESIMA": 20}


def ordinal_palavra(s):
    """'DÉCIMA PRIMEIRA' -> 11."""
    toks = sem_acento(s).upper().split()
    total = 0
    for t in toks:
        if t not in ORD_PAL:
            return None
        total += ORD_PAL[t]
    return total or None


def linhas_docx_com_tabelas(caminho):
    if not caminho.lower().endswith(".docx"):
        return texto_do_arquivo(caminho)
    import zipfile
    import html
    with zipfile.ZipFile(caminho) as z:
        xml = z.read("word/document.xml").decode("utf-8")

    def linha_tabela(m):
        celulas = re.findall(r"<w:tc\b.*?</w:tc>", m.group(0), flags=re.S)
        txt = [re.sub(r"<[^>]+>", "", re.sub(r"</w:p>", " ", c)).strip() for c in celulas]
        return "<w:p><w:r><w:t>| " + " | ".join(txt) + " |</w:t></w:r></w:p>"

    xml = re.sub(r"<w:tr\b.*?</w:tr>", linha_tabela, xml, flags=re.S)
    xml = re.sub(r"<w:tab/>", "\t", xml)
    xml = re.sub(r"<w:br[^>]*/>", "\n", xml)
    xml = re.sub(r"</w:p>", "\n", xml)
    return html.unescape(re.sub(r"<[^>]+>", "", xml))


class Rel:
    def __init__(self, nome):
        self.nome, self.itens = nome, []

    def add(self, sev, msg):
        self.itens.append((sev, msg))

    def conta(self, sev):
        return sum(1 for s, _ in self.itens if s == sev)


def numero_br(s):
    return Decimal(s.replace(".", "").replace(",", "."))


def conferir(caminho, dados, protocolo):
    rel = Rel(os.path.basename(caminho))
    txt = linhas_docx_com_tabelas(caminho)
    txt = txt.replace(" ", " ")
    limpo = re.sub(r"[*_`\\]", "", txt)  # tira markdown
    linhas = [l.strip() for l in limpo.splitlines()]
    eh_alteracao = bool(re.search(r"ALTERA[ÇC][ÃA]O CONTRATUAL", limpo[:600], re.I))

    # --- placeholders
    ph = re.findall(r"\[\s*\.{3,}\s*\]|\(_{3,}[^)]*\)|\(\s*_+\s*\)|\bX{4,}\b", limpo)
    ph_linhas = sum(1 for l in linhas if re.search(r"\[\s*\.{3,}\s*\]|\(_{3,}|\bX{4,}\b", l))
    if ph:
        rel.add("ERRO" if protocolo else "PENDÊNCIA",
                f"{len(ph)} campo(s) em aberto, em {ph_linhas} parágrafo(s). Preencha antes do protocolo.")
    if "Passos-MG" in limpo:
        rel.add("ALERTA", "Texto contém 'Passos-MG' — resíduo do modelo de origem na qualificação. Confirme a naturalidade.")

    # --- numeracao de clausulas (cabecalhos no inicio do paragrafo, fora de aspas)
    nums = []
    for l in linhas:
        if l.startswith(('"', "“")):
            continue
        m = re.match(r"CL[ÁA]USULA\s+([IVXLC]+)\b(?![ªº])", l)
        if m:
            rel.add("ERRO", f"Rótulo 'CLÁUSULA {m.group(1)}' com algarismo romano — no modelo de origem era o "
                            "título do capítulo do foro. Use 'CAPÍTULO'.")
            continue
        m = re.match(r"CL[ÁA]USULA\s+(\d+)\s*[ªºa°]?\s*[-–—:]", l, re.I)
        if m:
            nums.append(int(m.group(1)))
            continue
        m = re.match(r"CL[ÁA]USULA\s+([A-ZÁÉÍÓÚÊÔÇ ]+?)\s*[-–—:]", l)
        if m:
            n = ordinal_palavra(m.group(1))
            if n:
                nums.append(n)
            elif re.fullmatch(r"[IVXLC]+", m.group(1).strip()):
                rel.add("ERRO", f"Rótulo 'CLÁUSULA {m.group(1).strip()}' com algarismo romano — no modelo de origem "
                                "era o título do capítulo do foro. Use 'CAPÍTULO'.")
    if nums:
        esperado = list(range(1, len(nums) + 1))
        if nums != esperado:
            faltam = sorted(set(range(1, max(nums) + 1)) - set(nums))
            rep = sorted({n for n in nums if nums.count(n) > 1})
            det = []
            if faltam:
                det.append("faltam " + ", ".join(f"{n}ª" for n in faltam))
            if rep:
                det.append("repetidas " + ", ".join(f"{n}ª" for n in rep))
            if not det:
                det.append("fora de ordem")
            rel.add("ERRO", f"Numeração das cláusulas não é contínua ({'; '.join(det)}). Toda alteração futura "
                            "remete por número; buraco ou repetição gera ambiguidade.")
    existentes = set(nums)

    # --- capitulos
    caps = []
    for l in linhas:
        m = re.match(r"CAP[ÍI]TULO\s+([IVXLC]+)\b", l)
        if m:
            caps.append(de_romano(m.group(1)))
    if caps and caps != list(range(1, len(caps) + 1)):
        faltam = sorted(set(range(1, max(caps) + 1)) - set(caps))
        rel.add("ERRO", "Numeração dos capítulos não é contínua"
                + (f" (falta(m) {', '.join(_rom(n) for n in faltam)})" if faltam else "") + ".")

    # --- remissoes
    corpo = "\n".join(l for l in linhas if not re.match(r"CL[ÁA]USULA\s", l))
    if not eh_alteracao:
        for m in re.finditer(r"Cl[áa]usula\s+(\d+)\s*[ªº]?", corpo):
            n = int(m.group(1))
            if existentes and n not in existentes:
                rel.add("ERRO", f"Remissão à Cláusula {n}ª, que não existe no instrumento.")
        for m in re.finditer(r"Cap[íi]tulo\s+([IVXLC]+)\b", corpo):
            n = de_romano(m.group(1))
            if caps and n not in caps:
                rel.add("ERRO", f"Remissão ao Capítulo {m.group(1)}, que não existe no instrumento.")
    else:
        for m in re.finditer(r"Cl[áa]usula\s+((?:D[ée]cima\s+|Vig[ée]sima\s+)?[A-ZÁÉÍÓÚa-záéíóú]+)\b", corpo):
            n = ordinal_palavra(m.group(1))
            if n and existentes and n not in existentes:
                rel.add("ERRO", f"Remissão à Cláusula {m.group(1)}, que não existe nesta alteração.")

    # --- extenso: reais
    for m in re.finditer(r"R\$\s*([\d.]+,\d{2})\s*\(([^)]+)\)", limpo):
        v = numero_br(m.group(1))
        if chave_extenso(m.group(2)) != chave_extenso(reais_extenso(v)):
            rel.add("ERRO", f"Extenso não bate: R$ {m.group(1)} ({m.group(2)}) — o correto é ({reais_extenso(v)}).")
    # --- extenso: quotas
    for m in re.finditer(r"\b(\d{1,3}(?:\.\d{3})*)\s*\(([^)]+)\)\s*(?:de\s+)?(?:quotas|cotas)", limpo, re.I):
        n = int(m.group(1).replace(".", ""))
        ext = m.group(2)
        if chave_extenso(ext) != chave_extenso(inteiro_extenso(n)):
            rel.add("ERRO", f"Extenso não bate: {m.group(1)} ({ext}) quotas — o correto é ({inteiro_extenso(n, fem=True)}).")
        elif sem_acento(ext).lower() != sem_acento(inteiro_extenso(n, fem=True)).lower() and \
                re.search(r"\b(um|dois|duzentos|trezentos|quatrocentos|quinhentos|seiscentos|setecentos|oitocentos|novecentos)\b(?!\s+(milh|bilh))",
                          sem_acento(ext).lower()):
            rel.add("ALERTA", f"Concordância: '{m.group(1)} ({ext}) quotas' — quota é feminino: ({inteiro_extenso(n, fem=True)}).")

    # --- CNAE
    for m in re.finditer(r"\b(\d{4})-(\d{2})/(\d{2})\b", limpo):
        rel.add("ERRO", f"CNAE em notação inválida: {m.group(0)}. O formato é NNNN-N/NN (ex.: 6462-0/00).")
    if not eh_alteracao and "6462-0/00" not in limpo and "64.62-0/00" not in limpo:
        rel.add("ALERTA", "CNAE 6462-0/00 (holdings de instituições não-financeiras) não aparece no objeto.")

    # --- deliberacao majoritaria por escrito
    if re.search(r"documento\s+assinado\s+por\s+s[óo]cios\s+que\s+representem\s+(a\s+)?maioria", limpo, re.I):
        rel.add("ERRO", "Deliberação por documento assinado pela maioria do capital: a dispensa de reunião exige "
                        "decisão escrita de TODOS os sócios (CC, art. 1.072, § 3º; Manual DREI, item 3.1, II). "
                        "A exceção da LC 123 (art. 70) não alcança holding (art. 3º, § 4º, VII).")
    if re.search(r"incorpora[çc][ãa]o\s+de\s+(quotas|cotas)", limpo, re.I):
        rel.add("ALERTA", "'Incorporação de quotas' é termo de outra operação (art. 252 da Lei 6.404/76, própria de "
                          "S.A.). O DREI chama de 'integralização de capital com quotas de outra sociedade'.")
    if re.search(r"\bfus[ãa]o\s+(das|de)\s+empresas\b", limpo, re.I):
        rel.add("ALERTA", "O texto fala em 'fusão de empresas'. Integralizar quotas numa holding não é fusão "
                          "(CC, art. 1.119): as investidas continuam existindo.")
    if re.search(r"\bEIRELI\b", limpo):
        rel.add("ALERTA", "Menção a EIRELI — extinta pela Lei 14.382/2022.")

    # --- holding: itens de conteudo
    if not eh_alteracao:
        if re.search(r"integraliz", limpo, re.I) and "1.055" not in limpo:
            rel.add("ALERTA", "Não há menção ao art. 1.055, § 1º (solidariedade pela exata estimação das quotas "
                              "conferidas, por 5 anos).")
        if not re.search(r"1º\s*Ato|arquivamento conjuntamente|compartilhadoras", limpo, re.I):
            rel.add("ERRO", "O contrato não indica o ato de transferência das quotas nas investidas (1º Ato). O Manual "
                            "DREI, item 4.3.5, b, exige essa indicação.")
        if not re.search(r"visto\s+do\s+advogado|OAB", limpo, re.I):
            rel.add("ALERTA", "Sem visto de advogado. A holding não é ME/EPP (LC 123, art. 3º, § 4º, VII): o visto é "
                              "obrigatório (Lei 8.906/1994, art. 1º, § 2º).")
    else:
        if not re.search(r"constitui[çc][ãa]o|integraliza", limpo, re.I):
            rel.add("ERRO", "A alteração não diz que as quotas se destinam a integralizar o capital da holding "
                            "(Manual DREI, item 4.3.5, a).")
        if not re.search(r"prefer[êe]ncia", limpo, re.I):
            rel.add("ALERTA", "A alteração não registra a renúncia ao direito de preferência pelos demais sócios.")

    # --- tabelas: total fecha?
    bloco = []
    for l in linhas + [""]:
        if l.startswith("|"):
            bloco.append(l)
            continue
        if bloco:
            _conferir_tabela(bloco, rel)
            bloco = []

    # --- cruzamento com os dados
    if dados:
        _cruzar(limpo, dados, eh_alteracao, rel)
    return rel


def _rom(n):
    from lib_holding import romano
    return romano(n)


def _conferir_tabela(bloco, rel):
    soma_q, soma_v, total = 0, Decimal(0), None
    for l in bloco:
        cel = [c.strip() for c in l.strip("|").split("|")]
        if len(cel) < 3 or set("".join(cel)) <= set("-: "):
            continue
        q = re.fullmatch(r"[\d.]+(,00)?", cel[1].replace(" ", ""))
        v = re.search(r"R?\$?\s*([\d.]+,\d{2})", cel[-1])
        if "TOTAL" in cel[0].upper():
            total = (int(cel[1].replace(".", "").split(",")[0]) if q else None, numero_br(v.group(1)) if v else None)
            if cel[1].endswith(",00"):
                rel.add("ALERTA", f"Na linha TOTAL, a quantidade de quotas está formatada como dinheiro ({cel[1]}).")
        elif q:
            soma_q += int(cel[1].replace(".", "").split(",")[0])
            if v:
                soma_v += numero_br(v.group(1))
    if total:
        if total[0] is not None and total[0] != soma_q:
            rel.add("ERRO", f"Tabela do quadro: as linhas somam {fmt_int(soma_q)} quotas, mas o TOTAL diz {fmt_int(total[0])}.")
        if total[1] is not None and total[1] != soma_v:
            rel.add("ERRO", f"Tabela do quadro: as linhas somam R$ {soma_v}, mas o TOTAL diz R$ {total[1]}.")


def _cruzar(txt, dados, eh_alt, rel):
    h = dados.get("holding", {})
    if h.get("denominacao") and h["denominacao"] not in txt:
        rel.add("ERRO", f"O nome da holding ('{h['denominacao']}') não aparece com a grafia do arquivo de dados.")
    invs = {i["id"]: i for i in dados.get("investidas", [])}
    if not eh_alt:
        for s in dados.get("socios", []):
            if s.get("nome") and s["nome"] not in txt:
                rel.add("ERRO", f"Sócio '{s['nome']}' não aparece com a grafia do arquivo de dados.")
            for p in s.get("participacoes", []):
                inv = invs.get(p.get("investida"), {})
                q = fmt_int(int(p.get("quotas", 0)))
                if q not in txt:
                    rel.add("ERRO", f"{s.get('nome')}: a quantidade conferida de {inv.get('denominacao')} ({q} quotas) "
                                    "não aparece no contrato.")
        for inv in invs.values():
            cnpj = inv.get("cnpj", "")
            if cnpj and "[" not in cnpj and cnpj not in txt:
                rel.add("ERRO", f"CNPJ de {inv.get('denominacao')} ({cnpj}) não aparece no contrato.")
    else:
        alvo = None
        for inv in invs.values():
            if inv.get("denominacao") and inv["denominacao"] in txt[:800]:
                alvo = inv
        if alvo and alvo.get("cnpj") and "[" not in alvo["cnpj"] and alvo["cnpj"] not in txt:
            rel.add("ERRO", f"CNPJ de {alvo['denominacao']} não confere com o arquivo de dados.")


def main():
    forcar_utf8()
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("arquivos", nargs="+")
    ap.add_argument("--dados", help="o mesmo .json usado no gerar_holding.py")
    ap.add_argument("--protocolo", action="store_true", help="versão de protocolo: campo em aberto vira ERRO")
    ap.add_argument("--saida", help="grava o relatório neste .md")
    a = ap.parse_args()
    dados = json.load(io.open(a.dados, encoding="utf-8-sig")) if a.dados else None

    out, erros = [], 0
    for arq in a.arquivos:
        rel = conferir(arq, dados, a.protocolo)
        erros += rel.conta("ERRO")
        out.append(f"## {rel.nome}")
        out.append(f"ERRO {rel.conta('ERRO')} | ALERTA {rel.conta('ALERTA')} | PENDÊNCIA {rel.conta('PENDÊNCIA')}")
        out += [f"- **{s}** — {m}" for s, m in rel.itens] or ["- nada a apontar"]
        out.append("")
    txt = "\n".join(out)
    print(txt)
    if a.saida:
        with io.open(a.saida, "w", encoding="utf-8") as f:
            f.write("# Conferência das minutas\n\n" + txt)
    sys.exit(1 if erros else 0)


if __name__ == "__main__":
    main()
