#Requires -Version 5.1
<#
.SYNOPSIS
    Converte PDF em Markdown enxuto, para gastar menos tokens na analise.

.DESCRIPTION
    Extrai o texto do PDF reconstruindo a posicao de cada trecho na pagina,
    remonta linhas e paragrafos, detecta titulos, listas e numeracao juridica,
    e remove cabecalhos/rodapes repetidos (timbrado, hash de assinatura,
    "Pagina X de Y"), que sao puro desperdicio de token.

.EXAMPLE
    .\pdf2md.ps1 contrato.pdf
    .\pdf2md.ps1 C:\Users\muril\Downloads\processos -Out C:\md
    .\pdf2md.ps1            # abre o seletor de arquivos
#>
[CmdletBinding()]
param(
    [Parameter(Position = 0, ValueFromRemainingArguments = $true)]
    [string[]]$Path,

    # Arquivo .md de saida (1 PDF) ou pasta de saida (varios). Padrao: ao lado do PDF.
    [string]$Out,

    # Nao remover cabecalhos/rodapes repetidos.
    [switch]$ManterRepetidos,

    # Nao inserir as marcas [p. N].
    [switch]$SemMarcasDePagina,

    # Abrir o .md gerado ao terminar.
    [switch]$Abrir,

    # Pausar no fim (usado pelo atalho de arrastar-e-soltar).
    [switch]$Pausar,

    # Diagnostico: gera tambem um .tsv com pagina/posicao/tamanho de cada linha crua.
    [switch]$Linhas
)

$ErrorActionPreference = 'Stop'

# ------------------------------------------------------------------ motor C#

$engine = @'
using System;
using System.Collections.Generic;
using System.Globalization;
using System.IO;
using System.IO.Compression;
using System.Linq;
using System.Text;
using System.Text.RegularExpressions;

public class PdfObj { public int Num; public string Dict = ""; public byte[] Data; }

public class PdfLine {
    public int Page;
    public double Y, X0, X1, Size, PageH, PageW;
    public bool Bold;
    public string Text = "";
}

public class PdfDoc {
    public List<PdfLine> Lines = new List<PdfLine>();
    public int PageCount;
    public bool Encrypted;
    public int RawChars;
    public int Unknown;
}

class PdfFont {
    public Dictionary<int, string> CMap;
    public Dictionary<int, double> W;     // largura por codigo, em 1/1000 em
    public double DW = 0;                 // largura padrao (fontes CID)
    public double SpaceEm = 0.25;
    public bool TwoByte;
    public bool Bold;
    public string Base = "";
}

class Run {
    public double X, Y, Size, EndX, SpaceW;
    public bool Bold;
    public string Text;
}

class Tok {
    public int K;          // 0 num, 1 string, 2 name, 3 op, 4 '[', 5 ']'
    public string S;
    public double N;
}

public static class PdfMd
{
    static Encoding Latin = Encoding.GetEncoding(28591);

    // ---------------------------------------------------------- baixo nivel

    static byte[] Inflate(byte[] data, int off, int len)
    {
        if (len <= 0) return null;
        foreach (int skip in new int[] { 2, 0, 1 })
        {
            if (len - skip <= 0) continue;
            try
            {
                using (var ms = new MemoryStream(data, off + skip, len - skip))
                using (var ds = new DeflateStream(ms, CompressionMode.Decompress))
                using (var o = new MemoryStream())
                {
                    ds.CopyTo(o);
                    var r = o.ToArray();
                    if (r.Length > 0) return r;
                }
            }
            catch (Exception) { }
        }
        return null;
    }

    static int LastRoot = -1;

    static Dictionary<int, PdfObj> Parse(string path, out bool encrypted)
    {
        byte[] bytes = File.ReadAllBytes(path);
        string all = Latin.GetString(bytes);
        encrypted = Regex.IsMatch(all, @"/Encrypt\s+\d+\s+\d+\s+R");

        // /Root do trailer mais recente (arquivos com atualizacao incremental
        // tem varios catalogos; o ultimo e o que vale)
        LastRoot = -1;
        foreach (Match rm in Regex.Matches(all, @"/Root\s+(\d+)\s+\d+\s+R"))
            LastRoot = int.Parse(rm.Groups[1].Value);

        var objs = new Dictionary<int, PdfObj>();
        var rx = new Regex(@"(?<![0-9])(?<n>\d+)\s+(?<g>\d+)\s+obj\b");
        foreach (Match m in rx.Matches(all))
        {
            int num = int.Parse(m.Groups["n"].Value);
            int start = m.Index + m.Length;
            int end = all.IndexOf("endobj", start, StringComparison.Ordinal);
            if (end < 0) end = all.Length;

            var o = new PdfObj { Num = num };
            int sIdx = all.IndexOf("stream", start, StringComparison.Ordinal);
            if (sIdx >= 0 && sIdx < end)
            {
                o.Dict = all.Substring(start, sIdx - start);
                int d = sIdx + 6;
                if (d < all.Length && all[d] == '\r') d++;
                if (d < all.Length && all[d] == '\n') d++;
                int e = all.IndexOf("endstream", d, StringComparison.Ordinal);
                if (e > d)
                {
                    byte[] dec = null;
                    if (o.Dict.Contains("FlateDecode")) dec = Inflate(bytes, d, e - d);
                    if (dec == null && !o.Dict.Contains("Decode"))
                    {
                        dec = new byte[e - d];
                        Array.Copy(bytes, d, dec, 0, e - d);
                    }
                    o.Data = dec;
                }
            }
            else
            {
                o.Dict = all.Substring(start, end - start);
            }
            objs[num] = o;
        }

        // objetos comprimidos dentro de /ObjStm (PDF 1.5+)
        foreach (var kv in objs.ToList())
        {
            var od = kv.Value;
            if (od.Data == null || od.Dict.IndexOf("/ObjStm", StringComparison.Ordinal) < 0) continue;
            string first = GetVal(od.Dict, "First");
            string nStr = GetVal(od.Dict, "N");
            int firstOff, count;
            if (!int.TryParse(first, out firstOff) || !int.TryParse(nStr, out count)) continue;

            string body = Latin.GetString(od.Data);
            if (firstOff > body.Length) continue;
            string head = body.Substring(0, firstOff);
            var nums = new List<int[]>();
            var mm = Regex.Matches(head, @"(\d+)\s+(\d+)");
            for (int i = 0; i < mm.Count && i < count; i++)
                nums.Add(new int[] { int.Parse(mm[i].Groups[1].Value), int.Parse(mm[i].Groups[2].Value) });

            for (int i = 0; i < nums.Count; i++)
            {
                int st = firstOff + nums[i][1];
                int en = (i + 1 < nums.Count) ? firstOff + nums[i + 1][1] : body.Length;
                if (st < 0 || st >= body.Length) continue;
                if (en > body.Length) en = body.Length;
                if (en <= st) continue;
                if (!objs.ContainsKey(nums[i][0]))
                    objs[nums[i][0]] = new PdfObj { Num = nums[i][0], Dict = body.Substring(st, en - st) };
            }
        }
        return objs;
    }

