#!/usr/bin/env bash
#
# fund-skill sync script (Bash)
#
# Parse api/*.md markdown structure -> auto-generate API_REGISTRY -> sync validator, SKILL.md & README
# No metadata comments needed.
#
# Usage: bash scripts/sync.sh

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
API_DIR="$ROOT/api"
VALIDATOR="$ROOT/validator/index.html"
SKILL_MD="$ROOT/SKILL.md"
README_MD="$ROOT/README.md"
API_URLS_MD="$ROOT/references/api-urls.md"

TMP_REGISTRY=$(mktemp /tmp/funds-registry.XXXXXX)
TMP_QUICKREF=$(mktemp /tmp/funds-quickref.XXXXXX)
TMP_BOARDTABLE=$(mktemp /tmp/funds-boardtable.XXXXXX)
TMP_PROJTREE=$(mktemp /tmp/funds-projtree.XXXXXX)
trap 'rm -f "$TMP_REGISTRY" "$TMP_QUICKREF" "$TMP_BOARDTABLE" "$TMP_PROJTREE"' EXIT

# ── Build Registry JS via Python (handles multiline reliably) ──

echo "const API_REGISTRY = {" > "$TMP_REGISTRY"

comma=""
while IFS=: read -r filename key label icon; do
  filepath="$API_DIR/$filename"
  [[ ! -f "$filepath" ]] && { echo "❌ 板块文件不存在: $filepath"; exit 1; }

  # Count ## headings (each = one API)
  count=$(grep -c '^## ' "$filepath" || true)
  [[ "$count" -eq 0 ]] && continue

  echo "🔍 正在解析 api/$filename ... 找到 $count 个接口"

  # Use Python to parse sections and generate JS entries
  python3 - "$filepath" "$key" "$label" "$icon" "$comma" >> "$TMP_REGISTRY" <<'PYEOF'
import sys, re

filepath, key, label, icon, comma = sys.argv[1:6]
if comma:
    print(",", end="")

with open(filepath, encoding="utf-8") as f:
    content = f.read()

sections = re.split(r'^## ', content, flags=re.MULTILINE)[1:]
api_lines = []
CJK = r'[一-鿿]'

for section in sections:
    title = section.split("\n")[0]
    cn = re.search(CJK + r'+', title)
    name = cn.group() if cn else re.sub(r'^\d+\.\s*', '', title).strip()

    en = re.sub(CJK, '', title).strip()
    en = re.sub(r'^\d+\.\s*', '', en)
    short = '-'.join(re.findall(r'[A-Za-z]+', en)[:3]).lower() or name
    api_id = f"{key}-{short}"

    url_m = re.search(r'```\w*\n(?:GET\s+)?(\S+)\n```', section)
    url = url_m.group(1) if url_m else ""

    transport_m = re.search(r'\*\*Transport\*\*:\s*(.+)', section)
    transport = transport_m.group(1) if transport_m else ""

    method = "jsonp"
    full = transport + section
    if re.search(r'fetch.*gbk|gbk', full, re.I):
        method = "fetch-gbk"
    elif re.search(r'fetch', transport, re.I):
        method = "fetch"
    elif re.search(r'<script>|script tag', transport, re.I):
        method = "script"
    elif re.search(r'apidata|window\.apidata', full, re.I):
        method = "apidata"
    elif not transport and not url:
        method = "none"

    callback = "'jsonpgz'" if re.search(r'jsonpgz', full, re.I) else "null"

    if method == "none":
        continue

    # Build URL function
    build_fn = '() => ``'
    if url:
        u = url
        u = re.sub(r'\{timestamp\}', '${Date.now()}', u)
        u = re.sub(r'\{callback\}', '_cb', u)
        u = re.sub(r'\{cb\}', '_cb', u)
        placeholders = re.findall(r'\{(\w+)\}', u)
        for ph in placeholders:
            u = u.replace('{' + ph + '}', '${p.' + ph + '}')
        if '${' not in u:
            build_fn = f'() => `{u}`'
        else:
            build_fn = f'p => `{u}`'

    # Default params
    defaults = {'code': '110011', 'keyword': '沪深300', 'key': '沪深300',
                'fundCode': '110011', 'stockCode': '600519', 'symbol': '110011',
                'codes': 'sh600519', 'secids': '1.000001', 'secid': '1.600519',
                'lid': '2509', 'page': '1', 'per': '20', 'perPage': '10',
                'sdate': '', 'edate': '', 'year': '', 'month': '',
                'fs': 'm:0+t:6,m:0+t:80,m:1+t:2,m:1+t:23',
                'encodedFeedUrl': 'https%3A%2F%2Ffinance.yahoo.com%2Fnews%2Frssindex',
                'topline': '10', 'hkCode': '00700'}
    hints = {'code': '代码', 'keyword': '关键词', 'key': '关键词',
             'fundCode': '基金代码', 'stockCode': '股票代码', 'symbol': '代码',
             'codes': '代码', 'secids': 'secids', 'secid': 'secid',
             'lid': 'lid', 'page': '页码', 'per': '每页条数', 'perPage': '每页条数',
             'sdate': '开始日期', 'edate': '结束日期', 'year': '年份', 'month': '月份',
             'fs': '筛选条件', 'encodedFeedUrl': 'RSS URL',
             'topline': '条数(10或200)', 'hkCode': '港股代码'}
    placeholders = re.findall(r'\{(\w+)\}', url or "")
    dp = {ph: defaults.get(ph, '1') for ph in placeholders if ph not in ('timestamp', 'callback', 'cb')}
    ph_dict = {ph: hints.get(ph, ph) for ph in placeholders if ph not in ('timestamp', 'callback', 'cb')}

    parts = [f"id:'{api_id}'", f"name:'{name}'", f"method:'{method}'"]
    if callback == "'jsonpgz'":
        parts.append("callback:'jsonpgz', dispatcher:'jsonpgz'")
    parts.append(f"buildUrl:{build_fn}")
    dp_str = ', '.join(f"'{k}':'{v}'" for k, v in dp.items())
    parts.append(f"defaultParam:{{{dp_str}}}")
    if ph_dict:
        ph_str = ', '.join(f"'{k}':'{v}'" for k, v in ph_dict.items())
        parts.append(f"paramHints:{{{ph_str}}}")
    parts.append("validate: d => d !== null && d !== undefined")
    parts.append("extract: d => d")

    api_lines.append('      { ' + ', '.join(parts) + ' }')

