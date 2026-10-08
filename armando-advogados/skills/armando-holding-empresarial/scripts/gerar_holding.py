#!/usr/bin/env python3
"""Gera o contrato social da holding empresarial e as alteracoes contratuais
de cada sociedade investida, a partir de um unico arquivo de dados.

    python3 gerar_holding.py dados.json --saida pasta/

Produz, na pasta de saida:
    00-diagnostico.md             erros, alertas, pontos a conferir e pendencias
    01-contrato-<holding>.md      contrato social da holding (2o Ato do DREI)
    02-alteracao-<investida>.md   uma por sociedade investida (1o Ato do DREI)

Sai com codigo 1 se houver ERRO. Com ERRO, NAO grava as minutas (so o
diagnostico) — quadro que nao fecha nao vira texto pronto para colar. Use
--forcar apenas para inspecionar o rascunho, nunca para entregar.

Porque um arquivo so de dados: o contrato da holding e as alteracoes das
investidas descrevem a MESMA operacao vista dos dois lados. Quantidade de
quotas, valor e qualificacao saem do mesmo lugar, e nao podem divergir.

Modelos de texto em ../assets/ (ou assets/ ao lado do script). Para mudar a
redacao, edite o modelo, nao este script.
"""

import argparse
import io
import json
import os
import re
import sys
from decimal import Decimal

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from lib_holding import (ErroModelo, fmt_int, fmt_pct, fmt_real, forcar_utf8,  # noqa: E402
                         ordinal_extenso, para_decimal, qt, renderizar, rs, slug)

PH = "[......]"

ESTADOS = {"AC": "Acre", "AL": "Alagoas", "AP": "Amapá", "AM": "Amazonas", "BA": "Bahia",
           "CE": "Ceará", "DF": "Distrito Federal", "ES": "Espírito Santo", "GO": "Goiás",
           "MA": "Maranhão", "MT": "Mato Grosso", "MS": "Mato Grosso do Sul",
           "MG": "Minas Gerais", "PA": "Pará", "PB": "Paraíba", "PR": "Paraná",
           "PE": "Pernambuco", "PI": "Piauí", "RJ": "Rio de Janeiro",
           "RN": "Rio Grande do Norte", "RS": "Rio Grande do Sul", "RO": "Rondônia",
           "RR": "Roraima", "SC": "Santa Catarina", "SP": "São Paulo", "SE": "Sergipe",
           "TO": "Tocantins"}

JUNTAS = {"TO": "Junta Comercial do Estado do Tocantins – JUCETINS"}


class Diag:
    def __init__(self):
        self.erros, self.alertas, self.conferir, self.pendencias = [], [], [], []

    def erro(self, m): self.erros.append(m)
    def alerta(self, m): self.alertas.append(m)
    def conf(self, m):
        if m not in self.conferir:
            self.conferir.append(m)
    def pend(self, m):
        if m not in self.pendencias:
            self.pendencias.append(m)


def achar_assets():
    aqui = os.path.dirname(os.path.abspath(__file__))
    for cand in (os.path.join(aqui, "..", "assets"), os.path.join(aqui, "assets"),
                 os.path.join(aqui, "..", "skills", "armando-holding-empresarial", "assets")):
        if os.path.isfile(os.path.join(cand, "modelo-contrato-holding.md")):
            return os.path.normpath(cand)
    raise SystemExit("Modelos não encontrados (assets/modelo-contrato-holding.md).")


def ler(caminho):
    with io.open(caminho, encoding="utf-8-sig") as f:
        return f.read()


def val(d, k, padrao=None):
    v = d.get(k, padrao) if isinstance(d, dict) else padrao
    return padrao if v is None else v


def campo(d, k, diag, rotulo):
    """Valor de texto obrigatorio; vazio vira placeholder e pendencia."""
    v = str(val(d, k, "") or "").strip()
    if not v or tem_placeholder(v):
        diag.pend(rotulo)
        return PH if not v else v
    return v


def tem_placeholder(v):
    return bool(re.search(r"\[\s*\.{3,}\s*\]|\(_{3,}|_{5,}|X{4,}", str(v)))


def artigo(socio):
    return "A sócia" if str(val(socio, "genero", "M")).upper().startswith("F") else "O sócio"


def lista_nomes(nomes):
    nomes = [f"**{n}**" for n in nomes]
    if len(nomes) <= 1:
        return "".join(nomes)
    return ", ".join(nomes[:-1]) + " e " + nomes[-1]


def tabela(linhas, total_q, total_v):
    t = ["| SÓCIOS | QUOTAS | % | VALOR R$ |", "|---|---:|---:|---:|"]
    for nome, q, pct, v in linhas:
        t.append(f"| {nome} | {fmt_int(q)} | {fmt_pct(pct)} | R$ {fmt_real(v)} |")
    t.append(f"| **TOTAL** | **{fmt_int(total_q)}** | **100%** | **R$ {fmt_real(total_v)}** |")
    return "\n".join(t)


# ------------------------------------------------------------- validacao ---