    // valor bruto de uma chave do dicionario, respeitando << >> e [ ] aninhados
    static string GetVal(string dict, string key)
    {
        if (dict == null) return null;
        int i = 0;
        string k = "/" + key;
        while (true)
        {
            i = dict.IndexOf(k, i, StringComparison.Ordinal);
            if (i < 0) return null;
            int after = i + k.Length;
            if (after < dict.Length && (char.IsLetterOrDigit(dict[after]) || dict[after] == '#' || dict[after] == '-'))
            { i = after; continue; }

            int j = after;
            while (j < dict.Length && (char.IsWhiteSpace(dict[j]))) j++;
            if (j >= dict.Length) return null;

            if (dict[j] == '<' && j + 1 < dict.Length && dict[j + 1] == '<')
            {
                int depth = 0, p = j;
                while (p < dict.Length - 1)
                {
                    if (dict[p] == '<' && dict[p + 1] == '<') { depth++; p += 2; }
                    else if (dict[p] == '>' && dict[p + 1] == '>') { depth--; p += 2; if (depth == 0) break; }
                    else p++;
                }
                if (p > dict.Length) p = dict.Length;
                return dict.Substring(j, p - j);
            }
            if (dict[j] == '[')
            {
                int depth = 0, p = j;
                while (p < dict.Length)
                {
                    if (dict[p] == '[') depth++;
                    else if (dict[p] == ']') { depth--; if (depth == 0) { p++; break; } }
                    p++;
                }
                if (p > dict.Length) p = dict.Length;
                return dict.Substring(j, p - j);
            }
            var m = Regex.Match(dict.Substring(j), @"^(\d+\s+\d+\s+R|/[^\s/<>\[\]()]*|[-+.\d]+|true|false|null)");
            if (m.Success) return m.Value;
            return null;
        }
    }

    static string Deref(string val, Dictionary<int, PdfObj> objs)
    {
        if (val == null) return null;
        var m = Regex.Match(val.Trim(), @"^(\d+)\s+\d+\s+R$");
        if (!m.Success) return val;
        int n = int.Parse(m.Groups[1].Value);
        return objs.ContainsKey(n) ? objs[n].Dict : null;
    }

    // ------------------------------------------------------------- ToUnicode

    static string HexToStr(string hex)
    {
        hex = Regex.Replace(hex, @"\s", "");
        var sb = new StringBuilder();
        int i = 0;
        for (; i + 4 <= hex.Length; i += 4)
            sb.Append((char)Convert.ToInt32(hex.Substring(i, 4), 16));
        if (hex.Length - i == 2)
            sb.Append((char)Convert.ToInt32(hex.Substring(i, 2), 16));
        return sb.ToString();
    }

    static Dictionary<int, string> ParseCMap(string cm)
    {
        var map = new Dictionary<int, string>();
        foreach (Match blk in Regex.Matches(cm, @"beginbfchar(.*?)endbfchar", RegexOptions.Singleline))
            foreach (Match p in Regex.Matches(blk.Groups[1].Value, @"<([0-9A-Fa-f]+)>\s*<([0-9A-Fa-f]+)>"))
                map[Convert.ToInt32(p.Groups[1].Value, 16)] = HexToStr(p.Groups[2].Value);

        foreach (Match blk in Regex.Matches(cm, @"beginbfrange(.*?)endbfrange", RegexOptions.Singleline))
        {
            string b = blk.Groups[1].Value;
            foreach (Match p in Regex.Matches(b, @"<([0-9A-Fa-f]+)>\s*<([0-9A-Fa-f]+)>\s*<([0-9A-Fa-f]+)>"))
            {
                int lo = Convert.ToInt32(p.Groups[1].Value, 16);
                int hi = Convert.ToInt32(p.Groups[2].Value, 16);
                string dst = HexToStr(p.Groups[3].Value);
                if (dst.Length == 0) continue;
                for (int c = lo; c <= hi && c - lo < 65536; c++)
                {
                    var chars = dst.ToCharArray();
                    chars[chars.Length - 1] = (char)(chars[chars.Length - 1] + (c - lo));
                    map[c] = new string(chars);
                }
            }
            foreach (Match p in Regex.Matches(b, @"<([0-9A-Fa-f]+)>\s*<([0-9A-Fa-f]+)>\s*\[(.*?)\]", RegexOptions.Singleline))
            {
                int lo = Convert.ToInt32(p.Groups[1].Value, 16);
                int i = 0;
                foreach (Match d in Regex.Matches(p.Groups[3].Value, @"<([0-9A-Fa-f]+)>"))
                { map[lo + i] = HexToStr(d.Groups[1].Value); i++; }
            }
        }
        return map;
    }

    static PdfFont BuildFont(string fdict, Dictionary<int, PdfObj> objs)
    {
        var f = new PdfFont();
        if (fdict == null) return f;

        string sub = GetVal(fdict, "Subtype");
        string enc = GetVal(fdict, "Encoding");
        string bf = GetVal(fdict, "BaseFont");
        if (bf != null) f.Base = bf;
        f.Bold = f.Base.IndexOf("bold", StringComparison.OrdinalIgnoreCase) >= 0 || f.Base.Contains(",B");
        f.TwoByte = (sub != null && sub.Contains("Type0")) || (enc != null && enc.Contains("Identity"));

        // larguras dos glifos: sem elas nao da para saber onde termina cada trecho
        f.W = new Dictionary<int, double>();
        if (f.TwoByte)
        {
            string desc = Deref(GetVal(fdict, "DescendantFonts"), objs);
            if (desc != null)
            {
                var dm = Regex.Match(desc, @"(\d+)\s+\d+\s+R");
                if (dm.Success && objs.ContainsKey(int.Parse(dm.Groups[1].Value)))
                    desc = objs[int.Parse(dm.Groups[1].Value)].Dict;
                string dw = GetVal(desc, "DW");
                double dwv;
                if (dw != null && double.TryParse(dw, NumberStyles.Any, CultureInfo.InvariantCulture, out dwv)) f.DW = dwv;
                ParseW(Deref(GetVal(desc, "W"), objs), f.W);
            }
            if (f.DW <= 0) f.DW = 1000;
            f.SpaceEm = 0.25;
        }
        else
        {
            string fc = GetVal(fdict, "FirstChar");
            string wid = Deref(GetVal(fdict, "Widths"), objs);
            int first;
            if (fc != null && wid != null && int.TryParse(fc, out first))
            {
                int i = 0;
                foreach (Match wm in Regex.Matches(wid, @"-?[\d.]+"))
                {
                    double v;
                    if (double.TryParse(wm.Value, NumberStyles.Any, CultureInfo.InvariantCulture, out v))
                        f.W[first + i] = v;
                    i++;
                }
            }
            double sw;
            f.SpaceEm = f.W.TryGetValue(32, out sw) && sw > 0 ? sw / 1000.0 : 0.25;
        }

        string tu = GetVal(fdict, "ToUnicode");
        if (tu != null)
        {
            var m = Regex.Match(tu.Trim(), @"^(\d+)\s+\d+\s+R$");
            if (m.Success)
            {
                int n = int.Parse(m.Groups[1].Value);
                if (objs.ContainsKey(n) && objs[n].Data != null)
                {
                    f.CMap = ParseCMap(Latin.GetString(objs[n].Data));
                    if (f.CMap.Count > 0 && f.CMap.Keys.Max() > 255) f.TwoByte = true;
                }
            }
        }
        return f;
    }

    // /W de fonte CID: "c [w1 w2 ...]" ou "c1 c2 w"
    static void ParseW(string arr, Dictionary<int, double> w)
    {
        if (arr == null) return;
        var toks = new List<string>();
        foreach (Match m in Regex.Matches(arr, @"\[[^\]]*\]|-?[\d.]+")) toks.Add(m.Value);
        int i = 0;
        while (i < toks.Count)
        {
            int c;
            if (!int.TryParse(toks[i], out c)) { i++; continue; }
            if (i + 1 < toks.Count && toks[i + 1].StartsWith("["))
            {
                int k = 0;
                foreach (Match m in Regex.Matches(toks[i + 1], @"-?[\d.]+"))
                {
                    double v;
                    if (double.TryParse(m.Value, NumberStyles.Any, CultureInfo.InvariantCulture, out v))
                        w[c + k] = v;
                    k++;
                }
                i += 2;
            }
            else if (i + 2 < toks.Count)
            {
                int c2; double v;
                if (int.TryParse(toks[i + 1], out c2) &&
                    double.TryParse(toks[i + 2], NumberStyles.Any, CultureInfo.InvariantCulture, out v))
                {
                    if (c2 - c > 65535) c2 = c + 65535;
                    for (int k = c; k <= c2; k++) w[k] = v;
                }
                i += 3;
            }
            else i++;
        }
    }

