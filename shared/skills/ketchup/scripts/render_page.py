#!/usr/bin/env python3
"""Render a ketchup catch-up page from a JSON content file.

Usage: python3 render_page.py CONTENT.json --out PAGE.html

The agent writes only the content (see ../assets/example.json); this script owns
the layout, the section order, and the colors, so every page looks the same.
Text fields accept **bold**, `code`, and [text](link); a link that starts with
"/" points to a local file. Blank lines split paragraphs.
Warnings (missing fields, unknown values, missing media files) go to stderr.
"""
import argparse
import html
import json
import os
import re
import sys
from urllib.parse import quote

VIDEO = (".mp4", ".webm", ".mov", ".m4v")
# Ioskeley Mono (SIL Open Font License 1.1, github.com/ahatem/IoskeleyMono), served by jsDelivr.
FONT_URL = "https://cdn.jsdelivr.net/gh/ahatem/IoskeleyMono@v2.2.0/site/fonts"
FACES = (("IoskeleyMono-Regular.woff2", 400, "normal"), ("IoskeleyMono-Italic.woff2", 400, "italic"), ("IoskeleyMono-Bold.woff2", 700, "normal"))
STATES = {
    # value: (css class, symbol, label)
    "needs-you": ("attn", "!", "needs you"),
    "done": ("ok", "✓", "done"),
    "running": ("info", "▶", "running"),
    "working": ("info", "▶", "working"),
    "waiting": ("attn", "…", "waiting on you"),
    "blocked": ("bad", "■", "blocked"),
    "failed": ("bad", "✕", "failed"),
    "crashed": ("bad", "✕", "crashed"),
    "gone": ("muted", "–", "gone"),
    "idle": ("muted", "○", "idle"),
    "unknown": ("muted", "?", "unknown"),
    "ok": ("ok", "✓", "ok"),
    "warn": ("attn", "!", "watch"),
    "bad": ("bad", "■", "problem"),
}
warnings = []


def warn(msg):
    warnings.append(msg)


def link(url):
    return "file://" + quote(url) if url.startswith("/") else url


def inline(text):
    """Escape text, then apply `code`, **bold**, and [text](link)."""
    if text is None:
        return ""
    parts = re.split(r"(`[^`]+`)", str(text))
    out = []
    for part in parts:
        if part.startswith("`") and part.endswith("`") and len(part) > 1:
            out.append("<code>" + html.escape(part[1:-1]) + "</code>")
            continue
        s = html.escape(part, quote=False)
        s = re.sub(r"\*\*(.+?)\*\*", r"<strong>\1</strong>", s)
        s = re.sub(
            r"\[([^\]]+)\]\(([^)\s]+)\)",
            lambda m: f'<a href="{html.escape(link(html.unescape(m.group(2))))}">{m.group(1)}</a>',
            s,
        )
        out.append(s)
    return "".join(out)


def paras(text):
    if not text:
        return ""
    return "".join(f"<p>{inline(p.strip())}</p>" for p in str(text).split("\n\n") if p.strip())


def badge(value, where):
    key = str(value or "unknown").lower()
    if key not in STATES:
        warn(f"{where}: unknown state '{value}', shown as unknown; use one of {', '.join(STATES)}")
        key = "unknown"
    cls, sym, label = STATES[key]
    return f'<span class="badge {cls}"><span aria-hidden="true">{sym}</span> {label}</span>'


def field(item, key, where, required=True):
    value = item.get(key)
    if required and not value:
        warn(f"{where}: missing '{key}'")
    return value


def media(items, where):
    if not items:
        return ""
    cells = []
    for i, m in enumerate(items):
        path = m.get("path", "")
        cap = inline(m.get("caption", ""))
        if not path.startswith("/"):
            warn(f"{where} media {i + 1}: use an absolute path, got '{path}'")
        if not os.path.exists(path):
            warn(f"{where} media {i + 1}: file not found: {path}")
            body = f'<div class="missing">File not found: <code>{html.escape(path)}</code></div>'
        elif path.lower().endswith(VIDEO):
            body = f'<video controls preload="metadata" src="{html.escape(link(path))}"></video>'
        else:
            body = f'<a href="{html.escape(link(path))}"><img loading="lazy" src="{html.escape(link(path))}" alt=""></a>'
        cells.append(f"<figure>{body}<figcaption>{cap}</figcaption></figure>")
    return f'<div class="media">{"".join(cells)}</div>'