def preparar(dados, diag):
    h = dados.get("holding") or {}
    socios = dados.get("socios") or []
    invs = {i.get("id"): i for i in (dados.get("investidas") or [])}
    rota = str(val(dados, "rota", "conjunta")).lower()
    if rota not in ("conjunta", "posterior"):
        diag.erro(f"'rota' deve ser 'conjunta' ou 'posterior' (veio '{rota}').")
        rota = "conjunta"

    if not socios:
        diag.erro("Nenhum sócio informado.")
    if not invs:
        diag.erro("Nenhuma sociedade investida informada — sem quotas a conferir não há holding empresarial.")

    vq_h = para_decimal(val(h, "valorQuota", 1)) or Decimal(1)
    ids = {s.get("id") for s in socios}

    # --- investidas: aritmetica do quadro atual
    for iid, inv in invs.items():
        nome = val(inv, "denominacao", iid)
        cap = para_decimal(val(inv, "capital"))
        vq = para_decimal(val(inv, "valorQuota", 1)) or Decimal(1)
        inv["_vq"] = vq
        if cap is None:
            diag.erro(f"{nome}: capital social não informado.")
            inv["_tq"] = 0
            continue
        tq = cap / vq
        if tq != tq.to_integral():
            diag.erro(f"{nome}: capital de R$ {fmt_real(cap)} não é divisível pelo valor nominal de R$ {fmt_real(vq)}.")
        inv["_tq"] = int(tq)
        soma = sum(int(val(q, "quotas", 0)) for q in val(inv, "quadro", []))
        if soma != inv["_tq"]:
            diag.erro(f"{nome}: o quadro atual soma {fmt_int(soma)} quotas, mas o capital de R$ {fmt_real(cap)} "
                      f"comporta {fmt_int(inv['_tq'])}. Confira o último instrumento arquivado.")
        if val(inv, "capitalIntegralizado") is False:
            diag.erro(f"{nome}: capital não totalmente integralizado. O Manual DREI (item 4.3.5) exige que o capital "
                      "objeto da operação esteja totalmente integralizado.")
        elif val(inv, "capitalIntegralizado") is None:
            diag.conf(f"{nome}: confirmar no último instrumento arquivado que o capital está totalmente integralizado "
                      "(exigência do item 4.3.5 do Manual DREI).")
        for q in val(inv, "quadro", []):
            if q.get("socio") and q["socio"] not in ids:
                diag.erro(f"{nome}: o quadro aponta o sócio '{q['socio']}', que não está na lista de sócios da holding.")
        for c in ("cnpj", "nire", "sede"):
            campo(inv, c, diag, f"{nome}: {c.upper() if c != 'sede' else 'endereço da sede'}")
        if not val(inv, "numeroAlteracao"):
            diag.pend(f"{nome}: número desta alteração na série da empresa (conferir o último instrumento arquivado)")
        if not val(inv, "clausulaCapital"):
            diag.pend(f"{nome}: número da cláusula do capital social no contrato vigente")
        uf = str(val(inv, "uf", "TO")).upper()
        if uf != str(val(h, "uf", "TO")).upper():
            diag.alerta(f"{nome}: sede em {uf}, Junta diferente da holding. Não há tramitação conjunta: arquive "
                        "primeiro a alteração da investida (mencionando a holding em constituição) e junte-a ao "
                        "processo da holding, ou use a rota 'posterior'. Confirme o procedimento com as duas Juntas.")
        if val(inv, "simples") is None:
            diag.conf(f"{nome}: verificar se é optante do Simples / enquadrada como ME ou EPP. Com sócia pessoa "
                      "jurídica, perde o enquadramento (LC 123/2006, art. 3º, § 4º, I).")

    # --- socios e participacoes
    capital_h = Decimal(0)
    for s in socios:
        nome = val(s, "nome", "?")
        campo(s, "qualificacao", diag, f"{nome}: qualificação completa")
        q = str(val(s, "qualificacao", ""))
        if q and "CPF" not in q.upper():
            diag.alerta(f"{nome}: a qualificação não traz o CPF.")
        if "Passos-MG" in q:
            diag.alerta(f"{nome}: a qualificação contém 'Passos-MG', resíduo do modelo de origem. Confirme a naturalidade.")
        total = Decimal(0)
        s["_parts"] = []
        for p in val(s, "participacoes", []):
            inv = invs.get(p.get("investida"))
            if not inv:
                diag.erro(f"{nome}: participação em investida inexistente ('{p.get('investida')}').")
                continue
            qtd = int(val(p, "quotas", 0))
            if qtd <= 0:
                diag.erro(f"{nome}: quantidade de quotas de {inv.get('denominacao')} não informada.")
                continue
            possui = sum(int(val(x, "quotas", 0)) for x in val(inv, "quadro", []) if x.get("socio") == s.get("id"))
            if qtd > possui:
                diag.erro(f"{nome}: confere {fmt_int(qtd)} quotas de {inv.get('denominacao')}, mas o quadro "
                          f"atual lhe atribui {fmt_int(possui)}.")
            nominal = qtd * inv["_vq"]
            valor = para_decimal(val(p, "valor")) if val(p, "valor") is not None else nominal
            if valor != nominal:
                diag.alerta(f"{nome}: quotas de {inv.get('denominacao')} conferidas por R$ {fmt_real(valor)}, "
                            f"diferente do valor nominal (R$ {fmt_real(nominal)}). A cláusula dirá o valor de "
                            "conferência; confirme o critério (custo na DIRPF, patrimônio líquido ou mercado).")
            dirpf = para_decimal(val(p, "valorDirpf")) if val(p, "valorDirpf") is not None else None
            if dirpf is None:
                diag.conf(f"{nome}: informar o custo das quotas de {inv.get('denominacao')} na DIRPF. Conferência "
                          "acima do custo declarado gera ganho de capital (Lei 9.249/1995, art. 23, § 2º).")
            elif valor > dirpf:
                diag.alerta(f"{nome}: quotas de {inv.get('denominacao')} conferidas por R$ {fmt_real(valor)}, acima "
                            f"do custo na DIRPF (R$ {fmt_real(dirpf)}). A diferença, R$ {fmt_real(valor - dirpf)}, é "
                            "tributável como ganho de capital (Lei 9.249/1995, art. 23, § 2º).")
            pl = para_decimal(val(inv, "patrimonioLiquido")) if val(inv, "patrimonioLiquido") is not None else None
            if pl is not None and inv["_tq"]:
                pl_prop = pl * qtd / inv["_tq"]
                if valor > pl_prop:
                    diag.alerta(f"{nome}: quotas de {inv.get('denominacao')} conferidas por R$ {fmt_real(valor)}, "
                                f"acima do patrimônio líquido proporcional (R$ {fmt_real(pl_prop)}). Todos os sócios "
                                "da holding respondem solidariamente pela exata estimação por 5 anos (CC, art. 1.055, § 1º).")
            s["_parts"].append({"inv": inv, "quotas": qtd, "valor": valor, "dirpf": dirpf, "possui": possui})
            total += valor
        dinheiro = para_decimal(val(s, "dinheiro", 0)) or Decimal(0)
        s["_dinheiro"] = dinheiro
        total += dinheiro
        s["_total"] = total
        qh = total / vq_h
        if qh != qh.to_integral():
            diag.erro(f"{nome}: aporte de R$ {fmt_real(total)} não é divisível pelo valor nominal da quota da holding "
                      f"(R$ {fmt_real(vq_h)}). Quota fracionária é vedada.")
        s["_quotas"] = int(qh)
        if total <= 0:
            diag.erro(f"{nome}: não aporta nada ao capital.")
        capital_h += total

    # --- regime de bens (art. 977 CC)
    porid = {s.get("id"): s for s in socios}
    for s in socios:
        cj = val(s, "conjuge")
        if cj and cj in porid:
            reg = str(val(s, "regimeBens", "")).lower()
            if reg in ("comunhao_universal", "separacao_obrigatoria"):
                diag.erro(f"{val(s, 'nome')} e {val(porid[cj], 'nome')} são cônjuges casados em "
                          f"{'comunhão universal de bens' if reg == 'comunhao_universal' else 'separação obrigatória de bens'}"
                          ": não podem ser sócios entre si (CC, art. 977).")
        if str(val(s, "estadoCivil", "")).lower() == "casado" and not val(s, "regimeBens"):
            diag.pend(f"{val(s, 'nome')}: regime de bens do casamento")

    if len(socios) == 1:
        diag.alerta("Holding com um único sócio: o modelo é pluripessoal. Suprima capítulos de cessão, quórum e "
                    "exclusão, ou use o regime da sociedade limitada unipessoal (CC, art. 1.052, §§ 1º e 2º).")
    admins = [s for s in socios if val(s, "administrador")]
    if not admins:
        diag.erro("Nenhum sócio marcado como administrador da holding.")

    h["_capital"] = capital_h
    h["_vq"] = vq_h
    h["_tq"] = int(capital_h / vq_h) if capital_h else 0

    if capital_h and socios:
        maior = max(s["_total"] for s in socios) * 100 / capital_h
        if maior == 50 and len(socios) == 2:
            diag.alerta("Sociedade 50/50: todo quórum de 'mais da metade' (ou '50% + 1') equivale a unanimidade. "
                        "Impasse é provável; defina no acordo de sócios um mecanismo de desempate.")
        elif maior > 50:
            diag.alerta(f"Um sócio detém {fmt_pct(maior)} do capital: decide sozinho todas as matérias de quórum "
                        "'50% + 1'. Confirme se é o desenho pretendido.")
    for k, r in (("denominacao", "nome empresarial da holding"), ("sede", "endereço da sede da holding"),
                 ("inicio", "data de início das atividades da holding")):
        campo(h, k, diag, r)
    if not val(h, "data"):
        diag.pend("data de assinatura")
    adv = val(h, "advogado") or {}
    if not adv or tem_placeholder(val(adv, "nome", "")) or tem_placeholder(val(adv, "oab", "")):
        diag.pend("advogado que dá o visto (nome e OAB) — a holding não é ME/EPP (LC 123, art. 3º, § 4º, VII), "
                  "logo o visto de advogado é obrigatório (Lei 8.906/1994, art. 1º, § 2º)")
    return h, socios, invs, rota


