import json
from pathlib import Path
import html

repo_root = Path(__file__).resolve().parents[1]
data_path = repo_root / 'data' / 'projects.json'
out_root = repo_root / 'projects'

def escape(s):
    return html.escape(str(s or ''))

def template(p):
    og_image = p.get('images', [None])[0] or '/assets/Headshot.jpg'
    images_html = '\n'.join([f'<figure style="margin:0 0 12px"><img src="{escape(img)}" alt="{escape(p.get("title"))}" style="max-width:100%;border-radius:8px;display:block"/></figure>' for img in p.get('images', [])])
    tags_html = ''.join([f'<span style="display:inline-block;background:rgba(255,255,255,0.03);padding:6px 10px;border-radius:999px;margin-right:8px;font-size:13px;color:#9aaebf">{escape(t)}</span>' for t in p.get('tags', [])])

    return f'''<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width,initial-scale=1">
  <title>{escape(p.get('title'))} · Danny Elizur</title>
  <meta name="description" content="{escape(p.get('subtitle') or p.get('description') or '')}">
  <meta property="og:title" content="{escape(p.get('title'))}">
  <meta property="og:description" content="{escape(p.get('subtitle') or p.get('description') or '')}">
  <meta property="og:image" content="{escape(og_image)}">
  <link rel="icon" href="/assets/favicon.png">
  <style>
    body{{font-family:ui-sans-serif,system-ui,Segoe UI,Roboto,Helvetica,Arial;background:#0b1016;color:#e5e7eb;margin:0;padding:24px}}
    a{{color:#60a5fa}}
    .card{{background:#0f172a;border-radius:12px;padding:20px;max-width:1000px;margin:24px auto;border:1px solid rgba(148,163,184,.08)}}
    img{{max-width:100%;height:auto;border-radius:8px;display:block}}
    .row{{display:flex;gap:8px;flex-wrap:wrap;margin-top:12px}}
    .tags{{margin:10px 0}}
  </style>
</head>
<body>
  <div class="card">
    <h1>{escape(p.get('title'))}</h1>
    <p style="color:#94a3b8;margin-top:4px">{escape(p.get('subtitle') or '')}</p>
    <div class="tags">{tags_html}</div>
    {images_html}
    <p style="color:#cbd5e1">{escape(p.get('description') or '')}</p>
    <div class="row">
      <a href="/">← Back to home</a>
      {f'<a href="{escape(p.get("github"))}" target="_blank" rel="noopener">View on GitHub</a>' if p.get('github') else ''}
      {f'<a href="{escape(p.get("demo"))}" target="_blank" rel="noopener">Live demo</a>' if p.get('demo') else ''}
    </div>
  </div>
</body>
</html>'''

def main():
    if not data_path.exists():
        print('Data file not found:', data_path)
        return
    projects = json.loads(data_path.read_text(encoding='utf8'))
    out_root.mkdir(parents=True, exist_ok=True)
    for p in projects:
        slug = p.get('slug')
        if not slug:
            print('Skipping project with no slug', p.get('title'))
            continue
        dir = out_root / slug
        dir.mkdir(parents=True, exist_ok=True)
        html_text = template(p)
        (dir / 'index.html').write_text(html_text, encoding='utf8')
        print('Wrote', slug)

if __name__ == '__main__':
    main()
