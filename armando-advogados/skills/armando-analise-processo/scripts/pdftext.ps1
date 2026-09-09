param([string]$Src, [string]$Dst)

$code = @'
using System;
using System.Collections.Generic;
using System.Globalization;
using System.IO;
using System.IO.Compression;
using System.Linq;
using System.Text;
using System.Text.RegularExpressions;

public class PdfObj
{
    public int Num;
    public string Dict = "";
    public byte[] Data;
}

public static class PdfText2
{
    static Encoding Latin = Encoding.GetEncoding(28591);

    static byte[] Inflate(byte[] data, int off, int len)
    {
        foreach (int skip in new int[] { 2, 0 })
        {
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

    public static Dictionary<int, PdfObj> Parse(string path)
    {
        byte[] bytes = File.ReadAllBytes(path);
        string all = Latin.GetString(bytes);
        var objs = new Dictionary<int, PdfObj>();
        var rx = new Regex(@"(?<n>\d+)\s+\d+\s+obj\b");
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
                    var dec = Inflate(bytes, d, e - d);
                    if (dec == null)
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
        return objs;
    }

    static string HexToStr(string hex)
    {
        hex = Regex.Replace(hex, @"\s", "");
        var sb = new StringBuilder();
        for (int i = 0; i + 3 < hex.Length + 1 && i + 4 <= hex.Length; i += 4)
        {
            int v = Convert.ToInt32(hex.Substring(i, 4), 16);
            sb.Append((char)v);
        }
        if (hex.Length % 4 == 2)
            sb.Append((char)Convert.ToInt32(hex.Substring(hex.Length - 2, 2), 16));
        return sb.ToString();
    }

    public static Dictionary<int, string> ParseCMap(string cm)
    {
        var map = new Dictionary<int, string>();
        foreach (Match blk in Regex.Matches(cm, @"beginbfchar(.*?)endbfchar", RegexOptions.Singleline))
        {
            foreach (Match p in Regex.Matches(blk.Groups[1].Value, @"<([0-9A-Fa-f]+)>\s*<([0-9A-Fa-f]+)>"))
            {
                int src = Convert.ToInt32(p.Groups[1].Value, 16);
                map[src] = HexToStr(p.Groups[2].Value);
            }
        }
        foreach (Match blk in Regex.Matches(cm, @"beginbfrange(.*?)endbfrange", RegexOptions.Singleline))
        {
            string b = blk.Groups[1].Value;
            foreach (Match p in Regex.Matches(b, @"<([0-9A-Fa-f]+)>\s*<([0-9A-Fa-f]+)>\s*<([0-9A-Fa-f]+)>"))
            {
                int lo = Convert.ToInt32(p.Groups[1].Value, 16);
                int hi = Convert.ToInt32(p.Groups[2].Value, 16);
                string dst = HexToStr(p.Groups[3].Value);
                for (int c = lo; c <= hi && c - lo < 65536; c++)
                {
                    if (dst.Length > 0)
                    {
                        var chars = dst.ToCharArray();
                        chars[chars.Length - 1] = (char)(chars[chars.Length - 1] + (c - lo));
                        map[c] = new string(chars);
                    }
                }
            }
            foreach (Match p in Regex.Matches(b, @"<([0-9A-Fa-f]+)>\s*<([0-9A-Fa-f]+)>\s*\[(.*?)\]", RegexOptions.Singleline))
            {
                int lo = Convert.ToInt32(p.Groups[1].Value, 16);
                int i = 0;
                foreach (Match d in Regex.Matches(p.Groups[3].Value, @"<([0-9A-Fa-f]+)>"))
                {
                    map[lo + i] = HexToStr(d.Groups[1].Value);
                    i++;
                }
            }
        }
        return map;
    }

    public static string Extract(string path)
    {
        var objs = Parse(path);

        // font object -> cmap
        var fontCMap = new Dictionary<int, Dictionary<int, string>>();
        foreach (var kv in objs)
        {
            var m = Regex.Match(kv.Value.Dict, @"/ToUnicode\s+(\d+)\s+\d+\s+R");
            if (m.Success)
            {
                int tu = int.Parse(m.Groups[1].Value);
                if (objs.ContainsKey(tu) && objs[tu].Data != null)
                    fontCMap[kv.Key] = ParseCMap(Latin.GetString(objs[tu].Data));
            }
        }

        // resource font name -> font obj
        var nameToFont = new Dictionary<string, int>();
        foreach (var kv in objs)
        {
            foreach (Match fm in Regex.Matches(kv.Value.Dict, @"/Font\s*<<(.*?)>>", RegexOptions.Singleline))
            {
                foreach (Match p in Regex.Matches(fm.Groups[1].Value, @"/([^\s/<>\[\]]+)\s+(\d+)\s+\d+\s+R"))
                    nameToFont[p.Groups[1].Value] = int.Parse(p.Groups[2].Value);
            }
        }

        var sb = new StringBuilder();
        var contentNums = objs.Where(k => k.Value.Data != null &&
                                     (Latin.GetString(k.Value.Data).Contains("Tj") || Latin.GetString(k.Value.Data).Contains("TJ")) &&
                                     !k.Value.Dict.Contains("/ToUnicode") && !k.Value.Dict.Contains("CMapName"))
                              .Select(k => k.Key).OrderBy(k => k).ToList();

        foreach (int n in contentNums)
        {
            string body = Latin.GetString(objs[n].Data);
            if (body.Contains("begincmap")) continue;
            Dictionary<int, string> cur = null;
            var rx = new Regex(@"(?s)/([^\s/<>\[\]]+)\s+[\d.]+\s+Tf|<([0-9A-Fa-f\s]*)>\s*Tj|\((?<lit>(?:\\.|[^\\()])*)\)\s*Tj|\[(?<arr>(?:<[0-9A-Fa-f\s]*>|\((?:\\.|[^\\()])*\)|[^\[\]])*)\]\s*TJ|(?<nl>T\*|Td|TD|ET)");
            foreach (Match m in rx.Matches(body))
            {
                if (m.Groups[1].Success)
                {
                    string fn = m.Groups[1].Value;
                    cur = null;
                    if (nameToFont.ContainsKey(fn) && fontCMap.ContainsKey(nameToFont[fn]))
                        cur = fontCMap[nameToFont[fn]];
                }
                else if (m.Groups[2].Success)
                {
                    sb.Append(DecodeHex(m.Groups[2].Value, cur));
                }
                else if (m.Groups["lit"].Success && m.Value.EndsWith("Tj"))
                {
                    sb.Append(m.Groups["lit"].Value);
                }
                else if (m.Groups["arr"].Success)
                {
                    foreach (Match sm in Regex.Matches(m.Groups["arr"].Value, @"<([0-9A-Fa-f\s]*)>|\(((?:\\.|[^\\()])*)\)|(-?[\d.]+)"))
                    {
                        if (sm.Groups[1].Success) sb.Append(DecodeHex(sm.Groups[1].Value, cur));
                        else if (sm.Groups[2].Success) sb.Append(sm.Groups[2].Value);
                        else
                        {
                            double v;
                            if (double.TryParse(sm.Groups[3].Value, NumberStyles.Any, CultureInfo.InvariantCulture, out v) && v < -180)
                                sb.Append(' ');
                        }
                    }
                }
                else if (m.Groups["nl"].Success)
                {
                    if (sb.Length > 0 && sb[sb.Length - 1] != '\n') sb.Append('\n');
                }
            }
            sb.Append("\n\n=== [fim obj " + n + "] ===\n\n");
        }
        return sb.ToString();
    }

    static string DecodeHex(string hex, Dictionary<int, string> cmap)
    {
        hex = Regex.Replace(hex, @"\s", "");
        var sb = new StringBuilder();
        if (cmap == null)
        {
            for (int i = 0; i + 2 <= hex.Length; i += 2)
                sb.Append((char)Convert.ToInt32(hex.Substring(i, 2), 16));
            return sb.ToString();
        }
        for (int i = 0; i + 4 <= hex.Length; i += 4)
        {
            int c = Convert.ToInt32(hex.Substring(i, 4), 16);
            if (cmap.ContainsKey(c)) sb.Append(cmap[c]);
            else sb.Append('?');
        }
        return sb.ToString();
    }
}
'@

Add-Type -TypeDefinition $code -ReferencedAssemblies System.IO.Compression, System.IO.Compression.FileSystem, System.Core
$t = [PdfText2]::Extract($Src)
$t = [regex]::Replace($t, "[ \t]+", " ")
$t = [regex]::Replace($t, "(\r?\n){3,}", "`n`n")
[System.IO.File]::WriteAllText($Dst, $t, [System.Text.Encoding]::UTF8)
"OK -> $Dst ($($t.Length) chars)"
