const fs = require('fs');
const path = require('path');

const dataPath = path.join(__dirname, '..', 'data', 'projects.json');
const outRoot = path.join(__dirname, '..', 'projects');

function escapeHtml(s = ''){
  return String(s)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;');
}

function template(p){
  const ogImage = p.images && p.images.length ? p.images[0] : '/assets/Headshot.jpg';
  const imagesHtml = (p.images||[]).map(img=>{
    return `<figure style="margin:0 0 12px"><img src="${escapeHtml(img)}" alt="${escapeHtml(p.title)}" style="max-width:100%;border-radius:8px;display:block"/></figure>`;
  }).join('\n');
  const tagsHtml = (p.tags||[]).map(t=>`<span style="display:inline-block;background:rgba(255,255,255,0.03);padding:6px 10px;border-radius:999px;margin-right:8px;font-size:13px;color:#9aaebf">${escapeHtml(t)}</span>`).join('');

  return `<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width,initial-scale=1">
  <title>${escapeHtml(p.title)} · Danny Elizur</title>
  <meta name="description" content="${escapeHtml(p.subtitle || p.description || '')}">
  <meta property="og:title" content="${escapeHtml(p.title)}">
  <meta property="og:description" content="${escapeHtml(p.subtitle || p.description || '')}">
  <meta property="og:image" content="${escapeHtml(ogImage)}">
  <link rel="icon" href="/assets/favicon.png">
  <style>
    body{font-family:ui-sans-serif,system-ui,Segoe UI,Roboto,Helvetica,Arial;background:#0b1016;color:#e5e7eb;margin:0;padding:24px}
    a{color:#60a5fa}
    .card{background:#0f172a;border-radius:12px;padding:20px;max-width:1000px;margin:24px auto;border:1px solid rgba(148,163,184,.08)}
    img{max-width:100%;height:auto;border-radius:8px;display:block}
    .row{display:flex;gap:8px;flex-wrap:wrap;margin-top:12px}
    .tags{margin:10px 0}
  </style>
</head>
<body>
  <div class="card">
    <h1>${escapeHtml(p.title)}</h1>
    <p style="color:#94a3b8;margin-top:4px">${escapeHtml(p.subtitle || '')}</p>
    <div class="tags">${tagsHtml}</div>
    ${imagesHtml}
    <p style="color:#cbd5e1">${escapeHtml(p.description || '')}</p>
    <div class="row">
      <a href="/">← Back to home</a>
      ${p.github?`<a href="${escapeHtml(p.github)}" target="_blank" rel="noopener">View on GitHub</a>`:''}
      ${p.demo?`<a href="${escapeHtml(p.demo)}" target="_blank" rel="noopener">Live demo</a>`:''}
    </div>
  </div>
</body>
</html>`;
}

function main(){
  if(!fs.existsSync(dataPath)){
    console.error('Data file not found:', dataPath);
    process.exit(1);
  }
  const raw = fs.readFileSync(dataPath, 'utf8');
  const projects = JSON.parse(raw);
  if(!fs.existsSync(outRoot)) fs.mkdirSync(outRoot, { recursive: true });

  projects.forEach(p => {
    const dir = path.join(outRoot, p.slug);
    if(!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true });
    const html = template(p);
    fs.writeFileSync(path.join(dir, 'index.html'), html, 'utf8');
    console.log('Wrote', p.slug);
  });
}

main();
