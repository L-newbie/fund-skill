#!/usr/bin/env node
/**
 * fund-skill sync script (Node.js)
 *
 * Parse api/*.md markdown structure → auto-generate API_REGISTRY → sync downstream files + validate
 * No metadata comments needed — scripts derive everything from headings, code blocks, and Transport lines.
 *
 * Usage: node scripts/sync.js           # sync + validate + open browser
 *        node scripts/sync.js --no-open  # sync + validate, don't open browser
 *        node scripts/sync.js --no-validate  # sync only, skip validation
 */

const fs = require('fs');
const path = require('path');
const http = require('http');
const https = require('https');

const NO_VALIDATE = process.argv.includes('--no-validate');

const ROOT = path.resolve(__dirname, '..');
const API_DIR = path.join(ROOT, 'api');
const VALIDATOR = path.join(ROOT, 'validator', 'index.html');
const SKILL_MD = path.join(ROOT, 'SKILL.md');
const README_MD = path.join(ROOT, 'README.md');
const API_URLS_MD = path.join(ROOT, 'references', 'api-urls.md');

// Auto-derive board meta from filename
const LABEL_MAP = {
  fund: '基金', stock: '股票', 'global-index': '全球指数',
  news: '财经资讯', 'market-resolve': '市场解析',
  bond: '债券', futures: '期货', forex: '外汇', crypto: '数字货币',
  etf: 'ETF', macro: '宏观经济', industry: '行业分析',
  'exchange-rate': '汇率',
};
const ICON_MAP = {
  fund: '📊', stock: '📈', 'global-index': '🌍', news: '📰',
  'market-resolve': '🔍', bond: '💰', futures: '🔥', forex: '💱',
  crypto: '₿', etf: '📋', macro: '🏢', industry: '🏭',
  'exchange-rate': '💱',
};

function getBoardMeta(filename) {
  const key = filename.replace(/\.md$/, '');
  return {
    key,
    label: LABEL_MAP[key] || key,
    icon: ICON_MAP[key] || '📄',
  };
}

// ── Parse markdown structure ─────────────────────────────

function parseApiFile(filePath) {
  const content = fs.readFileSync(filePath, 'utf-8');
  const basename = path.basename(filePath);
  const board = getBoardMeta(basename);

  const apis = [];
  const sections = content.split(/^## /m).slice(1);

  let globalIndex = 0;
  for (const section of sections) {
    globalIndex++;
    const titleLine = section.split('\n')[0];
    const numMatch = titleLine.match(/^(\d+)\.\s*/);
    const num = numMatch ? numMatch[1] : String(globalIndex);

    const cnMatch = titleLine.match(/[一-龥]+/);
    const name = cnMatch ? cnMatch[0] : titleLine.replace(/^\d+\.\s*/, '').trim();

    const enPart = titleLine.replace(/[一-龥]+/g, '').replace(/^\d+\.\s*/, '').trim();
    const enName = enPart || name;

    const shortId = enPart
      .replace(/[^a-zA-Z0-9\s-]/g, '')
      .split(/\s+/)
      .filter(Boolean)
      .slice(0, 3)
      .join('-')
      .toLowerCase()
      .replace(/-+/g, '-') || name;
    const id = `${board.key}-${shortId}`;

    const urlMatch = section.match(/```\w*\n(?:GET\s+)?(\S+)\n```/);
    const url = urlMatch ? urlMatch[1] : '';

    const transportLine = section.match(/\*\*Transport\*\*:\s*(.+)/)?.[1] || '';
    let method = 'jsonp';
    if (/fetch.*gbk|gbk/i.test(transportLine)) method = 'fetch-gbk';
    else if (/fetch/i.test(transportLine)) method = 'fetch';
    else if (/<script>|script tag/i.test(transportLine)) method = 'script';
    else if (/apidata|window\.apidata/i.test(transportLine + section)) method = 'apidata';
    else if (/^$/i.test(transportLine) && !url) method = 'none';

    const transport = transportLine.trim();
    const callback = /jsonpgz/i.test(transportLine + section) ? 'jsonpgz' : null;

    // Infer globalVar for script/apidata method
    let globalVar = null;
    if (method === 'script' || method === 'apidata') {
      // First try URL-based matching (most reliable)
      if (/pingzhongdata/.test(url)) globalVar = 'Data_netWorthTrend';
      else if (/fundcode_search/.test(url)) globalVar = 'r';
      else if (/smartbox/.test(url)) globalVar = 'v_hint';
      else if (method === 'apidata') globalVar = 'apidata';
      // Then try explicit mentions like "sets window.v_hint" or "var r ="
      if (!globalVar) {
        const gvMatch = section.match(/sets\s+`?window\.(\w+)`?|`?var\s+(\w+)\s*=\s*/);
        if (gvMatch) globalVar = gvMatch[1] || gvMatch[2];
      }
    }

    // Extract default params from URL placeholders like {code} or {code:110011}
    // {name} → fallback to common defaults, {name:value} → use inline value
    const placeholderMatches = [...url.matchAll(/\{(\w+)(?::([^}]*))?\}/g)];
    const defaultParam = {};
    const paramHints = {};
    const commonDefaults = {
      code: '110011', keyword: '沪深300', key: '沪深300',
      fundCode: '110011', stockCode: '600519', symbol: '110011',
    };
    const commonHints = {
      code: '基金代码', keyword: '关键词', key: '关键词',
      fundCode: '基金代码', stockCode: '股票代码', symbol: '代码',
    };
    for (const m of placeholderMatches) {
      const ph = m[1];
      const inlineDefault = m[2];
      if (['timestamp', 'callback', 'cb'].includes(ph)) continue;
      if (inlineDefault !== undefined) {
        // Inline default: {code:110011} or {sdate:} (empty string)
        defaultParam[ph] = inlineDefault;
      } else {
        defaultParam[ph] = commonDefaults[ph] !== undefined ? commonDefaults[ph] : '1';
      }
      paramHints[ph] = commonHints[ph] || ph;
    }

    const noteLines = [];
    const noteMatches = section.matchAll(/^- \*\*(.+?)\*\*\s*(.*)/gm);
    for (const m of noteMatches) {
      noteLines.push(`**${m[1]}** ${m[2]}`.trim());
    }

    const responseFields = [];
    const respMatches = section.matchAll(/\|\s*(\d+|`?\w+`?)\s*\|\s*(.+?)\s*\|/g);
    for (const m of respMatches) {
      const field = m[1].trim();
      const desc = m[2].trim();
      if (field && desc && field !== 'Index' && field !== 'Field' && !field.startsWith('--')) {
        responseFields.push({ field: field.replace(/`/g, ''), desc });
      }
    }

    apis.push({
      id, name, enName, num, method, callback, globalVar, url, transport,
      defaultParam, paramHints, noteLines, responseFields,
    });
  }

  return { ...board, apis, file: basename };
}

