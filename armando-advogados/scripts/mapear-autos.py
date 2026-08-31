#!/usr/bin/env python3
"""Mapeia autos processuais: capa, indice de pecas, fronteiras de juntada, linha
do tempo, prazos e alertas. Diz tambem se o extrato esta vencido e se a foliacao
reinicia dentro do arquivo.

Equivalente ao mapear-autos.ps1, para ambiente com Python (Claude na nuvem,
Cowork, Linux, Mac), onde o PowerShell e inerte. Mesmas opcoes, com dois
hifens, e mesma saida.

Le os autos ja convertidos em Markdown pelo pdf2md (ou o PDF direto) e produz um
mapa navegavel. Serve para NAO ler 375 paginas: le-se o mapa, decide-se o que
abrir, e abre-se so isso por faixa de linha.

O script LOCALIZA. Ele nao interpreta o processo e nao conta prazo. A leitura das
pecas decisorias continua obrigatoria.

Exemplos:
    python3 mapear-autos.py autos.md --out mapa.md
    python3 mapear-autos.py processo.pdf --out mapa.md --hoje 2026-08-27
"""

import argparse
import datetime
import io
import os
import re
import subprocess
import sys
from collections import Counter, OrderedDict

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from lib_peca import forcar_utf8, sem_acento, texto_da_peca  # noqa: E402

AQUI = os.path.dirname(os.path.abspath(__file__))


# ----------------------------------------------------------------------------
# Utilitarios
# ----------------------------------------------------------------------------


def ascii_min(s):
    """Tira acento e cedilha e baixa a caixa. Todos os padroes deste script sao
       ASCII puro: assim a regex nao depende da codificacao do .md."""
    return sem_acento(s or "").lower()


def trecho(linha, maximo):
    t = re.sub(r"\s+", " ", linha).strip()
    return t if len(t) <= maximo else t[:maximo] + "..."