# --------------------------------------------------------------- contrato ---

def bloco_capital(h, socios, rota):
    tem_dinheiro = any(s["_dinheiro"] > 0 for s in socios)
    forma = "mediante a transferência das quotas que os sócios possuem em outras sociedades"
    if tem_dinheiro:
        forma += " e em moeda corrente nacional"
    vq = h["_vq"]
    out = [f"O capital social será de {rs(h['_capital'])}, dividido em {qt(h['_tq'])} quotas, com valor "
           f"nominal unitário de {rs(vq)}, subscritas e totalmente integralizadas {forma}, distribuídas da "
           "seguinte forma:", ""]
    for n, s in enumerate(socios, 1):
        art = artigo(s)
        out.append(f"{_romano(n)} – {art} **{s['nome']}**, {'qualificada' if art.startswith('A') else 'qualificado'} acima, "
                   f"subscreve {qt(s['_quotas'])} quotas, totalizando {rs(s['_total'])}, as quais são integralizadas "
                   + ("mediante a transferência das quotas que possui nas empresas abaixo:" if s["_parts"] and not s["_dinheiro"]
                      else "da seguinte forma:" if s["_parts"] else "em moeda corrente nacional, neste ato."))
        out.append("")
        letras = "abcdefghijklmnopqrstuvwxyz"
        k = 0
        for p in s["_parts"]:
            inv = p["inv"]
            nominal = p["quotas"] * inv["_vq"]
            if p["valor"] == nominal:
                desc = (f"{qt(p['quotas'])} quotas, com valor unitário de {rs(inv['_vq'])}, totalizando "
                        f"{rs(p['valor'])}")
            else:
                desc = (f"{qt(p['quotas'])} quotas, com valor nominal unitário de {rs(inv['_vq'])}, conferidas "
                        f"pelo valor total de {rs(p['valor'])}")
            junta = val(inv, "junta") or JUNTAS.get(str(val(inv, "uf", "TO")).upper(), PH)
            sigla = junta.split("–")[-1].strip() if "–" in junta else junta
            num = val(inv, "numeroAlteracao")
            ato = f"{num}ª Alteração Contratual" if num else f"{PH} Alteração Contratual"
            if rota == "conjunta":
                origem = (f", cuja transferência é formalizada pela {ato} da referida sociedade (1º Ato), "
                          "levada a arquivamento conjuntamente com este instrumento")
            else:
                origem = (", cuja transferência será formalizada por alteração contratual da referida sociedade, "
                          "na forma do parágrafo segundo desta cláusula")
            out.append(f"{letras[k]}) {desc}, da empresa **{inv.get('denominacao')}**, pessoa jurídica de direito "
                       f"privado, inscrita no CNPJ sob o nº {val(inv, 'cnpj') or PH}, registrada na {sigla} sob o "
                       f"NIRE nº {val(inv, 'nire') or PH}, com sede na {val(inv, 'sede') or PH}{origem};")
            out.append("")
            k += 1
        if s["_dinheiro"] > 0 and s["_parts"]:
            out.append(f"{letras[k]}) {rs(s['_dinheiro'])} em moeda corrente nacional, neste ato.")
            out.append("")
        # troca o ";" final da ultima alinea por "."
        for j in range(len(out) - 1, -1, -1):
            if out[j].strip():
                if out[j].endswith(";"):
                    out[j] = out[j][:-1] + "."
                break
    out.append("Desta forma, ficará o capital assim distribuído entre os sócios:")
    out.append("")
    linhas = [(s["nome"], s["_quotas"], Decimal(s["_quotas"]) * 100 / h["_tq"], s["_total"]) for s in socios]
    out.append(tabela(linhas, h["_tq"], h["_capital"]))
    out.append("")
    out.append("Parágrafo primeiro. Os sócios respondem solidariamente pela exata estimação das quotas conferidas "
               "ao capital social, até 5 (cinco) anos da data do registro da sociedade, nos termos do art. 1.055, "
               "§ 1º, do Código Civil.")
    out.append("")
    if rota == "conjunta":
        out.append("Parágrafo segundo. As alterações contratuais das sociedades investidas que formalizam a "
                   "transferência das quotas conferidas (1º Ato), indicadas nas alíneas desta cláusula, são levadas "
                   "a arquivamento conjuntamente com o presente instrumento, nos termos do item 4.3.5 do Manual de "
                   "Registro de Sociedade Limitada (Anexo IV da Instrução Normativa DREI nº 81/2020).")
    else:
        out.append("Parágrafo segundo. Os sócios se comprometem a apresentar o ato de alteração das empresas "
                   "compartilhadoras no prazo de 30 (trinta) dias.")
    partes = [p for s in socios for p in s["_parts"]]
    if partes and all(p["dirpf"] is not None and p["dirpf"] == p["valor"] for p in partes):
        out.append("")
        out.append("Parágrafo terceiro. As quotas conferidas são transferidas pelo valor constante da declaração "
                   "de bens de cada sócio, nos termos do art. 23 da Lei nº 9.249/1995.")
    return "\n".join(out)


