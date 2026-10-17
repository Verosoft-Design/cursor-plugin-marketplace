// Builds the Q&A bot's knowledge and the site pages from the spec folder.
// Run from the site folder: node scripts/build-knowledge.mjs
//
// Reads site.config.json, collects every .md under specDir (except this site's
// own folder) and under each guideDirs entry, and turns each screen page's
// "What to review" note into screens/<slug>.md. Security rows (IDs starting with
// SEC) and <!-- internal --> … <!-- /internal --> blocks never reach the bot, and any
// security ID left anywhere else stops the build.
// Everything is checked for customer names and secrets first.
//
// Exit 0: written. Exit 1: a name or secret was found, nothing written.
// Exit 2: no customer-name list on this machine, nothing written.
// Names come from VSD_CUSTOMER_NAMES (comma or newline separated) or
// ~/.config/verosoft/customer-names.txt. This file never lists any.
import { existsSync, readFileSync, readdirSync, rmSync, statSync, writeFileSync } from 'node:fs';
import { homedir } from 'node:os';
import { basename, dirname, join, relative, resolve, sep } from 'node:path';
import { fileURLToPath } from 'node:url';

const site = join(dirname(fileURLToPath(import.meta.url)), '..');
const config = JSON.parse(readFileSync(join(site, 'site.config.json'), 'utf8'));
const specDir = resolve(site, config.specDir ?? '..');
const guideDirs = (config.guideDirs ?? []).map((d) => resolve(site, d));
const outputs = {
  knowledge: join(site, 'api', '_knowledge.generated.ts'),
  site: join(site, 'api', '_site.generated.ts'),
  ask: join(site, 'ask.html'),
  index: join(site, 'index.html'),
};

for (const dir of [specDir, ...guideDirs]) {
  if (!existsSync(dir) || !statSync(dir).isDirectory()) {
    console.error(`folder not found: ${dir} (check specDir and guideDirs in site.config.json)`);
    process.exit(1);
  }
}

// Never leave an older build behind if this one stops.
for (const path of Object.values(outputs)) rmSync(path, { force: true });

function loadNames() {
  const raw = process.env.VSD_CUSTOMER_NAMES
    ? process.env.VSD_CUSTOMER_NAMES.split(/[,\n]/)
    : (() => {
        const file = join(process.env.HOME || homedir(), '.config', 'verosoft', 'customer-names.txt');
        return existsSync(file) ? readFileSync(file, 'utf8').split('\n') : [];
      })();
  return raw.map((n) => n.trim()).filter((n) => n && !n.startsWith('#'));
}

const names = loadNames();
if (names.length === 0) {
  console.error('no customer-name list (set VSD_CUSTOMER_NAMES or create ~/.config/verosoft/customer-names.txt)');
  process.exit(2);
}

const escapeRe = (s) => s.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
const nameRes = names.map((n) => new RegExp(`(?<![A-Za-z0-9])${escapeRe(n)}(?![A-Za-z0-9])`, 'i'));
const secretRes = [
  [/https?:\/\/[^\s/]*:[^\s/]*@/i, 'URL with credentials'],
  [/\b(api[_-]?key|secret|password|passwd|token)\s*[:=]\s*\S+/i, 'key=value secret'],
  [/BEGIN [A-Z ]*PRIVATE KEY/, 'private key'],
  [/\b(sk-ant-|sk_live_|ghp_|gho_|xox[bp]-|AKIA[0-9A-Z]{12}|vcp_|AIza)[A-Za-z0-9]/, 'token'],
  [/^[A-Z][A-Z0-9_]{2,}=\S+/, '.env line'],
];
// Any security ID still in the text after stripping stops the build: mark it internal instead.
const securityIdRe = /(?<![A-Za-z0-9])SEC[\w-]*\d+(?![A-Za-z0-9])/;