def font_css():
    """Ioskeley Mono: an installed copy first, then the web copy (needs internet), else the system monospace font."""
    rules = []
    for name, weight, style in FACES:
        stem = name.rsplit(".", 1)[0]
        full = "Ioskeley Mono " + stem.split("-", 1)[1]
        rules.append(
            '@font-face{font-family:"Ioskeley Mono";font-weight:%d;font-style:%s;font-display:swap;'
            'src:local("%s"),local("%s"),url("%s/%s") format("woff2")}' % (weight, style, full, stem, FONT_URL, name)
        )
    return "".join(rules)


def section(sid, title, body, count=None):
    if not body:
        return ""
    n = f' <span class="count">{count}</span>' if count else ""
    return f'<section id="{sid}"><h2>{title}{n}</h2>{body}</section>'


def render(c):
    for key in c:
        if key not in KNOWN:
            warn(f"unknown top-level field '{key}' is ignored")
    needs = c.get("needs_you") or []
    done_name = c.get("done_in_your_name") or []
    said = c.get("your_messages") or []
    streams = c.get("workstreams") or []
    workers = c.get("workers") or []
    beliefs = c.get("changed_beliefs") or []
    resources = c.get("resources") or []
    words = c.get("glossary") or []
    hand = c.get("handoff") or {}
    for k in ("project", "lead", "written_at", "headline"):
        field(c, k, "page")
    for k in ("time", "quote", "goal"):
        field(hand, k, "handoff")

    # Needs you
    cards = []
    for i, n in enumerate(needs, 1):
        w = f"needs_you {i}"
        opts = n.get("options") or []
        if len(opts) < 2:
            warn(f"{w}: give at least two options, including leaving it as it is")
        rows = "".join(
            f"<tr><th>{inline(o.get('name'))}</th><td>{inline(o.get('gain'))}</td><td>{inline(o.get('cost'))}</td></tr>"
            for o in opts
        )
        table = f'<table class="opts"><thead><tr><th>Option</th><th>Gets you</th><th>Costs</th></tr></thead><tbody>{rows}</tbody></table>' if rows else ""
        urgent = '<span class="badge bad"><span aria-hidden="true">■</span> urgent</span> ' if n.get("urgent") else ""
        cards.append(
            f'<li class="card attn-edge"><h3>{urgent}{inline(field(n, "title", w))}</h3>'
            f'{paras(field(n, "what", w))}'
            f'<p class="pick"><strong>My pick:</strong> {inline(field(n, "pick", w))}. {inline(n.get("why"))}</p>{table}</li>'
        )
    needs_html = f'<ol class="cards">{"".join(cards)}</ol>' if cards else ""
    if not needs:
        needs_html = '<p class="none">Nothing waits on you.</p>'

    # Done in your name
    rows = []
    for i, d in enumerate(done_name, 1):
        w = f"done_in_your_name {i}"
        undo = d.get("undo")
        irreversible = d.get("reversible") is False
        tag = '<span class="badge bad"><span aria-hidden="true">✕</span> cannot be undone</span> ' if irreversible else ""
        rows.append(f"<tr><td>{tag}{inline(field(d, 'what', w))}</td><td>{inline(field(d, 'why', w))}</td><td>{inline(undo) if undo else '–'}</td></tr>")
    done_html = f'<table><thead><tr><th>What was done</th><th>Why</th><th>How to undo</th></tr></thead><tbody>{"".join(rows)}</tbody></table>' if rows else ""

    # What the user said during the work
    rows = "".join(
        f"<tr><td class='nowrap'>{inline(s.get('time'))}</td><td>{inline(s.get('said'))}</td><td>{inline(s.get('outcome'))}</td></tr>"
        for s in said
    )
    said_html = f'<table><thead><tr><th>When</th><th>You said</th><th>What came of it</th></tr></thead><tbody>{rows}</tbody></table>' if rows else ""

    # Workstreams
    blocks = []
    for i, s in enumerate(streams, 1):
        w = f"workstream {i}"
        steps = "".join(
            f'<li><span class="when">{inline(st.get("time"))}</span> <strong>{inline(st.get("did"))}</strong>'
            f'{" Found: " + inline(st.get("found")) if st.get("found") else ""}'
            f'{" <em>Why next:</em> " + inline(st.get("why_next")) if st.get("why_next") else ""}</li>'
            for st in (s.get("steps") or [])
        )
        evidence = "".join(f"<li>{inline(e)}</li>" for e in (s.get("evidence") or []))
        blocks.append(
            f'<article class="stream"><h3>{badge(s.get("status"), w)} {inline(field(s, "goal", w))}</h3>'
            f'<div class="result">{paras(field(s, "result", w))}</div>'
            f'{"<h4>Steps</h4><ol class=steps>" + steps + "</ol>" if steps else ""}'
            f'{media(s.get("media"), w)}'
            f'{"<h4>How strong the evidence is</h4><ul>" + evidence + "</ul>" if evidence else ""}'
            f'<dl><dt>How far from done</dt><dd>{inline(field(s, "distance", w))}</dd>'
            f'<dt>Next, without you</dt><dd>{inline(s.get("next") or "nothing")}</dd></dl></article>'
        )
    streams_html = "".join(blocks)

    rows = "".join(
        f"<tr><td><code>{html.escape(str(x.get('name', '')))}</code></td><td>{inline(x.get('task'))}</td>"
        f"<td>{badge(x.get('state'), 'worker ' + str(x.get('name')))}</td><td>{inline(x.get('last_result'))}</td>"
        f"<td class='nowrap'>{inline(x.get('where'))}</td></tr>"
        for x in workers
    )
    workers_html = f'<table><thead><tr><th>Worker</th><th>Task</th><th>State</th><th>Last result</th><th>Where</th></tr></thead><tbody>{rows}</tbody></table>' if rows else ""

    rows = "".join(
        f"<tr><td>{inline(b.get('before'))}</td><td>{inline(b.get('now'))}</td><td>{inline(b.get('affects'))}</td></tr>"
        for b in beliefs
    )
    beliefs_html = f'<table><thead><tr><th>We thought</th><th>Now we know</th><th>What it changes</th></tr></thead><tbody>{rows}</tbody></table>' if rows else ""

    rows = "".join(
        f"<tr><td>{badge(r.get('level'), 'resource')}</td><td>{inline(r.get('what'))}</td><td>{inline(r.get('state'))}</td></tr>"
        for r in resources
    )
    res_html = f"<table><tbody>{rows}</tbody></table>" if rows else ""

    words_html = "<dl class='words'>" + "".join(
        f"<dt>{inline(g.get('term'))}</dt><dd>{inline(g.get('meaning'))}</dd>" for g in words
    ) + "</dl>" if words else ""

    lead = f"Lead: <code>{html.escape(str(c.get('lead', '')))}</code>"
    if c.get("parent_lead"):
        lead += f", started by <code>{html.escape(str(c['parent_lead']))}</code>"
    prev = f' Earlier catch-up: {inline(c["previous_catchup"])}.' if c.get("previous_catchup") else ""
    chips = (
        f'<a class="chip attn" href="#needs">{len(needs)} need you</a>'
        f'<a class="chip bad" href="#done-in-your-name">{len(done_name)} done in your name</a>'
        f'<a class="chip" href="#what-happened">{len(streams)} workstreams</a>'
        f'<a class="chip" href="#workers">{len(workers)} workers</a>'
    )
    body = (
        f'<header><p class="meta">{inline(c.get("project"))} · catch-up written {inline(c.get("written_at"))} · {lead}</p>'
        f'<h1>{inline(c.get("headline"))}</h1>'
        f'<div class="handoff"><p><strong>Covers the work since your hand-off</strong> on {inline(hand.get("time"))}:</p>'
        f'<blockquote>{inline(hand.get("quote"))}</blockquote><p><strong>Goal:</strong> {inline(hand.get("goal"))}{prev}</p></div>'
        f'<nav>{chips}</nav></header>'
        + section("needs", "Needs you", needs_html, len(needs) or None)
        + section("done-in-your-name", "Done in your name", done_html, len(done_name) or None)
        + section("you-said", "What you said during the work", said_html)
        + section("what-happened", "What happened", streams_html)
        + section("workers", "Workers", workers_html)
        + section("changed-beliefs", "Changed beliefs", beliefs_html)
        + section("resources", "Resources", res_html)
        + section("words", "Words used on this page", words_html)
    )
    title = html.escape(f"Catch-up: {c.get('project', '')} {c.get('written_at', '')}")
    return f'<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1"><title>{title}</title><style>{font_css()}{CSS}</style></head><body><main>{body}</main></body></html>'


