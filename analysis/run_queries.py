"""Run every analysis/queries/*.sql against data/metrics.db and write analysis/results.json.

The report (reports/september_2026_churn_report.html) is built from results.json, so every
number in it traces back to one of these SQL files. A few significance tests are computed
here in plain Python from the query outputs (see `significance`).
"""
import json
import math
import re
import sqlite3
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
DB = ROOT / "data" / "metrics.db"
QUERIES = ROOT / "analysis" / "queries"
OUT = ROOT / "analysis" / "results.json"


def parse_header(sql):
    meta = {}
    for key in ("title", "description"):
        m = re.search(rf"^--\s*{key}:\s*(.+)$", sql, re.MULTILINE)
        meta[key] = m.group(1).strip() if m else ""
    return meta


def run_all(conn):
    results = {}
    for path in sorted(QUERIES.glob("*.sql")):
        sql = path.read_text()
        cur = conn.execute(sql)
        cols = [d[0] for d in cur.description]
        rows = [dict(zip(cols, r)) for r in cur.fetchall()]
        results[path.stem] = {"file": f"analysis/queries/{path.name}", **parse_header(sql),
                              "sql": sql.strip(), "columns": cols, "rows": rows}
    return results


def two_prop_z(x1, n1, x2, n2):
    p1, p2 = x1 / n1, x2 / n2
    p = (x1 + x2) / (n1 + n2)
    se = math.sqrt(p * (1 - p) * (1 / n1 + 1 / n2))
    z = (p1 - p2) / se
    return {"p1_pct": round(100 * p1, 2), "p2_pct": round(100 * p2, 2), "z": round(z, 2),
            "p_value": float(f"{math.erfc(abs(z) / math.sqrt(2)):.2e}")}


def wilson(x, n, z=1.96):
    p = x / n
    d = 1 + z * z / n
    c = (p + z * z / (2 * n)) / d
    h = z * math.sqrt(p * (1 - p) / n + z * z / (4 * n * n)) / d
    return [round(100 * (c - h), 1), round(100 * (c + h), 1)]


def significance(q):
    seg = {(r["region"], r["payment_method"], r["month"]): r for r in q["05_region_x_payment"]["rows"]}
    did = {(r["grp"], r["window"]): r for r in q["10_did_groups"]["rows"]}

    def pooled(region_filter, method, months):
        x = n = 0
        for (reg, pmeth, mon), r in seg.items():
            if region_filter(reg) and pmeth == method and mon in months:
                x += r["cancellations"]
                n += r["active_start"]
        return x, n

    base = [f"2026-0{m}" for m in range(3, 9)]
    eu = lambda r: r == "EU"
    non_eu = lambda r: r != "EU"
    eu_sep = pooled(eu, "card", ["2026-09"])
    eu_base = pooled(eu, "card", base)
    rest_sep = pooled(non_eu, "card", ["2026-09"])
    rest_base = pooled(non_eu, "card", base)
    eu_inv_sep = pooled(eu, "invoice", ["2026-09"])

    def rate(g, w):
        return did[(g, w)]["logo_churn_pct"]

    did_pp = round((rate("EU / card", "post_sep_oct") - rate("EU / card", "pre_jun_aug"))
                   - (rate("non-EU / card", "post_sep_oct") - rate("non-EU / card", "pre_jun_aug")), 2)
    return {
        "eu_card_sep_vs_baseline": two_prop_z(*eu_sep, *eu_base),
        "eu_card_sep_ci95_pct": wilson(*eu_sep),
        "non_eu_card_sep_vs_baseline": two_prop_z(*rest_sep, *rest_base),
        "non_eu_card_sep_ci95_pct": wilson(*rest_sep),
        "eu_card_vs_eu_invoice_sep": two_prop_z(*eu_sep, *eu_inv_sep),
        "did_eu_card_vs_non_eu_card_pp": did_pp,
        "method": "Two-proportion z-tests on monthly logo churn (pooled Mar-Aug baseline); Wilson 95% intervals; "
                  "difference-in-differences on pooled Jun-Aug vs Sep-Oct rates from query 10.",
    }


def main():
    conn = sqlite3.connect(f"file:{DB}?mode=ro", uri=True)
    q = run_all(conn)
    out = {"queries": q, "significance": significance(q)}
    OUT.write_text(json.dumps(out, indent=1))
    print(f"wrote {OUT.relative_to(ROOT)} ({len(q)} queries)")


if __name__ == "__main__":
    main()