// ── Generate API_REGISTRY JS ─────────────────────────────

function buildBuildUrl(api) {
  if (!api.url) return '() => ``';
  let url = api.url;
  // Strip inline defaults: {code:110011} → {code}
  url = url.replace(/\{(\w+):[^}]*\}/g, '{$1}');
  url = url.replace(/\{timestamp\}/g, '${Date.now()}');
  url = url.replace(/\{callback\}/g, '_cb');
  url = url.replace(/\{cb\}/g, '_cb');
  const remaining = [...url.matchAll(/\{(\w+)\}/g)].map(m => m[1]);
  for (const ph of remaining) {
    url = url.replace(`{${ph}}`, `\${p.${ph}}`);
  }
  if (!url.includes('${')) return `() => \`${url}\``;
  return `p => \`${url}\``;
}

function generateRegistry(allBoards) {
  const boards = [];
  for (const board of allBoards) {
    const apis = board.apis.filter(a => a.method !== 'none');
    if (apis.length === 0) continue;
    const apiLines = apis.map(api => {
      const parts = [`id:'${api.id}'`, `name:'${api.name}'`, `method:'${api.method}'`];
      if (api.callback === 'jsonpgz') {
        parts.push(`callback:'jsonpgz'`, `dispatcher:'jsonpgz'`);
      }
      if (api.globalVar) {
        parts.push(`globalVar:'${api.globalVar}'`);
      }
      parts.push(`buildUrl:${buildBuildUrl(api)}`);
      parts.push(`defaultParam:${JSON.stringify(api.defaultParam)}`);
      if (Object.keys(api.paramHints).length > 0) {
        parts.push(`paramHints:${JSON.stringify(api.paramHints)}`);
      }
      parts.push('validate: d => d !== null && d !== undefined', 'extract: d => d');
      return `      { ${parts.join(', ')} }`;
    });
    boards.push(
      `${/^[\w]+$/.test(board.key) ? board.key : `'${board.key}'`}: {\n      label:'${board.label}', icon:'${board.icon}',\n      apis:[\n${apiLines.join(',\n')}\n      ]\n    }`
    );
  }
  return `const API_REGISTRY = {\n${boards.join(',\n')}\n  };`;
}

// ── Generate Quick Reference ─────────────────────────────

