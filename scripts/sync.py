#!/usr/bin/env python3
"""
fund-skill sync script (Python)

Parse api/*.md markdown structure -> auto-generate API_REGISTRY -> sync validator, SKILL.md, README & api-urls.md
No metadata comments needed — scripts derive everything from headings, code blocks, and Transport lines.

Usage: python3 scripts/sync.py
"""

import os
import re
import sys

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
API_DIR = os.path.join(ROOT, 'api')
VALIDATOR = os.path.join(ROOT, 'validator', 'index.html')
SKILL_MD = os.path.join(ROOT, 'SKILL.md')
README_MD = os.path.join(ROOT, 'README.md')
API_URLS_MD = os.path.join(ROOT, 'references', 'api-urls.md')

# Auto-derive board meta from filename
LABEL_MAP = {
    'fund': '基金', 'stock': '股票', 'global-index': '全球指数',
    'news': '财经资讯', 'market-resolve': '市场解析',
    'bond': '债券', 'futures': '期货', 'forex': '外汇', 'crypto': '数字货币',
    'etf': 'ETF', 'macro': '宏观经济', 'industry': '行业分析',
    'exchange-rate': '汇率',
}
ICON_MAP = {
    'fund': '📊', 'stock': '📈', 'global-index': '🌍', 'news': '📰',
    'market-resolve': '🔍', 'bond': '💰', 'futures': '🔥', 'forex': '💱',
    'crypto': '₿', 'etf': '📋', 'macro': '🏢', 'industry': '🏭',
    'exchange-rate': '💱',
}

def get_board_meta(filename):
    key = filename.replace('.md', '')
    return {
        'key': key,
        'label': LABEL_MAP.get(key, key),
        'icon': ICON_MAP.get(key, '📄'),
    }

BOARD_META = {}  # kept for compatibility, dynamically filled

CJK_RANGE = r'[一-鿿]'

DEFAULTS_MAP = {
    'code': '110011', 'keyword': '沪深300', 'key': '沪深300',
    'fundCode': '110011', 'stockCode': '600519', 'symbol': '110011',
    'codes': 'sh600519', 'secids': '1.000001', 'secid': '1.600519',
    'lid': '2509', 'page': '1', 'per': '20', 'perPage': '10',
    'sdate': '', 'edate': '', 'year': '', 'month': '',
    'fs': 'm:0+t:6,m:0+t:80,m:1+t:2,m:1+t:23',
    'encodedFeedUrl': 'https%3A%2F%2Ffinance.yahoo.com%2Fnews%2Frssindex',
    'topline': '10', 'hkCode': '00700',
}
HINTS_MAP = {
    'code': '代码', 'keyword': '关键词', 'key': '关键词',
    'fundCode': '基金代码', 'stockCode': '股票代码', 'symbol': '代码',
    'codes': '代码', 'secids': 'secids', 'secid': 'secid',
    'lid': 'lid', 'page': '页码', 'per': '每页条数', 'perPage': '每页条数',
    'sdate': '开始日期', 'edate': '结束日期', 'year': '年份', 'month': '月份',
    'fs': '筛选条件', 'encodedFeedUrl': 'RSS URL',
    'topline': '条数(10或200)', 'hkCode': '港股代码',
}

# ── Parse markdown structure ──────────────────────────────