def inicio_txt(v):
    v = str(v).strip()
    return ("em " + v) if (v[:1].isdigit() or v.startswith("[")) else v


def _romano(n):
    from lib_holding import romano
    return romano(n)


def contrato(h, socios, rota, modelo):
    admins = [s for s in socios if val(s, "administrador")]
    nomes_adm = [s["nome"] for s in admins]
    if len(admins) > 1:
        todos_f = all(artigo(s).startswith("A") for s in admins)
        adm = (f"A administração será exercida isoladamente {'pelas sócias' if todos_f else 'pelos sócios'} "
               f"{lista_nomes(nomes_adm)}, que representarão legalmente a empresa e poderão praticar todo e "
               "qualquer ato de gestão pertinente ao objeto.")
        desimp = ("Os administradores declaram, sob as penas da lei, que não estão impedidos de exercer a "
                  "administração da sociedade, por lei especial, ou em virtude de condenação criminal, ou por se "
                  "encontrarem sob os efeitos dela, a pena que vede, ainda que temporariamente, o acesso a cargos "
                  "públicos, ou por crime falimentar, de prevaricação, peita ou suborno, concussão, peculato, ou "
                  "contra a economia popular, contra o sistema financeiro nacional, contra normas de defesa da "
                  "concorrência, contra as relações de consumo, fé pública ou propriedade.")
    else:
        a = admins[0] if admins else {"nome": PH}
        pelo = "pela sócia" if artigo(a).startswith("A") else "pelo sócio"
        adm = (f"A administração será exercida {pelo} **{a['nome']}**, que representará legalmente a empresa e "
               "poderá praticar todo e qualquer ato de gestão pertinente ao objeto.")
        desimp = ("O administrador declara, sob as penas da lei, que não está impedido de exercer a administração "
                  "da sociedade, por lei especial, ou em virtude de condenação criminal, ou por se encontrar sob os "
                  "efeitos dela, a pena que vede, ainda que temporariamente, o acesso a cargos públicos, ou por crime "
                  "falimentar, de prevaricação, peita ou suborno, concussão, peculato, ou contra a economia popular, "
                  "contra o sistema financeiro nacional, contra normas de defesa da concorrência, contra as relações "
                  "de consumo, fé pública ou propriedade.")

    preambulo = "\n\n".join(f"**{s['nome']}**, {str(val(s, 'qualificacao', PH)).strip().rstrip('.')}." for s in socios)
    uf = str(val(h, "uf", "TO")).upper()
    cidade = val(h, "cidade", PH)
    foro = val(h, "foro") or f"{cidade}, Estado do {ESTADOS.get(uf, PH)}"
    local = val(h, "local") or f"{cidade} - {uf}"
    data = val(h, "data") or "[...... de ...... de ......]"
    ass = []
    for s in socios:
        papel = ("Sócia" if artigo(s).startswith("A") else "Sócio") + (" Administradora" if artigo(s).startswith("A") and val(s, "administrador") else " Administrador" if val(s, "administrador") else "")
        ass.append(f"\\_\\_\\_\\_\\_\\_\\_\\_\\_\\_\\_\\_\\_\\_\\_\\_\\_\\_\\_\\_\\_\\_\\_\\_\\_\\_\\_\\_\\_\\_  \n**{s['nome']}**  \n{papel}")
    adv = val(h, "advogado") or {}
    ass.append(f"Visto do advogado:\n\n\\_\\_\\_\\_\\_\\_\\_\\_\\_\\_\\_\\_\\_\\_\\_\\_\\_\\_\\_\\_\\_\\_\\_\\_\\_\\_\\_\\_\\_\\_  \n"
               f"**{val(adv, 'nome', PH)}**  \nOAB/{val(adv, 'uf', 'TO')} nº {val(adv, 'oab', PH)}")
    objeto = val(h, "objeto") or "6462-0/00 – Holdings de instituições não-financeiras."
    if isinstance(objeto, list):
        objeto = "; ".join(objeto) + "."
    variaveis = {
        "DENOMINACAO": val(h, "denominacao", PH),
        "NOME_FANTASIA": val(h, "nomeFantasia") or val(h, "denominacao", PH).replace(" LTDA", ""),
        "SEDE": val(h, "sede", PH),
        "PREAMBULO": preambulo,
        "OBJETO": objeto,
        "INICIO": inicio_txt(val(h, "inicio", PH)),
        "CAPITAL": bloco_capital(h, socios, rota),
        "QUORUM": val(h, "quorum", "50% + 1 (cinquenta por cento mais um)"),
        "ADMIN_CLAUSULA": adm,
        "DESIMPEDIMENTO": desimp,
        "FORO": foro,
        "LOCAL_DATA": f"{local}, {data}.",
        "ASSINATURAS": "\n\n".join(ass),
    }
    conds = {"varios_admin": len(admins) > 1, "dois_socios": len(socios) == 2,
             "com_acordo": bool(val(h, "acordoSocios", False))}
    return renderizar(modelo, variaveis, conds)