KNOWN = {"project", "lead", "parent_lead", "written_at", "headline", "handoff", "previous_catchup", "needs_you",
         "done_in_your_name", "your_messages", "workstreams", "workers", "changed_beliefs", "resources", "glossary"}

CSS = """
:root{color-scheme:dark;--bg:#000;--card:#0e0f11;--text:#e8e9ec;--muted:#9097a3;--line:#2a2d33;--code:#1b1d22;
--attn:#f0b45a;--attn-bg:#33270f;--bad:#ff8a80;--bad-bg:#3a1714;--ok:#6fd38b;--ok-bg:#122a19;--info:#8ab4f8;--info-bg:#15233a;--muted-bg:#1f2126}
*{box-sizing:border-box}body{margin:0;background:var(--bg);color:var(--text);font:15px/1.6 "Ioskeley Mono",ui-monospace,"SF Mono",Menlo,Consolas,monospace}
main{max-width:1000px;margin:0 auto;padding:32px 20px 80px}
h1{font-size:1.75rem;line-height:1.25;margin:.3em 0 .6em}h2{font-size:1.3rem;margin:2.2em 0 .7em;padding-bottom:.3em;border-bottom:1px solid var(--line)}
h3{font-size:1.08rem;margin:0 0 .5em}h4{font-size:.95rem;margin:1.2em 0 .4em;color:var(--muted)}
p{margin:.45em 0}a{color:var(--info)}code{font-family:inherit;background:var(--code);padding:.08em .35em;border-radius:4px;font-size:.92em}
.meta{color:var(--muted);font-size:.9rem;margin:0}
.handoff{background:var(--card);border:1px solid var(--line);border-radius:10px;padding:14px 18px;margin:12px 0}
blockquote{margin:.4em 0;padding:.2em .9em;border-left:3px solid var(--line);color:var(--muted);font-style:italic}
nav{display:flex;flex-wrap:wrap;gap:8px;margin-top:14px}
.chip{border:1px solid var(--line);border-radius:999px;padding:3px 12px;font-size:.88rem;text-decoration:none;color:var(--text);background:var(--card)}
.chip.attn{border-color:var(--attn);color:var(--attn)}.chip.bad{border-color:var(--bad);color:var(--bad)}
.count{display:inline-block;min-width:1.6em;text-align:center;font-size:.8rem;background:var(--attn-bg);color:var(--attn);border-radius:999px;padding:1px 7px;vertical-align:middle}
.cards{padding-left:1.4em}.card{background:var(--card);border:1px solid var(--line);border-radius:10px;padding:14px 18px;margin:0 0 14px}
.attn-edge{border-left:5px solid var(--attn)}.pick{background:var(--attn-bg);border-radius:6px;padding:6px 10px}
.none{color:var(--ok);font-weight:600}
table{width:100%;border-collapse:collapse;margin:.5em 0;background:var(--card);border:1px solid var(--line);border-radius:8px;font-size:.94rem}
th,td{text-align:left;vertical-align:top;padding:8px 10px;border-bottom:1px solid var(--line)}thead th{font-size:.82rem;color:var(--muted);font-weight:600}
table.opts tbody th{white-space:nowrap}.nowrap{white-space:nowrap}
.badge{display:inline-block;font-size:.78rem;font-weight:700;padding:1px 8px;border-radius:999px;white-space:nowrap;vertical-align:middle}
.badge.attn{background:var(--attn-bg);color:var(--attn)}.badge.bad{background:var(--bad-bg);color:var(--bad)}
.badge.ok{background:var(--ok-bg);color:var(--ok)}.badge.info{background:var(--info-bg);color:var(--info)}.badge.muted{background:var(--muted-bg);color:var(--muted)}
.stream{background:var(--card);border:1px solid var(--line);border-radius:10px;padding:16px 18px;margin:0 0 16px}
.result{font-size:1.02rem}.steps li{margin:.3em 0}.when{color:var(--muted);font-size:.85rem;font-variant-numeric:tabular-nums}
dl{display:grid;grid-template-columns:max-content 1fr;gap:4px 14px;margin:.8em 0 0}dt{color:var(--muted);font-size:.9rem}dd{margin:0}
dl.words dt{color:var(--text);font-weight:600}
.media{display:grid;grid-template-columns:repeat(auto-fit,minmax(280px,1fr));gap:12px;margin:12px 0}
figure{margin:0}img,video{width:100%;border-radius:6px;border:1px solid var(--line);background:#000}figcaption{font-size:.85rem;color:var(--muted);margin-top:4px}
.missing{padding:20px;border:1px dashed var(--bad);color:var(--bad);border-radius:6px;font-size:.9rem}
@media (max-width:640px){th,td{padding:6px}dl{grid-template-columns:1fr}}
"""


def main():
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("content", help="JSON content file")
    ap.add_argument("--out", required=True, help="HTML page to write")
    a = ap.parse_args()
    with open(a.content, encoding="utf-8") as f:
        content = json.load(f)
    page = render(content)
    os.makedirs(os.path.dirname(os.path.abspath(a.out)), exist_ok=True)
    with open(a.out, "w", encoding="utf-8") as f:
        f.write(page)
    for w in warnings:
        print("warning:", w, file=sys.stderr)
    print(os.path.abspath(a.out))


if __name__ == "__main__":
    main()