    // sem /Widths (fontes padrao): estimativa por classe de caractere
    static double FallbackW(int code)
    {
        char c = (char)code;
        if (c == ' ') return 260;
        if ("iljIf.,;:'`|!()[]{}".IndexOf(c) >= 0) return 290;
        if ("rt/\\-".IndexOf(c) >= 0) return 350;
        if ("mwMW@".IndexOf(c) >= 0) return 850;
        if (char.IsDigit(c)) return 500;
        if (char.IsUpper(c)) return 680;
        return 510;
    }

    static double GlyphW(int code, PdfFont f)
    {
        double w;
        if (f != null && f.W != null && f.W.TryGetValue(code, out w) && w > 0) return w;
        if (f != null && f.TwoByte) return f.DW > 0 ? f.DW : 1000;
        return FallbackW(code);
    }

    static double Advance(string raw, PdfFont f, double fs, double charSp, double wordSp)
    {
        double sum = 0; int n = 0, spaces = 0;
        if (f != null && f.TwoByte)
        {
            for (int i = 0; i + 2 <= raw.Length; i += 2)
            { sum += GlyphW((raw[i] << 8) | raw[i + 1], f); n++; }
        }
        else
        {
            for (int i = 0; i < raw.Length; i++)
            {
                int c = raw[i] & 0xFF;
                sum += GlyphW(c, f); n++;
                if (c == 32) spaces++;
            }
        }
        return sum / 1000.0 * fs + charSp * n + wordSp * spaces;
    }

    static string WinAnsiHigh = "\u20AC\u0081\u201A\u0192\u201E\u2026\u2020\u2021\u02C6\u2030\u0160\u2039\u0152\u008D\u017D\u008F"
                              + "\u0090\u2018\u2019\u201C\u201D\u2022\u2013\u2014\u02DC\u2122\u0161\u203A\u0153\u009D\u017E\u0178";

    static string Decode(string raw, PdfFont f, PdfDoc doc)
    {
        var sb = new StringBuilder();
        if (f != null && f.TwoByte)
        {
            for (int i = 0; i + 2 <= raw.Length; i += 2)
            {
                int c = (raw[i] << 8) | raw[i + 1];
                string v;
                if (f.CMap != null && f.CMap.TryGetValue(c, out v)) sb.Append(v);
                else { sb.Append('\uFFFD'); doc.Unknown++; }
            }
            return sb.ToString();
        }
        for (int i = 0; i < raw.Length; i++)
        {
            int c = raw[i] & 0xFF;
            string v;
            if (f != null && f.CMap != null && f.CMap.TryGetValue(c, out v)) sb.Append(v);
            else if (c >= 0x80 && c <= 0x9F) sb.Append(WinAnsiHigh[c - 0x80]);
            else sb.Append((char)c);
        }
        return sb.ToString();
    }

    // ----------------------------------------------------------- content lexer

    static List<Tok> Lex(string s)
    {
        var t = new List<Tok>();
        int i = 0, n = s.Length;
        while (i < n)
        {
            char c = s[i];
            if (c == '\0' || char.IsWhiteSpace(c)) { i++; continue; }
            if (c == '%') { while (i < n && s[i] != '\n' && s[i] != '\r') i++; continue; }

            if (c == '/')
            {
                int j = i + 1;
                while (j < n && !char.IsWhiteSpace(s[j]) && "/<>[]()%".IndexOf(s[j]) < 0) j++;
                t.Add(new Tok { K = 2, S = s.Substring(i + 1, j - i - 1) });
                i = j; continue;
            }
            if (c == '(')
            {
                var sb = new StringBuilder();
                int depth = 1; int j = i + 1;
                while (j < n && depth > 0)
                {
                    char d = s[j];
                    if (d == '\\')
                    {
                        j++;
                        if (j >= n) break;
                        char e = s[j];
                        if (e >= '0' && e <= '7')
                        {
                            int v = 0, k = 0;
                            while (k < 3 && j < n && s[j] >= '0' && s[j] <= '7') { v = v * 8 + (s[j] - '0'); j++; k++; }
                            sb.Append((char)(v & 0xFF));
                            continue;
                        }
                        if (e == 'n') sb.Append('\n');
                        else if (e == 'r') sb.Append('\r');
                        else if (e == 't') sb.Append('\t');
                        else if (e == 'b') sb.Append('\b');
                        else if (e == 'f') sb.Append('\f');
                        else if (e == '\n') { }
                        else if (e == '\r') { if (j + 1 < n && s[j + 1] == '\n') j++; }
                        else sb.Append(e);
                        j++; continue;
                    }
                    if (d == '(') { depth++; sb.Append(d); j++; continue; }
                    if (d == ')') { depth--; if (depth > 0) sb.Append(d); j++; continue; }
                    sb.Append(d); j++;
                }
                t.Add(new Tok { K = 1, S = sb.ToString() });
                i = j; continue;
            }
            if (c == '<')
            {
                if (i + 1 < n && s[i + 1] == '<')   // dicionario inline: pular
                {
                    int depth = 0, p = i;
                    while (p < n - 1)
                    {
                        if (s[p] == '<' && s[p + 1] == '<') { depth++; p += 2; }
                        else if (s[p] == '>' && s[p + 1] == '>') { depth--; p += 2; if (depth == 0) break; }
                        else p++;
                    }
                    i = p; continue;
                }
                int e2 = s.IndexOf('>', i + 1);
                if (e2 < 0) e2 = n - 1;
                string hex = Regex.Replace(s.Substring(i + 1, e2 - i - 1), @"[^0-9A-Fa-f]", "");
                if (hex.Length % 2 == 1) hex += "0";
                var sb2 = new StringBuilder();
                for (int k = 0; k + 2 <= hex.Length; k += 2)
                    sb2.Append((char)Convert.ToInt32(hex.Substring(k, 2), 16));
                t.Add(new Tok { K = 1, S = sb2.ToString() });
                i = e2 + 1; continue;
            }
            if (c == '[') { t.Add(new Tok { K = 4 }); i++; continue; }
            if (c == ']') { t.Add(new Tok { K = 5 }); i++; continue; }
            if (c == '{' || c == '}' || c == ')' || c == '>') { i++; continue; }

            if (c == '+' || c == '-' || c == '.' || (c >= '0' && c <= '9'))
            {
                int j = i;
                while (j < n && ("+-.0123456789eE".IndexOf(s[j]) >= 0)) j++;
                double v;
                double.TryParse(s.Substring(i, j - i), NumberStyles.Any, CultureInfo.InvariantCulture, out v);
                t.Add(new Tok { K = 0, N = v });
                i = j; continue;
            }
            {
                int j = i;
                while (j < n && !char.IsWhiteSpace(s[j]) && "/<>[]()%".IndexOf(s[j]) < 0) j++;
                if (j == i) j++;
                t.Add(new Tok { K = 3, S = s.Substring(i, j - i) });
                i = j;
            }
        }
        return t;
    }