// Drop security rows and internal blocks: they must never be answerable publicly.
function strip(text) {
  const out = [];
  let internal = false;
  for (const line of text.split('\n')) {
    if (/<!--\s*internal\s*-->/i.test(line)) { internal = true; continue; }
    if (/<!--\s*\/internal\s*-->/i.test(line)) { internal = false; continue; }
    if (internal) continue;
    if (/^\s*\|?\s*SEC[\w-]*\d+\s*\|/i.test(line)) continue;
    out.push(line);
  }
  return out.join('\n');
}

function walk(dir, skip) {
  const files = [];
  for (const entry of readdirSync(dir)) {
    if (entry === 'node_modules' || entry.startsWith('.')) continue;
    const full = join(dir, entry);
    if (statSync(full).isDirectory()) {
      if (full === skip) continue;
      files.push(...walk(full, skip));
    } else if (entry.endsWith('.md')) {
      files.push(full);
    }
  }
  return files;
}

const toPosix = (p) => p.split(sep).join('/');
const docs = [];
for (const file of walk(specDir, resolve(site))) {
  docs.push({ path: toPosix(relative(specDir, file)), content: strip(readFileSync(file, 'utf8')) });
}
for (const dir of guideDirs) {
  for (const file of walk(dir, resolve(site))) {
    docs.push({ path: `guide/${toPosix(relative(dir, file))}`, content: strip(readFileSync(file, 'utf8')) });
  }
}