def parse_api_file(filepath):
    basename = os.path.basename(filepath)
    board = get_board_meta(basename)

    with open(filepath, encoding='utf-8') as f:
        content = f.read()

    apis = []
    sections = re.split(r'^## ', content, flags=re.MULTILINE)[1:]

    global_idx = 0
    for section in sections:
        global_idx += 1
        title_line = section.split('\n')[0]
        num_match = re.match(r'^(\d+)\.\s*', title_line)
        num = num_match.group(1) if num_match else str(global_idx)

        cn_match = re.search(CJK_RANGE + r'+', title_line)
        name = cn_match.group() if cn_match else re.sub(r'^\d+\.\s*', '', title_line).strip()

        en_part = re.sub(CJK_RANGE, '', title_line).strip()
        en_part = re.sub(r'^\d+\.\s*', '', en_part)
        en_name = en_part or name

        short_id = re.sub(r'[^a-zA-Z0-9\s-]', '', en_part).split()[:3]
        short_id = '-'.join(w.lower() for w in short_id if w) or name
        api_id = f"{board['key']}-{short_id}"

        url_match = re.search(r'```\w*\n(?:GET\s+)?(\S+)\n```', section)
        url = url_match.group(1) if url_match else ''

        transport_match = re.search(r'\*\*Transport\*\*:\s*(.+)', section)
        transport = transport_match.group(1).strip() if transport_match else ''
        method = 'jsonp'
        if re.search(r'fetch.*gbk|gbk', transport, re.I):
            method = 'fetch-gbk'
        elif re.search(r'fetch', transport, re.I):
            method = 'fetch'
        elif re.search(r'<script>|script tag', transport, re.I):
            method = 'script'
        elif re.search(r'apidata|window\.apidata', transport + section, re.I):
            method = 'apidata'
        elif not transport and not url:
            method = 'none'

        callback = 'jsonpgz' if re.search(r'jsonpgz', transport + section, re.I) else None

        placeholders = re.findall(r'\{(\w+)\}', url)
        default_param = {}
        param_hints = {}
        for ph in placeholders:
            if ph in ('timestamp', 'callback', 'cb'):
                continue
            default_param[ph] = DEFAULTS_MAP.get(ph, '1')
            param_hints[ph] = HINTS_MAP.get(ph, ph)

        # Extract note lines
        note_lines = []
        for m in re.finditer(r'^- \*\*(.+?)\*\*\s*(.*)', section, re.M):
            note_lines.append(f"**{m.group(1)}** {m.group(2)}".strip())

        # Extract response field table rows
        response_fields = []
        for m in re.finditer(r'\|\s*(\d+|`?\w+`?)\s*\|\s*(.+?)\s*\|', section):
            field = m.group(1).strip().replace('`', '')
            desc = m.group(2).strip()
            if field and desc and field not in ('Index', 'Field') and not field.startswith('--'):
                response_fields.append({'field': field, 'desc': desc})

        apis.append({
            'id': api_id, 'name': name, 'enName': en_name, 'num': num,
            'method': method, 'callback': callback, 'url': url,
            'transport': transport,
            'defaultParam': default_param, 'paramHints': param_hints,
            'noteLines': note_lines, 'responseFields': response_fields,
        })

    return {**board, 'apis': apis, 'file': basename}

# ── Generate API_REGISTRY JS ─────────────────────────────

def build_url_fn(url):
    if not url:
        return '() => ``'
    u = url
    u = re.sub(r'\{timestamp\}', '${Date.now()}', u)
    u = re.sub(r'\{callback\}', '_cb', u)
    u = re.sub(r'\{cb\}', '_cb', u)
    remaining = re.findall(r'\{(\w+)\}', u)
    for ph in remaining:
        u = u.replace('{' + ph + '}', '${p.' + ph + '}')
    if '${' not in u:
        return f'() => `{u}`'
    return f'p => `{u}`'