    static double[] Mul(double[] m, double[] n)
    {
        return new double[] {
            m[0]*n[0] + m[1]*n[2],
            m[0]*n[1] + m[1]*n[3],
            m[2]*n[0] + m[3]*n[2],
            m[2]*n[1] + m[3]*n[3],
            m[4]*n[0] + m[5]*n[2] + n[4],
            m[4]*n[1] + m[5]*n[3] + n[5] };
    }
    static double[] Id() { return new double[] { 1, 0, 0, 1, 0, 0 }; }
    static double Scale(double[] m)
    {
        double det = Math.Abs(m[0] * m[3] - m[1] * m[2]);
        return det > 0 ? Math.Sqrt(det) : 1;
    }

    // ------------------------------------------------------------- pagina

    static Dictionary<string, PdfFont> FontMap(string resText, Dictionary<int, PdfObj> objs,
                                               Dictionary<int, PdfFont> cache)
    {
        var fonts = new Dictionary<string, PdfFont>();
        string fdict = Deref(GetVal(resText, "Font"), objs);
        if (fdict == null) return fonts;
        foreach (Match p in Regex.Matches(fdict, @"/([^\s/<>\[\]()]+)\s+(\d+)\s+\d+\s+R"))
        {
            int fn = int.Parse(p.Groups[2].Value);
            if (!cache.ContainsKey(fn))
                cache[fn] = BuildFont(objs.ContainsKey(fn) ? objs[fn].Dict : null, objs);
            fonts[p.Groups[1].Value] = cache[fn];
        }
        return fonts;
    }

    static void RunPage(string content, string resText, Dictionary<int, PdfObj> objs,
                        Dictionary<int, PdfFont> cache, double[] ctm0, List<Run> outp,
                        PdfDoc doc, int depth, HashSet<int> stack)
    {
        var fonts = FontMap(resText, objs, cache);
        var toks = Lex(content);
        var st = new List<double[]>();
        double[] ctm = (double[])ctm0.Clone();
        double[] tm = Id(), lm = Id();
        double fs = 12, leading = 0, hscale = 1, charSp = 0, wordSp = 0;
        PdfFont font = null;
        var ops = new List<Tok>();

        for (int ti = 0; ti < toks.Count; ti++)
        {
            var tk = toks[ti];
            // um TJ justificado passa fácil de 100 operandos; cortar cedo aqui
            // descarta o '[' e faz o trecho inteiro sumir sem erro
            if (tk.K != 3) { ops.Add(tk); if (ops.Count > 8192) ops.RemoveAt(0); continue; }
            string op = tk.S;

            if (op == "Do" && depth < 8)
            {
                string xn = null;
                for (int k = ops.Count - 1; k >= 0; k--) if (ops[k].K == 2) { xn = ops[k].S; break; }
                string xdict = Deref(GetVal(resText, "XObject"), objs);
                if (xn != null && xdict != null)
                {
                    var xm = Regex.Match(xdict, @"/" + Regex.Escape(xn) + @"\s+(\d+)\s+\d+\s+R");
                    int xo;
                    if (xm.Success && int.TryParse(xm.Groups[1].Value, out xo) &&
                        objs.ContainsKey(xo) && objs[xo].Data != null && !stack.Contains(xo))
                    {
                        string xd = objs[xo].Dict;
                        string xsub = GetVal(xd, "Subtype");
                        if (xsub != null && xsub.Contains("Form"))
                        {
                            double[] fm = Id();
                            string mx = GetVal(xd, "Matrix");
                            if (mx != null)
                            {
                                var nn = Regex.Matches(mx, @"-?[\d.]+");
                                if (nn.Count >= 6)
                                    for (int k = 0; k < 6; k++)
                                        fm[k] = double.Parse(nn[k].Value, CultureInfo.InvariantCulture);
                            }
                            string xres = Deref(GetVal(xd, "Resources"), objs);
                            if (xres == null) xres = resText;
                            stack.Add(xo);
                            try
                            {
                                RunPage(Latin.GetString(objs[xo].Data), xres, objs, cache,
                                        Mul(fm, ctm), outp, doc, depth + 1, stack);
                            }
                            catch (Exception) { }
                            stack.Remove(xo);
                        }
                    }
                }
            }
            else if (op == "q") { st.Add((double[])ctm.Clone()); }
            else if (op == "Q") { if (st.Count > 0) { ctm = st[st.Count - 1]; st.RemoveAt(st.Count - 1); } }
            else if (op == "cm" && ops.Count >= 6)
            {
                var a = Nums(ops, 6);
                ctm = Mul(a, ctm);
            }
            else if (op == "BT") { tm = Id(); lm = Id(); }
            else if (op == "Tf")
            {
                if (ops.Count >= 2 && ops[ops.Count - 1].K == 0) fs = ops[ops.Count - 1].N;
                for (int k = ops.Count - 1; k >= 0; k--)
                    if (ops[k].K == 2)
                    {
                        font = fonts.ContainsKey(ops[k].S) ? fonts[ops[k].S] : null;
                        break;
                    }
            }
            else if (op == "TL") { if (ops.Count >= 1) leading = ops[ops.Count - 1].N; }
            else if (op == "Tz") { if (ops.Count >= 1) hscale = ops[ops.Count - 1].N / 100.0; }
            else if (op == "Tc") { if (ops.Count >= 1) charSp = ops[ops.Count - 1].N; }
            else if (op == "Tw") { if (ops.Count >= 1) wordSp = ops[ops.Count - 1].N; }
            else if (op == "Td" || op == "TD")
            {
                var a = Nums(ops, 2);
                if (op == "TD") leading = -a[1];
                lm = Mul(new double[] { 1, 0, 0, 1, a[0], a[1] }, lm);
                tm = (double[])lm.Clone();
            }
            else if (op == "Tm")
            {
                var a = Nums(ops, 6);
                lm = a; tm = (double[])a.Clone();
            }
            else if (op == "T*")
            {
                lm = Mul(new double[] { 1, 0, 0, 1, 0, -leading }, lm);
                tm = (double[])lm.Clone();
            }
            else if (op == "Tj" || op == "'" || op == "\"")
            {
                if (op != "Tj")
                {
                    lm = Mul(new double[] { 1, 0, 0, 1, 0, -leading }, lm);
                    tm = (double[])lm.Clone();
                }
                string raw = LastStr(ops);
                if (raw != null) Show(raw, ref tm, ctm, fs, hscale, charSp, wordSp, font, outp, doc);
            }
            else if (op == "TJ")
            {
                int open = -1;
                for (int k = ops.Count - 1; k >= 0; k--) if (ops[k].K == 4) { open = k; break; }
                if (open >= 0)
                {
                    var sb = new StringBuilder();
                    double x0 = 0, y0 = 0, sz = 0; bool started = false;
                    for (int k = open + 1; k < ops.Count; k++)
                    {
                        if (ops[k].K == 1)
                        {
                            if (!started)
                            {
                                var trm = Mul(tm, ctm);
                                x0 = trm[4]; y0 = trm[5]; sz = fs * Scale(trm); started = true;
                            }
                            sb.Append(Decode(ops[k].S, font, doc));
                            AdvanceRaw(ref tm, Advance(ops[k].S, font, fs, charSp, wordSp), hscale);
                        }
                        else if (ops[k].K == 0)
                        {
                            double gap = -ops[k].N / 1000.0 * fs;
                            double spw = (font != null ? font.SpaceEm : 0.25) * fs;
                            if (gap > 0.45 * spw && gap > 0.07 * fs && sb.Length > 0 && sb[sb.Length - 1] != ' ')
                                sb.Append(' ');
                            AdvanceRaw(ref tm, gap, hscale);
                        }
                    }
                    if (started && sb.Length > 0)
                        Emit(sb.ToString(), x0, y0, sz, font, tm, ctm, outp, doc);
                }
            }
            ops.Clear();
        }
    }