// Screen pages: every .html here except the site's own pages, if it has a review note.
const entities = { '&amp;': '&', '&lt;': '<', '&gt;': '>', '&quot;': '"', '&#39;': "'", '&nbsp;': ' ' };
const decode = (s) => s.replace(/&(amp|lt|gt|quot|#39|nbsp);/g, (m) => entities[m]);
const inline = (html) =>
  decode(
    html
      .replace(/<(b|strong)>(.*?)<\/\1>/gs, '**$2**')
      .replace(/<(i|em)>(.*?)<\/\1>/gs, '*$2*')
      .replace(/<code>(.*?)<\/code>/gs, '`$1`')
      .replace(/<[^>]+>/g, '')
      .replace(/\s+/g, ' ')
      .trim(),
  );
const screens = {};
const sitePages = new Set(['index.html', 'ask.html']);
for (const file of readdirSync(site).filter((f) => f.endsWith('.html') && !sitePages.has(f)).sort()) {
  const html = readFileSync(join(site, file), 'utf8');
  const block = html.match(/<details class="review"[^>]*>([\s\S]*?)<\/details>/);
  if (!block) continue;
  const slug = basename(file, '.html');
  const name = inline(html.match(/<title>([\s\S]*?)<\/title>/)?.[1] ?? slug).split(' · ')[0] || slug;
  screens[slug] = name;
  const items = [...block[1].matchAll(/<li>([\s\S]*?)<\/li>/g)].map((m) => inline(m[1]));
  docs.push({
    path: `screens/${slug}.md`,
    content: [
      `# Design screen: ${name}`,
      '',
      `- URL path: /${slug}.html`,
      `- Note header: ${inline(block[1].match(/<summary>([\s\S]*?)<\/summary>/)?.[1] ?? '')}`,
      '',
      '## What to review',
      '',
      ...items.map((t, i) => `${i + 1}. ${t}`),
      '',
    ].join('\n'),
  });
}

// Check everything before writing anything: the bot's documents, every file the
// site deploys (screen pages, styles, scripts), and the config values that end up
// in the pages and the bot's prompt.
const generated = new Set(Object.values(outputs));
function deployedFiles(dir) {
  const files = [];
  for (const entry of readdirSync(dir)) {
    if (entry === 'node_modules' || entry === 'scripts' || entry.startsWith('.')) continue;
    const full = join(dir, entry);
    if (statSync(full).isDirectory()) files.push(...deployedFiles(full));
    else if (/\.(html|css|js|mjs|ts|json|md|svg|txt)$/.test(entry) && !generated.has(full)) files.push(full);
  }
  return files;
}
const checks = docs.map((d) => ({ path: d.path, content: d.content }));
for (const file of deployedFiles(site)) {
  checks.push({ path: toPosix(relative(site, file)), content: readFileSync(file, 'utf8') });
}
const configText = [config.feature, config.issue, config.approver, ...(config.examples ?? []).map((e) => e.text)]
  .filter(Boolean)
  .join('\n');
checks.push({ path: 'site.config.json (values)', content: configText });

let hits = 0;
for (const doc of checks) {
  doc.content.split('\n').forEach((line, i) => {
    if (nameRes.some((re) => re.test(line))) {
      hits++;
      console.error(`REDACT? ${doc.path}:${i + 1} contains a customer name`);
    }
    if (securityIdRe.test(line)) {
      hits++;
      console.error(`REDACT? ${doc.path}:${i + 1} mentions a security finding; wrap it in <!-- internal --> … <!-- /internal -->`);
    }
    for (const [re, what] of secretRes) {
      if (re.test(line)) {
        hits++;
        console.error(`REDACT? ${doc.path}:${i + 1} looks like a ${what}`);
      }
    }
  });
}
if (hits) {
  console.error(`Nothing written: ${hits} redaction hit(s).`);
  process.exit(1);
}

// Binding rules first, then the reasoning and answers, the screens, the guide, the rest.
const rank = (p) =>
  p === 'decisions.md' ? 0 : p === 'decision-log.md' ? 1 : p === 'team-faq.md' ? 2
    : p.startsWith('screens/') ? 3 : p.startsWith('guide/') ? 4 : 5;
docs.sort((a, b) => rank(a.path) - rank(b.path) || a.path.localeCompare(b.path));

writeFileSync(
  outputs.knowledge,
  `// Generated by scripts/build-knowledge.mjs. Do not edit by hand.\n` +
    `export const DOCS: ReadonlyArray<{ path: string; content: string }> = ${JSON.stringify(docs, null, 1)};\n`,
);
const siteInfo = { feature: config.feature, issue: config.issue, approver: config.approver, screens };
writeFileSync(
  outputs.site,
  `// Generated by scripts/build-knowledge.mjs. Do not edit by hand.\n` +
    `export const SITE = ${JSON.stringify(siteInfo, null, 1)} as const;\n`,
);

// Pages: fill the templates with the feature, the screens and the example questions.
const esc = (s) => String(s).replace(/[&<>"']/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' })[c]);
const examples = (config.examples ?? [])
  .map((e) => `      <button type="button" class="ex" lang="${esc(e.lang)}"><span class="lang" aria-hidden="true">${esc(e.lang.toUpperCase())}</span><span>${esc(e.text)}</span></button>`)
  .join('\n');
const screenList = Object.entries(screens)
  .map(([slug, name]) => `      <li><a href="${esc(slug)}.html">${esc(name)}</a></li>`)
  .join('\n');
const fill = (template) =>
  template
    .replaceAll('{{FEATURE}}', esc(config.feature))
    .replaceAll('{{ISSUE}}', esc(config.issue))
    .replaceAll('{{APPROVER}}', esc(config.approver))
    .replaceAll('{{EXAMPLES_HTML}}', examples)
    .replaceAll('{{SCREENS_HTML}}', screenList || '      <li>No screens yet.</li>')
    .replaceAll('{{SCREENS_JSON}}', JSON.stringify(screens).replaceAll('<', '\\u003c'));
for (const [template, out] of [['ask.template.html', outputs.ask], ['index.template.html', outputs.index]]) {
  const path = join(site, template);
  if (existsSync(path)) writeFileSync(out, fill(readFileSync(path, 'utf8')));
}

console.log(`Knowledge: ${docs.length} documents, ${Object.keys(screens).length} screens. Redaction hits: 0.`);