def generate_registry(all_boards):
    boards = []
    for board in all_boards:
        apis = [a for a in board['apis'] if a['method'] != 'none']
        if not apis:
            continue
        api_lines = []
        for api in apis:
            parts = [f"id:'{api['id']}'", f"name:'{api['name']}'", f"method:'{api['method']}'"]
            if api.get('callback') == 'jsonpgz':
                parts.append("callback:'jsonpgz'")
                parts.append("dispatcher:'jsonpgz'")
            parts.append(f"buildUrl:{build_url_fn(api['url'])}")
            parts.append(f"defaultParam:{json_simple(api['defaultParam'])}")
            if api['paramHints']:
                parts.append(f"paramHints:{json_simple(api['paramHints'])}")
            parts.append('validate: d => d !== null && d !== undefined')
            parts.append('extract: d => d')
            api_lines.append('      { ' + ', '.join(parts) + ' }')
        key = board['key']
        key_js = key if re.fullmatch(r'\w+', key) else f"'{key}'"
        boards.append(
            f"    {key_js}: {{\n"
            f"      label:'{board['label']}', icon:'{board['icon']}',\n"
            f"      apis:[\n" +
            ',\n'.join(api_lines) +
            '\n      ]\n    }'
        )
    return 'const API_REGISTRY = {\n' + ',\n'.join(boards) + '\n  };'

def json_simple(d):
    pairs = [f"'{k}':'{v}'" for k, v in d.items()]
    return '{' + ', '.join(pairs) + '}'

# ── Generate Quick Reference ─────────────────────────────

def generate_quick_ref(all_boards):
    lines = ['| Board | File | Key Capabilities |', '|-------|------|-----------------|']
    for board in all_boards:
        caps = ', '.join(a['name'] for a in board['apis'] if a['method'] != 'none')
        if not caps:
            continue
        lines.append(f"| {board['icon']} {board['label']} | `api/{board['file']}` | {caps} |")
    lines += ['', '| Reference | File |', '|-----------|------|',
              '| Full API URL list & params | `references/api-urls.md` |',
              '| Data-source strategy & fallback | `references/data-sources.md` |',
              '| Common errors & fixes | `references/errors.md` |']
    return '\n'.join(lines)

# ── Generate README sections ─────────────────────────────

def generate_board_table(all_boards):
    lines = ['| 板块 | 文件 | 接口 | 核心能力 |', '|:----:|:----:|:----:|:--------|']
    for board in all_boards:
        active_apis = [a for a in board['apis'] if a['method'] != 'none']
        count = len(active_apis)
        caps = ' · '.join(a['name'] for a in active_apis)
        if not caps:
            continue
        lines.append(f"| {board['icon']} {board['label']} | `api/{board['file']}` | **{count}** | {caps} |")
    return '\n'.join(lines)

def generate_project_tree(all_boards):
    lines = ['```', 'fund-skill/',
             '├── 📄 SKILL.md                ← Skill 主入口',
             '├── 📂 api/                    ← 接口定义（按板块分文件）']
    active_boards = [b for b in all_boards if any(a['method'] != 'none' for a in b['apis'])]
    for board in active_boards:
        lines.append(f"│   ├── {board['icon']} {board['file']}")
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
    return '\n'.join(lines)

# ── Generate api-urls.md ─────────────────────────────────

def generate_api_urls(all_boards):
    METHOD_DISPLAY = {
        'jsonp': 'JSONP',
        'script': '`<script>` tag',
        'apidata': '`<script>` tag (hybrid apidata)',
        'fetch': '`fetch`',
        'fetch-gbk': '`fetch` (GBK encoded)',
    }
    lines = []
    global_num = 0

    for board in all_boards:
        active_apis = [a for a in board['apis'] if a['method'] != 'none']
        if not active_apis:
            continue
        lines.append(f"## {board['label']} Board")
        lines.append('')

        for api in active_apis:
            global_num += 1
            title = f"{global_num}. {api['enName']}"
            if api['name'] != api['enName']:
                title += f" {api['name']}"
            lines.append(f"### {title}")
            lines.append('| Field | Value |')
            lines.append('|-------|-------|')

            if api['url']:
                lines.append(f"| URL | `{api['url']}` |")

            lines.append(f"| Method | {METHOD_DISPLAY.get(api['method'], api['method'])} |")

            if api.get('callback') == 'jsonpgz':
                lines.append('| Callback | `jsonpgz` (fixed, not customizable) |')

            lines.append('| Auth | None |')

            for note in api['noteLines']:
                m = re.match(r'\*\*(.+?)\*\*\s*(.*)', note)
                if m:
                    lines.append(f"| {m.group(1)} | {m.group(2)} |")

            if api['responseFields']:
                lines.append('')
                lines.append('**Response**:')
                lines.append('')
                lines.append('| Index | Field | Description |')
                lines.append('|-------|-------|-------------|')
                for rf in api['responseFields']:
                    lines.append(f"| {rf['field']} | | {rf['desc']} |")

            lines.append('')

        lines.append('---')
        lines.append('')

    # Remove trailing --- and blank lines
    while lines and (lines[-1] == '---' or lines[-1] == ''):
        lines.pop()

    return '\n'.join(lines)

