---
name: Fund Skill
slug: fund-skill
version: 3.0.0
description: Query fund valuations, stock quotes, financial news, and global market indices from EastMoney, Sina, Tencent, overseas RSS sources, and Python SDKs (akshare, finance-datareader).
changelog: Replace sync scripts with AI-driven maintenance rules; api-urls.md becomes pointer index
metadata: {"emoji":"📈","requires":{"bins":[]},"os":["linux","darwin","win32"]}
---

## When to Use

- User asks for fund real-time valuation, NAV history, holdings, or fund search
- User needs stock quotes, stock search, yesterday's change, or K-line data
- User wants global index data (A-share, HK, US, JP, KR, EU indices)
- User requests financial news (Sina, EastMoney, or overseas RSS)
- User needs to resolve stock market codes across exchanges
- User provides raw API information and wants it integrated into the project

## Directory Structure

```
api/
├── browser/           ← Frontend HTTP APIs (JSONP, script, fetch)
│   ├── fund.md
│   ├── stock.md
│   ├── news.md
│   ├── global-index.md
│   └── market-resolve.md
└── python/            ← Python SDK (akshare)
    ├── profiles.md    ← SDK shared metadata
    ├── fund.md
    └── stock.md
```

### Language Board Conventions

| Rule | Detail |
|------|--------|
| **Directory = Language** | Each subdirectory under `api/` is a language board (e.g. `browser/`, `python/`) |
| **Priority** | browser → python → future languages, in order |
| **Same filenames** | `fund.md` / `stock.md` etc. are reused across boards — routing replaces the directory prefix only |
| **profiles.md** | Shared SDK metadata; filename always `profiles.md`; not a board file (no `## N.` API entries) |
| **No tushare** | Only free, no-auth-required SDKs. Paid/token-gated SDKs are excluded |

## Contributing New APIs

### When a user provides raw API info (URL, params, description — any format)

**Step 1 — 整理（只读，不写文件）：** 读取用户的原始内容（对话描述或文件均可）。解析 URL、参数、说明，归类到对应板块和语言板（browser/fund.md, python/stock.md, 新建等）。此步骤仅在内存中整理，**不写入任何文件**。

**Step 2 — 验证：** Follow the validation rules in "Project Maintenance → Validate APIs" below. Mark each API ✅ available / ⚠️ not-installed / ❌ failed.

**Step 2.5 — 暂存失败接口：** 对验证失败的接口，按失败类型判断是否暂存：
- **暂存** → `network`（Connection reset / ECONNREFUSED / ENETUNREACH）、`timeout`（ETIMEDOUT / Timeout）、`unknown`（其他不明原因）
- **不暂存** → `confirmed-dead`（HTTP 404/410、DNS 解析失败 NXDOMAIN、返回明确错误业务码）

暂存的接口写入 `pending/` 目录，文件名格式 `{board-key}-{YYYYMMDD-HHmmss}.md`，包含时间、提交者、失败原因、失败类型、重试次数、来源接口等信息。Retry Count 达到 5 后自动标记为 `confirmed-dead`。

**Step 3 — 确认：** 展示整理后的 API 清单和验证结果，询问用户是否继续。用户可选择停止。

**Step 4 — 生成文档 + 维护：**
- **默认只写入 ✅ 已通过验证的 API** 到对应 `api/{language}/{board}.md`
- 除非用户明确要求也写入 ❌ 未通过的
- 以标准格式追加到文件末尾（序号递增）
- 执行 Project Maintenance 流程 → 更新所有下游文件
- 如用户提供的是原始文件，完成后删除原始文件（除非用户要求保留）

**Step 5 — 输出完整分析报告：** 分析报告、修改记录、最终结论

### Standard Format (Step 4 write rules)

#### Single-channel format (backward compatible, one implementation only)

```markdown
## {N}. {English Title} {中文标题}

​```
GET {full URL with {placeholder} for variable parts}
​```

- **Transport**: {jsonp / script / apidata / fetch / fetch-gbk / none}
- **Parameters**:
  - `{name}` — 参数说明（默认: `{value}`）
- **Response**: `{ field: description }`
- **Notes**: rate limits, fallbacks, special parsing, etc.
```

#### Multi-channel format (same capability, multiple implementations)

```markdown
## {N}. {English Title} {中文标题}

| Channel | Transport | Call | Freshness |
|---------|-----------|------|-----------|
| web | jsonp | `GET https://.../{code}.js?rt={timestamp}` | realtime |
| akshare | →akshare | `ak.fund_etf_hist_sina(symbol="{code}")` | historical |

- **Fallback**: web → akshare（按运行环境自动跳过不可用 Channel）
- **Requires**:
  - akshare: `pip install akshare`
- **Parameters**:
  - `{code}` — 代码（默认: `110011`）
- **Response**:
  - web: `{ fundcode, name, gz, dwjz, gszzl }`
  - akshare: `DataFrame[日期, 开盘, 收盘, 最高, 最低, 成交量]`