    static void AdvanceRaw(ref double[] tm, double tx, double hscale)
    {
        tm = Mul(new double[] { 1, 0, 0, 1, tx * hscale, 0 }, tm);
    }

    static void Show(string raw, ref double[] tm, double[] ctm, double fs, double hscale,
                     double charSp, double wordSp, PdfFont font, List<Run> outp, PdfDoc doc)
    {
        var trm = Mul(tm, ctm);
        double x = trm[4], y = trm[5], sz = fs * Scale(trm);
        string txt = Decode(raw, font, doc);
        AdvanceRaw(ref tm, Advance(raw, font, fs, charSp, wordSp), hscale);
        Emit(txt, x, y, sz, font, tm, ctm, outp, doc);
    }

    static void Emit(string txt, double x, double y, double sz, PdfFont font,
                     double[] tm, double[] ctm, List<Run> outp, PdfDoc doc)
    {
        if (string.IsNullOrEmpty(txt)) return;
        doc.RawChars += txt.Length;
        if (txt.Trim().Length == 0 && outp.Count == 0) return;
        var end = Mul(tm, ctm);
        outp.Add(new Run
        {
            X = x,
            Y = y,
            Size = sz > 0.01 ? sz : 10,
            EndX = end[4] > x ? end[4] : x + txt.Length * sz * 0.5,
            SpaceW = (font != null ? font.SpaceEm : 0.25) * sz,
            Bold = font != null && font.Bold,
            Text = txt
        });
    }

    static double[] Nums(List<Tok> ops, int count)
    {
        var r = new double[count];
        int idx = count - 1;
        for (int k = ops.Count - 1; k >= 0 && idx >= 0; k--)
            if (ops[k].K == 0) { r[idx] = ops[k].N; idx--; }
        return r;
    }

    static string LastStr(List<Tok> ops)
    {
        for (int k = ops.Count - 1; k >= 0; k--) if (ops[k].K == 1) return ops[k].S;
        return null;
    }

    // ------------------------------------------------------- arvore de paginas

    class PageRef { public int Num; public string Dict; public string Res; public string Box; }

    static void Walk(int num, Dictionary<int, PdfObj> objs, string res, string box,
                     List<PageRef> outp, HashSet<int> seen, int depth)
    {
        if (depth > 64 || seen.Contains(num) || !objs.ContainsKey(num)) return;
        seen.Add(num);
        string d = objs[num].Dict;
        string myRes = GetVal(d, "Resources"); if (myRes == null) myRes = res;
        string myBox = GetVal(d, "MediaBox"); if (myBox == null) myBox = box;
        string type = GetVal(d, "Type");

        string kids = GetVal(d, "Kids");
        if (kids != null && (type == null || type.Contains("Pages")))
        {
            foreach (Match m in Regex.Matches(kids, @"(\d+)\s+\d+\s+R"))
                Walk(int.Parse(m.Groups[1].Value), objs, myRes, myBox, outp, seen, depth + 1);
            return;
        }
        if (type != null && type.Contains("Page"))
            outp.Add(new PageRef { Num = num, Dict = d, Res = myRes, Box = myBox });
    }

    static List<PageRef> Pages(Dictionary<int, PdfObj> objs)
    {
        var outp = new List<PageRef>();
        var roots = new List<int>();
        if (LastRoot >= 0 && objs.ContainsKey(LastRoot)) roots.Add(LastRoot);
        foreach (var kv in objs)
            if (kv.Value.Dict.Contains("/Catalog") && !roots.Contains(kv.Key)) roots.Add(kv.Key);

        foreach (int root in roots)
        {
            string pg = GetVal(objs[root].Dict, "Pages");
            var m = Regex.Match(pg ?? "", @"^(\d+)\s+\d+\s+R");
            if (!m.Success) continue;
            var got = new List<PageRef>();
            Walk(int.Parse(m.Groups[1].Value), objs, null, null, got, new HashSet<int>(), 0);
            if (got.Count > outp.Count) outp = got;
        }

        // se a arvore trouxe menos paginas do que existem objetos /Page, usa todos
        var loose = objs.Where(k => GetVal(k.Value.Dict, "Type") == "/Page").OrderBy(k => k.Key).ToList();
        if (outp.Count < loose.Count)
        {
            var byNum = new HashSet<int>(outp.Select(p => p.Num));
            var all = new List<PageRef>();
            foreach (var kv in loose)
            {
                var known = outp.FirstOrDefault(p => p.Num == kv.Key);
                if (known != null) { all.Add(known); continue; }
                string res = GetVal(kv.Value.Dict, "Resources");
                string box = GetVal(kv.Value.Dict, "MediaBox");
                if (res == null || box == null)
                {
                    // herda do /Parent
                    var pm = Regex.Match(GetVal(kv.Value.Dict, "Parent") ?? "", @"^(\d+)");
                    int pn;
                    if (pm.Success && int.TryParse(pm.Groups[1].Value, out pn) && objs.ContainsKey(pn))
                    {
                        if (res == null) res = GetVal(objs[pn].Dict, "Resources");
                        if (box == null) box = GetVal(objs[pn].Dict, "MediaBox");
                    }
                }
                all.Add(new PageRef { Num = kv.Key, Dict = kv.Value.Dict, Res = res, Box = box });
            }
            outp = all;
        }
        return outp;
    }

    // --------------------------------------------------------------- publico

    public static PdfDoc Extract(string path)
    {
        var doc = new PdfDoc();
        bool enc;
        var objs = Parse(path, out enc);
        doc.Encrypted = enc;

        var pages = Pages(objs);
        doc.PageCount = pages.Count;
        var fontCache = new Dictionary<int, PdfFont>();

        int pageNo = 0;
        foreach (var pr in pages)
        {
            pageNo++;
            double pw = 595, ph = 842;
            if (pr.Box != null)
            {
                var nums = Regex.Matches(pr.Box, @"-?[\d.]+");
                if (nums.Count >= 4)
                {
                    double x0 = double.Parse(nums[0].Value, CultureInfo.InvariantCulture);
                    double y0 = double.Parse(nums[1].Value, CultureInfo.InvariantCulture);
                    double x1 = double.Parse(nums[2].Value, CultureInfo.InvariantCulture);
                    double y1 = double.Parse(nums[3].Value, CultureInfo.InvariantCulture);
                    pw = Math.Abs(x1 - x0); ph = Math.Abs(y1 - y0);
                    if (pw < 10) pw = 595;
                    if (ph < 10) ph = 842;
                }
            }

            string res = Deref(pr.Res, objs);

            // conteudo
            var sbc = new StringBuilder();
            string cts = GetVal(pr.Dict, "Contents");
            if (cts != null)
            {
                foreach (Match m in Regex.Matches(cts, @"(\d+)\s+\d+\s+R"))
                {
                    int cn = int.Parse(m.Groups[1].Value);
                    if (objs.ContainsKey(cn) && objs[cn].Data != null)
                    { sbc.Append(Latin.GetString(objs[cn].Data)); sbc.Append('\n'); }
                }
            }
            if (sbc.Length == 0) continue;

            var runs = new List<Run>();
            try
            {
                RunPage(sbc.ToString(), res, objs, fontCache, Id(), runs, doc, 0, new HashSet<int>());
            }
            catch (Exception) { }

            foreach (var ln in GroupLines(runs))
            {
                ln.Page = pageNo; ln.PageH = ph; ln.PageW = pw;
                doc.Lines.Add(ln);
            }
        }
        return doc;
    }