def trecho_centrado(linha, pos, pos_max, maximo):
    """Recorta em torno do match. Sem isso o trecho impresso comeca no inicio da
       linha e frequentemente NAO contem o termo que disparou o achado - o leitor
       tinha de abrir a linha so para descobrir por que ela foi listada."""
    t = re.sub(r"\s+", " ", linha)
    if len(t) <= maximo:
        return t.strip()
    p = int(pos * len(t) / pos_max) if pos_max > 0 else 0
    ini = max(0, min(p - maximo // 3, len(t) - maximo))
    s = t[ini:ini + maximo].strip()
    if ini > 0:
        s = "..." + s
    if ini + maximo < len(t):
        s = s + "..."
    return s


def celula(s):
    return re.sub(r"\s+", " ", (s or "").replace("|", "/")).strip()


def testa_cnj(digitos):
    """Digito verificador do numero unico CNJ: modulo 97 base 10 (ISO 7064).
       NNNNNNN DD AAAA J TR OOOO -> NNNNNNN AAAA J TR OOOO + '00'."""
    if len(digitos) != 20:
        return False
    base = digitos[0:7] + digitos[9:20] + "00"
    return int(digitos[7:9]) == 98 - (int(base) % 97)


def formata_cnj(d):
    return "%s-%s.%s.%s.%s.%s" % (d[0:7], d[7:9], d[9:13], d[13:14],
                                  d[14:16], d[16:20])


def nova_data(dd, mm, aa):
    if not (1 <= dd <= 31 and 1 <= mm <= 12 and 1970 <= aa <= 2100):
        return None
    try:
        return datetime.date(aa, mm, dd)
    except ValueError:
        return None


def data_br(s):
    p = (s or "").split("/")
    if len(p) == 3:
        try:
            return nova_data(int(p[0]), int(p[1]), int(p[2]))
        except ValueError:
            return None
    return None


def dbr(d):
    return d.strftime("%d/%m/%Y")


# ----------------------------------------------------------------------------
# Entrada: PDF, .md, .txt, .docx
# ----------------------------------------------------------------------------

RX_CREATIONDATE = re.compile(
    rb"/CreationDate\s*\(\s*D?:?\s*(\d{4})(\d{2})(\d{2})(\d{2})?(\d{2})?")


def creationdate_do_pdf(path):
    """/CreationDate do PDF -> 'dd/mm/aaaa hh:mm'. QUINTA ancora de atualidade.

    Le os bytes crus: o /Info raramente vive em stream comprimido. Varre a cauda
    e, nao achando, a cabeca.
    """
    try:
        tam = os.path.getsize(path)
        n = min(2 * 1024 * 1024, tam)
        with io.open(path, "rb") as fh:
            fh.seek(tam - n)
            m = RX_CREATIONDATE.search(fh.read(n))
            if not m:
                fh.seek(0)
                m = RX_CREATIONDATE.search(fh.read(n))
    except Exception:
        return None
    if not m:
        return None
    aa, mm, dd = (m.group(i).decode() for i in (1, 2, 3))
    if not (1 <= int(mm) <= 12 and 1 <= int(dd) <= 31):
        return None
    hh = m.group(4).decode() if m.group(4) else "00"
    mi = m.group(5).decode() if m.group(5) else "00"
    return "%s/%s/%s %s:%s" % (dd, mm, aa, hh, mi)


def localizar_pdf2md():
    for c in (os.path.join(AQUI, "..", "skills", "armando-pdf-markdown",
                           "scripts", "pdf2md.py"),
              os.path.expanduser("~/.claude/skills/armando-pdf-markdown/"
                                 "scripts/pdf2md.py")):
        c = os.path.normpath(c)
        if os.path.exists(c):
            return c
    return None


def fonte(arquivo, tmpdir=None):
    """Devolve (caminho de um .md legivel, caminho do PDF de origem ou None)."""
    if os.path.splitext(arquivo)[1].lower() != ".pdf":
        # o PDF irmao, existindo, ainda serve para os metadados
        irmao = os.path.splitext(arquivo)[0] + ".pdf"
        return arquivo, (irmao if os.path.exists(irmao) else None)

    conv = localizar_pdf2md()
    if not conv:
        raise IOError("PDF recebido, mas pdf2md.py nao foi localizado. "
                      "Converta antes e passe o .md.")
    import tempfile
    destino = os.path.join(tmpdir or tempfile.gettempdir(),
                           os.path.splitext(os.path.basename(arquivo))[0] + "-mapa.md")
    sys.stderr.write("  convertendo PDF -> %s\n" % destino)
    # --manter-repetidos: sem o carimbo de folha as ancoras 2 e 3 mentem.
    subprocess.run([sys.executable, conv, arquivo, "--out", destino,
                    "--manter-repetidos"],
                   stdout=subprocess.DEVNULL, check=False)
    if not os.path.exists(destino):
        raise IOError("Conversao do PDF falhou: %s" % arquivo)
    return destino, arquivo


def ler_linhas(arquivo):
    if os.path.splitext(arquivo)[1].lower() == ".docx":
        return texto_da_peca(arquivo).splitlines()
    with io.open(arquivo, encoding="utf-8-sig", errors="replace") as fh:
        return fh.read().splitlines()


# ----------------------------------------------------------------------------
# Catalogos
# ----------------------------------------------------------------------------

# Campos de capa. Chave = rotulo; valor = quanto capturar (sobre o texto ASCII
# em minuscula).
CAMPOS_CAPA = [
    ("Numero", r"n[uy]mero\s*:\s*(.+)$"),
    ("Classe", r"classe\s*:\s*(.+?)(?:\s+orgao julgador|\s+ultima distribuicao|$)"),
    ("Orgao julgador",
     r"orgao julgador(?:\s+colegiado)?\s*:\s*(.+?)(?:\s+ultima distribuicao|\s+valor da causa|$)"),
    ("Ultima distribuicao", r"ultima distribuicao\s*:?\s*(\d{2}/\d{2}/\d{4})"),
    ("Data da autuacao", r"data da autuacao\s*:?\s*(\d{2}/\d{2}/\d{4})"),
    ("Valor da causa",
     r"valor (?:da causa|da acao)\s*:?\s*(r\$\s?[\d\.]+,\d{2}|[\d\.]+,\d{2})"),
    ("Classe - Assunto",
     r"classe\s*[-–—]\s*assunto\s*:\s*(.{3,110}?)(?:\s+requerente|\s+requerido|\s+autor|\s+reu\b|$)"),
    ("Assuntos",
     r"assuntos?\s*:\s*(.{3,110}?)(?:\s+nivel de sigilo|\s+segredo de justica|\s+requerente|\s+requerido|$)"),
    ("Sigilo",
     r"(?:nivel de sigilo|segredo de justica\??)\s*:?\s*(.+?)(?:\s+justica gratuita|$)"),
    ("Justica gratuita", r"justica gratuita\??\s*:?\s*(sim|nao)"),
    ("Liminar/tutela pedida", r"pedido de liminar[^:?]*\??\s*:?\s*(sim|nao)"),
    ("Processo referencia", r"processo referencia\s*:?\s*(.+)$"),
    ("Relator", r"\brelator.?\s*:\s*(.+?)(?:\s{2,}|$)"),
    ("Juiz/Juiza",
     r"\bjui[zs].?(?:\s+de\s+direito)?(?:\(a\))?\s*(?:de direito)?\s*dr?\(?a?\)?\s*:\s*(.+?)(?:\s{2,}|$)"),
]

# Partes: rotulos de polo usados na capa do PJe e no cabecalho do eSAJ.
ROTULOS_PARTE = (
    r"autor|autora|r[eé]u|r[eé]|requerente|requerido|requerida|"
    r"reclamante|reclamado|reclamada|exequente|executado|executada|embargante|"
    r"embargado|impetrante|impetrado|agravante|agravado|apelante|apelado|"
    r"denunciado|investigado|indiciado|vitima|paciente|excipiente|excepto|"
    r"consignante|consignatario|terceiro interessado|advogado|advogada")

# Ordem importa: o primeiro que casar nomeia a peca.
CATALOGO_PECAS = [
    ("Acordao", r"\bac.rd(ao|aos)\b"),
    ("Voto", r"^\s*#*\s*(voto|voto vencido|voto do relator)\b"),
    ("Sentenca", r"\bsenten.a(s)?\b"),
    ("Saneamento", r"\bsaneador(a)?\b|\bsaneamento\b|\borganiza.ao do processo\b"),
    ("Decisao", r"\bdecis.o\b"),
    ("Despacho", r"\bdespacho\b|\bconclus.o\b"),
    ("Peticao inicial",
     r"\bpeti.ao inicial\b|\bexordial\b|\breclama.ao trabalhista\b|\btermo de ajuizamento\b|^\s*#*\s*inicial\b"),
    ("Emenda a inicial", r"\bemenda\s+(a\s+)?inicial\b"),
    ("Contestacao", r"\bcontesta.ao\b|\bdefesa escrita\b"),
    ("Resposta a acusacao", r"\bresposta\s+(a\s+)?acusa.ao\b|\bdefesa previa\b"),
    ("Reconvencao", r"\breconven.ao\b"),
    ("Replica / impugnacao", r"\breplica\b|\bimpugna.ao\b"),
    ("Denuncia", r"\bden.ncia\b"),
    ("Inquerito / relatorio pol",
     r"\binquerito\b|\brelatorio final\b|\bindiciamento\b|\brelatorio de missao\b|\bboletim de ocorrencia\b"),
    ("Alegacoes finais", r"\balega.oes finais\b|\bmemoriais\b"),
    ("Embargos de declaracao", r"\bembargos de declara.ao\b"),
    ("Embargos / EPE",
     r"\bembargos\s+(a|do|de)\s+(execu.ao|terceiro|devedor)\b|\bexce.ao de pre-executividade\b|\bembargos a arrematacao\b"),
    ("Apelacao", r"\bapela.ao\b"),
    ("Recurso ordinario/revista", r"\brecurso ordinario\b|\brecurso de revista\b"),
    ("Agravo", r"\bagravo\b"),
    ("REsp / RE", r"\brecurso especial\b|\brecurso extraordinario\b"),
    ("Contrarrazoes", r"\bcontrarraz.es\b|\bcontra-razoes\b"),
    ("Habeas corpus", r"\bhabeas corpus\b"),
    ("Mandado de seguranca", r"\bmandado de seguran.a\b"),
    ("Cumprimento / execucao",
     r"\bcumprimento de senten.a\b|\bexecu.ao (fiscal|de titulo|provisoria|definitiva)\b|\bcarta de senten.a\b|\bcertidao de divida ativa\b|\bcda\b"),
    ("Ata / termo de audiencia",
     r"\bata de audi.ncia\b|\btermo de audi.ncia\b|\bassentada\b|\btermo de audiencia de instrucao\b"),
    ("Laudo / pericia",
     r"\blaudo\b|\bpericia\b|\bperito\b|\bquesitos\b|\bparecer tecnico\b"),
    ("Calculo / liquidacao",
     r"\bmemoria de calculo\b|\bplanilha de calculo\b|\bliquida.ao\b|\bdemonstrativo de debito\b|\bcalculos?\b"),
    ("Constricao patrimonial",
     r"\bpenhora\b|\bsisbajud\b|\brenajud\b|\binfojud\b|\barresto\b|\bavalia.ao\b|\bleilao\b|\bhasta publica\b|\bbloqueio\b|\bbusca e apreensao\b"),
    ("Certidao", r"\bcertid.o\b"),
    ("Citacao / intimacao",
     r"\bcita.ao\b|\bintima.ao\b|\bnotifica.ao\b|\bmandado\b|\bcarta precatoria\b|\baviso de recebimento\b|\ba\.?r\.?\b|\becarta\b|\bedital\b|\bdiligencia\b"),
    ("Procuracao / habilitacao",
     r"\bprocura.ao\b|\bsubstabelecimento\b|\bhabilita.ao\b"),
    ("Alvara / oficio", r"\balvar.\b|\bof.cio\b"),
    # 'conciliacao' NAO entra aqui: audiencia de conciliacao e audiencia, nao
    # acordo. Enquanto entrava, o corpo da carta de citacao virava "acordo
    # homologado" num processo que nunca teve acordo nenhum.
    ("Acordo / homologacao",
     r"\bacordo\b|\bhomologa.ao\b|\btransacao\b|\bautocomposicao\b"),
    ("Volume (autos fisicos)",
     r"^\s*#*\s*volume\b|\bprocesso migrado\b|\bautos digitalizados\b"),
    ("Manifestacao / peticao",
     r"\bmanifesta.ao\b|\bpeti.ao\b|\brequerimento\b|\bcota ministerial\b|\bparecer do mp\b"),
]

# Formulas de alta precisao, validas em QUALQUER posicao da linha. Existem porque
# peca sem titulo e comum: a denuncia que so tem enderecamento, e a sentenca do
# JEC, que vive DENTRO do termo de audiencia e nunca aparece como peca autonoma.
CATALOGO_FORMULAS = [
    ("Denuncia (MP)",
     r"oferec(e|er)\s+den.ncia|denuncia-se|incurso nas penas do art|como incurso no art"),
    ("Dispositivo de sentenca",
     r"\b(ante o exposto|isto posto|pelo exposto|diante do exposto|posto isso)\b.{0,40}\bjulgo\b|\bjulgo\s+(procedente|improcedente|parcialmente|extint)"),
    ("Sentenca proferida em ata",
     r"foi proferida a seguinte senten.a|passo a proferir senten.a"),
    ("Acordao / sessao",
     r"acordam os? (senhores )?(desembargadores|ministros|juizes)|vistos, relatados e discutidos"),
    ("Recebimento da denuncia", r"recebo a den.ncia|recebida a den.ncia"),
    ("Abertura de peca de parte",
     r"vem,?\s+(respeitosamente|mui respeitosamente).{0,90}(propor|apresentar|impetrar|interpor|oferecer|requerer)|vem a presen.a de vossa excelencia"),
    ("Certidao de cartorio", r"^\s*certifico\b|certifico e dou fe"),
    ("Conclusao ao juiz", r"fa.o (estes autos )?conclusos|fa.o conclusos"),
    ("Ordem de expediente",
     r"\b(intime-se|cite-se|notifique-se|expe.a-se|cumpra-se|publique-se|arquivem-se|remetam-se)\b"),
    ("Deferimento / indeferimento",
     r"\b(defiro|indefiro|homologo|declaro extint|concedo a liminar|denego a ordem|decreto a revelia)\b"),
]

CATALOGO_ALERTAS = [
    ("ALTA", "Transito em julgado", r"\btr.nsit(o|ou|ado)\s+em\s+julgado\b"),
    ("ALTA", "Revelia / confissao", r"\brevel(ia)?\b|\bconfess(o|a)\b"),
    ("ALTA", "Intempestividade", r"\bintempestiv"),
    ("ALTA", "Decurso de prazo",
     r"\bdecurso de prazo\b|\bpreclu(so|sa|sao|iu)\b|\bin albis\b"),
    ("ALTA", "Prescricao / decadencia", r"\bprescri.|\bdecadenc"),
    ("ALTA", "Extincao / arquivamento",
     r"\bextin(cao|to|ta|guir|guiu)\b|\barquivamento\b|\bbaixa definitiva\b"),
    ("ALTA", "Constricao patrimonial",
     r"\bpenhora\b|\bbloqueio\b|\bindisponibilidade\b|\bleilao\b|\bhasta publica\b|\barresto\b|\bsequestro\b|\bbusca e apreensao\b"),
    ("ALTA", "Multa / astreinte",
     r"\bastreinte\b|\bmulta diaria\b|\bmulta cominatoria\b|\bmulta de 10%\b"),
    ("ALTA", "Medida de liberdade",
     r"\bpris.o\b|\bmedida cautelar (pessoal|diversa)\b|\bmandado de pris.o\b|\bpreventiva\b|\bmonitoracao eletronica\b"),
    ("ALTA", "Sigilo / segredo", r"\bsigilo(so|sa)?\b|\bsegredo de justi.a\b"),
    ("ALTA", "Desconsideracao / redir",
     r"\bdesconsidera.ao da personalidade\b|\bredirecionamento\b|\bincluir no polo passivo\b|\bgrupo economico\b|\bsucessao (de empresas|trabalhista)\b"),
    ("MEDIA", "Audiencia", r"\baudi.ncia\b|\bsessao de julgamento\b|\bpauta\b"),
    ("MEDIA", "Pericia", r"\bpericia\b|\bperito\b|\blaudo\b"),
    ("ALTA", "Art. 40 LEF / intercorr.",
     r"\bart\.? ?40\b.{0,30}(lei|lef)|\bprescri.ao intercorrente\b|\bsuspens(ao|o) do (feito|processo) por (1|um) ano\b"),
    ("MEDIA", "Suspensao / sobrestam.",
     r"\bsuspens(ao|o|a)\b|\bsobrestad|\bsobrestamento\b"),
    ("MEDIA", "Conclusos / vista",
     r"\bconclus(o|os|ao)\b|\bvista dos autos\b|\bremessa ao mp\b|\bde-se vista\b"),
    ("MEDIA", "Diligencia frustrada",
     r"\bnegativ(o|a)\b|\bnao localizad|\bmudou-se\b|\bfrustrad|\bsem cumprimento\b|\bendereco incorreto\b|\bnao encontrad"),
    ("MEDIA", "Emenda / regularizacao",
     r"\bemende\b|\bemenda\b|\bsanar\b|\bregularize\b|\bsob pena de indeferimento\b|\bart\.? ?76 do cpc\b"),
    ("MEDIA", "Recuperacao / falencia",
     r"\brecupera.ao judicial\b|\bfal.ncia\b|\bjuizo universal\b"),
    ("MEDIA", "Tema / IRDR / repetit.",
     r"\btema \d+\b|\birdr\b|\brepercussao geral\b|\brepetitivo\b|\bsumula vinculante\b"),
    ("MEDIA", "Migracao / apenso",
     r"\bprocesso migrado\b|\bautos em apartado\b|\bautos dependentes\b|\bapenso\b|\bredistribui"),
]

MESES = {"janeiro": 1, "fevereiro": 2, "marco": 3, "abril": 4, "maio": 5,
         "junho": 6, "julho": 7, "agosto": 8, "setembro": 9, "outubro": 10,
         "novembro": 11, "dezembro": 12}

# Marcas de foliacao. A do e-STJ e o carimbo canonico, uma por folha; as demais
# aparecem tambem no corpo do texto, referindo folha alheia.
RX_FOLHA_STJ = re.compile(r"\(\s*e-STJ\s*Fl\.\s*(\d{1,5})", re.I)
RX_FOLHA = re.compile(r"\bfls?\.\s*(\d{1,5})\b", re.I)
RX_CRIADO_MD = re.compile(r"PDF criado em\s*(\d{2}/\d{2}/\d{4}(?:\s+\d{2}:\d{2})?)")


# ----------------------------------------------------------------------------
# Motor
# ----------------------------------------------------------------------------


def mapear(arquivo, args):
    src, pdf_origem = fonte(arquivo)
    linhas = ler_linhas(src)
    total = len(linhas)

    out = []

    def add(t=""):
        out.append(str(t))

    # ---------------- passe unico ----------------
    # Comeca em 1, e nao em 0: o pdf2md nao emite marcador para a primeira pagina
    # (o primeiro que aparece e "[p. 2]"). Comecando em 0, a pagina 1 nunca era
    # contada como coberta e saia SEMPRE na lista de "sem camada de texto" - falso
    # positivo que ja foi copiado para dentro de uma ficha, afirmando nao lida a
    # pagina de onde a propria ficha tirara o numero, a classe e a qualificacao.
    pagina = 1
    cnjs = OrderedDict()
    capa = OrderedDict()
    partes, pecas, datas, prazos, alertas = [], [], [], [], []
    assin, idx_linhas, formulas, url_datas = [], [], [], []
    valores, oabs, repetidas, paginas_com_texto = Counter(), Counter(), Counter(), {}
    folhas_stj, folhas_gen = [], []
    sistema = []
    data_extrato = None
    criado_em = creationdate_do_pdf(pdf_origem) if pdf_origem else None
    linha_indice = linha_sumario = 0
    acentos = total_chars = 0

    if not args.cru:
        for l in linhas:
            k = trecho(l, 90)
            if len(k) >= 20:
                repetidas[k] += 1

    for i, orig in enumerate(linhas):
        if not orig.strip():
            continue
        nl = i + 1
        m = re.search(r"\[p\.\s*(\d+)\]", orig)
        if m:
            pagina = int(m.group(1))

        a = ascii_min(orig)
        tr = trecho(orig, args.contexto)
        carimbo = False
        if not args.cru:
            carimbo = repetidas.get(trecho(orig, 90), 0) >= 5

        if criado_em is None:
            mc = RX_CRIADO_MD.search(orig)
            if mc:
                criado_em = mc.group(1)

        # cobertura e sanidade da conversao
        total_chars += len(orig)
        # Letra fora do ASCII = letra acentuada.
        acentos += (len(re.findall(r"[^\W\d_]", orig, re.UNICODE))
                    - len(re.findall(r"[a-zA-Z]", orig)))
        # Pagina so conta como coberta se tiver linha de CONTEUDO. Nao sao
        # conteudo: o carimbo repetido, a URL de validacao, a foliacao e o numero
        # do documento - e sao exatamente eles que sobram numa pagina de imagem.
        limpo = re.sub(r"https?://\S+", "", a)
        limpo = re.sub(r"numero do (processo|documento)\s*:?\s*[\d\.\-/]*", "", limpo)
        limpo = re.sub(r"fls?\.?\s*:?\s*\d+", "", limpo)
        limpo = re.sub(r"pag(ina)?\.?\s*\d+([/ ]\d+)?", "", limpo)
        limpo = re.sub(r"instancia\s*=?\s*\d*", "", limpo)
        limpo = re.sub(r"[^a-z]", "", limpo)
        if (not carimbo and len(limpo) >= 12
                and not re.match(r"^\s*\[p\.", orig)
                and not re.match(r"^\s*<!--", orig)):
            paginas_com_texto[pagina] = True

        # --- foliacao ---
        for mm in RX_FOLHA_STJ.finditer(orig):
            folhas_stj.append((pagina, nl, int(mm.group(1))))
        for mm in RX_FOLHA.finditer(orig):
            folhas_gen.append((pagina, nl, int(mm.group(1))))

        # relogio embutido na URL de validacao do PJe-JT: AAMMDDHHMMSS nos 12
        # primeiros digitos. E o unico jeito de datar peca sem rodape de assinatura.
        for mm in re.finditer(r"validacao/(\d{12})", orig):
            s = mm.group(1)
            dt = nova_data(int(s[4:6]), int(s[2:4]), 2000 + int(s[0:2]))
            if dt:
                url_datas.append({"data": dt,
                                  "hora": "%s:%s:%s" % (s[6:8], s[8:10], s[10:12]),
                                  "pagina": pagina, "linha": nl})

        # --- sistema ---
        if nl <= 60:
            if re.search(r"processo judicial eletronico|\bpje\b", a):
                marca = ("PJe-JT (Justica do Trabalho)"
                         if re.search(r"justica do trabalho|tribunal regional do trabalho", a)
                         else "PJe")
                if marca not in sistema:
                    sistema.append(marca)
            if re.search(r"\be-?proc\b", a) and "eproc" not in sistema:
                sistema.append("eproc")
            if (re.search(r"tribunal de justica do estado de sao paulo|\besaj\b", a)
                    and "eSAJ (TJSP)" not in sistema):
                sistema.append("eSAJ (TJSP)")
            if re.search(r"projudi", a) and "Projudi" not in sistema:
                sistema.append("Projudi")
            if data_extrato is None:
                md = re.match(r"^\s*(\d{2})/(\d{2})/(\d{4})\s*$", orig)
                if md:
                    data_extrato = nova_data(int(md.group(1)), int(md.group(2)),
                                             int(md.group(3)))
        if re.search(r"pje\.trt|pje\dg?\.|pjekz", a):
            marca = "PJe-JT (Justica do Trabalho)" if re.search(r"pje\.trt", a) else "PJe"
            if marca not in sistema:
                sistema.append(marca)
        if re.search(r"pastadigital|assinado digitalmente por.*tribunal de justica do estado de sao paulo", a):
            if "eSAJ (TJSP)" not in sistema:
                sistema.append("eSAJ (TJSP)")

        # --- indice oficial ---
        if linha_indice == 0 and re.search(
                r"documentos?\s+id\.?\s+data|^\s*#*\s*documentos\s*$|"
                r"id\.?\s+data da\s+documento|data da\s+id\.\s+documento", a):
            linha_indice = nl
        if linha_sumario == 0 and re.search(
                r"^\s*#*\s*sumario\s*$|para acessar o sumario", a):
            linha_sumario = nl

        # Linhas de indice: PJe usa Id numerico de 9-10 digitos; PJe-JT usa hash
        # de 7 hex. A captura do nome do documento e LAZY e para no proximo
        # lancamento: o extrato imprime varios lancamentos na mesma linha, e um
        # limite fixo de caracteres engolia o lancamento seguinte - fazendo sumir
        # do indice justamente os IDs da prova e o ultimo despacho dos autos.
        for mm in re.finditer(
                r"(?<!\d)(\d{9,10})\s+(\d{2}/\d{2}/\d{4})(?:\s+(\d{2}:\d{2}))?\s+"
                r"(.*?)(?=(?:(?<!\d)\d{9,10}\s+\d{2}/\d{2}/\d{4})|$)", orig):
            nome = celula(mm.group(4))
            if len(nome) >= 2:
                idx_linhas.append({"id": mm.group(1), "data": mm.group(2),
                                   "resto": nome, "linha": nl})
        for mm in re.finditer(
                r"(?<![0-9a-fA-F])([0-9a-f]{7})\s+(\d{2}/\d{2}/\d{4})\s+(\d{2}:\d{2})\s+"
                r"(.*?)(?=(?:(?<![0-9a-fA-F])[0-9a-f]{7}\s+\d{2}/\d{2}/\d{4})|$)", orig):
            nome = celula(mm.group(4))
            if len(nome) >= 2:
                idx_linhas.append({"id": mm.group(1), "data": mm.group(2),
                                   "resto": nome, "linha": nl})

        # --- fronteiras de peca: assinatura eletronica ---
        m1 = re.search(r"Assinado eletronicamente por:\s*(.+?)\s*-\s*"
                       r"(\d{2}/\d{2}/\d{4})\s+(\d{2}:\d{2}(?::\d{2})?)", orig, re.I)
        m2 = re.search(r"assinado eletronicamente por\s+(.+?),\s*em\s*(\d{2}/\d{2}/\d{4}),?"
                       r"\s*[aà]s\s*(\d{2}:\d{2}(?::\d{2})?)\s*-\s*([0-9a-fA-F]{6,10})",
                       orig, re.I)
        m3 = re.search(r"assinado digitalmente por\s+(.+?),.*?protocolado em\s*"
                       r"(\d{2}/\d{2}/\d{4})\s*[aà]s\s*(\d{2}:\d{2})", orig, re.I)
        if m1:
            assin.append({"assinante": celula(m1.group(1)), "data": m1.group(2),
                          "hora": m1.group(3), "id": "", "pagina": pagina, "linha": nl})
        elif m2:
            assin.append({"assinante": celula(m2.group(1)), "data": m2.group(2),
                          "hora": m2.group(3), "id": m2.group(4),
                          "pagina": pagina, "linha": nl})
        elif m3:
            assin.append({"assinante": celula(m3.group(1)), "data": m3.group(2),
                          "hora": m3.group(3), "id": "", "pagina": pagina, "linha": nl})

        # --- numero CNJ ---
        for mm in re.finditer(
                r"(?<![\d-])\d{7}[-\.]?\d{2}[\.\s]?\d{4}[\.\s]?\d[\.\s]?\d{2}[\.\s]?\d{4}(?!\d)",
                orig):
            d = re.sub(r"\D", "", mm.group(0))
            if len(d) != 20:
                continue
            if d not in cnjs:
                cnjs[d] = {"digitos": d, "ocorrencias": 0, "primeira": nl,
                           "valido": testa_cnj(d)}
            cnjs[d]["ocorrencias"] += 1

        # --- capa ---
        if nl <= 200:
            for rotulo, padrao in CAMPOS_CAPA:
                if rotulo in capa:
                    continue
                mm = re.search(padrao, a)
                if mm:
                    v = celula(mm.group(1))
                    if 2 <= len(v) <= 220:
                        capa[rotulo] = v
            # Casa na linha ORIGINAL, com IgnoreCase: o nome da parte tem de sair
            # como esta impresso. Sair em caixa baixa convidava a preencher a ficha
            # do lado errado, que e o defeito numero um do controle de qualidade.
            for mm in re.finditer(
                    r"\b(%s)\s*:\s*([^:,\r\n]{3,90}?)(?=\s*,|\s+(?:%s)\s*:|\s*$)"
                    % (ROTULOS_PARTE, ROTULOS_PARTE), orig, re.I):
                p = "%s: %s" % (mm.group(1).upper(), celula(mm.group(2)))
                if p not in partes:
                    partes.append(p)
            for mm in re.finditer(
                    r"([A-Z][A-Za-zÀ-ÿ\.\' ]{4,70}?)\s*\((EXEQUENTE|EXECUTADO|"
                    r"EXECUTADA|AUTOR|AUTORA|REU|R[EÉ]|REQUERENTE|REQUERIDO|REQUERIDA|"
                    r"IMPETRANTE|IMPETRADO|RECLAMANTE|RECLAMADO|RECLAMADA|AGRAVANTE|"
                    r"AGRAVADO|APELANTE|APELADO)\)", orig):
                # "Partes Advogados" e cabecalho de quadro, nao parte do nome.
                nome = re.sub(r"^partes\s+advogados\s*", "", celula(mm.group(1)), flags=re.I)
                p = "%s: %s" % (mm.group(2), nome)
                if p not in partes:
                    partes.append(p)

        # --- indice de pecas por titulo ---
        # Tres filtros, todos aprendidos em uso real:
        #  (a) a palavra-chave tem de estar no COMECO da linha e a linha tem de ser
        #      curta - senao trecho de corpo de carta de citacao virava "acordo";
        #  (b) linha de negacao nao vira constricao: "sem restricao" numa tela
        #      RENAJUD e ausencia de constricao, e rotula-la de constricao inverte;
        #  (c) marca d agua ("SEM VALOR DE CERTIDAO") nao e certidao - eram 38
        #      numa ficha da JUCESP, falseando a composicao dos autos.
        eh_titulo = bool(
            re.match(r"^\s*#{1,6}\s", orig)
            # re.I de proposito: em PowerShell `-match` e case-insensitive por
            # padrao, entao esta classe [A-Z...] do mapear-autos.ps1 casa minuscula
            # tambem. Porta-se o comportamento real do .ps1, nao o pretendido.
            or re.match(r"^\s*[A-ZÀ-Ü0-9\s\.\-\/\(\)ºª]{6,90}\s*$", orig, re.I)
            or re.match(r"^\s*(evento|mov(imento)?|id\.?|seq\.?|doc\.?|fls?\.|f\.)\s*[:nº]?\s*\d", a))
        ruido = bool(re.search(
            r"sem valor de certid|sem restri|nada consta|nada a constar|"
            r"nao consta restri|marca d.agua", a))
        if eh_titulo and not carimbo and not ruido and len(orig.strip()) <= 110:
            cabeca = a[:70]
            for rotulo, padrao in CATALOGO_PECAS:
                if re.search(padrao, cabeca):
                    pecas.append({"pagina": pagina, "linha": nl, "peca": rotulo,
                                  "trecho": tr})
                    break

        # --- formulas de abertura e de dispositivo ---
        if not carimbo:
            for rotulo, padrao in CATALOGO_FORMULAS:
                mf = re.search(padrao, a)
                if mf:
                    formulas.append({"pagina": pagina, "linha": nl, "rotulo": rotulo,
                                     "trecho": trecho_centrado(orig, mf.start(),
                                                               len(a), args.contexto)})
                    break

        # --- datas ---
        if not carimbo:
            for mm in re.finditer(r"\b(\d{1,2})/(\d{1,2})/(\d{4})\b", orig):
                dt = nova_data(int(mm.group(1)), int(mm.group(2)), int(mm.group(3)))
                if dt:
                    datas.append({"data": dt, "pagina": pagina, "linha": nl, "trecho": tr})
            for mm in re.finditer(r"\b(\d{1,2})\s+de\s+([a-z]+)\s+de\s+(\d{4})\b", a):
                mes = MESES.get(mm.group(2))
                if mes:
                    dt = nova_data(int(mm.group(1)), mes, int(mm.group(3)))
                    if dt:
                        datas.append({"data": dt, "pagina": pagina, "linha": nl,
                                      "trecho": tr})

        # --- prazos ---
        for mm in re.finditer(
                r"(no\s+)?prazo\s+(comum\s+|sucessivo\s+|improrrogavel\s+|em\s+dobro\s+|legal\s+)?"
                r"de\s+\d{1,3}\s*(\([a-z\s]+\)\s*)?(dias?|horas?|meses)(\s+uteis)?|"
                r"\b\d{1,3}\s*\([a-z\s]+\)\s*dias?\s+(uteis\s+)?(para|a\s+contar|apos|sob\s+pena)|"
                r"\bprazo\s*:\s*\d{1,3}\s*dias?", a):
            prazos.append({"pagina": pagina, "linha": nl,
                           "expressao": celula(mm.group(0)), "trecho": tr})

        # --- alertas ---
        if not carimbo:
            for sev, rotulo, padrao in CATALOGO_ALERTAS:
                ma = re.search(padrao, a)
                if ma:
                    alertas.append({"sev": sev, "rotulo": rotulo, "pagina": pagina,
                                    "linha": nl,
                                    "trecho": trecho_centrado(orig, ma.start(),
                                                              len(a), args.contexto)})

        # --- valores e OAB ---
        for mm in re.finditer(r"R\$\s?[\d\.]{1,15},\d{2}", orig):
            valores[re.sub(r"\s", "", mm.group(0))] += 1
        for mm in re.finditer(r"OAB\s*[/\-]?\s*([A-Z]{2})\s*n?[.º\s]*([\d\.]{3,9})", orig):
            oabs["OAB/%s %s" % (mm.group(1), mm.group(2).replace(".", ""))] += 1

    # ---------------- relatorio ----------------
    add("# Mapa dos autos - " + os.path.basename(arquivo))
    add("")
    add("Fonte lida: `%s`  |  %d linhas  |  %d paginas detectadas" % (src, total, pagina))
    if sistema:
        add("Sistema: **%s**" % " / ".join(sistema))
    else:
        add("Sistema: nao identificado pelo cabecalho.")
    add("")

    # --- 0. atualidade -------------------------------------------------------
    # Cinco ancoras independentes, porque nenhuma existe em todos os sistemas: o
    # eSAJ nao tem data de geracao nem carimbo de assinatura apos a conversao; o
    # PJe-JT tem pecas recentes SEM rodape de assinatura, cuja unica data esta nos
    # 12 primeiros digitos da URL de validacao; e ha arquivo cuja unica data
    # recente esta so nos metadados do PDF. Usar so uma ancora ja errou por 48
    # dias num caso, falhou inteiramente noutro e erraria 13 meses num terceiro.
    add("## 0. O extrato esta atual?")
    add("")

    ancoras = []
    if url_datas:
        u = max(url_datas, key=lambda x: x["data"])
        ancoras.append({"nome": "URL de validacao (relogio do PJe-JT)", "d": u["data"],
                        "detalhe": "%s %s, p. %d, linha %d" % (dbr(u["data"]), u["hora"],
                                                              u["pagina"], u["linha"])})
    if idx_linhas:
        com_d = [(data_br(r["data"]), r) for r in idx_linhas if data_br(r["data"])]
        if com_d:
            d, r = max(com_d, key=lambda x: x[0])
            ancoras.append({"nome": "Ultima linha do indice oficial", "d": d,
                            "detalhe": "%s - Id %s - %s" % (r["data"], r["id"], r["resto"])})
    if assin:
        com_d = [(data_br(r["data"]), r) for r in assin if data_br(r["data"])]
        if com_d:
            d, r = max(com_d, key=lambda x: x[0])
            ancoras.append({"nome": "Ultima assinatura eletronica", "d": d,
                            "detalhe": "%s %s, por %s (p. %d, linha %d)"
                                       % (r["data"], r["hora"], r["assinante"],
                                          r["pagina"], r["linha"])})
    d_criado = data_br(criado_em.split()[0]) if criado_em else None
    if d_criado:
        ancoras.append({"nome": "Metadados do arquivo (CreationDate)", "d": d_criado,
                        "detalhe": "PDF gerado em %s" % criado_em})

    inferida = None
    if not ancoras:
        passadas = sorted([d for d in datas if d["data"] <= args.hoje],
                          key=lambda x: x["data"])
        if passadas:
            inferida = passadas[-1]
            ancoras.append({"nome": "Data mais recente do texto (INFERIDA)",
                            "d": inferida["data"],
                            "detalhe": "%s, p. %d, linha %d - %s"
                                       % (dbr(inferida["data"]), inferida["pagina"],
                                          inferida["linha"], inferida["trecho"])})

    if data_extrato:
        add("- **Extrato gerado em %s** (data impressa pelo sistema)." % dbr(data_extrato))
    if criado_em:
        add("- **PDF criado em %s** (metadado `CreationDate` do arquivo)." % criado_em)

    if ancoras:
        add("")
        add("| ancora da ultima atividade | data | onde |")
        add("|---|---|---|")
        for an in sorted(ancoras, key=lambda x: x["d"], reverse=True):
            add("| %s | **%s** | %s |" % (an["nome"], dbr(an["d"]), celula(an["detalhe"])))
        add("")
        topo = max(ancoras, key=lambda x: x["d"])
        if len(ancoras) > 1:
            base = min(ancoras, key=lambda x: x["d"])
            if topo["d"] > base["d"]:
                add("> As ancoras divergem em %d dia(s). Vale a MAIS RECENTE (%s): as "
                    "demais nao cobrem pecas que entraram sem aquele marcador. "
                    "Divergencia grande tambem pode significar que o arquivo esta "
                    "truncado." % ((topo["d"] - base["d"]).days, dbr(topo["d"])))
                add("")
        gap = (args.hoje - topo["d"]).days
        add("- Ultima atividade retratada: **%s**. Hoje e %s. O arquivo tem **%d dia(s)**."
            % (dbr(topo["d"]), dbr(args.hoje), gap))
        if criado_em:
            add("- **A data de criacao do PDF diz quando o retrato foi tirado, nao quando "
                "o processo se moveu.** Registre as duas: sem ela, arquivo cujo unico "
                "marcador antigo e o texto ja fez datar o retrato treze meses atras.")
        if inferida:
            add("- **A data acima e inferida do texto**, nao de um marcador do sistema. "
                "Neste arquivo nao ha data de geracao, indice, assinatura eletronica, "
                "URL de validacao nem metadado de criacao: a atualidade NAO pode ser "
                "afirmada com base nele.")
        add("")
        if gap >= 30:
            add("> **ATENCAO - EXTRATO VENCIDO.** Ha %d dias entre o ultimo ato retratado "
                "neste arquivo e hoje. Tudo o que ocorreu nesse intervalo esta invisivel "
                "aqui. NAO afirme fase atual, prazo em curso nem \"ultimo movimento\" com "
                "base so neste PDF: baixe extrato novo ou consulte o andamento no sistema "
                "do tribunal antes de concluir." % gap)
        else:
            add("> Janela aceitavel, mas confirme o andamento no sistema antes de cravar prazo.")
    else:
        add("- Nao foi possivel datar o arquivo por nenhuma das cinco ancoras. Trate-o "
            "como desatualizado ate consultar o sistema.")
    add("")

    # --- 0.1 cobertura e sanidade da conversao -------------------------------
    add("## 0.1 O que o arquivo NAO mostra")
    add("")
    if pagina > 0:
        mudas = [n for n in range(1, pagina + 1) if n not in paginas_com_texto]
        if not mudas:
            add("- Todas as %d paginas produziram texto." % pagina)
        else:
            faixas = comprimir(mudas)
            add("- **%d de %d paginas nao produziram texto:** %s"
                % (len(mudas), pagina, ", ".join(faixas)))
            add("")
            add("> Sao documentos digitalizados sem OCR, e o mapa nao diz NADA sobre o "
                "conteudo delas. Costumam ser exatamente a prova - extrato de FGTS, ficha "
                "de registro, ASO, laudo, termo de declaracoes, foto de album policial. "
                "Liste-as como nao lidas na entrega e abra o PDF original ou peca ao "
                "cliente. Nunca conclua \"nao ha X nos autos\" sem antes cobrir estas paginas.")
    else:
        add("- O arquivo nao tem marcadores de pagina `[p. N]`; a cobertura por pagina "
            "nao pode ser apurada.")
    add("")
    if total_chars > 2000:
        p = 100.0 * acentos / total_chars
        ptxt = ("%.2f" % p).replace(".", ",")   # virgula decimal, como no .ps1
        if p < 1.0:
            add("- **ACENTUACAO PERDIDA NA CONVERSAO: apenas %s%% dos caracteres sao "
                "acentuados.**" % ptxt)
            add("")
            add("> Texto juridico em portugues fica entre 2% e 3%. Abaixo de 1% a fonte do "
                "PDF nao traz `/ToUnicode` confiavel e os acentos viraram outro glifo "
                "(`sintese` sai `s?ntese`, `Alvaro` sai `?lvaro`). Consequencia pratica: "
                "**nome proprio, razao social e endereco copiados daqui vao errados para a "
                "peca.** Confira toda transcricao contra o PDF antes de usar.")
        else:
            add("- Acentuacao integra (%s%% dos caracteres) - a conversao preservou os "
                "glifos." % ptxt)
    add("")

    # --- 0.2 foliacao --------------------------------------------------------
    for l in secao_foliacao(folhas_stj, folhas_gen, pagina):
        add(l)

    # --- 1. identificacao ---------------------------------------------------
    add("## 1. Identificacao")
    add("")
    if not cnjs:
        add("- Nenhum numero CNJ localizado: autos sem numeracao no texto, ou PDF sem "
            "camada de texto.")
    else:
        add("| Numero | Ocorrencias | 1a linha | DV |")
        add("|---|---:|---:|---|")
        for c in sorted(cnjs.values(), key=lambda x: (-x["ocorrencias"], x["primeira"])):
            add("| %s | %d | %d | %s |" % (formata_cnj(c["digitos"]), c["ocorrencias"],
                                           c["primeira"],
                                           "ok" if c["valido"] else "**INVALIDO**"))
        if len(cnjs) > 1:
            add("")
            add("> Ha %d numeros distintos. Decida qual e o principal antes de analisar: "
                "os demais podem ser apenso, recurso, precatoria, execucao em apartado, "
                "numero antigo do mesmo feito - ou peca de OUTRO processo colada por "
                "engano." % len(cnjs))
        invalidos = [c for c in cnjs.values() if not c["valido"]]
        if invalidos:
            add("")
            add("> %d numero(s) com digito verificador invalido. Ou houve erro de digitacao "
                "na peca, ou o OCR corrompeu o numero. Confira no sistema antes de copiar "
                "para qualquer lugar." % len(invalidos))
    add("")
    if capa:
        add("**Campos da capa** (como impressos, sem correcao):")
        add("")
        add("| campo | valor |")
        add("|---|---|")
        for k, v in capa.items():
            add("| %s | %s |" % (k, celula(v)))
        add("")
    if partes:
        add("**Partes e procuradores localizados:** " + " &middot; ".join(partes[:24]))
        add("")
        add("> Polo em branco, ou parte sem advogado ao lado, e informacao - nao e lacuna "
            "do extrato. Registre.")
        add("")

    # --- 2. indice oficial --------------------------------------------------
    add("## 2. Indice oficial do sistema")
    add("")
    if linha_indice:
        add("- Tabela \"Documentos / Id. / Data da Assinatura\" comeca na **linha %d**."
            % linha_indice)
    if linha_sumario:
        add("- Marcador de SUMARIO na **linha %d**. No PJe-JT o sumario fica na ULTIMA "
            "folha - va ao fim do arquivo." % linha_sumario)
    if not linha_indice and not linha_sumario:
        add("- Nenhum indice impresso. E o caso do eSAJ e das pastas digitais: a espinha e "
            "a foliacao `fls. N` e a ordem cronologica de juntada. Use a secao 3 "
            "(fronteiras de peca) como indice substituto.")
    add("")
    if idx_linhas:
        add("**%d lancamento(s) reconhecido(s)** no formato `<Id> <data> <documento>`:"
            % len(idx_linhas))
        add("")
        add("| Id | data | documento / tipo | linha |")
        add("|---|---|---|---:|")
        for n, r in enumerate(idx_linhas):
            if n >= args.max_eventos:
                add("| ... | ... | *(+%d omitidos)* | |" % (len(idx_linhas) - n))
                break
            add("| %s | %s | %s | %d |" % (r["id"], r["data"], r["resto"], r["linha"]))
        add("")
        add("> O indice do PJe imprime a coluna da HORA quebrada na linha vizinha: a hora "
            "que aparece junto de um Id pode ser do lancamento anterior. E o indice e um "
            "indice, nao um inventario - peca protocolada com visibilidade restrita "
            "(defesa antes da conciliacao, por exemplo) existe nos autos e NAO aparece "
            "aqui. Confira sempre contra a secao 3.")
    add("")

    # --- 3. fronteiras de peca ----------------------------------------------
    add("## 3. Fronteiras de peca (assinaturas eletronicas)")
    add("")
    if not assin:
        add("- Nenhum carimbo de assinatura reconhecido. Sem ele, a separacao entre uma "
            "peca e a seguinte so se faz pelo titulo - o que e menos confiavel.")
    else:
        blocos, atual = [], None
        for s in assin:
            chave = "%s|%s|%s|%s" % (s["assinante"], s["data"], s["hora"], s["id"])
            if atual is None or atual["chave"] != chave:
                if atual:
                    blocos.append(atual)
                atual = {"chave": chave, "assinante": s["assinante"], "data": s["data"],
                         "hora": s["hora"], "id": s["id"], "pag_ini": s["pagina"],
                         "pag_fim": s["pagina"], "lin_ini": s["linha"],
                         "lin_fim": s["linha"], "folhas": 1}
            else:
                atual["pag_fim"] = s["pagina"]
                atual["lin_fim"] = s["linha"]
                atual["folhas"] += 1
        if atual:
            blocos.append(atual)

        tem_id = any(b["id"] for b in blocos)
        cobertas = len({n for b in blocos for n in range(b["pag_ini"], b["pag_fim"] + 1)})

        add("**%d bloco(s) de assinatura** = candidatos a peca autonoma. O carimbo do "
            "rodape, e nao o titulo, e o que diz onde uma peca termina e outra comeca."
            % len(blocos))
        add("")
        if tem_id:
            add("| # | assinante | data/hora | Id | paginas | linhas | folhas |")
            add("|---:|---|---|---|---|---|---:|")
        else:
            add("| # | assinante | data/hora | paginas | linhas | folhas |")
            add("|---:|---|---|---|---|---:|")
        for n, b in enumerate(blocos, 1):
            if n > args.max_eventos:
                add("| ... | *(+%d blocos omitidos)* | | | | |"
                    % (len(blocos) - args.max_eventos))
                break
            if tem_id:
                add("| %d | %s | %s %s | %s | %d-%d | %d-%d | %d |"
                    % (n, b["assinante"], b["data"], b["hora"], b["id"], b["pag_ini"],
                       b["pag_fim"], b["lin_ini"], b["lin_fim"], b["folhas"]))
            else:
                add("| %d | %s | %s %s | %d-%d | %d-%d | %d |"
                    % (n, b["assinante"], b["data"], b["hora"], b["pag_ini"],
                       b["pag_fim"], b["lin_ini"], b["lin_fim"], b["folhas"]))
        add("")
        if not tem_id:
            add("> Este sistema nao repete o Id no rodape - so o nome e a data. A amarracao "
                "assinatura -> Id tem de ser feita contra a secao 2, casando data e paginas.")
            add("")
        if pagina > 0 and cobertas < pagina:
            add("> **COBERTURA PARCIAL: %d de %d paginas tem carimbo de assinatura.** As "
                "demais nao sao lacuna do arquivo - sao pecas que este sistema nao carimba "
                "(anexo, prova documental, peca protocolada por outro meio). Para essas, a "
                "secao 3 NAO serve de indice, e o \"ultimo movimento\" apurado so por ela "
                "pode estar desatualizado. Confira contra a secao 2." % (cobertas, pagina))
            add("")
        add("> Assinante servidor ou magistrado = ato do juizo (intimacao, despacho, "
            "decisao, sentenca, certidao): e nele que mora o prazo. Assinante advogado = "
            "peca de parte: nela mora a tese, nunca o prazo.")
        add("")
        add("> A data do carimbo e a data da ASSINATURA, nao a data do ato retratado nem a "
            "da juntada. Documento assinado em janeiro e juntado em marco aparece aqui com "
            "a data de janeiro.")
    add("")

    # --- 4. indice de pecas por titulo --------------------------------------
    add("## 4. Pecas reconhecidas por titulo")
    add("")
    if not pecas:
        add("- Nenhum titulo de peca reconhecido. Confira se o .md preservou os titulos (o "
            "pdf2md marca com `#`) e se o PDF tem camada de texto.")
    else:
        resumo = Counter(p["peca"] for p in pecas)
        add("**Quantas de cada:** " + " &middot; ".join(
            "%s (%d)" % (k, v) for k, v in resumo.most_common()))
        add("")
        add("| pag | linha | peca | titulo localizado |")
        add("|---:|---:|---|---|")
        for n, p in enumerate(pecas):
            if n >= args.max_eventos:
                add("| ... | ... | ... | *(+%d omitidas - use --max-eventos)* |"
                    % (len(pecas) - n))
                break
            add("| %d | %d | %s | %s |" % (p["pagina"], p["linha"], p["peca"],
                                           celula(p["trecho"])))
    add("")
    add("> **Rotulo e palpite, nao classificacao.** O reconhecimento e por palavra no "
        "comeco da linha: uma linha pode ser rotulada errado, e uma peca sem titulo NAO "
        "aparece aqui de jeito nenhum. Nunca conclua \"nao ha sentenca nos autos\" a "
        "partir desta tabela - confira a secao 4.1 e abra a linha.")
    add("")

    # --- 4.1 formulas -------------------------------------------------------
    add("### 4.1 Pecas reconhecidas por formula")
    add("")
    if not formulas:
        add("- Nenhuma formula de abertura ou de dispositivo localizada.")
    else:
        res_f = Counter(f["rotulo"] for f in formulas)
        add("**Quantas de cada:** " + " &middot; ".join(
            "%s (%d)" % (k, v) for k, v in res_f.most_common()))
        add("")
        add("| pag | linha | o que e | trecho |")
        add("|---:|---:|---|---|")
        for n, f in enumerate(formulas):
            if n >= args.max_eventos:
                add("| ... | ... | ... | *(+%d omitidas)* |" % (len(formulas) - n))
                break
            add("| %d | %d | %s | %s |" % (f["pagina"], f["linha"], f["rotulo"],
                                           celula(f["trecho"])))
        add("")
        add("> Esta tabela apanha a peca que a de cima perde: a denuncia que so tem "
            "enderecamento, e a sentenca do JEC, que vive dentro do termo de audiencia e "
            "nunca aparece como peca autonoma. `Dispositivo de sentenca` e `Acordao` sao "
            "os dois achados mais valiosos do mapa inteiro.")
    add("")

    # --- 5. linha do tempo --------------------------------------------------
    add("## 5. Linha do tempo")
    add("")
    if not datas:
        add("- Nenhuma data localizada.")
    else:
        ordenadas = sorted(datas, key=lambda x: x["data"])
        add("Intervalo coberto: **%s** a **%s** (%d datas)."
            % (dbr(ordenadas[0]["data"]), dbr(ordenadas[-1]["data"]), len(datas)))
        futuras = [d for d in datas if d["data"] > args.hoje]
        if futuras:
            add("")
            add("**%d data(s) no futuro** - candidatas a audiencia, sessao ou vencimento "
                "designado:" % len(futuras))
            add("")
            add("| data | pag | linha | trecho |")
            add("|---|---:|---:|---|")
            for d in sorted(futuras, key=lambda x: x["data"])[:20]:
                add("| %s | %d | %d | %s |" % (dbr(d["data"]), d["pagina"], d["linha"],
                                               celula(d["trecho"])))
        add("")
        add("### 5.1 As 15 datas passadas mais recentes")
        add("")
        add("| data | pag | linha | trecho |")
        add("|---|---:|---:|---|")
        passadas = [d for d in ordenadas if d["data"] <= args.hoje][-15:]
        for d in sorted(passadas, key=lambda x: x["data"], reverse=True):
            add("| %s | %d | %d | %s |" % (dbr(d["data"]), d["pagina"], d["linha"],
                                           celula(d["trecho"])))
        add("")
        add("> A data mais recente do TEXTO nao e o ultimo movimento. Pode ser data de "
            "emissao do PDF, de assinatura, de vencimento de titulo ou de nascimento de "
            "parte. O ultimo movimento se apura na secao 3, nao aqui.")
        add("")
        if args.cronologia:
            add("### 5.2 Todas as datas, na ordem em que aparecem no arquivo")
            add("")
            add("> **Isto NAO e a cronologia do processo.** E a ordem das paginas do PDF, "
                "que nao coincide com a ordem dos fatos, e a lista mistura ato processual "
                "com data de nascimento, vencimento de titulo, ata de assembleia e termo "
                "inicial de indice. Nao copie para a ficha: a cronologia se reconstroi a "
                "partir da secao 2 e da secao 3.")
            add("")
            add("| data | pag | linha | trecho |")
            add("|---|---:|---:|---|")
            for n, d in enumerate(sorted(datas, key=lambda x: x["linha"])):
                if n >= args.max_eventos:
                    add("| ... | ... | ... | *(+%d datas omitidas)* |" % (len(datas) - n))
                    break
                add("| %s | %d | %d | %s |" % (dbr(d["data"]), d["pagina"], d["linha"],
                                               celula(d["trecho"])))
        else:
            add("### 5.2 Demais datas — suprimidas")
            add("")
            add("Ha %d datas no arquivo. A lista completa sai fora de ordem cronologica "
                "(segue a ordem das paginas) e mistura ato processual com data de "
                "nascimento, vencimento e ata de assembleia - em autos grandes ela ocupa "
                "metade do mapa e nao se usa. Rode com `--cronologia` se quiser mesmo."
                % len(datas))
    add("")

    # --- 6. prazos ----------------------------------------------------------
    add("## 6. Prazos mencionados no texto")
    add("")
    if not prazos:
        add("- Nenhuma expressao de prazo localizada.")
    else:
        add("| pag | linha | expressao | trecho |")
        add("|---:|---:|---|---|")
        for n, p in enumerate(prazos):
            if n >= args.max_eventos:
                add("| ... | ... | ... | *(+%d omitidos)* |" % (len(prazos) - n))
                break
            add("| %d | %d | `%s` | %s |" % (p["pagina"], p["linha"], p["expressao"],
                                             celula(p["trecho"])))
    add("")
    add("> O script localiza a EXPRESSAO de prazo. Ele nao conta prazo e nao sabe o dies a "
        "quo. Dia util, suspensao, feriado local, prazo em dobro, intimacao pessoal e data "
        "de disponibilizacao no DJe dependem de conferencia humana no sistema do tribunal. "
        "O extrato de autos quase nunca traz a data da publicacao.")
    add("")

    # --- 7. alertas ---------------------------------------------------------
    add("## 7. Alertas")
    add("")
    if not alertas:
        add("- Nenhum alerta.")
    else:
        for sev in ("ALTA", "MEDIA"):
            do_nivel = [al for al in alertas if al["sev"] == sev]
            if not do_nivel:
                continue
            add("### %s - %d ocorrencia(s)" % (sev, len(do_nivel)))
            add("")
            grupos = OrderedDict()
            for al in do_nivel:
                grupos.setdefault(al["rotulo"], []).append(al)
            for rotulo, g in sorted(grupos.items(), key=lambda x: -len(x[1])):
                primeiras = g[:4]
                add("- **%s** (%dx) - em %s"
                    % (rotulo, len(g),
                       ", ".join("p.%d/l.%d" % (x["pagina"], x["linha"]) for x in primeiras)))
                add("    > %s" % primeiras[0]["trecho"])
            add("")
        add("> Alerta e pista, nao conclusao. \"Prescricao\" pode ser a tese da defesa e nao "
            "o reconhecimento dela; \"revelia\" pode estar na advertencia da notificacao e "
            "nao no decreto. Abra a linha antes de escrever qualquer coisa.")
    add("")

    # --- 8. valores e procuradores -----------------------------------------
    add("## 8. Valores e procuradores")
    add("")
    if valores:
        add("**Valores mais repetidos:** " + " &middot; ".join(
            "%s (%dx)" % (k, v) for k, v in valores.most_common(12)))
    else:
        add("**Valores:** nenhum localizado.")
    add("")
    if oabs:
        add("**OAB citadas:** " + " &middot; ".join(
            "%s (%dx)" % (k, v) for k, v in oabs.most_common(20)))
        add("")
        add("> Duas inscricoes proximas para o mesmo nome (ex.: 125.510 e 128.510) sao erro "
            "de digitacao, nao duas pessoas. Confira antes de reproduzir.")
    else:
        add("**OAB:** nenhuma localizada.")
    add("")

    # --- 9. proximo passo ---------------------------------------------------
    add("## 9. Proximo passo")
    add("")
    add("O mapa nao substitui a leitura. Abra por faixa de linha, nesta ordem:")
    add("")
    add("1. O indice oficial (secao 2) ou as fronteiras de peca (secao 3) - para escolher "
        "o que ler.")
    add("2. O ultimo ato de JUIZO (secao 3, assinante servidor ou magistrado) - integral. "
        "E ele que fixa a fase e o prazo.")
    add("3. A peca que abriu o feito (inicial, denuncia, CDA, termo de ajuizamento) - integral.")
    add("4. A defesa (contestacao, embargos, resposta a acusacao) - integral, se existir.")
    add("5. Toda linha listada nos alertas ALTA.")
    add("6. As paginas que o mapa NAO cobriu: pagina sem texto e documento digitalizado sem "
        "OCR, e costuma ser a prova.")
    add("")
    add("```")
    add("sed -n '<inicio>,<fim>p' \"%s\"" % src)
    add("```")

    return "\n".join(out) + "\n"


def comprimir(nums):
    """[16,17,18,22] -> ['16-18', '22']"""
    faixas = []
    ini = ant = nums[0]
    for k in nums[1:]:
        if k != ant + 1:
            faixas.append(str(ini) if ini == ant else "%d-%d" % (ini, ant))
            ini = k
        ant = k
    faixas.append(str(ini) if ini == ant else "%d-%d" % (ini, ant))
    return faixas


def serie_de_folhas(marcas):
    """Uma folha por pagina do PDF, seguindo a folha esperada.

    Cada pagina traz o carimbo uma vez, mas o corpo do texto cita folha alheia
    ("conforme fls. 1264") e o maximo da pagina mentiria. Escolhe-se, entre os
    candidatos da pagina, o que melhor continua a folha anterior.
    """
    por_pagina = OrderedDict()
    for pag, lin, val in marcas:
        por_pagina.setdefault(pag, []).append((val, lin))

    serie, esperado = [], None
    for pag in sorted(por_pagina):
        cands = por_pagina[pag]
        if esperado is None:
            val, lin = min(cands)
        else:
            val, lin = min(cands, key=lambda x: (abs(x[0] - esperado), x[0]))
        serie.append((pag, lin, val))
        esperado = val + 1
    return serie


def secao_foliacao(folhas_stj, folhas_gen, total_paginas):
    """Secao 0.2: a foliacao e continua, ou reinicia dentro do arquivo?

    Num extrato real a folha ia ate 830 e voltava para 1 na pagina 813 do PDF:
    comecava um apenso. Nada no mapa nem na ordem de leitura previa isso, e a
    citacao por folha passava a ser ambigua sem que ninguem soubesse.

    So se AFIRMA reinicio quando as marcas se comportam como carimbo, isto e,
    quando cobrem a maioria das paginas. No PJe nao ha carimbo de folha, e o que
    o regex apanha sao referencias do corpo do texto ("conforme fls. 44"): num
    processo do TRF1 elas produziam 18 reinicios inexistentes, ou seja, dezoito
    apensos que nao existem - achado pior do que achado nenhum.
    """
    out = ["## 0.2 A foliacao e continua?", ""]

    # o carimbo do e-STJ e uma marca por folha; as demais aparecem tambem no corpo
    usa_stj = len(folhas_stj) >= 5
    marcas = folhas_stj if usa_stj else folhas_gen
    canonica = ("carimbo `(e-STJ Fl.N)`" if usa_stj
                else "marcas `fl.`/`fls.` do texto")

    if len(marcas) < 5:
        out += ["- Menos de 5 marcas de folha no arquivo: **este arquivo nao tem "
                "foliacao carimbada**. Cite por ID, evento ou numero de documento - "
                "nunca por folha.", ""]
        return out

    serie = serie_de_folhas(marcas)
    vals = [v for _, _, v in serie]
    cobertura = (len(serie) / float(total_paginas)) if total_paginas else 0.0

    if not usa_stj and cobertura < 0.5:
        out += ["- **%d marcas de folha** (%s) em apenas %d das %d paginas — "
                "**cobertura de %d%%.**"
                % (len(marcas), canonica, len(serie), total_paginas,
                   round(100 * cobertura)),
                "",
                "> Cobertura baixa significa que **nao ha carimbo de folha neste "
                "arquivo**: o que o mapa apanhou sao referencias do corpo do texto "
                "(`conforme fls. 44`), que apontam para folha de OUTRA autuacao ou "
                "de peca anexa. **Nao da para afirmar nem negar reinicio de "
                "foliacao aqui**, e citar por folha e inseguro — cite por ID ou "
                "evento (secao 2). E o caso normal do PJe e do eproc.", ""]
        return out

    reinicios, saltos = [], []
    for k in range(1, len(serie)):
        pag, lin, v = serie[k]
        pag_ant, _, v_ant = serie[k - 1]
        if v < v_ant:
            reinicios.append((pag, lin, v_ant, v))
        elif pag == pag_ant + 1 and v > v_ant + 1:
            saltos.append((pag, lin, v_ant, v))

    out.append("- **%d marcas de folha** (%s), em %d das %d paginas do PDF, da folha "
               "**%d** a **%d**." % (len(marcas), canonica, len(serie),
                                     total_paginas, min(vals), max(vals)))

    if len(reinicios) > max(3, 0.05 * len(serie)):
        out += ["- **%d descidas de numeracao em %d paginas** — proporcao alta demais "
                "para serem apensos. As marcas apanhadas estao poluidas por referencia "
                "de corpo de texto; **o mapa nao afirma nada sobre a foliacao deste "
                "arquivo.** Cite por ID ou evento." % (len(reinicios), len(serie)), ""]
        return out

    if not reinicios:
        out += ["- A foliacao **nao reinicia**: um unico bloco de numeracao no arquivo "
                "inteiro.", ""]
    else:
        out.append("- **A foliacao REINICIA %d vez(es)** dentro do mesmo arquivo:"
                   % len(reinicios))
        out += ["", "| na pagina do PDF | linha | folha anterior | volta para |",
                "|---:|---:|---:|---:|"]
        for pag, lin, ant, novo in reinicios[:20]:
            out.append("| %d | %d | %d | **%d** |" % (pag, lin, ant, novo))
        if len(reinicios) > 20:
            out.append("| ... | | | *(+%d omitidos)* |" % (len(reinicios) - 20))
        out += ["",
                "> **Reinicio de foliacao significa peca apensada** - o arquivo contem "
                "mais de uma autuacao. A consequencia e imediata: a partir daqui **o mesmo "
                "numero de folha existe duas vezes no mesmo PDF**, e toda citacao de folha "
                "tem de dizer DE QUAL AUTUACAO (`fl. 12 do apenso`, nunca `fl. 12`). "
                "Confira tambem quantos apensos a capa declara contra quantos este arquivo "
                "efetivamente traz - e o campo `COBERTURA DO ARQUIVO` da ficha.", ""]

    if saltos:
        out.append("- **%d salto(s) de foliacao** entre paginas consecutivas do PDF "
                   "(folhas faltando, ou juntada fora de ordem):" % len(saltos))
        out.append("")
        for pag, lin, ant, novo in saltos[:10]:
            out.append("    - p. %d (linha %d): de %d para %d - faltam %d folha(s)."
                       % (pag, lin, ant, novo, novo - ant - 1))
        if len(saltos) > 10:
            out.append("    - *(+%d omitidos)*" % (len(saltos) - 10))
        out += ["",
                "> Salto pode ser folha ausente do extrato, pagina sem camada de texto "
                "(secao 0.1) ou simples verso nao numerado. Cruze com a secao 0.1 antes de "
                "afirmar que falta peca.", ""]
    return out


# ----------------------------------------------------------------------------


def main():
    forcar_utf8()
    ap = argparse.ArgumentParser(
        description="Mapeia autos processuais a partir do .md convertido (ou do PDF).")
    ap.add_argument("path", nargs="+", help="arquivos .md, .txt, .docx ou .pdf")
    ap.add_argument("--out", help="grava o mapa em arquivo (recomendado)")
    ap.add_argument("--hoje", default=None, metavar="AAAA-MM-DD",
                    help="data de referencia para o alerta de extrato vencido")
    ap.add_argument("--contexto", type=int, default=160,
                    help="caracteres de trecho por achado (padrao 160)")
    ap.add_argument("--max-eventos", type=int, default=300, dest="max_eventos",
                    help="teto de linhas por tabela (padrao 300)")
    ap.add_argument("--cru", action="store_true",
                    help="nao descartar linhas de carimbo repetido")
    ap.add_argument("--cronologia", action="store_true",
                    help="listar todas as datas na secao 5.2")
    args = ap.parse_args()

    if args.hoje:
        args.hoje = datetime.datetime.strptime(args.hoje, "%Y-%m-%d").date()
    else:
        args.hoje = datetime.date.today()

    tudo = []
    for p in args.path:
        if not os.path.exists(p):
            sys.stderr.write("Arquivo nao encontrado: %s\n" % p)
            continue
        sys.stderr.write("Mapeando %s\n" % os.path.basename(p))
        tudo.append(mapear(p, args))
        tudo.append("\n---\n")

    texto = "\n".join(tudo)
    if args.out:
        d = os.path.dirname(os.path.abspath(args.out))
        if d and not os.path.isdir(d):
            os.makedirs(d, exist_ok=True)
        with io.open(args.out, "w", encoding="utf-8") as fh:
            fh.write(texto)
        sys.stderr.write("Mapa gravado em %s\n" % args.out)
    else:
        sys.stdout.write(texto)
    return 0


if __name__ == "__main__":
    sys.exit(main())