# -------------------------------------------------------------- alteracao ---

def alteracao(inv, h, socios, rota, modelo, diag):
    porid = {s.get("id"): s for s in socios}
    nome_inv = val(inv, "denominacao", PH)
    denom_h = val(h, "denominacao", PH)
    quadro = val(inv, "quadro", [])
    vq = inv["_vq"]

    # transferencias desta investida
    cessoes = []
    for s in socios:
        for p in s["_parts"]:
            if p["inv"] is inv:
                cessoes.append((s, p))

    # preambulo: todos os socios atuais
    pre = []
    for q in quadro:
        if q.get("socio"):
            s = porid[q["socio"]]
            pre.append(f"**{s['nome']}**, {str(val(s, 'qualificacao', PH)).strip().rstrip('.')};")
        else:
            nm = val(q, "nome", PH)
            ql = val(q, "qualificacao")
            if not ql:
                diag.pend(f"{nome_inv}: qualificação do sócio {nm}, que não integra a holding")
            pre.append(f"**{nm}**, {str(ql or PH).strip().rstrip('.')};")

    # holding: em constituicao (rota conjunta) ou ja registrada
    admins = [s for s in socios if val(s, "administrador")]
    socios_inv = {q.get("socio") for q in quadro if q.get("socio")}
    ja = [a for a in admins if a.get("id") in socios_inv]
    novos = [a for a in admins if a.get("id") not in socios_inv]
    partes_rep = []
    if ja:
        partes_rep.append(lista_nomes([a["nome"] for a in ja]) + (", já qualificados" if len(ja) > 1 else
                          (", já qualificada" if artigo(ja[0]).startswith("A") else ", já qualificado")))
    for a in novos:
        partes_rep.append(f"**{a['nome']}**, {str(val(a, 'qualificacao', PH)).strip().rstrip('.')}")
    rep_txt = " e ".join(partes_rep) if partes_rep else PH
    rep_lbl = "por seus sócios administradores" if len(admins) > 1 else "por seu sócio administrador"
    if rota == "conjunta":
        qual_h = (f"sociedade empresária limitada em constituição, com sede na {val(h, 'sede', PH)}, cujo contrato "
                  f"social é levado a arquivamento conjuntamente com o presente instrumento, neste ato representada "
                  f"{rep_lbl}, {rep_txt}")
        diag.conf("JUCETINS: confirmar se aceita a holding em constituição como cessionária interveniente, "
                  "representada pelos futuros administradores, nas alterações das investidas. O Manual DREI "
                  "(4.3.5) exige apenas a menção de que as quotas se destinam à constituição.")
    else:
        cnpj_h, nire_h = val(h, "cnpj"), val(h, "nire")
        if not cnpj_h or not nire_h:
            diag.pend(f"{nome_inv}: CNPJ e NIRE da holding (rota 'posterior' exige a holding já registrada)")
        qual_h = (f"sociedade empresária limitada, com sede na {val(h, 'sede', PH)}, inscrita no CNPJ sob o nº "
                  f"{cnpj_h or PH}, registrada na {JUNTAS.get(str(val(h, 'uf', 'TO')).upper(), PH)} sob o NIRE nº "
                  f"{nire_h or PH}, neste ato representada {rep_lbl}, {rep_txt}")

    # clausula de transferencia
    paras, saidas, cedentes, saem = [], [], [], []
    novo = {}  # nome -> quotas apos
    for q in quadro:
        nm = porid[q["socio"]]["nome"] if q.get("socio") else val(q, "nome", PH)
        novo[nm] = novo.get(nm, 0) + int(val(q, "quotas", 0))
    total_h = 0
    for s, p in cessoes:
        art = artigo(s)
        qual = "já qualificada" if art.startswith("A") else "já qualificado"
        tot = p["quotas"] == p["possui"]
        quanto = (f"a totalidade de suas {qt(p['quotas'])} quotas" if tot
                  else f"{qt(p['quotas'])} das suas {qt(p['possui'])} quotas")
        constit = ", em sua constituição" if rota == "conjunta" else ""
        paras.append(f"{art} **{s['nome']}**, {qual}, titular de {qt(p['possui'])} quotas do capital social, com valor "
                     f"nominal unitário de {rs(vq)}, totalmente integralizadas, transfere à **{denom_h}** {quanto}, no "
                     f"valor total de {rs(p['valor'])}, as quais são utilizadas para integralizar o capital social por "
                     f"{'ela' if art.startswith('A') else 'ele'} subscrito na referida sociedade{constit}.")
        if tot:
            saem.append(s)
        else:
            rest = p["possui"] - p["quotas"]
            saidas.append(f"{art} **{s['nome']}** permanece na sociedade, titular de {qt(rest)} quotas.")
        novo[s["nome"]] -= p["quotas"]
        total_h += p["quotas"]
        cedentes.append(s)
    if len(saem) == 1:
        s0 = saem[0]
        saidas.insert(0, f"Em consequência, retira-se da sociedade {artigo(s0).lower()} **{s0['nome']}**, que "
                         "transfere a totalidade de suas quotas.")
    elif saem:
        todas_f = all(artigo(x).startswith("A") for x in saem)
        saidas.insert(0, f"Em consequência, retiram-se da sociedade {'as sócias' if todas_f else 'os sócios'} "
                         f"{lista_nomes([x['nome'] for x in saem])}, que transferem a totalidade de suas quotas.")
    novo[denom_h] = novo.get(denom_h, 0) + total_h
    novo = {k: v for k, v in novo.items() if v > 0}

    tq = inv["_tq"]
    cap = Decimal(tq) * vq
    linhas = [(k, v, Decimal(v) * 100 / tq, v * vq) for k, v in novo.items()]
    capital_novo = (f"CLÁUSULA {val(inv, 'clausulaCapital', PH)} – O capital social é de {rs(cap)}, dividido em "
                    f"{qt(tq)} quotas, com valor nominal unitário de {rs(vq)}, totalmente subscrito e integralizado, "
                    "assim distribuído:")
    unipessoal = list(novo.keys()) == [denom_h]

    # administracao: cedente administrador que sai
    adm_saindo = [s for s, p in cessoes
                  if p["quotas"] == p["possui"] and any(q.get("socio") == s.get("id") and val(q, "administrador")
                                                         for q in quadro)]
    adm_txt = ""
    if adm_saindo:
        nomes = lista_nomes([s["nome"] for s in adm_saindo])
        plural = len(adm_saindo) > 1
        adm_txt = (f"A administração da sociedade continua a ser exercida por {nomes}, "
                   f"{'que, em razão da transferência da totalidade de suas quotas, passam' if plural else 'que, em razão da transferência da totalidade de suas quotas, passa'} "
                   f"à condição de {'administradores não sócios' if plural else 'administrador não sócio'}, mantidos os "
                   "poderes e limites previstos no contrato social, designação aprovada por todos os sócios, nos termos "
                   "do art. 1.061 do Código Civil.\n\n"
                   f"Parágrafo único. {'Os administradores declaram' if plural else 'O administrador declara'}, sob as "
                   f"penas da lei, que não {'estão impedidos' if plural else 'está impedido'} de exercer a administração "
                   "da sociedade, por lei especial, ou em virtude de condenação criminal, ou por se encontrar sob os "
                   "efeitos dela, a pena que vede, ainda que temporariamente, o acesso a cargos públicos; ou por crime "
                   "falimentar, de prevaricação, peita ou suborno, concussão, peculato; ou contra a economia popular, "
                   "contra o sistema financeiro nacional, contra normas de defesa da concorrência, contra as relações "
                   "de consumo, fé pública ou a propriedade.")
        if val(inv, "permiteAdmNaoSocio") is not True:
            diag.conf(f"{nome_inv}: {', '.join(s['nome'] for s in adm_saindo)} deixa(m) de ser sócio(s) e continua(m) "
                      "administrando. O contrato da investida precisa permitir administrador não sócio (CC, art. 1.061); "
                      "se não permitir, inclua na alteração a cláusula que o autoriza. A minuta presume a continuidade "
                      "do mesmo administrador — confirme o desenho com o cliente.")

    simples = val(inv, "simples") is True
    if unipessoal:
        diag.alerta(f"{nome_inv}: a holding passa a ser sócia única. A investida segue como sociedade limitada "
                    "unipessoal; recomenda-se consolidar o contrato, ajustando as cláusulas que pressupõem pluralidade "
                    "de sócios (reunião, quórum, cessão entre sócios).")

    ced_nomes = lista_nomes([s["nome"] for s in cedentes])
    plural_c = len(cedentes) > 1
    resp = (f"{'Os sócios cedentes' if plural_c else ('A sócia cedente' if cedentes and artigo(cedentes[0]).startswith('A') else 'O sócio cedente')} "
            f"{ced_nomes} {'respondem' if plural_c else 'responde'} solidariamente com a cessionária, perante a "
            f"sociedade e terceiros, pelas obrigações que {'tinham' if plural_c else 'tinha'} como "
            f"{'sócios' if plural_c else 'sócio'}, até 2 (dois) anos depois de averbada a presente alteração, nos "
            "termos do parágrafo único do art. 1.003 e do parágrafo único do art. 1.057 do Código Civil.")

    num = val(inv, "numeroAlteracao")
    num_txt = f"{num}ª" if num else PH
    pref = val(inv, "clausulaPreferencia")
    local = val(inv, "local") or val(h, "local") or f"{val(h, 'cidade', PH)} - {str(val(h, 'uf', 'TO')).upper()}"
    data = val(inv, "data") or val(h, "data") or "[...... de ...... de ......]"
    junta = val(inv, "junta") or JUNTAS.get(str(val(inv, "uf", "TO")).upper(), PH)
    linha = "\\_" * 30
    ass = []
    for q in quadro:
        if q.get("socio"):
            s = porid[q["socio"]]
            ass.append(f"{linha}  \n**{s['nome']}**  \n{'Sócia' if artigo(s).startswith('A') else 'Sócio'}"
                       + (" cedente" if s in cedentes else ""))
        else:
            ass.append(f"{linha}  \n**{val(q, 'nome', PH)}**  \nSócio anuente")
    ass.append(f"{linha}  \n**{denom_h}**  \nCessionária, representada por "
               + (lista_nomes([a['nome'] for a in admins]) or PH))
    variaveis = {
        "NUM_ALTERACAO": num_txt, "DENOM_INV": nome_inv, "CNPJ_INV": val(inv, "cnpj", PH),
        "NIRE_INV": val(inv, "nire", PH), "PREAMBULO_INV": "\n\n".join(pre), "SEDE_INV": val(inv, "sede", PH),
        "JUNTA_INV": junta, "DENOM_HOLDING": denom_h, "QUALIF_HOLDING": qual_h,
        "CESSOES": "\n\n".join(paras), "SAIDAS": "\n\n".join(saidas),
        "PREF_CLAUSULA": f" (Cláusula {pref})" if pref else "",
        "CL_CAPITAL": f"Cláusula {val(inv, 'clausulaCapital', PH)}", "CAPITAL_NOVO": capital_novo,
        "QUADRO": tabela(linhas, tq, cap), "ADM_TEXTO": adm_txt, "RESP_CEDENTE": resp,
        "CONSOLIDACAO": ("[CONSOLIDAÇÃO — transcrever aqui o contrato social consolidado vigente, já com as "
                         "cláusulas modificadas por este instrumento. Ver referencias/alteracao-da-investida.md, "
                         "seção 5.]"),
        "LOCAL_DATA": f"{local}, {data}.", "ASSINATURAS": "\n\n".join(ass),
    }
    conds = {"holding_em_constituicao": rota == "conjunta", "unipessoal": unipessoal,
             "saida_adm": bool(adm_saindo), "simples": simples,
             "consolidar": bool(val(inv, "consolidar", False))}
    md, _, _ = renderizar(modelo, variaveis, conds,
                          rotulo_clausula="CLÁUSULA {ext} –", formato_ref="Cláusula {ext}")
    resumo = {"investida": nome_inv, "antes": quadro, "depois": novo, "unipessoal": unipessoal,
              "cedentes": [s["nome"] for s in cedentes]}
    return md, resumo