    static List<PdfLine> GroupLines(List<Run> runs)
    {
        var res = new List<PdfLine>();
        var live = runs.Where(r => r.Text != null && r.Text.Trim().Length > 0).OrderByDescending(r => r.Y).ToList();
        int i = 0;
        while (i < live.Count)
        {
            var group = new List<Run>();
            double y = live[i].Y;
            double tol = Math.Max(1.2, live[i].Size * 0.4);
            while (i < live.Count && Math.Abs(live[i].Y - y) <= tol) { group.Add(live[i]); i++; }

            group = group.OrderBy(r => r.X).ToList();
            var sb = new StringBuilder();
            double prevEnd = 0; double prevSize = group[0].Size;
            foreach (var r in group)
            {
                string t = r.Text.Replace("\r", " ").Replace("\n", " ").Replace("\t", " ");
                if (sb.Length > 0)
                {
                    double gap = r.X - prevEnd;
                    bool spaced = sb[sb.Length - 1] == ' ' || t.StartsWith(" ");
                    double spw = r.SpaceW > 0.5 ? r.SpaceW : 0.25 * r.Size;
                    if (!spaced && gap > 0.45 * spw) sb.Append(' ');
                }
                sb.Append(t);
                prevEnd = r.EndX; prevSize = r.Size;
            }
            string text = Regex.Replace(sb.ToString(), @"[ ]{2,}", " ").Trim();
            if (text.Length == 0) continue;

            int boldChars = group.Where(r => r.Bold).Sum(r => r.Text.Length);
            int allChars = Math.Max(1, group.Sum(r => r.Text.Length));

            res.Add(new PdfLine
            {
                Y = group.Average(r => r.Y),
                X0 = group.Min(r => r.X),
                X1 = group.Max(r => r.EndX),
                Size = group.OrderByDescending(r => r.Text.Length).First().Size,
                Bold = boldChars * 2 >= allChars,
                Text = text
            });
        }
        return res;
    }
}
'@

if (-not ('PdfMd' -as [type])) {
    Add-Type -TypeDefinition $engine -ReferencedAssemblies System.IO.Compression, System.IO.Compression.FileSystem, System.Core
}

# ------------------------------------------------------- montagem do markdown

function Get-Percentile {
    param([double[]]$Values, [double]$P)
    if (-not $Values -or $Values.Count -eq 0) { return 0 }
    $s = [double[]]($Values | Sort-Object)
    $i = [int][Math]::Floor(($s.Count - 1) * $P)
    return $s[[Math]::Max(0, [Math]::Min($s.Count - 1, $i))]
}

function Get-NormKey {
    param([string]$t)
    $k = $t.ToLower()
    $k = [regex]::Replace($k, '[0-9a-f]{8,}', '#')
    $k = [regex]::Replace($k, '\d+', '#')
    $k = [regex]::Replace($k, '\s+', ' ')
    return $k.Trim()
}

# Padroes IMUNES a remocao de repetidos. O carimbo de folha repete em toda pagina
# por definicao - e era exatamente por isso que ia embora junto com o cabecalho.
# Num extrato e-STJ de 844 paginas, das 855 ocorrencias de "(e-STJ Fl.N)" sobrava
# menos da metade, e a ultima folha visivel no .md era a 822 quando a real era a
# 830. Sem o carimbo, as ancoras 2 e 3 da secao 3 da armando-analise-processo
# mentem, e nao se cita peca por folha.
$RX_IMUNES = @(
    '\(e-STJ\s*Fl\.',          # e-STJ / STJ
    '\bFl\.?\s*\d',            # foliacao "Fl. 830"
    '\bfls\.',                 # "fls. 145/336"
    '\bID\s+[0-9A-Za-z]',      # PJe: "ID 037030e"
    '\bEvento\s+\d',           # eproc: "Evento 12"
    '\bNum\.\s*\d'             # PJe-JT: "Num. 3c1f2a9"
)

function Test-Imune {
    <# A linha carrega identificador de folha, documento ou evento? Entao fica,
       ainda que repita em toda pagina. #>
    param([string]$t)
    foreach ($rx in $RX_IMUNES) {
        if ([regex]::IsMatch($t, $rx, [Text.RegularExpressions.RegexOptions]::IgnoreCase)) {
            return $true
        }
    }
    return $false
}

function Get-DataCriacaoPdf {
    <# /CreationDate do PDF -> 'dd/MM/yyyy HH:mm'. E a QUINTA ancora de atualidade
       da armando-analise-processo: diz quando o PDF foi tirado, nao quando o
       processo se moveu - mas num caso real era o unico marcador recente do
       arquivo, e sem ele a analise teria errado o retrato em treze meses.
       Le os bytes crus: o /Info raramente vive em stream comprimido. #>
    param([string]$Path)
    $m = $null
    try {
        $fs = [IO.File]::OpenRead($Path)
        try {
            $len = [int][Math]::Min([long]2MB, $fs.Length)
            $buf = New-Object byte[] $len
            $rx = '/CreationDate\s*\(\s*D?:?\s*(\d{4})(\d{2})(\d{2})(\d{2})?(\d{2})?'
            # o /Info costuma estar na cauda; nao achando, tenta a cabeca
            [void]$fs.Seek(-$len, [IO.SeekOrigin]::End)
            [void]$fs.Read($buf, 0, $len)
            $m = [regex]::Match([Text.Encoding]::ASCII.GetString($buf), $rx)
            if (-not $m.Success) {
                [void]$fs.Seek(0, [IO.SeekOrigin]::Begin)
                [void]$fs.Read($buf, 0, $len)
                $m = [regex]::Match([Text.Encoding]::ASCII.GetString($buf), $rx)
            }
        }
        finally { $fs.Dispose() }
    }
    catch { return $null }
    if (-not $m -or -not $m.Success) { return $null }
    $mes = [int]$m.Groups[2].Value
    $dia = [int]$m.Groups[3].Value
    if ($mes -lt 1 -or $mes -gt 12 -or $dia -lt 1 -or $dia -gt 31) { return $null }
    $hh = if ($m.Groups[4].Success) { $m.Groups[4].Value } else { '00' }
    $mi = if ($m.Groups[5].Success) { $m.Groups[5].Value } else { '00' }
    return ('{0}/{1}/{2} {3}:{4}' -f $m.Groups[3].Value, $m.Groups[2].Value,
        $m.Groups[1].Value, $hh, $mi)
}

