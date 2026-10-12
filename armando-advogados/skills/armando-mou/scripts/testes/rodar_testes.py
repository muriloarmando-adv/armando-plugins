#!/usr/bin/env python3
"""Regressão da skill armando-mou. Rode depois de mexer em qualquer script:

    python3 scripts/testes/rodar_testes.py

1. exemplo-familia.mou.md tem de montar sem erro e conferir com 0 ERRO e
   0 ALERTA em --final;
2. defeitos-do-acervo.md tem de disparar cada um dos achados esperados;
3. o esqueleto com TODOS os módulos colados tem de montar sem erro (prova
   que nenhuma remissão entre módulos está quebrada).
"""

import io
import os
import subprocess
import sys
import tempfile

AQUI = os.path.dirname(os.path.abspath(__file__))
SCRIPTS = os.path.dirname(AQUI)
SKILL = os.path.dirname(SCRIPTS)
PY = sys.executable

ESPERADOS = [
    "JOÃO BRASILEIRO DE TESTE (parte) é qualificado mas não tem linha de assinatura",
    "EMPRESA TESTE LTDA (parte) é qualificado mas não tem linha de assinatura",
    "(interveniente anuente) é qualificado mas não tem linha de assinatura",
    "CPF 360.848.529-56 com dígito verificador inválido",
    "aparece com CNPJ diferentes",
    "considerando (iv) onde se esperava (iii)",
    "remissão a \"Seção 9\", que não existe",
    "deveria ser \"quinhentos e vinte mil reais\"",
    "número solto \"16.\"",
    "30 por extenso deveria ser \"trinta\"",
    "numeração pula de 3.2 para 3.4",
    "remissão à cláusula 3.3, que não existe",
    "TOTAL da tabela é R$ 3.000.000,00 mas as linhas somam R$ 2.000.000,00",
    "1/3 por extenso deveria ser \"um terço\"",
    "cláusula 4.2 repetida",
    "numeração pula de 5.1 para 5.3",
    "fecho sem local e data",
    "cita anexo que não acompanha",
    "casado(a) sem regime de bens",
    "pessoa jurídica sem quem a representa",
    "palavra repetida: \"atribuições atribuições\"",
    "palavra repetida: \"na na\"",
    "\"R-n-M-n\" é o número do registro",
    "campo em aberto: \"?\"",
    "campo em aberto: ____",
    "\"divócio\" → divórcio",
    "\"nu-propriedade\" → nua-propriedade",
    "\"revestidos e reembolsados\" → revertidos",
    "\"das empresa operacional\"",
    "\"INTERESSADOS\"",
    "reversão/destino aos filhos do donatário",
    "art. 1.831 do CC é o direito real de habitação",
    "\"incapacidade absoluta\"",
    "a cláusula 5.1 remete a si mesma",
    "renúncia genérica",
    "\"Contrato\" num Memorando",
    "fala em testemunhas, mas não há bloco",
    "nome grafado \"JOÃO BRAISLEIRO DE TESTE\"",
    "mas MARIA DE TESTE está qualificado(a) como solteiro(a)",
    "art. 462 do CC",
    "as parcelas antes de \"totalizando\" somam R$ 520.000,00",
    "incomunicabilidade afasta a meação, não a herança",
    "dispensa de colação",
    "justa causa declarada",
]


def rodar(*args):
    r = subprocess.run([PY] + list(args), capture_output=True, text=True, encoding="utf-8",
                       env=dict(os.environ, PYTHONIOENCODING="utf-8"))
    return r.returncode, r.stdout + r.stderr


def main():
    sys.path.insert(0, SCRIPTS)
    from lib_mou import forcar_utf8
    forcar_utf8()
    falhas = []
    tmp = tempfile.mkdtemp(prefix="mou-teste-")

    # 1. teste positivo
    saida = os.path.join(tmp, "exemplo.md")
    cod, out = rodar(os.path.join(SCRIPTS, "montar_mou.py"),
                     os.path.join(AQUI, "exemplo-familia.mou.md"), "--saida", saida)
    if cod:
        falhas.append("exemplo não montou:\n" + out)
    else:
        cod, out = rodar(os.path.join(SCRIPTS, "conferir_mou.py"), saida, "--final")
        if cod or "0 ERRO · 0 ALERTA" not in out:
            falhas.append("exemplo não passou limpo na conferência:\n" + out)

    # 2. defeitos do acervo
    cod, out = rodar(os.path.join(SCRIPTS, "conferir_mou.py"),
                     os.path.join(AQUI, "defeitos-do-acervo.md"))
    if cod != 1:
        falhas.append("defeitos-do-acervo.md devia sair com código 1")
    for e in ESPERADOS:
        if e not in out:
            falhas.append(f"não acusou: {e}")

    # 3. esqueleto + todos os módulos
    with io.open(os.path.join(SKILL, "assets", "esqueleto.mou.md"), encoding="utf-8") as f:
        esq = f.read()
    with io.open(os.path.join(SKILL, "assets", "modulos.mou.md"), encoding="utf-8") as f:
        mod = f.read()
    marca = "%% >>> MÓDULOS DO CASO AQUI <<<"
    if marca not in esq:
        falhas.append("o esqueleto perdeu a marca dos módulos")
    tudo = os.path.join(tmp, "tudo.mou.md")
    with io.open(tudo, "w", encoding="utf-8") as f:
        f.write(esq.replace(marca, marca + "\n" + mod))
    cod, out = rodar(os.path.join(SCRIPTS, "montar_mou.py"), tudo,
                     "--saida", os.path.join(tmp, "tudo.md"))
    if cod:
        falhas.append("esqueleto + módulos não montou:\n" + out)

    if falhas:
        print("FALHOU")
        for f_ in falhas:
            print(" -", f_)
        return 1
    print(f"OK — exemplo limpo, {len(ESPERADOS)} defeitos acusados, módulos montam juntos")
    return 0


if __name__ == "__main__":
    sys.exit(main())