function generateQuickRef(allBoards) {
  const lines = [];
  lines.push('| Board | File | Key Capabilities |');
  lines.push('|-------|------|-----------------|');
  for (const board of allBoards) {
    const caps = board.apis.filter(a => a.method !== 'none').map(a => a.name).join(', ');
    if (!caps) continue;
    lines.push(`| ${board.icon} ${board.label} | \`api/${board.file}\` | ${caps} |`);
  }
  lines.push('');
  lines.push('| Reference | File |');
  lines.push('|-----------|------|');
  lines.push('| Full API URL list & params | `references/api-urls.md` |');
  lines.push('| Data-source strategy & fallback | `references/data-sources.md` |');
  lines.push('| Common errors & fixes | `references/errors.md` |');
  return lines.join('\n');
}

// ── Generate README sections ─────────────────────────────

function generateBoardTable(allBoards) {
  const lines = [];
  lines.push('| 板块 | 文件 | 接口 | 核心能力 |');
  lines.push('|:----:|:----:|:----:|:--------|');
  for (const board of allBoards) {
    const activeApis = board.apis.filter(a => a.method !== 'none');
    const count = activeApis.length;
    const caps = activeApis.map(a => a.name).join(' · ');
    if (!caps) continue;
    lines.push(`| ${board.icon} ${board.label} | \`api/${board.file}\` | **${count}** | ${caps} |`);
  }
  return lines.join('\n');
}

function generateProjectTree(allBoards) {
  const lines = [
    '```',
    'fund-skill/',
    '├── 📄 SKILL.md                ← Skill 主入口',
    '├── 📂 api/                    ← 接口定义（按板块分文件）',
  ];
  const activeBoards = allBoards.filter(b => b.apis.some(a => a.method !== 'none'));
  for (const board of activeBoards) {
    lines.push(`│   ├── ${board.icon} ${board.file}`);
  }
  lines.push('├── 📂 references/             ← 深度参考文档');
  lines.push('│   ├── 🔗 api-urls.md         完整 API URL 清单');
  lines.push('│   ├── 🔄 data-sources.md     数据源策略与兜底方案');
  lines.push('│   └── ⚠️ errors.md           常见错误与修复');
  lines.push('├── 📂 scripts/                ← 同步脚本');
  lines.push('│   ├── 📜 sync.js             Node.js 版（推荐）');
  lines.push('│   ├── 🐍 sync.py             Python 版');
  lines.push('│   └── 🐚 sync.sh             Bash 版（零依赖）');
  lines.push('├── 📂 validator/              ← 前端验证页面');
  lines.push('│   └── 🖥️ index.html          单文件 SPA');
  lines.push('├── 📂 .git/                   ← Git 仓库数据');
  lines.push('├── 📄 .gitignore              ← Git 忽略规则');
  lines.push('└── 📄 README.md');
  lines.push('```');
  return lines.join('\n');
}

// ── Generate api-urls.md ─────────────────────────────────

function generateApiUrls(allBoards) {
  const lines = [];
  let globalNum = 0;

  for (const board of allBoards) {
    const activeApis = board.apis.filter(a => a.method !== 'none');
    if (activeApis.length === 0) continue;

    lines.push(`## ${board.label} Board`);
    lines.push('');

    for (const api of activeApis) {
      globalNum++;
      lines.push(`### ${globalNum}. ${api.enName} ${api.name !== api.enName ? api.name : ''}`.trim());
      lines.push('| Field | Value |');
      lines.push('|-------|-------|');

      if (api.url) {
        lines.push(`| URL | \`${api.url}\` |`);
      }

      const methodDisplay = {
        'jsonp': 'JSONP',
        'script': '`<script>` tag',
        'apidata': '`<script>` tag (hybrid apidata)',
        'fetch': '`fetch`',
        'fetch-gbk': '`fetch` (GBK encoded)',
      }[api.method] || api.method;
      lines.push(`| Method | ${methodDisplay} |`);

      if (api.callback === 'jsonpgz') {
        lines.push('| Callback | `jsonpgz` (fixed, not customizable) |');
      }

      lines.push('| Auth | None |');

      for (const note of api.noteLines) {
        const noteKeyMatch = note.match(/^\*\*(.+?)\*\*\s*(.*)/);
        if (noteKeyMatch) {
          lines.push(`| ${noteKeyMatch[1]} | ${noteKeyMatch[2]} |`);
        }
      }

      if (api.responseFields.length > 0) {
        lines.push('');
        lines.push('**Response**:');
        lines.push('');
        lines.push('| Index | Field | Description |');
        lines.push('|-------|-------|-------------|');
        for (const rf of api.responseFields) {
          lines.push(`| ${rf.field} | | ${rf.desc} |`);
        }
      }

      lines.push('');
    }

    lines.push('---');
    lines.push('');
  }

  while (lines.length > 0 && (lines[lines.length - 1] === '---' || lines[lines.length - 1] === '')) {
    lines.pop();
  }

  return lines.join('\n');
}