# ── File update ──────────────────────────────────────────

def replace_between(content, start, end, replacement):
    si = content.find(start)
    ei = content.find(end)
    if si == -1 or ei == -1:
        print(f'❌ 找不到标记: {start} ... {end}')
        sys.exit(1)
    return content[:si + len(start)] + '\n' + replacement + '\n' + content[ei:]

# ── Main ─────────────────────────────────────────────────

def main():
    all_boards = []
    md_files = sorted(f for f in os.listdir(API_DIR) if f.endswith('.md'))

    for filename in md_files:
        filepath = os.path.join(API_DIR, filename)
        board = parse_api_file(filepath)
        if board:
            print(f"🔍 正在解析 api/{filename} ... 找到 {len(board['apis'])} 个接口")
            all_boards.append(board)

    total = sum(len(b['apis']) for b in all_boards)
    if total == 0:
        print('❌ 未找到任何接口，请检查 api/*.md 中的 ## 标题和代码块')
        sys.exit(1)

    print(f'\n✅ 解析完成：{total} 个接口')

    # Update validator
    registry_js = generate_registry(all_boards)
    with open(VALIDATOR, encoding='utf-8') as f:
        html = f.read()
    html = replace_between(html, '// AUTO-GENERATED START', '// AUTO-GENERATED END', registry_js)
    with open(VALIDATOR, 'w', encoding='utf-8') as f:
        f.write(html)
    print('📝 已更新 validator/index.html (API_REGISTRY)')

    # Update SKILL.md
    quick_ref = generate_quick_ref(all_boards)
    with open(SKILL_MD, encoding='utf-8') as f:
        skill = f.read()
    skill = replace_between(skill, '<!-- AUTO-QUICK-REF START -->', '<!-- AUTO-QUICK-REF END -->', quick_ref)
    with open(SKILL_MD, 'w', encoding='utf-8') as f:
        f.write(skill)
    print('📝 已更新 SKILL.md (Quick Reference)')

    # Update README.md
    board_table = generate_board_table(all_boards)
    with open(README_MD, encoding='utf-8') as f:
        readme = f.read()
    readme = replace_between(readme, '<!-- AUTO-BOARD-TABLE START -->', '<!-- AUTO-BOARD-TABLE END -->', board_table)

    project_tree = generate_project_tree(all_boards)
    readme = replace_between(readme, '<!-- AUTO-PROJECT-TREE START -->', '<!-- AUTO-PROJECT-TREE END -->', project_tree)
    with open(README_MD, 'w', encoding='utf-8') as f:
        f.write(readme)
    print('📝 已更新 README.md (板块说明 + 项目结构)')

    # Update api-urls.md
    api_urls = generate_api_urls(all_boards)
    with open(API_URLS_MD, encoding='utf-8') as f:
        urls_md = f.read()
    urls_md = replace_between(urls_md, '<!-- AUTO-API-URLS START -->', '<!-- AUTO-API-URLS END -->', api_urls)
    with open(API_URLS_MD, 'w', encoding='utf-8') as f:
        f.write(urls_md)
    print('📝 已更新 references/api-urls.md (API URL 清单)')

    print('\n🎉 同步完成！运行 python3 -m http.server 8080 -d validator 查看验证页面')

if __name__ == '__main__':
    main()