- **Notes**: ...
```

#### SDK Profile reference

In a board file, if multiple entries share the same SDK, define it once in `profiles.md` and reference with `→{profile_name}` in the Channel table's Transport column.

```markdown
# Python Fund SDK

Profiles: [→ profiles.md](profiles.md)

---

## 1. Real-time ETF Valuation 实时ETF估值

| Channel | Transport | Call | Freshness |
|---------|-----------|------|-----------|
| akshare | →akshare | `ak.fund_etf_spot_em()` | realtime |
...
```

#### Format conversion rules

- Title must have both English and Chinese
- URL variables use `{placeholder}` syntax, defaults go in **Parameters** list
- Do NOT use `{name:default}` inline defaults in URLs
- Transport must be one of:
  - Browser: `jsonp`, `script`, `apidata`, `fetch`, `fetch-gbk`, `none`
  - Python SDK: `pip`, `pip+token`
  - Node.js SDK: `npm`, `npm+token`
  - CLI: `cli`
- If JSONP callback is fixed `jsonpgz`, note it in Transport
- If appending to existing file, continue numbering from last entry
- **Preserve each API's unique format**, do not cross-replace globally

#### Channel table field conventions

| Field | Required | Description | Example |
|:-----:|:--------:|-------------|---------|
| Channel | ✅ | Channel name, unique within entry | `web`, `akshare` |
| Transport | ✅ | Transport type or `→{profile}` | `jsonp`, `→akshare` |
| Call | ✅ | Call statement | URL or function call |
| Freshness | ❌ | Data freshness | `realtime`, `delayed`, `historical` |

### Adding a New Language Board

When adding a new language (e.g. `node/`):

1. Create `api/{language}/` directory
2. Create `profiles.md` with SDK metadata
3. Create board files (fund.md, stock.md, etc.) following the multi-channel format
4. Execute Project Maintenance to update all downstream files

### Adding a New API to an Existing Board

1. Determine which language board(s) it belongs to
2. If the capability already exists in another board, add a new Channel row to the existing entry
3. If it's a new capability, append as a new numbered `## N.` entry
4. Execute Project Maintenance to update all downstream files

### Modifying an Existing API

- **Change call signature**: Update the Channel table's `Call` column + `Parameters` section
- **Change transport**: Update `Transport` column + `Requires` section
- **Deprecate a channel**: Remove the Channel row, update `Fallback` order
- **Deprecate an API**: Remove the entire `## N.` section, renumber subsequent entries, execute Project Maintenance

### When a user drops a raw file into the project root

If the user provides a file like `fund11111.md` or `my-apis.txt` in the project root:

1. Read the file content
2. Follow Steps 1–5 above (整理 → 验证 → 确认 → 写入+维护 → 报告)
3. After successful integration, delete the original raw file (unless user requests to keep it)

### Special case: "只生成 api 文件"

When the user explicitly says they only want the api file generated (e.g., "只生成 api 文件"):
- Execute Step 1 (整理) + write to `api/{language}/{board}.md` only
- Skip Step 2 (验证), Step 4's maintenance, and Step 5 (报告)

## Project Maintenance

When `api/` files are added, modified, or deleted — or when the user says "同步"/"更新下游文件"/"运行维护" — execute these steps **in order**:

### Step M1: Scan Structure

Read all `api/{language}/{board}.md` files (skip `profiles.md`). For each file, identify:
- Language (directory name)
- Board name (filename without .md)
- API entries (each `## N.` heading)
- Key capabilities (API names from titles)

### Step M2: Update `references/api-urls.md`

Replace the `<!-- AUTO-API-INDEX START -->` ... `<!-- AUTO-API-INDEX END -->` section.

Format: **Pointer index** — each entry has a → link to the source file + minimal call info.

For browser APIs:
```markdown
### {N}. {English Title} {Chinese Title} → [{lang}/{board}.md#{N}](../api/{lang}/{board}.md)
`GET {url}` · {Method} · Auth: None
```

For SDK APIs:
```markdown
### {N}. {English Title} {Chinese Title} → [{lang}/{board}.md#{N}](../api/{lang}/{board}.md)
→{profile} · `{call_statement}` · {freshness} · Auth: None
```

Group entries by language board. Number sequentially across all boards (browser first, then python, etc.).

### Step M3: Update `SKILL.md` Quick Reference

Replace the `<!-- AUTO-QUICK-REF START -->` ... `<!-- AUTO-QUICK-REF END -->` section.

Format:
```markdown
| Board | File | Key Capabilities |
|-------|------|-----------------|
| 🌐 基金 | `api/browser/fund.md` | 实时估值, 基金详情, ... |
| 🐍 基金 | `api/python/fund.md` | 实时ETF估值, 历史净值, ... |

| Reference | File |
|-----------|------|
| API Index (pointer to source files) | `references/api-urls.md` |
| Data-source strategy & fallback | `references/data-sources.md` |
| Common errors & fixes | `references/errors.md` |
```