// ── Backend validation ───────────────────────────────────

function buildTestUrl(api) {
  if (!api.url) return null;
  let url = api.url;
  // Fill placeholders with defaults
  for (const [k, v] of Object.entries(api.defaultParam)) {
    url = url.replace(`{${k}}`, v);
  }
  // Fill timestamp/callback placeholders
  url = url.replace(/\{timestamp\}/g, Date.now());
  url = url.replace(/\{callback\}/g, '_cb');
  url = url.replace(/\{cb\}/g, '_cb');
  // Skip if still has unfilled placeholders
  if (/\{\w+\}/.test(url)) return null;
  return url;
}

function httpGet(url, timeout = 8000) {
  return new Promise((resolve) => {
    const mod = url.startsWith('https') ? https : http;
    const req = mod.get(url, { timeout }, (res) => {
      let body = '';
      res.on('data', chunk => body += chunk);
      res.on('end', () => {
        resolve({ ok: res.statusCode >= 200 && res.statusCode < 400, status: res.statusCode, body: body.slice(0, 500) });
      });
    });
    req.on('error', (e) => resolve({ ok: false, status: 0, error: e.message }));
    req.on('timeout', () => { req.destroy(); resolve({ ok: false, status: 0, error: 'Timeout' }); });
  });
}

async function validateApis(allBoards) {
  const allApis = allBoards.flatMap(b => b.apis.filter(a => a.method !== 'none'));
  const testableApis = allApis.filter(a => {
    const url = buildTestUrl(a);
    return url && (a.method === 'fetch' || a.method === 'fetch-gbk');
  });
  const scriptApis = allApis.filter(a => a.method === 'jsonp' || a.method === 'script' || a.method === 'apidata');

  let ok = 0, fail = 0, skip = 0;
  const results = [];

  console.log(`\n🔍 后端接口验证（fetch 类 ${testableApis.length} 个，JSONP/script 类 ${scriptApis.length} 个需浏览器验证）`);
  console.log('─'.repeat(60));

  // Validate fetch-type APIs (can be tested from backend)
  for (const api of testableApis) {
    const url = buildTestUrl(api);
    const res = await httpGet(url);
    if (res.ok) {
      ok++;
      console.log(`  ✅ ${api.name} — ${res.status}`);
    } else {
      fail++;
      const reason = res.error || `HTTP ${res.status}`;
      console.log(`  ❌ ${api.name} — ${reason}`);
      results.push({ name: api.name, reason });
    }
  }

  // Skip JSONP/script APIs (require browser)
  for (const api of scriptApis) {
    skip++;
    console.log(`  ⏭️  ${api.name} — 需浏览器验证（${api.method}）`);
  }

  console.log('─'.repeat(60));
  console.log(`📊 验证结果：✅ ${ok} 可用  ❌ ${fail} 失败  ⏭️  ${skip} 需浏览器`);

  if (fail > 0) {
    console.log('\n⚠️  以下接口后端验证失败（不阻断流程，可在浏览器中复验）：');
    for (const r of results) {
      console.log(`  • ${r.name}：${r.reason}`);
    }
  }

  return { ok, fail, skip };
}

// ── File update ──────────────────────────────────────────

function replaceBetween(content, startMarker, endMarker, replacement) {
  const si = content.indexOf(startMarker);
  const ei = content.indexOf(endMarker);
  if (si === -1 || ei === -1) {
    console.error(`❌ 找不到标记: ${startMarker} ... ${endMarker}`);
    process.exit(1);
  }
  return content.substring(0, si + startMarker.length) +
    '\n' + replacement + '\n' +
    content.substring(ei);
}

// ── Main ─────────────────────────────────────────────────