function Convert-DocToMarkdown {
    param($Doc, [string]$SourceName, [bool]$StripRepeated, [bool]$PageMarks,
          [string]$CriadoEm)

    $all = @($Doc.Lines | Where-Object { $_.Text -and $_.Text.Trim().Length -gt 0 })
    if ($all.Count -eq 0) { return $null }

    # --- cabecalhos / rodapes repetidos
    $dropped = 0
    $salvos = 0
    $blocked = @{}
    $blockedPrefix = @{}
    if ($StripRepeated -and $Doc.PageCount -ge 3) {
        $seen = @{}
        $seenPre = @{}
        foreach ($l in $all) {
            $k = Get-NormKey $l.Text
            if ($k.Length -lt 2) { continue }
            $inBand = ($l.Y -gt 0.87 * $l.PageH) -or ($l.Y -lt 0.13 * $l.PageH)
            if ($inBand -or $k.Length -ge 40) {
                if (-not $seen.ContainsKey($k)) { $seen[$k] = New-Object 'System.Collections.Generic.HashSet[int]' }
                [void]$seen[$k].Add($l.Page)
            }
            # carimbo de assinatura muda o nome/codigo em cada pagina: casa pelo inicio
            if ($k.Length -ge 60) {
                $p = $k.Substring(0, 60)
                if (-not $seenPre.ContainsKey($p)) { $seenPre[$p] = New-Object 'System.Collections.Generic.HashSet[int]' }
                [void]$seenPre[$p].Add($l.Page)
            }
        }
        $limit = [Math]::Max(3, [int][Math]::Ceiling($Doc.PageCount * 0.5))
        foreach ($k in $seen.Keys) { if ($seen[$k].Count -ge $limit) { $blocked[$k] = $true } }
        foreach ($k in $seenPre.Keys) { if ($seenPre[$k].Count -ge $limit) { $blockedPrefix[$k] = $true } }
    }

    $kept = New-Object System.Collections.ArrayList
    foreach ($l in $all) {
        $inBand = ($l.Y -gt 0.87 * $l.PageH) -or ($l.Y -lt 0.13 * $l.PageH)
        $t = $l.Text.Trim()
        $ehImune = Test-Imune $t
        if ($StripRepeated) {
            $k = Get-NormKey $t
            $repetida = $blocked.ContainsKey($k) -or
                        ($k.Length -ge 60 -and $blockedPrefix.ContainsKey($k.Substring(0, 60)))
            if ($repetida) {
                # imune: repete, mas carrega folha/ID/evento. Fica.
                if ($ehImune) { $salvos++ } else { $dropped++; continue }
            }
        }
        if ($inBand -and -not $ehImune -and $t -match '^(p(a|á)g(ina)?\.?\s*)?\d{1,4}(\s*(/|de)\s*\d{1,4})?$') { $dropped++; continue }
        [void]$kept.Add($l)
    }
    if ($kept.Count -eq 0) { return $null }

    # --- tamanho de corpo (moda ponderada por caractere)
    $w = @{}
    foreach ($l in $kept) {
        $s = [Math]::Round($l.Size, 1)
        if (-not $w.ContainsKey($s)) { $w[$s] = 0 }
        $w[$s] += $l.Text.Length
    }
    $body = ($w.GetEnumerator() | Sort-Object Value -Descending | Select-Object -First 1).Key
    if (-not $body -or $body -le 0) { $body = 11 }

    $rxHeadWord = '^\s*(CL(Á|A)USULA|CAP(Í|I)TULO|SE(Ç|C)(Ã|A)O|T(Í|I)TULO|ANEXO|AP(Ê|E)NDICE|PRE(Â|A)MBULO|CONSIDERANDO|D(O|A)S?\s+[A-ZÁÉÍÓÚÂÊÔÃÕÇ]{3,})\b'
    $rxList = '^\s*([\u2022\u25AA\u25CF\u25E6\u00B7\-\u2013\u2014\*]|\(?[a-z]\)|\(?[ivxlIVXL]{1,5}\)|\d{1,3}(\.\d{1,3})*\s*[\.\)\-\u2013])\s+'
    $rxNum = '^\s*\d{1,3}(\.\d{1,3})+\.?\s'

    $blocks = New-Object System.Collections.ArrayList
    $buf = New-Object System.Collections.ArrayList
    $prev = $null
    $bufLevel = 0

    # dot-sourced: roda no escopo desta funcao, enxerga $buf e $blocks
    $flush = {
        if ($buf.Count -gt 0) {
            $txt = ''
            foreach ($piece in $buf) {
                if ($txt.Length -eq 0) { $txt = $piece }
                elseif ($txt.EndsWith('-')) { $txt += $piece }   # hifen de quebra de linha
                else { $txt += ' ' + $piece }
            }
            $txt = [regex]::Replace($txt, '\s{2,}', ' ').Trim()
            if ($txt.Length -gt 0) {
                # titulo que virou paragrafo inteiro nao e titulo
                if ($bufLevel -gt 0 -and $txt.Length -le 150) { $txt = ('#' * $bufLevel) + ' ' + $txt }
                [void]$blocks.Add($txt)
            }
            $buf.Clear()
        }
        $bufLevel = 0
    }

    $byPage = $kept | Group-Object Page
    foreach ($pg in $byPage) {
        $pl = @($pg.Group)
        $right = Get-Percentile ([double[]]($pl | ForEach-Object { $_.X1 })) 0.92
        $left = Get-Percentile ([double[]]($pl | ForEach-Object { $_.X0 })) 0.08
        $width = [Math]::Max(1, $right - $left)

        # margem direita por nivel de recuo: citacao recuada tem margem propria
        $edge = @{}
        foreach ($g in ($pl | Group-Object { [int]([Math]::Round($_.X0 / 12)) })) {
            $xs = [double[]]($g.Group | ForEach-Object { $_.X1 })
            $edge[$g.Name] = if ($g.Group.Count -ge 2) { Get-Percentile $xs 0.92 } else { $right }
        }
        $gaps = @()
        for ($i = 1; $i -lt $pl.Count; $i++) {
            $g = $pl[$i - 1].Y - $pl[$i].Y
            if ($g -gt 0.5 -and $g -lt 100) { $gaps += $g }
        }
        $medGap = if ($gaps.Count -gt 0) { Get-Percentile ([double[]]$gaps) 0.5 } else { $body * 1.3 }

        if ($PageMarks -and $pg.Name -ne $byPage[0].Name) {
            . $flush
            [void]$blocks.Add("[p. $($pg.Name)]")
        }

        for ($i = 0; $i -lt $pl.Count; $i++) {
            $l = $pl[$i]
            $t = $l.Text.Trim()
            if ($t.Length -eq 0) { continue }

            # -creplace: com -replace o .NET ignora maiuscula/minuscula ate em \p{Lu}
            $letters = ($t -creplace '[^\p{L}]', '')
            $upper = ($t -creplace '[^\p{Lu}]', '')
            $isCaps = ($letters.Length -ge 3) -and ($upper.Length -ge $letters.Length * 0.9)
            $ratio = $l.Size / $body

            $short = $t.Length -le 100
            $level = 0
            if ($ratio -ge 1.5 -and $short) { $level = 1 }
            elseif ($ratio -ge 1.28 -and $short) { $level = 2 }
            elseif ($ratio -ge 1.12 -and $short -and ($l.Bold -or $isCaps) -and $t -notmatch '[.,;]$') { $level = 3 }
            elseif ($isCaps -and $short -and ($l.Bold -or $t -cmatch $rxHeadWord) -and $t -notmatch '[.,;]$') { $level = 2 }
            elseif ($t -cmatch $rxHeadWord -and $short -and ($l.Bold -or $isCaps)) { $level = 2 }

            $isList = ($level -eq 0) -and ($t -match $rxList) -and ($t -notmatch $rxNum)
            $isNum = ($level -eq 0) -and ($t -match $rxNum)

            $gap = if ($prev -and $prev.Page -eq $l.Page) { $prev.Y - $l.Y } else { 0 }
            $brk = $false
            if ($null -eq $prev -or $prev.Page -ne $l.Page) {
                $brk = $true
            }
            elseif ($level -gt 0 -or $bufLevel -gt 0) {
                # titulos: so quebram por mudanca de nivel ou espaco vertical
                $brk = ($level -ne $bufLevel) -or ($gap -gt 1.6 * $medGap)
            }
            else {
                $bk = [string][int]([Math]::Round($prev.X0 / 12))
                $pRight = if ($edge.ContainsKey($bk)) { $edge[$bk] } else { $right }
                $deficit = $pRight - $prev.X1
                $fecha = $prev.Text -match '[.!?:;"”»)]\s*$'
                if ($gap -gt 1.45 * $medGap) { $brk = $true }                        # espaco vertical
                if ($deficit -gt 0.06 * $width -and $fecha) { $brk = $true }         # linha curta + pontuacao final
                if ($deficit -gt 0.30 * $width) { $brk = $true }                     # linha bem curta
                if ($l.X0 -gt $prev.X0 + 0.02 * $width) { $brk = $true }             # recuo de 1a linha

                if ([Math]::Abs($prev.Size - $l.Size) -gt 0.7) { $brk = $true }
                if ($isList -or $isNum) { $brk = $true }
            }

            if ($brk) { . $flush }

            if ($isList) {
                $t = '- ' + [regex]::Replace($t, '^\s*[\u2022\u25AA\u25CF\u25E6\u00B7\-\u2013\u2014\*]\s+', '')
            }
            if ($buf.Count -eq 0) { $bufLevel = $level }
            [void]$buf.Add($t)
            $prev = $l
        }
        . $flush
    }
    . $flush

    $md = New-Object System.Collections.ArrayList
    foreach ($b in $blocks) {
        if ($b -match '^\s*$') { continue }
        [void]$md.Add($b)
    }

    $header = "<!-- $SourceName | $($Doc.PageCount) pag."
    if ($CriadoEm) { $header += " | PDF criado em $CriadoEm" }
    if ($dropped -gt 0) { $header += " | $dropped linhas de cabecalho/rodape removidas" }
    if ($salvos -gt 0) { $header += " | $salvos preservadas por carregarem folha/ID" }
    $header += " -->"

    $text = $header + "`n`n" + (($md -join "`n`n"))
    $text = [regex]::Replace($text, '(\r?\n){3,}', "`n`n")
    $text = [regex]::Replace($text, '[ \t]+(\r?\n)', '$1')
    return [pscustomobject]@{ Text = $text; Dropped = $dropped; Salvos = $salvos }
}