# ------------------------------------------------------------------ saida ---

def diagnostico_md(diag, h, socios, invs, resumos, rota, gravou):
    L = ["# Diagnóstico — holding empresarial", ""]
    L.append(f"**Holding:** {val(h, 'denominacao', PH)}  ")
    if h.get("_capital"):
        L.append(f"**Capital:** {rs(h['_capital'])} — {fmt_int(h['_tq'])} quotas de R$ {fmt_real(h['_vq'])}  ")
    L.append(f"**Rota de registro:** {'conjunta (1º e 2º Atos tramitam juntos — Manual DREI 4.3.5, Nota I)' if rota == 'conjunta' else 'posterior (modelo de origem: alterações das investidas em até 30 dias)'}  ")
    L.append(f"**Situação:** {'REPROVADO — há ERRO; minutas não foram geradas' if diag.erros and not gravou else 'com ERRO (gerado com --forcar; não entregar)' if diag.erros else 'aprovado na aritmética — minutas geradas'}")
    L.append("")
    for titulo, itens in (("ERRO (impede a entrega)", diag.erros), ("ALERTA (decida conscientemente)", diag.alertas),
                          ("CONFERIR (confirmação humana)", diag.conferir), ("PENDÊNCIAS (campos em aberto)", diag.pendencias)):
        L.append(f"## {titulo} — {len(itens)}")
        L.append("")
        L += [f"- {i}" for i in itens] or ["- nenhum"]
        L.append("")
    if resumos:
        L.append("## Quadro das investidas — antes e depois")
        L.append("")
        for r in resumos:
            L.append(f"### {r['investida']}")
            L.append("")
            porid = {s.get("id"): s for s in socios}
            antes = ", ".join(f"{porid[q['socio']]['nome'] if q.get('socio') else q.get('nome')}: {fmt_int(q.get('quotas', 0))}"
                              for q in r["antes"])
            depois = ", ".join(f"{k}: {fmt_int(v)}" for k, v in r["depois"].items())
            L.append(f"- Antes: {antes}")
            L.append(f"- Depois: {depois}" + (" — **sócia única**" if r["unipessoal"] else ""))
            L.append("")
    return "\n".join(L) + "\n"