# Quote key if it contains hyphens
key_js = f"'{key}'" if '-' in key else key
print(f"    {key_js}: {{")
print(f"      label:'{label}', icon:'{icon}',")
print(f"      apis:[")
print(',\n'.join(api_lines))
print('      ]')
print('    }', end="")
PYEOF

  comma="1"
done < <(for md in "$API_DIR"/*.md; do
  filename=$(basename "$md")
  key="${filename%.md}"
  # Auto-derive label and icon
  case "$key" in
    fund)           label='基金';    icon='📊' ;;
    stock)          label='股票';    icon='📈' ;;
    global-index)   label='全球指数'; icon='🌍' ;;
    news)           label='财经资讯'; icon='📰' ;;
    market-resolve) label='市场解析'; icon='🔍' ;;
    bond)           label='债券';    icon='💰' ;;
    futures)        label='期货';    icon='🔥' ;;
    forex)          label='外汇';    icon='💱' ;;
    crypto)         label='数字货币'; icon='₿' ;;
    etf)            label='ETF';     icon='📋' ;;
    exchange-rate)  label='汇率';    icon='💱' ;;
    *)              label="$key";    icon='📄' ;;
  esac
  echo "$filename:$key:$label:$icon"
done)

echo "" >> "$TMP_REGISTRY"
echo "  };" >> "$TMP_REGISTRY"

# ── Count totals ─────────────────────────────────────────

total=$(grep -c "id:'" "$TMP_REGISTRY" || echo 0)

if [[ "$total" -eq 0 ]]; then
  echo "❌ 未找到任何接口，请检查 api/*.md 中的 ## 标题和代码块"
  exit 1
fi

echo ""
echo "✅ 解析完成：$total 个接口"

# ── Update validator/index.html ───────────────────────────

registry_content=$(cat "$TMP_REGISTRY")

python3 -c "
import sys
marker_start = '// AUTO-GENERATED START'
marker_end = '// AUTO-GENERATED END'
content = open('$VALIDATOR', encoding='utf-8').read()
si = content.find(marker_start)
ei = content.find(marker_end)
if si == -1 or ei == -1:
    print('❌ 找不到标记: ' + marker_start + ' ... ' + marker_end)
    sys.exit(1)
replacement = sys.stdin.read()
result = content[:si + len(marker_start)] + '\n' + replacement + '\n' + content[ei:]
open('$VALIDATOR', 'w', encoding='utf-8').write(result)
" <<< "$registry_content"

echo "📝 已更新 validator/index.html (API_REGISTRY)"

# ── Build Quick Reference ────────────────────────────────

python3 - "$API_DIR" > "$TMP_QUICKREF" <<'PYEOF'
import sys, re, os, glob

api_dir = sys.argv[1]

LABEL_MAP = {
    'fund': '基金', 'stock': '股票', 'global-index': '全球指数',
    'news': '财经资讯', 'market-resolve': '市场解析',
    'bond': '债券', 'futures': '期货', 'forex': '外汇',
    'crypto': '数字货币', 'etf': 'ETF', 'macro': '宏观经济', 'industry': '行业分析',
    'exchange-rate': '汇率',
}
ICON_MAP = {
    'fund': '📊', 'stock': '📈', 'global-index': '🌍', 'news': '📰',
    'market-resolve': '🔍', 'bond': '💰', 'futures': '🔥', 'forex': '💱',
    'crypto': '₿', 'etf': '📋', 'macro': '🏢', 'industry': '🏭',
    'exchange-rate': '💱',
}

boards = []
for md in sorted(glob.glob(os.path.join(api_dir, '*.md'))):
    filename = os.path.basename(md)
    key = filename.replace('.md', '')
    label = LABEL_MAP.get(key, key)
    icon = ICON_MAP.get(key, '📄')
    boards.append((filename, key, label, icon))

print("| Board | File | Key Capabilities |")
print("|-------|------|-----------------|")
for filename, key, label, icon in boards:
    filepath = f"{api_dir}/{filename}"
    try:
        with open(filepath, encoding="utf-8") as f:
            content = f.read()
    except FileNotFoundError:
        continue
    names = []
    for m in re.finditer(r'^## \s*\d*\.?\s*(.+)', content, re.M):
        title = m.group(1).strip()
        cn = re.search(r'[一-鿿]+', title)
        names.append(cn.group() if cn else title)
    if names:
        print(f"| {icon} {label} | `api/{filename}` | {', '.join(names)} |")

print("")
print("| Reference | File |")
print("|-----------|------|")
print("| Full API URL list & params | `references/api-urls.md` |")
print("| Data-source strategy & fallback | `references/data-sources.md` |")
print("| Common errors & fixes | `references/errors.md` |")
PYEOF

quickref_content=$(cat "$TMP_QUICKREF")

python3 -c "
import sys
marker_start = '<!-- AUTO-QUICK-REF START -->'
marker_end = '<!-- AUTO-QUICK-REF END -->'
content = open('$SKILL_MD', encoding='utf-8').read()
si = content.find(marker_start)
ei = content.find(marker_end)
if si == -1 or ei == -1:
    print('❌ 找不到标记: ' + marker_start + ' ... ' + marker_end)
    sys.exit(1)
replacement = sys.stdin.read()
result = content[:si + len(marker_start)] + '\n' + replacement + '\n' + content[ei:]
open('$SKILL_MD', 'w', encoding='utf-8').write(result)
" <<< "$quickref_content"

echo "📝 已更新 SKILL.md (Quick Reference)"

# ── Build README board table ─────────────────────────────

python3 - "$API_DIR" > "$TMP_BOARDTABLE" <<'PYEOF'
import sys, re, os, glob

api_dir = sys.argv[1]

LABEL_MAP = {
    'fund': '基金', 'stock': '股票', 'global-index': '全球指数',
    'news': '财经资讯', 'market-resolve': '市场解析',
    'bond': '债券', 'futures': '期货', 'forex': '外汇',
    'crypto': '数字货币', 'etf': 'ETF', 'macro': '宏观经济', 'industry': '行业分析',
    'exchange-rate': '汇率',
}
ICON_MAP = {
    'fund': '📊', 'stock': '📈', 'global-index': '🌍', 'news': '📰',
    'market-resolve': '🔍', 'bond': '💰', 'futures': '🔥', 'forex': '💱',
    'crypto': '₿', 'etf': '📋', 'macro': '🏢', 'industry': '🏭',
    'exchange-rate': '💱',
}

print("| 板块 | 文件 | 接口 | 核心能力 |")
print("|:----:|:----:|:----:|:--------|")
for md in sorted(glob.glob(os.path.join(api_dir, '*.md'))):
    filename = os.path.basename(md)
    key = filename.replace('.md', '')
    label = LABEL_MAP.get(key, key)
    icon = ICON_MAP.get(key, '📄')
    with open(md, encoding="utf-8") as f:
        content = f.read()
    names = []
    for m in re.finditer(r'^## \s*\d*\.?\s*(.+)', content, re.M):
        title = m.group(1).strip()
        cn = re.search(r'[一-鿿]+', title)
        names.append(cn.group() if cn else title)
    if names:
        print(f"| {icon} {label} | `api/{filename}` | **{len(names)}** | {' · '.join(names)} |")
PYEOF

boardtable_content=$(cat "$TMP_BOARDTABLE")

python3 -c "
import sys
marker_start = '<!-- AUTO-BOARD-TABLE START -->'
marker_end = '<!-- AUTO-BOARD-TABLE END -->'
content = open('$README_MD', encoding='utf-8').read()
si = content.find(marker_start)
ei = content.find(marker_end)
if si == -1 or ei == -1:
    print('❌ 找不到标记: ' + marker_start + ' ... ' + marker_end)
    sys.exit(1)
replacement = sys.stdin.read()
result = content[:si + len(marker_start)] + '\n' + replacement + '\n' + content[ei:]
open('$README_MD', 'w', encoding='utf-8').write(result)
" <<< "$boardtable_content"

# ── Build README project tree ────────────────────────────

python3 - "$API_DIR" > "$TMP_PROJTREE" <<'PYEOF'
import sys, re, os, glob

api_dir = sys.argv[1]

ICON_MAP = {
    'fund': '📊', 'stock': '📈', 'global-index': '🌍', 'news': '📰',
    'market-resolve': '🔍', 'bond': '💰', 'futures': '🔥', 'forex': '💱',
    'crypto': '₿', 'etf': '📋', 'macro': '🏢', 'industry': '🏭',
    'exchange-rate': '💱',
}

lines = ['```', 'fund-skill/',
         '├── 📄 SKILL.md                ← Skill 主入口',
         '├── 📂 api/                    ← 接口定义（按板块分文件）']
for md in sorted(glob.glob(os.path.join(api_dir, '*.md'))):
    filename = os.path.basename(md)
    key = filename.replace('.md', '')
    icon = ICON_MAP.get(key, '📄')
    lines.append(f'│   ├── {icon} {filename}')
lines += ['├── 📂 references/             ← 深度参考文档',
          '│   ├── 🔗 api-urls.md         完整 API URL 清单',
          '│   ├── 🔄 data-sources.md     数据源策略与兜底方案',
          '│   └── ⚠️ errors.md           常见错误与修复',
          '├── 📂 scripts/                ← 同步脚本',
          '│   ├── 📜 sync.js             Node.js 版（推荐）',
          '│   ├── 🐍 sync.py             Python 版',
          '│   └── 🐚 sync.sh             Bash 版（零依赖）',
          '├── 📂 validator/              ← 前端验证页面',
          '│   └── 🖥️ index.html          单文件 SPA',
          '├── 📂 .git/                   ← Git 仓库数据',
          '├── 📄 .gitignore              ← Git 忽略规则',
          '└── 📄 README.md',
          '```']
print('\n'.join(lines))
PYEOF

projtree_content=$(cat "$TMP_PROJTREE")

python3 -c "
import sys
marker_start = '<!-- AUTO-PROJECT-TREE START -->'
marker_end = '<!-- AUTO-PROJECT-TREE END -->'
content = open('$README_MD', encoding='utf-8').read()
si = content.find(marker_start)
ei = content.find(marker_end)
if si == -1 or ei == -1:
    print('❌ 找不到标记: ' + marker_start + ' ... ' + marker_end)
    sys.exit(1)
replacement = sys.stdin.read()
result = content[:si + len(marker_start)] + '\n' + replacement + '\n' + content[ei:]
open('$README_MD', 'w', encoding='utf-8').write(result)
" <<< "$projtree_content"

echo "📝 已更新 README.md (板块说明 + 项目结构)"

# ── Build api-urls.md ────────────────────────────────────

TMP_APIURLS=$(mktemp /tmp/funds-apiurls.XXXXXX)

python3 - "$API_DIR" > "$TMP_APIURLS" <<'PYEOF'
import sys, re, os, glob

api_dir = sys.argv[1]

LABEL_MAP = {
    'fund': '基金', 'stock': '股票', 'global-index': '全球指数',
    'news': '财经资讯', 'market-resolve': '市场解析',
    'bond': '债券', 'futures': '期货', 'forex': '外汇',
    'crypto': '数字货币', 'etf': 'ETF', 'macro': '宏观经济', 'industry': '行业分析',
    'exchange-rate': '汇率',
}
METHOD_DISPLAY = {
    'jsonp': 'JSONP',
    'script': '`<script>` tag',
    'apidata': '`<script>` tag (hybrid apidata)',
    'fetch': '`fetch`',
    'fetch-gbk': '`fetch` (GBK encoded)',
}

lines = []
global_num = 0

for md in sorted(glob.glob(os.path.join(api_dir, '*.md'))):
    filename = os.path.basename(md)
    key = filename.replace('.md', '')
    label = LABEL_MAP.get(key, key)

    with open(md, encoding="utf-8") as f:
        content = f.read()

    sections = re.split(r'^## ', content, flags=re.MULTILINE)[1:]
    board_has_apis = False

    for section in sections:
        title = section.split('\n')[0]
        cn = re.search(r'[一-鿿]+', title)
        name = cn.group() if cn else re.sub(r'^\d+\.\s*', '', title).strip()
        en = re.sub(r'[一-鿿]+', '', title).strip()
        en = re.sub(r'^\d+\.\s*', '', en).strip()
        en_name = en or name

        transport_m = re.search(r'\*\*Transport\*\*:\s*(.+)', section)
        transport = transport_m.group(1).strip() if transport_m else ''

        method = 'jsonp'
        if re.search(r'fetch.*gbk|gbk', transport, re.I):
            method = 'fetch-gbk'
        elif re.search(r'fetch', transport, re.I):
            method = 'fetch'
        elif re.search(r'<script>|script tag', transport, re.I):
            method = 'script'
        elif re.search(r'apidata|window\.apidata', transport + section, re.I):
            method = 'apidata'

        if method == 'none':
            continue

        if not board_has_apis:
            lines.append(f'## {label} Board')
            lines.append('')
            board_has_apis = True

        global_num += 1
        title_str = f"{global_num}. {en_name}"
        if name != en_name:
            title_str += f" {name}"
        lines.append(f'### {title_str}')
        lines.append('| Field | Value |')
        lines.append('|-------|-------|')

        url_m = re.search(r'```\w*\n(?:GET\s+)?(\S+)\n```', section)
        if url_m:
            lines.append(f"| URL | `{url_m.group(1)}` |")

        lines.append(f"| Method | {METHOD_DISPLAY.get(method, method)} |")

        if re.search(r'jsonpgz', transport + section, re.I):
            lines.append('| Callback | `jsonpgz` (fixed, not customizable) |')

        lines.append('| Auth | None |')

        # Notes
        for m in re.finditer(r'^- \*\*(.+?)\*\*\s*(.*)', section, re.M):
            lines.append(f"| {m.group(1)} | {m.group(2)} |")

        # Response fields
        resp_fields = []
        for m in re.finditer(r'\|\s*(\d+|`?\w+`?)\s*\|\s*(.+?)\s*\|', section):
            field = m.group(1).strip().replace('`', '')
            desc = m.group(2).strip()
            if field and desc and field not in ('Index', 'Field') and not field.startswith('--'):
                resp_fields.append((field, desc))

        if resp_fields:
            lines.append('')
            lines.append('**Response**:')
            lines.append('')
            lines.append('| Index | Field | Description |')
            lines.append('|-------|-------|-------------|')
            for f, d in resp_fields:
                lines.append(f'| {f} | | {d} |')

        lines.append('')

    if board_has_apis:
        lines.append('---')
        lines.append('')

# Remove trailing --- and blank lines
while lines and (lines[-1] == '---' or lines[-1] == ''):
    lines.pop()

print('\n'.join(lines))
PYEOF

apiurls_content=$(cat "$TMP_APIURLS")

python3 -c "
import sys
marker_start = '<!-- AUTO-API-URLS START -->'
marker_end = '<!-- AUTO-API-URLS END -->'
content = open('$API_URLS_MD', encoding='utf-8').read()
si = content.find(marker_start)
ei = content.find(marker_end)
if si == -1 or ei == -1:
    print('❌ 找不到标记: ' + marker_start + ' ... ' + marker_end)
    sys.exit(1)
replacement = sys.stdin.read()
result = content[:si + len(marker_start)] + '\n' + replacement + '\n' + content[ei:]
open('$API_URLS_MD', 'w', encoding='utf-8').write(result)
" <<< "$apiurls_content"

rm -f "$TMP_APIURLS"

echo "📝 已更新 references/api-urls.md (API URL 清单)"
echo ""
echo "🎉 同步完成！运行 python3 -m http.server 8080 -d validator 查看验证页面"