async function main() {
  const allBoards = [];
  const mdFiles = fs.readdirSync(API_DIR).filter(f => f.endsWith('.md')).sort();

  for (const filename of mdFiles) {
    const filePath = path.join(API_DIR, filename);
    const board = parseApiFile(filePath);
    if (board) {
      console.log(`🔍 正在解析 api/${filename} ... 找到 ${board.apis.length} 个接口`);
      allBoards.push(board);
    }
  }

  const total = allBoards.reduce((s, b) => s + b.apis.length, 0);
  if (total === 0) {
    console.error('❌ 未找到任何接口，请检查 api/*.md 中的 ## 标题和代码块');
    process.exit(1);
  }

  console.log(`\n✅ 解析完成：${total} 个接口`);

  // ── Validate parsed URLs ──────────────────────────────
  const warnings = [];
  for (const board of allBoards) {
    for (const api of board.apis) {
      if (api.method === 'none') continue;
      if (!api.url) {
        warnings.push(`[${board.label}] ${api.name} — 无 URL`);
        continue;
      }
      // Check for non-standard placeholders (e.g. {10|200}, {1}, {a_b})
      // Allow {name:default} format, flag anything else with special chars
      const badPlaceholders = [...api.url.matchAll(/\{([^}]*)\}/g)]
        .map(m => m[1])
        .filter(p => !/^\w+(:[^}]*)?$/.test(p) && !['timestamp', 'callback', 'cb'].includes(p.split(':')[0]));
      if (badPlaceholders.length > 0) {
        warnings.push(`[${board.label}] ${api.name} — URL 含非标准占位符: {${badPlaceholders.join('}, {')}} (应使用 {name} 或 {name:default} 格式)`);
      }
      // Check for unresolved placeholders that have no default
      const allPlaceholders = [...api.url.matchAll(/\{(\w+)(?::[^}]*)?\}/g)].map(m => m[1])
        .filter(p => !['timestamp', 'callback', 'cb'].includes(p));
      const missingDefaults = allPlaceholders.filter(p => api.defaultParam[p] === undefined);
      if (missingDefaults.length > 0) {
        warnings.push(`[${board.label}] ${api.name} — 占位符 {${missingDefaults.join('}, {')}} 无默认值`);
      }
    }
  }
  if (warnings.length > 0) {
    console.log('\n⚠️  URL 校验警告：');
    for (const w of warnings) {
      console.log(`  ⚠️  ${w}`);
    }
  } else {
    console.log('\n✅ URL 校验通过');
  }

  console.log('\n📝 同步下游文件...');
  console.log('─'.repeat(60));

  // 1. Update validator/index.html (API definitions)
  const registryJs = generateRegistry(allBoards);
  let html = fs.readFileSync(VALIDATOR, 'utf-8');
  html = replaceBetween(html, '// AUTO-GENERATED START', '// AUTO-GENERATED END', registryJs);
  fs.writeFileSync(VALIDATOR, html);
  console.log('  ✦ validator/index.html  （前端验证页面）');

  // 2. Validate APIs (after validator is updated, before references)
  let validateResult = { ok: 0, fail: 0, skip: 0 };
  if (!NO_VALIDATE) {
    validateResult = await validateApis(allBoards);
  } else {
    console.log('\n⏭️  跳过后端验证（--no-validate）');
  }

  // 3. Update references/api-urls.md
  const apiUrls = generateApiUrls(allBoards);
  let urlsMd = fs.readFileSync(API_URLS_MD, 'utf-8');
  urlsMd = replaceBetween(urlsMd, '<!-- AUTO-API-URLS START -->', '<!-- AUTO-API-URLS END -->', apiUrls);
  fs.writeFileSync(API_URLS_MD, urlsMd);
  console.log('\n  ✦ references/api-urls.md（API URL 清单）');

  // 4. Update SKILL.md
  const quickRef = generateQuickRef(allBoards);
  let skill = fs.readFileSync(SKILL_MD, 'utf-8');
  skill = replaceBetween(skill, '<!-- AUTO-QUICK-REF START -->', '<!-- AUTO-QUICK-REF END -->', quickRef);
  fs.writeFileSync(SKILL_MD, skill);
  console.log('  ✦ SKILL.md              （Skill Quick Reference）');

  // 5. Update README.md
  const boardTable = generateBoardTable(allBoards);
  let readme = fs.readFileSync(README_MD, 'utf-8');
  readme = replaceBetween(readme, '<!-- AUTO-BOARD-TABLE START -->', '<!-- AUTO-BOARD-TABLE END -->', boardTable);
  const projectTree = generateProjectTree(allBoards);
  readme = replaceBetween(readme, '<!-- AUTO-PROJECT-TREE START -->', '<!-- AUTO-PROJECT-TREE END -->', projectTree);
  fs.writeFileSync(README_MD, readme);
  console.log('  ✦ README.md             （板块说明 + 项目结构）');

  console.log('─'.repeat(60));
  console.log('📝 所有下游文件已同步');

  console.log('\n🎉 同步完成！运行以下命令启动验证页面：');
  console.log('   cd validator && python3 -m http.server 8080');
}

main();
