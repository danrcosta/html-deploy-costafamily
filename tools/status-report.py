#!/usr/bin/env python3
"""costafamily.ai uptime + broken-link validator → HTML report."""
import datetime
import html
import json
import re
import sys
from pathlib import Path
from urllib.parse import urljoin, urlparse

try:
    import requests
except ImportError:
    requests = None

BASE_URL = "https://costafamily.ai"
REPORT_DIR = Path.home() / "Hermes-Workspace" / "reports"
REPORT_DIR.mkdir(parents=True, exist_ok=True)


def fetch(url: str) -> tuple[int, str]:
    if requests is None:
        return -1, "requests library not installed"
    try:
        r = requests.get(url, timeout=20, allow_redirects=True)
        return r.status_code, r.text
    except Exception as e:
        return -1, str(e)


def extract_links(base_url: str, html_text: str) -> list[str]:
    links = []
    for m in re.finditer(r'href=["\'](.*?)["\']', html_text, re.IGNORECASE):
        href = m.group(1).strip()
        if href.startswith("#") or href.startswith("javascript:") or href.startswith("mailto:"):
            continue
        links.append(urljoin(base_url, href))
    return links


def validate_links(base_url: str, html_text: str, limit: int = 50) -> list[dict]:
    links = extract_links(base_url, html_text)
    results = []
    seen = set()
    for link in links[:limit]:
        if link in seen:
            continue
        seen.add(link)
        status, _ = fetch(link)
        results.append({"url": link, "status": status})
    return results


def build_report(base_status: int, links: list[dict]) -> str:
    ts = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    ok = sum(1 for l in links if l["status"] == 200)
    fail = sum(1 for l in links if l["status"] != 200)

    rows = ""
    for l in links:
        status_label = str(l["status"]) if l["status"] >= 0 else "ERR"
        css = "ok" if l["status"] == 200 else "fail"
        rows += f'<tr><td class="url">{html.escape(l["url"])}</td><td class="{css}">{status_label}</td></tr>\n'

    return f"""<!DOCTYPE html>
<html lang="pt-BR">
<head>
<meta charset="utf-8">
<title>costafamily.ai — Status Report</title>
<style>
  :root {{ --bg:#0a0a0a; --fg:#e5e5e5; --muted:#a3a3a3; --accent:#d4af37; --border:#262626; --card:#171717; }}
  * {{ box-sizing:border-box; }}
  body {{ margin:0; background:var(--bg); color:var(--fg); font-family:ui-sans-serif,system-ui,sans-serif; }}
  .container {{ max-width:980px; margin:0 auto; padding:24px; }}
  .header {{ border-bottom:1px solid var(--border); padding-bottom:16px; margin-bottom:24px; }}
  .badge {{ display:inline-block; padding:4px 10px; border-radius:9999px; font-size:12px; font-weight:600; border:1px solid var(--border); color:var(--muted); }}
  .badge.ok {{ color:#22c55e; border-color:#22c55e; }}
  .badge.fail {{ color:#ef4444; border-color:#ef4444; }}
  .kpis {{ display:grid; grid-template-columns:repeat(3,1fr); gap:12px; margin:16px 0; }}
  .kpi {{ background:var(--card); border:1px solid var(--border); border-radius:12px; padding:16px; }}
  .kpi .num {{ font-size:28px; font-weight:700; }}
  .kpi .lbl {{ font-size:12px; color:var(--muted); text-transform:uppercase; letter-spacing:.08em; }}
  table {{ width:100%; border-collapse:collapse; font-size:13px; }}
  th {{ text-align:left; padding:8px 10px; color:var(--muted); border-bottom:1px solid var(--border); }}
  td {{ padding:8px 10px; border-bottom:1px solid var(--border); }}
  .url {{ word-break:break-all; color:#d4d4d4; }}
</style>
</head>
<body>
<div class="container">
  <div class="header">
    <h1 style="margin:0 0 6px">costafamily.ai</h1>
    <div style="display:flex; gap:8px; align-items:center;">
      <span class="badge">Report</span>
      <span class="badge">Generated {ts}</span>
    </div>
  </div>

  <div class="kpis">
    <div class="kpi">
      <div class="num">{base_status}</div>
      <div class="lbl">Base HTTP Status</div>
    </div>
    <div class="kpi">
      <div class="num" style="color:#22c55e">{ok}</div>
      <div class="lbl">Links OK</div>
    </div>
    <div class="kpi">
      <div class="num" style="color:#ef4444">{fail}</div>
      <div class="lbl">Links Failed</div>
    </div>
  </div>

  <h2 style="margin-top:28px">Link validation</h2>
  <table>
    <thead><tr><th>URL</th><th>Status</th></tr></thead>
    <tbody>
      {rows if rows else '<tr><td colspan="2" style="color:var(--muted)">No links found or validation skipped.</td></tr>'}
    </tbody>
  </table>
</div>
</body>
</html>
"""


def main() -> int:
    base_status, base_html = fetch(BASE_URL)
    links = validate_links(BASE_URL, base_html)
    report = build_report(base_status, links)

    out = REPORT_DIR / f"costafamily-status-{datetime.date.today().isoformat()}.html"
    out.write_text(report, encoding="utf-8")
    print(f"REPORT_WRITTEN={out}")
    print(f"BASE_STATUS={base_status}")
    print(f"LINK_OK={sum(1 for l in links if l['status']==200)}")
    print(f"LINK_FAIL={sum(1 for l in links if l['status']!=200)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
