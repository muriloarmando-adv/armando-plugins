#!/usr/bin/env python3
"""Confere um Memorando de Entendimentos (MOU) do NPPS antes de sair do escritório.

Lê .docx, .md ou .txt e acusa, com a linha:

  ERRO      numeração que pula, repete ou foge do capítulo; número solto;
            remissão a cláusula ou capítulo inexistente; parte qualificada que
            não assina; CPF/CNPJ com dígito errado; mesma empresa com dois CNPJ;
            extenso que não bate com o número; tabela cujo TOTAL não fecha;
            considerandos fora de sequência; sem objeto, sem disposições
            gerais, sem foro, sem fecho com local e data.
  ALERTA    campo em aberto (ERRO com --final); nome grafado de dois jeitos;
            casado sem regime de bens; PJ sem representante; palavra repetida;
            erro de digitação conhecido do acervo; "deste Contrato" num MOU;
            renúncia genérica; "incapacidade absoluta"; reversão em favor de
            terceiro; registro (R-3-M-308) no lugar de matrícula; autorremissão.
  CONFERIR  decisão humana: força vinculante (art. 462), colação e cláusulas
            restritivas na doação, vedação de cônjuge refletida no contrato
            social, totais em texto corrido.

Uso:  python3 conferir_mou.py mou.docx [--final]
Saída 1 se houver ERRO. Minuta com ERRO não sai do escritório.
"""

import argparse
import os
import re
import sys
from decimal import Decimal

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from lib_mou import (forcar_utf8, linhas_do_arquivo, sem_markdown, norm,  # noqa: E402
                     sem_acento, cpf_valido, cnpj_valido, chave_extenso,
                     reais_extenso, inteiro_extenso, fracao_extenso,
                     FRACOES_UNICODE, para_decimal, de_romano, romano, fmt_real)

MESES = ("janeiro|fevereiro|março|marco|abril|maio|junho|julho|agosto|setembro|"
         "outubro|novembro|dezembro")
PALAVRAS_NUM = set(("zero um uma dois duas tres três quatro cinco seis sete oito nove "
                    "dez onze doze treze quatorze catorze quinze dezesseis dezessete "
                    "dezoito dezenove vinte trinta quarenta cinquenta sessenta setenta "
                    "oitenta noventa cem cento duzentos duzentas trezentos trezentas "
                    "quatrocentos quatrocentas quinhentos quinhentas seiscentos "
                    "seiscentas setecentos setecentas oitocentos oitocentas novecentos "
                    "novecentas mil milhão milhões bilhão bilhões").split())

# Erros de digitação achados no acervo de MOUs do NPPS (ver
# referencias/defeitos-do-acervo.md). Padrão -> correção.
DIGITACAO = [
    (r"\bdiv[óo]cio\b", "divórcio"),
    (r"\bdiv[óo]rico\b", "divórcio"),
    (r"\brevestidos e reembolsados\b", "revertidos e reembolsados"),
    (r"\bprovidenciais iniciais\b", "providências iniciais"),
    (r"\bnu-propriedade\b", "nua-propriedade"),
    (r"\bMemorando de Entendimento\b(?!s)", "Memorando de Entendimentos"),
    (r"\bdas empresa operacional\b", "das empresas operacionais"),
    (r"\bINTERESSADOS\b", "\"Partes\" (termo definido no preâmbulo)"),
]


class Relatorio:
    def __init__(self):
        self.itens = {"ERRO": [], "ALERTA": [], "CONFERIR": []}
        self._vistos = set()

    def add(self, nivel, linha, msg):
        chave = (nivel, linha, msg)
        if chave in self._vistos:
            return
        self._vistos.add(chave)
        self.itens[nivel].append((linha, msg))

    def imprimir(self):
        for nivel in ("ERRO", "ALERTA", "CONFERIR"):
            for linha, msg in sorted(self.itens[nivel], key=lambda x: (x[0] or 0)):
                onde = f"l.{linha:<4}" if linha else "      "
                print(f"{nivel:<9}{onde} {msg}")
        n = {k: len(v) for k, v in self.itens.items()}
        print(f"\n{n['ERRO']} ERRO · {n['ALERTA']} ALERTA · {n['CONFERIR']} CONFERIR")