def main():
    forcar_utf8()
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("dados", help="arquivo .json com holding, sócios e investidas")
    ap.add_argument("--saida", default=".", help="pasta de saída (padrão: atual)")
    ap.add_argument("--forcar", action="store_true", help="gera as minutas mesmo com ERRO (só para inspeção)")
    a = ap.parse_args()

    dados = json.loads(ler(a.dados))
    diag = Diag()
    h, socios, invs, rota = preparar(dados, diag)
    assets = achar_assets()
    os.makedirs(a.saida, exist_ok=True)

    gravar = not diag.erros or a.forcar
    resumos, arquivos = [], []
    if gravar:
        try:
            md, _, _ = contrato(h, socios, rota, ler(os.path.join(assets, "modelo-contrato-holding.md")))
            nome = os.path.join(a.saida, f"01-contrato-{slug(val(h, 'denominacao', 'holding'))}.md")
            with io.open(nome, "w", encoding="utf-8") as f:
                f.write(md)
            arquivos.append(nome)
            mod_alt = ler(os.path.join(assets, "modelo-alteracao-investida.md"))
            for inv in invs.values():
                if not any(p["inv"] is inv for s in socios for p in s["_parts"]):
                    diag.alerta(f"{inv.get('denominacao')}: nenhuma quota desta investida é conferida — sem alteração.")
                    continue
                md, r = alteracao(inv, h, socios, rota, mod_alt, diag)
                resumos.append(r)
                nome = os.path.join(a.saida, f"02-alteracao-{slug(val(inv, 'denominacao', inv.get('id')))}.md")
                with io.open(nome, "w", encoding="utf-8") as f:
                    f.write(md)
                arquivos.append(nome)
        except ErroModelo as e:
            diag.erro(f"Defeito no modelo de texto (assets/): {e}")
    nome = os.path.join(a.saida, "00-diagnostico.md")
    with io.open(nome, "w", encoding="utf-8") as f:
        f.write(diagnostico_md(diag, h, socios, invs, resumos, rota, gravar))
    arquivos.insert(0, nome)

    print(f"ERRO: {len(diag.erros)} | ALERTA: {len(diag.alertas)} | CONFERIR: {len(diag.conferir)} | "
          f"PENDÊNCIAS: {len(diag.pendencias)}")
    for e in diag.erros:
        print(f"  ERRO  {e}")
    for f in arquivos:
        print(f"  gravado: {f}")
    sys.exit(1 if diag.erros else 0)


if __name__ == "__main__":
    main()