### Step M4: Update `README.md`

Replace two sections:
- `<!-- AUTO-BOARD-TABLE START -->` ... `<!-- AUTO-BOARD-TABLE END -->` — same format as SKILL.md Quick Ref, with 接口 count column
- `<!-- AUTO-PROJECT-TREE START -->` ... `<!-- AUTO-PROJECT-TREE END -->` — project tree with nested language directories under api/

### Step M5: Validate APIs

**Browser APIs** — Use Bash `curl`:
```bash
curl -s "{test_url}" | head -c 500
```
- Fill URL placeholders with defaults (code=110011, keyword=沪深300, etc.)
- JSONP: check response contains callback pattern
- script: check response contains JS variable assignment
- fetch/fetch-gbk: check HTTP 200 + body length > 10
- Mark ✅ / ❌ with reason

**SDK APIs** — Use Bash pip + python3:
```bash
pip show {pkg}          # Check installation
# If not installed: offer to install (pip install {pkg}) or prompt user
python3 -c "import {module}; {sample_call}"  # Sample call if installed
```
- If package not installed: print prompt asking user to install, or auto-install
- If installed: try one sample call per package
- Same package → validate only once, skip repeated calls

**Pending APIs** — If `pending/` directory exists:
- Read each pending file
- Retry validation per the rules above
- Pass → merge back to board file + delete pending file
- Still fail → update Retry Count +1 and Date
- Retry Count ≥ 5 → mark `confirmed-dead`

**Failure classification** — Same rules as Step 2.5 above.

### Step M6: Report

Output:
1. Files modified (api-urls.md, SKILL.md, README.md)
2. Validation summary per board (✅/❌ counts)
3. Pending status
4. Overall conclusion

## Core Rules

1. **Language board separation** — Each language lives under `api/{language}/`. Board files (fund.md, stock.md, etc.) are organized by data domain, not by transport.
2. **Transport conventions**
   - EastMoney / TianTianFund APIs → JSONP (callback param `cb=` or fixed `jsonpgz`)
   - `pingzhongdata` / `fundcode_search` → `<script>` tag (reads window global vars)
   - Tencent quotes → `fetch` + `TextDecoder('gbk')`
   - Overseas RSS → `fetch` + rss2json.com proxy
   - Python SDK (AkShare) → `pip`
   - Node.js SDK → `npm` or `npm+token`
3. **Channel & Fallback** — Each capability may have multiple Channels (web / akshare etc.). Prefer Channels matching the current runtime Env. Fallback order is defined per-API; skip Channels whose Env doesn't match or whose Requires aren't met.
4. **Rate limiting** — Batch requests ≤ 50 per batch; inter-batch delay ≥ 100 ms; concurrent limit 5 for fund valuations. SDK calls ≥ 500ms apart.
5. **Data validation** — Always validate numeric fields (nav > 0, finite rate, etc.) before returning. Discard malformed entries silently.
6. **Code normalization** — Stock codes may arrive with suffixes (.US/.HK/.SZ/.SH) or market prefixes (sh/sz/hk/us/jp); strip before API call, reconstruct secid as `{market}.{code}`.
7. **No paid SDKs** — Only free, no-auth-required data sources. Token-gated or paid services are excluded.
8. **AI-driven maintenance** — No sync scripts. When project files change, AI follows the Project Maintenance rules (M1–M6) to update all downstream files. This eliminates code parsing bugs and ensures AI understands content rather than mechanically transforming it.

## Quick Reference

<!-- AUTO-QUICK-REF START -->
| Board | File | Key Capabilities |
|-------|------|-----------------|
| 🌐 基金 | `api/browser/fund.md` | 实时估值, 基金详情, 历史净值, 基金搜索, 全量目录, 基金持仓, 盘中估值走势 |
| 🌐 全球指数 | `api/browser/global-index.md` | A-Share Indices |
| 🌐 市场解析 | `api/browser/market-resolve.md` | 腾讯智能搜索 |
| 🌐 财经资讯 | `api/browser/news.md` | 新浪财经, 东方财富快讯, Overseas RSS — Yahoo Finance |
| 🌐 股票 | `api/browser/stock.md` | 批量行情, 股票搜索, 昨日涨跌, 腾讯行情 |
| 🐍 基金 | `api/python/fund.md` | 实时ETF估值, 历史净值, 基金基本信息, 基金排行, 基金持仓, 基金经理, ETF列表 |
| 🐍 股票 | `api/python/stock.md` | A股实时行情, 历史K线, 股票基本信息, 股票搜索, 指数行情, 多市场股票列表, 快照数据 |

| Reference | File |
|-----------|------|
| API Index (pointer to source files) | `references/api-urls.md` |
| Data-source strategy & fallback | `references/data-sources.md` |
| Common errors & fixes | `references/errors.md` |
<!-- AUTO-QUICK-REF END -->