def levenshtein(a, b):
    if a == b:
        return 0
    ant = list(range(len(b) + 1))
    for i, ca in enumerate(a, 1):
        atual = [i]
        for j, cb in enumerate(b, 1):
            atual.append(min(ant[j] + 1, atual[j - 1] + 1, ant[j - 1] + (ca != cb)))
        ant = atual
    return ant[-1]


def eh_titulo(txt):
    t = txt.strip().rstrip(":").strip()
    if not t or len(t) > 160 or re.search(r"[a-zà-ú]", t):
        return False
    return bool(re.match(r"^(D[OA]S?|DISPOSI[CÇ])", sem_acento(t)))


def main():
    forcar_utf8()
    ap = argparse.ArgumentParser(description="Confere MOU do NPPS")
    ap.add_argument("arquivo")
    ap.add_argument("--final", action="store_true",
                    help="versão para assinatura: campo em aberto vira ERRO")
    a = ap.parse_args()

    brutas = linhas_do_arquivo(a.arquivo)
    L = [sem_markdown(x).replace(" ", " ").rstrip() for x in brutas]
    R = Relatorio()
    n = len(L)

    def acha(padrao, ini=0, flags=re.I):
        for i in range(ini, n):
            if re.search(padrao, L[i], flags):
                return i
        return None

    i_cons = acha(r"^\s*CONSIDERANDO")
    i_fecho = acha(r"^\s*E,?\s+por\s+estarem")
    i_cap1 = None
    for i in range(n):
        if eh_titulo(re.sub(r"^\s*\d+\.?\s*", "", L[i])) and "OBJETO" in norm(L[i]):
            i_cap1 = i
            break
    fim_qualif = i_cons if i_cons is not None else (i_cap1 or 0)
    fim_corpo = i_fecho if i_fecho is not None else n
    assinaturas = " \n ".join(L[fim_corpo:]) if i_fecho is not None else ""

    # ------------------------------------------------------------ partes ---
    partes = []
    interveniente = False
    re_parte = re.compile(r"^\s*([A-ZÀ-Ý][A-ZÀ-Ý0-9 .&'\-/]{4,}?)\s*,\s*(.*)$")
    for i in range(fim_qualif):
        txt = L[i].strip()
        if re.search(r"interveniente", txt, re.I) and len(txt) < 120:
            interveniente = True
            continue
        m = re_parte.match(txt)
        if not m:
            continue
        nome = re.sub(r"\s+", " ", m.group(1)).strip(" .")
        if len(nome.split()) < 2 or "MEMORANDO" in norm(nome):
            continue
        resto = m.group(2)
        pj = bool(re.search(r"pessoa jur[íi]dica|\bLTDA\b|\bS\.?/?A\.?$|EIRELI", txt, re.I))
        partes.append({"nome": nome, "linha": i + 1, "txt": txt, "pj": pj,
                       "interv": interveniente})
        if pj:
            if not re.search(r"representad", resto, re.I):
                R.add("ALERTA", i + 1, f"{nome}: pessoa jurídica sem quem a representa")
            if not re.search(r"CNPJ", resto):
                R.add("ALERTA", i + 1, f"{nome}: pessoa jurídica sem CNPJ")
        else:
            if not re.search(r"CPF", resto):
                R.add("ALERTA", i + 1, f"{nome}: sem CPF na qualificação")
            if re.search(r"\bcasad[oa]\b", resto, re.I) and not re.search(r"regime", resto, re.I):
                R.add("ALERTA", i + 1, f"{nome}: casado(a) sem regime de bens — define "
                      "se o cônjuge precisa anuir (art. 1.647 do CC)")
            if (re.search(r"uni[ãa]o est[áa]vel|convivente", resto, re.I)
                    and not re.search(r"regime|contrato de conviv", resto, re.I)):
                R.add("CONFERIR", i + 1, f"{nome}: união estável sem regime/contrato de "
                      "convivência — sem contrato, vale a comunhão parcial (art. 1.725)")
    # Estado civil cruzado: "casado com Fulana" x Fulana "solteira"; cônjuge
    # nomeado que não assina como parte nem como anuente.
    primeiros = {sem_acento(p["nome"].split()[0]).upper(): p for p in partes}
    for i in range(fim_qualif):
        for m in re.finditer(r"\bcasad[oa]\b[^;]{0,80}?\bcom\s+([A-ZÀ-Ý][a-zà-ÿA-ZÀ-Ý]+)", L[i]):
            conj = sem_acento(m.group(1)).upper()
            alvo = primeiros.get(conj)
            if alvo and re.search(r"\bsolteir[oa]\b", alvo["txt"], re.I):
                R.add("ALERTA", i + 1, f"casado(a) com {m.group(1)}, mas {alvo['nome']} está "
                      f"qualificado(a) como solteiro(a) (l.{alvo['linha']})")
            elif not alvo and conj not in ("O", "A"):
                R.add("CONFERIR", i + 1, f"o cônjuge \"{m.group(1)}…\" não figura como parte "
                      "nem como interveniente anuente: precisa anuir? (art. 1.647 do CC)")
    if not partes:
        R.add("ALERTA", None, "não identifiquei a qualificação das partes "
              "(nome em CAIXA ALTA seguido de vírgula)")

    # ------------------------------------------------------- assinaturas ---
    if i_fecho is None:
        R.add("ERRO", None, "sem fecho (\"E por estarem assim justas e acertadas...\")")
    else:
        bloco = norm(assinaturas)
        for p in partes:
            if norm(p["nome"]) not in bloco:
                papel = "interveniente anuente" if p["interv"] else "parte"
                R.add("ERRO", p["linha"], f"{p['nome']} ({papel}) é qualificado mas não "
                      "tem linha de assinatura")
        if not re.search(r"\d{1,2}º?\s+de\s+(%s)\s+de\s+\d{4}" % MESES, assinaturas, re.I):
            R.add("ERRO", i_fecho + 1, "fecho sem local e data")
        if (re.search(r"presen[çc]a das testemunhas", L[i_fecho], re.I)
                and not re.search(r"testemunha", " ".join(L[i_fecho + 1:]), re.I)):
            R.add("ALERTA", i_fecho + 1, "o fecho fala em testemunhas, mas não há bloco delas")

    # ---------------------------------------------- grafia dos nomes ---
    palavras = []
    for i, x in enumerate(L[:fim_corpo] + L[fim_corpo:], 1):
        for w in re.findall(r"[A-Za-zÀ-ÿ0-9\-]+", x):
            palavras.append((w, i))
    for p in partes:
        alvo = p["nome"].split()
        k = len(alvo)
        alvo_n = [sem_acento(w).upper() for w in alvo]
        variantes = {}
        for j in range(len(palavras) - k + 1):
            if sem_acento(palavras[j][0]).upper() != alvo_n[0]:
                continue
            jan = [w for w, _ in palavras[j:j + k]]
            jan_n = [sem_acento(w).upper() for w in jan]
            dif = [t for t in range(k) if jan_n[t] != alvo_n[t]]
            linha = palavras[j][1]
            if not dif:
                bruto = " ".join(w.upper() for w in jan)
                if bruto != " ".join(w.upper() for w in alvo):
                    variantes.setdefault(bruto, linha)
            elif len(dif) == 1:
                t = dif[0]
                if len(alvo_n[t]) >= 5 and 0 < levenshtein(jan_n[t], alvo_n[t]) <= 2:
                    variantes.setdefault(" ".join(w.upper() for w in jan), linha)
        for v, linha in variantes.items():
            R.add("ALERTA", linha, f"nome grafado \"{v}\"; na qualificação está "
                  f"\"{p['nome']}\"")

    # -------------------------------------------------- CPF / CNPJ ---
    texto_todo = "\n".join(L)
    for i, x in enumerate(L, 1):
        x = re.sub(r"\[\[.*?\]\]", " ", x)   # campo em aberto já é acusado abaixo
        for c in re.findall(r"\b\d{3}\.\d{3}\.\d{3}-\d{2}\b", x):
            if not cpf_valido(c):
                R.add("ERRO", i, f"CPF {c} com dígito verificador inválido")
        for c in re.findall(r"\b\d{2}\.\d{3}\.\d{3}/\d{4}-\d{2}\b", x):
            if not cnpj_valido(c):
                R.add("ERRO", i, f"CNPJ {c} com dígito verificador inválido")
    empresas = {}
    for i, x in enumerate(L, 1):
        for m in re.finditer(r"([A-ZÀ-Ý][\w&.\-À-ÿ ]{2,60}?\b(?:LTDA|Ltda)\.?)[^\n]{0,80}?"
                             r"CNPJ[^\d]{0,20}(\d{2}\.\d{3}\.\d{3}/\d{4}-\d{2})", x):
            # Do LTDA para trás, só as palavras do nome: para na primeira
            # minúscula que não seja conectivo ("João é sócio da Empresa X Ltda").
            conect = ("de", "da", "do", "das", "dos", "e", "&")
            nome_t = []
            for t in reversed(m.group(1).split()):
                if t[0].isupper() or t.lower() in conect:
                    nome_t.insert(0, t)
                else:
                    break
            while nome_t and nome_t[0].lower() in conect:
                nome_t.pop(0)
            nome = norm(" ".join(nome_t)).replace("LTDA.", "LTDA")
            empresas.setdefault(nome, {}).setdefault(m.group(2), i)
    for nome, cnpjs in empresas.items():
        if len(cnpjs) > 1:
            lista = ", ".join(f"{c} (l.{li})" for c, li in cnpjs.items())
            R.add("ERRO", min(cnpjs.values()), f"{nome} aparece com CNPJ diferentes: {lista}")

    # ---------------------------------------------------- numeração ---
    titulos_num = []
    for i in range(fim_qualif, fim_corpo):
        m = re.match(r"^\s*(\d+)\.?\s+(.*)$", L[i])
        if m and eh_titulo(m.group(2)):
            titulos_num.append(int(m.group(1)))
    auto = len(titulos_num) >= 3 and len(set(titulos_num)) == 1
    if auto:
        R.add("ALERTA", None, "os capítulos estão todos como \"1.\": numeração automática "
              "do editor, que o texto exportado não mostra. Capítulos conferidos pela "
              "numeração das cláusulas; confira no Word.")
    cap = 0
    capitulos = {}          # numero -> (titulo, linha)
    clausulas = {}          # "3.1" -> linha
    ultimo = {}             # tupla-mãe -> último filho
    linha_da_clausula = []  # (linha, numero) para autorremissão
    soltos_auto = 0
    for i in range(fim_qualif, fim_corpo):
        x = L[i].strip()
        if not x or x.startswith("|"):
            continue
        m = re.match(r"^(\d+)\.?\s+(.*)$", x)
        if m and eh_titulo(m.group(2)):
            num = int(m.group(1))
            if auto:
                num = cap + 1
            elif num != cap + 1:
                R.add("ERRO", i + 1, f"capítulo {num} depois do {cap}")
            cap = num
            capitulos[cap] = (m.group(2).strip(), i + 1)
            continue
        if eh_titulo(x):
            cap += 1
            capitulos[cap] = (x, i + 1)
            continue
        m = re.match(r"^(\d+(?:\.\d+)+)\.?\s*\S", x)
        if m:
            t = tuple(int(v) for v in m.group(1).split("."))
            num = m.group(1)
            if cap and t[0] != cap:
                R.add("ERRO", i + 1, f"cláusula {num} dentro do capítulo {cap}")
            elif not cap:
                cap = t[0]
            mae = t[:-1]
            if len(t) > 2 and ".".join(map(str, mae)) not in clausulas:
                R.add("ERRO", i + 1, f"subcláusula {num} sem a cláusula-mãe "
                      f"{'.'.join(map(str, mae))}")
            esperado = ultimo.get(mae, 0) + 1
            if t[-1] == esperado - 1:
                R.add("ERRO", i + 1, f"cláusula {num} repetida")
            elif t[-1] > esperado:
                faltou = ".".join(map(str, mae + (esperado,)))
                R.add("ERRO", i + 1, f"numeração pula de {'.'.join(map(str, mae + (esperado - 1,)))}"
                      f" para {num} (falta {faltou})" if esperado > 1 else
                      f"cláusula {num} sem a {faltou}")
            elif t[-1] < esperado - 1:
                R.add("ERRO", i + 1, f"cláusula {num} fora de ordem")
            ultimo[mae] = max(ultimo.get(mae, 0), t[-1])
            clausulas.setdefault(num, i + 1)
            linha_da_clausula.append((i + 1, num))
            continue
        m = re.match(r"^(\d+)\.?\s+([A-Za-zÀ-ÿ].*)$", x)
        if m and cap:
            if auto and m.group(1) == "1":
                soltos_auto += 1
            else:
                R.add("ERRO", i + 1, f"número solto \"{m.group(1)}.\" no capítulo {cap} — "
                      f"devia ser {cap}.{ultimo.get((cap,), 0) + 1}?")
    if soltos_auto:
        R.add("ALERTA", None, f"{soltos_auto} parágrafo(s) com \"1.\" de lista automática: "
              "confira a numeração no Word")

    # ------------------------------------------------ considerandos ---
    if i_cons is not None:
        fim_c = i_cap1 if i_cap1 and i_cap1 > i_cons else fim_corpo
        esperado = 1
        for i in range(i_cons + 1, fim_c):
            m = re.match(r"^\s*\(([ivxlc]+)\)", L[i], re.I)
            if m:
                v = de_romano(m.group(1))
                if v != esperado:
                    R.add("ERRO", i + 1, f"considerando ({m.group(1)}) onde se esperava "
                          f"({romano(esperado).lower()})")
                esperado = v + 1

    # --------------------------------------------------- remissões ---
    def clausula_em(linha):
        atual = None
        for li, num in linha_da_clausula:
            if li <= linha:
                atual = num
            else:
                break
        return atual

    re_cl = re.compile(r"\b(?:cl[áa]usulas?|itens?|item|subcl[áa]usulas?|t[óo]picos?)"
                       r"\s+(?:n[º°o]\.?\s*)?(\d+(?:\.\d+)*)((?:\s*(?:,|e|a)\s*\d+(?:\.\d+)*)*)"
                       r"(?![^\n]{0,4}\d)(?!\s+(?:d[oa]s?\s+)?(?:contrato|acordo|lei|c[óo]digo|estatuto))",
                       re.I)
    re_cap = re.compile(r"\b(cap[íi]tulos?|se[çc](?:ão|ao|ões|oes))\s+(?:n[º°o]\.?\s*)?"
                        r"(\d+(?:\.\d+)*)", re.I)
    for i in range(0, fim_corpo):
        x = L[i]
        for m in re_cl.finditer(x):
            nums = [m.group(1)] + re.findall(r"\d+(?:\.\d+)*", m.group(2) or "")
            for num in nums:
                if "." in num:
                    if num not in clausulas:
                        R.add("ERRO", i + 1, f"remissão à cláusula {num}, que não existe")
                    elif clausula_em(i + 1) == num and clausulas[num] <= i + 1:
                        R.add("ALERTA", i + 1, f"a cláusula {num} remete a si mesma")
                elif int(num) not in capitulos:
                    R.add("ERRO", i + 1, f"remissão à cláusula/capítulo {num}, que não existe")
        for m in re_cap.finditer(x):
            num = m.group(2)
            if "." in num:
                if num not in clausulas:
                    R.add("ERRO", i + 1, f"remissão a \"{m.group(1)} {num}\", que não existe")
            elif int(num) not in capitulos:
                R.add("ERRO", i + 1, f"remissão a \"{m.group(1)} {num}\", que não existe")

    # ---------------------------------------- capítulos obrigatórios ---
    titulos = " | ".join(norm(t) for t, _ in capitulos.values())
    for termo, nivel, msg in (("OBJETO", "ERRO", "sem capítulo DO OBJETO"),
                              ("DISPOSICOES GERAIS", "ERRO", "sem DISPOSIÇÕES GERAIS"),
                              ("VIGENCIA", "ALERTA", "sem DA VIGÊNCIA E PRAZOS"),
                              ("RESCIS", "ALERTA", "sem DA RESCISÃO")):
        if termo not in titulos:
            R.add(nivel, None, msg)
    corpo = "\n".join(L[:fim_corpo])
    if not re.search(r"eleito o foro|foro da comarca", corpo, re.I):
        R.add("ERRO", None, "sem cláusula de foro")
    if not re.search(r"etapas procedimentais", corpo, re.I):
        R.add("ALERTA", None, "não achei as etapas procedimentais (DAS OBRIGAÇÕES): o MOU "
              "deve dizer quais instrumentos definitivos virão e em que ordem")

    # -------------------------------------------- campos em aberto ---
    nivel_aberto = "ERRO" if a.final else "ALERTA"
    for i in range(fim_corpo):
        x = L[i]
        achado = None
        if re.search(r"\[\[.*?\]\]", x):
            achado = re.search(r"\[\[.*?\]\]", x).group(0)
        elif re.search(r"_{3,}", x):
            achado = "____"
        elif re.search(r"\|\s*\?\s*\|", x) or re.match(r"^\s*\?\s*$", x):
            achado = "\"?\" no lugar do dado"
        elif re.search(r"\bX{3,}\b", x):
            achado = "XXX"
        elif re.search(r"n[ãa]o indicad[ao]", x, re.I):
            achado = "\"não indicada\""
        if achado:
            R.add(nivel_aberto, i + 1, f"campo em aberto: {achado}")

    # ------------------------------------------------------ extenso ---
    for i in range(fim_corpo):
        x = L[i]
        for m in re.finditer(r"R\$\s*([\d.]+,\d{2})\s*\(([^)]*)\)", x):
            v = para_decimal(m.group(1))
            if chave_extenso(m.group(2)) != chave_extenso(reais_extenso(v)):
                R.add("ERRO", i + 1, f"R$ {m.group(1)} por extenso deveria ser "
                      f"\"{reais_extenso(v)}\", está \"{m.group(2).strip()}\"")
        for m in re.finditer(r"(?<![\d.,/R$])(\d{1,3}(?:\.\d{3})+|\d+)(?:º)?\s*\(([^)]+)\)", x):
            txt = m.group(2).strip().lower()
            prim = re.split(r"[\s,]+", txt)[0]
            if prim not in PALAVRAS_NUM:
                continue
            v = int(m.group(1).replace(".", ""))
            if chave_extenso(txt) != chave_extenso(inteiro_extenso(v)):
                R.add("ERRO", i + 1, f"{m.group(1)} por extenso deveria ser "
                      f"\"{inteiro_extenso(v)}\", está \"{m.group(2).strip()}\"")
        for m in re.finditer(r"(\d+(?:,\d+)?)\s*%\s*\(([^)]+)\)", x):
            p = para_decimal(m.group(1))
            if p != int(p):
                continue
            esp = inteiro_extenso(int(p)) + " por cento"
            if chave_extenso(m.group(2)) != chave_extenso(esp):
                R.add("ERRO", i + 1, f"{m.group(1)}% por extenso deveria ser \"{esp}\", "
                      f"está \"{m.group(2).strip()}\"")
        fracs = [((int(a_), int(b_)), t) for a_, b_, t in
                 re.findall(r"(?<![\d/])(\d+)/(\d+)\s*\(([^)]+)\)", x)]
        fracs += [(FRACOES_UNICODE[c], t) for c, t in
                  re.findall("([%s])\\s*\\(([^)]+)\\)" % "".join(FRACOES_UNICODE), x)]
        for (num, den), t in fracs:
            if den == 0:
                continue
            esp = fracao_extenso(num, den)
            ok = chave_extenso(t) == chave_extenso(esp) or (
                (num, den) == (1, 2) and "metade" in t.lower())
            if not ok:
                R.add("ERRO", i + 1, f"{num}/{den} por extenso deveria ser \"{esp}\", "
                      f"está \"{t.strip()}\"")
        if not x.lstrip().startswith("|"):
            for m in re.finditer(r"R\$\s*[\d.]+,\d{2}(?!\s*\()", x):
                R.add("ALERTA", i + 1, f"{m.group(0)} sem extenso")

    # ------------------------------------------------------- totais ---
    def valor(s):
        m = re.search(r"R\$\s*([\d.]+,\d{2})", s)
        return para_decimal(m.group(1)) if m else None

    i = 0
    while i < fim_corpo:
        if not L[i].lstrip().startswith("|"):
            i += 1
            continue
        ini = i
        while i < fim_corpo and L[i].lstrip().startswith("|"):
            i += 1
        linhas_t = list(range(ini, i))
        tot = [k for k in linhas_t if re.search(r"\bTOTAL\b", L[k], re.I)]
        if tot:
            k_tot = tot[0]
            v_tot = valor(L[k_tot])
            soma = sum((valor(L[k]) or Decimal(0)) for k in linhas_t if k != k_tot)
            if v_tot is not None and abs(soma - v_tot) > Decimal("0.005"):
                R.add("ERRO", k_tot + 1, f"TOTAL da tabela é R$ {fmt_real(v_tot)} mas as "
                      f"linhas somam R$ {fmt_real(soma)}")
    for k in range(fim_corpo):
        x = L[k]
        m = re.search(r"totaliza(?:ndo|m|ndo em)?|perfaz(?:endo)?|no total de|somando", x, re.I)
        if not m or re.search(r"unit[áa]ri", x, re.I) or x.lstrip().startswith("|"):
            continue
        antes = [para_decimal(v) for v in re.findall(r"R\$\s*([\d.]+,\d{2})", x[:m.start()])]
        depois = re.search(r"R\$\s*([\d.]+,\d{2})", x[m.end():])
        if len(antes) >= 2 and depois:
            if sum(antes) != para_decimal(depois.group(1)):
                R.add("CONFERIR", k + 1, f"as parcelas antes de \"{m.group(0)}\" somam "
                      f"R$ {fmt_real(sum(antes))}, o total diz R$ {depois.group(1)}")

    # -------------------------------------- texto e pontos jurídicos ---
    for k in range(fim_corpo):
        x = L[k]
        for m in re.finditer(r"\b([A-Za-zÀ-ÿ]{2,})\s+\1\b", x, re.I):
            R.add("ALERTA", k + 1, f"palavra repetida: \"{m.group(0)}\"")
        for padrao, certo in DIGITACAO:
            # Padrão com maiúscula no texto é sensível à caixa ("INTERESSADOS"
            # é sobra de modelo; "terceiros interessados" não é).
            sensivel = any(c.isupper() for c in re.sub(r"\\[a-z]", "", padrao))
            mm = re.search(padrao, x, 0 if sensivel else re.I)
            if mm:
                R.add("ALERTA", k + 1, f"\"{mm.group(0)}\" → {certo}")
        if re.search(r"\b(?:deste|este|do presente|neste)\s+Contrato\b", x):
            R.add("ALERTA", k + 1, "\"Contrato\" num Memorando — o instrumento é o MOU "
                  "(sobra do modelo de contrato)")
        if re.search(r"renunciando a qualquer reclama", x, re.I):
            R.add("ALERTA", k + 1, "renúncia genérica a \"qualquer reclamação presente ou "
                  "futura\": use a declaração de inexistência de pendência (modelos de 2026)")
        if re.search(r"incapacidade absoluta|absolutamente incapaz", x, re.I):
            R.add("ALERTA", k + 1, "\"incapacidade absoluta\" de maior de 16 anos não existe "
                  "desde a Lei 13.146/2015 (art. 3º do CC): use os termos da sentença de curatela")
        if re.search(r"1\.831", x) and re.search(r"sucess", x, re.I):
            R.add("ALERTA", k + 1, "art. 1.831 do CC é o direito real de habitação do "
                  "cônjuge, não a regra da sucessão legítima e testamentária")
        if re.search(r"(?:transferid[oa]s?|reverter[áa]|retornar[áa]|destinad[oa]s?)\s+"
                     r"(?:\w+\s+){0,2}aos filhos", x, re.I):
            R.add("ALERTA", k + 1, "reversão/destino aos filhos do donatário: a reversão só "
                  "vale em favor do doador (art. 547, parágrafo único, do CC)")
        if re.search(r"sem comunica[çc][ãa]o com o c[ôo]njuge", x, re.I):
            R.add("CONFERIR", k + 1, "incomunicabilidade afasta a meação, não a herança: o "
                  "cônjuge pode concorrer com os filhos (arts. 1.829, I, e 1.845 do CC)")
        if re.search(r"\bR[-.]?\s?\d+[-/]M[-.]?\s?\d+", x):
            R.add("ALERTA", k + 1, "\"R-n-M-n\" é o número do registro (ato), não da "
                  "matrícula: a matrícula é o número depois do M")
    if re.search(r"art\.?\s*462", corpo, re.I):
        R.add("CONFERIR", None, "o MOU se declara feito \"nos termos do art. 462 do CC\" "
              "(contrato preliminar): pode ser exigido em juízo (arts. 463 e 464). "
              "Confirme que é essa a força que o caso pede")
    if re.search(r"\bdoa[çc](?:[ãa]o|[õo]es)|\bdoad[oa]s?\b|\bdoar\b|\bdonat[áa]ri",
                 corpo, re.I):
        if not re.search(r"cola[çc][ãa]o", corpo, re.I):
            R.add("CONFERIR", None, "há doação a herdeiro e o MOU não diz se é adiantamento "
                  "de legítima ou sai da parte disponível (dispensa de colação, arts. 544 e "
                  "2.005 do CC)")
        if (re.search(r"inalienabilidade|impenhorabilidade|incomunicabilidade", corpo, re.I)
                and not re.search(r"justa causa", corpo, re.I)):
            R.add("CONFERIR", None, "cláusulas restritivas sobre bem que integra a legítima "
                  "pedem justa causa declarada (art. 1.848 do CC)")
    if re.search(r"vedad[oa].{0,80}c[ôo]njuge", corpo, re.I | re.S):
        R.add("CONFERIR", None, "a vedação de cônjuge só protege de fato se for repetida no "
              "contrato social (cessão e sucessão de quotas) e na doação (incomunicabilidade)")
    if re.search(r"\banexo\b", corpo, re.I) and not re.search(r"^\s*ANEXO", "\n".join(L[fim_corpo:]),
                                                           re.M):
        R.add("ALERTA", None, "o texto cita anexo que não acompanha o documento")

    R.imprimir()
    return 1 if R.itens["ERRO"] else 0


if __name__ == "__main__":
    sys.exit(main())