# ------------------------------------------------------------------ execucao

function Convert-OnePdf {
    param([string]$Src, [string]$Dst)

    $doc = [PdfMd]::Extract($Src)
    if ($doc.Encrypted -and $doc.Lines.Count -eq 0) {
        Write-Host "  ! PDF protegido por senha - nao da para ler o texto." -ForegroundColor Red
        return $null
    }
    if ($doc.Lines.Count -eq 0) {
        Write-Host "  ! Sem camada de texto (PDF escaneado). Precisa de OCR." -ForegroundColor Red
        return $null
    }

    if ($Linhas) {
        $tsv = [IO.Path]::ChangeExtension($Dst, '.linhas.tsv')
        $rows = foreach ($l in $doc.Lines) {
            "{0}`t{1:F1}`t{2:F1}`t{3:F1}`t{4:F2}`t{5}`t{6}" -f `
                $l.Page, $l.Y, $l.X0, $l.X1, $l.Size, $l.Bold, $l.Text
        }
        [IO.File]::WriteAllLines($tsv, [string[]]$rows, (New-Object Text.UTF8Encoding $false))
        Write-Host "     diagnostico: $(Split-Path $tsv -Leaf)" -ForegroundColor DarkGray
    }

    $criadoEm = Get-DataCriacaoPdf $Src
    $r = Convert-DocToMarkdown -Doc $doc -SourceName ([IO.Path]::GetFileName($Src)) `
        -StripRepeated (-not $ManterRepetidos) -PageMarks (-not $SemMarcasDePagina) `
        -CriadoEm $criadoEm
    if ($null -eq $r) {
        Write-Host "  ! Nada de texto aproveitavel." -ForegroundColor Red
        return $null
    }

    [IO.File]::WriteAllText($Dst, $r.Text, (New-Object Text.UTF8Encoding $false))

    $pdfKb = [Math]::Round((Get-Item $Src).Length / 1KB)
    $chars = $r.Text.Length
    $tok = [Math]::Round($chars / 3.5)
    $bad = $doc.Unknown

    Write-Host ("  -> {0}" -f (Split-Path $Dst -Leaf)) -ForegroundColor Green
    Write-Host ("     {0} pag. | {1} KB de PDF -> {2} caracteres (~{3} tokens)" -f `
            $doc.PageCount, $pdfKb, $chars, $tok) -ForegroundColor DarkGray
    if ($r.Dropped -gt 0) {
        Write-Host ("     {0} linhas repetidas de cabecalho/rodape removidas" -f $r.Dropped) -ForegroundColor DarkGray
    }
    if ($r.Salvos -gt 0) {
        Write-Host ("     {0} linhas repetidas PRESERVADAS (carregam folha/ID/evento)" -f $r.Salvos) -ForegroundColor DarkGray
    }
    if ($criadoEm) {
        Write-Host ("     PDF criado em {0} (5a ancora de atualidade)" -f $criadoEm) -ForegroundColor DarkGray
    }
    if ($doc.PageCount -gt 0 -and ($chars / $doc.PageCount) -lt 200) {
        Write-Host "     AVISO: quase nao ha texto por pagina - PDF provavelmente digitalizado." -ForegroundColor Yellow
        Write-Host "            o .md so tem o carimbo/rodape. Para o conteudo, precisa de OCR." -ForegroundColor Yellow
    }
    if ($bad -gt $chars * 0.02) {
        Write-Host ("     aviso: {0} glifos nao mapeados - fonte sem /ToUnicode" -f $bad) -ForegroundColor Yellow
    }
    return $Dst
}

# ---- entrada

if (-not $Path -or $Path.Count -eq 0) {
    Add-Type -AssemblyName System.Windows.Forms
    $dlg = New-Object System.Windows.Forms.OpenFileDialog
    $dlg.Filter = 'PDF (*.pdf)|*.pdf'
    $dlg.Multiselect = $true
    $dlg.Title = 'Selecione o(s) PDF(s) para converter em Markdown'
    $dlg.InitialDirectory = [Environment]::GetFolderPath('MyDocuments')
    if ($dlg.ShowDialog() -ne [System.Windows.Forms.DialogResult]::OK) { return }
    $Path = $dlg.FileNames
}

$files = New-Object System.Collections.ArrayList
foreach ($p in $Path) {
    if ([string]::IsNullOrWhiteSpace($p)) { continue }
    if (Test-Path -LiteralPath $p -PathType Container) {
        Get-ChildItem -LiteralPath $p -Filter *.pdf -File | ForEach-Object { [void]$files.Add($_.FullName) }
    }
    elseif (Test-Path -LiteralPath $p -PathType Leaf) {
        [void]$files.Add((Resolve-Path -LiteralPath $p).Path)
    }
    else {
        Write-Host "Nao encontrado: $p" -ForegroundColor Yellow
    }
}

if ($files.Count -eq 0) {
    Write-Host 'Nenhum PDF para converter.' -ForegroundColor Yellow
    if ($Pausar) { Read-Host 'Enter para fechar' }
    return
}

$outIsDir = $false
if ($Out) {
    if ((Test-Path -LiteralPath $Out -PathType Container) -or $files.Count -gt 1 -or -not [IO.Path]::GetExtension($Out)) {
        $outIsDir = $true
        if (-not (Test-Path -LiteralPath $Out)) { New-Item -ItemType Directory -Path $Out -Force | Out-Null }
    }
}

$done = @()
foreach ($f in $files) {
    Write-Host ([IO.Path]::GetFileName($f)) -ForegroundColor Cyan
    $dst = if (-not $Out) { [IO.Path]::ChangeExtension($f, '.md') }
    elseif ($outIsDir) { Join-Path $Out ([IO.Path]::GetFileNameWithoutExtension($f) + '.md') }
    else { $Out }
    try {
        $r = Convert-OnePdf -Src $f -Dst $dst
        if ($r) { $done += $r }
    }
    catch {
        Write-Host ("  ! Erro: {0}" -f $_.Exception.Message) -ForegroundColor Red
    }
}

if ($done.Count -gt 1) {
    Write-Host ""
    Write-Host ("{0} arquivos convertidos." -f $done.Count) -ForegroundColor Green
}
if ($Abrir -and $done.Count -gt 0) { Invoke-Item $done[0] }
if ($Pausar) { Write-Host ""; Read-Host 'Enter para fechar' }
