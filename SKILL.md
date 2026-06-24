---
name: Fund Skill
slug: fund-skill
version: 1.0.0
description: Query fund valuations, stock quotes, financial news, and global market indices from EastMoney, Sina, Tencent and overseas RSS sources.
changelog: Initial release with fund, stock, index, news, and market-resolve modules
metadata: {"emoji":"📈","requires":{"bins":[]},"os":["linux","darwin","win32"]}
---

## When to Use

- User asks for fund real-time valuation, NAV history, holdings, or fund search
- User needs stock quotes, stock search, yesterday's change, or K-line data
- User wants global index data (A-share, HK, US, JP, KR, EU indices)
- User requests financial news (Sina, EastMoney, or overseas RSS)
- User needs to resolve stock market codes across exchanges
- User provides raw API information and wants it integrated into the project

## Contributing New APIs

### When a user provides raw API info (URL, params, description — any format)

**Step 1 — Absorb:** Read the user's raw content. It can be a markdown file, plain text, or just a verbal description in conversation. No specific format required.

**Step 2 — Deduce the board:** Determine which `api/*.md` file this belongs to:
- Fund data → `fund.md`, Stock quotes → `stock.md`, Global indices → `global-index.md`
- Financial news → `news.md`, Market code mapping → `market-resolve.md`
- Unknown/new category → create a new `api/{category}.md` file

**Step 3 — Convert to standard format:** Write the content into the target `api/*.md` file using this structure per interface:

```markdown
## {序号}. {English Title} {中文标题}

​```
GET {full URL with {placeholder} for variable parts}
​```

- **Transport**: {jsonp / script / apidata / fetch / fetch-gbk / none}
- **Response**: `{ field: description }`
- **Notes**: rate limits, fallbacks, special parsing, etc.
```

Key rules for conversion:
- Title must have both English and Chinese
- URL variable parts use `{placeholder}` syntax — for placeholders that need a default value for validation, use `{name:default}` format (e.g. `{secid:1.600519}`, `{lid:2509}`, `{sdate:}` for empty default)
- Only use `{name}` without default for common placeholders like `code` (falls back to `110011`) or `keyword` (falls back to `沪深300`)
- Transport must be one of: `jsonp`, `script`, `apidata`, `fetch`, `fetch-gbk`, `none`
- If the JSONP callback is fixed as `jsonpgz`, note it explicitly in the Transport line
- Include Response structure with field names and descriptions
- If appending to an existing file, increment the section number after the last one
- **Preserve each interface's unique format** — never use global search-replace across interfaces. Each API has its own parameter names, defaults, and response structure

**Step 4 — Sync:** Run `node scripts/sync.js` (or `python3 scripts/sync.py` / `bash scripts/sync.sh`) to auto-update all downstream files:
- `validator/index.html` — front-end validation page
- `SKILL.md` — Quick Reference table
- `README.md` — board table + project tree
- `references/api-urls.md` — API URL reference

The sync script parses markdown structure (headings + code blocks + Transport lines) — **no metadata comments needed**.

### When a user drops a raw file into the project root

If the user provides a file like `fund11111.md` or `my-apis.txt` in the project root:

1. Read the file content
2. Follow Steps 2–4 above to convert and integrate
3. Optionally delete the original raw file after successful integration

## Core Rules

1. **Board separation** — Fund / Stock / GlobalIndex / News / MarketResolve each has its own API file under `api/`. Read only the relevant file for the user's request.
2. **Transport conventions**
   - EastMoney / TianTianFund APIs → JSONP (callback param `cb=` or fixed `jsonpgz`)
   - `pingzhongdata` / `fundcode_search` → `<script>` tag (reads window global vars)
   - Tencent quotes → `fetch` + `TextDecoder('gbk')`
   - Overseas RSS → `fetch` + rss2json.com proxy
3. **Fallback chain** — Fund valuation: `fundgz` → `F10 lsjz`. Pingzhongdata empty → `searchFunds`. Any source fails → return null / empty, never throw to caller.
4. **Rate limiting** — Batch requests ≤ 50 per batch; inter-batch delay ≥ 100 ms; concurrent limit 5 for fund valuations.
5. **Data validation** — Always validate numeric fields (nav > 0, finite rate, etc.) before returning. Discard malformed entries silently.
6. **Code normalization** — Stock codes may arrive with suffixes (.US/.HK/.SZ/.SH) or market prefixes (sh/sz/hk/us/jp); strip before API call, reconstruct secid as `{market}.{code}`.

## Quick Reference

<!-- AUTO-QUICK-REF START -->
| Board | File | Key Capabilities |
|-------|------|-----------------|
| 📊 基金 | `api/fund.md` | 实时估值, 基金详情, 历史净值, 基金搜索, 全量目录, 基金持仓, 盘中估值走势 |
| 🌍 全球指数 | `api/global-index.md` | A-Share Indices |
| 🔍 市场解析 | `api/market-resolve.md` | 腾讯智能搜索 |
| 📰 财经资讯 | `api/news.md` | 新浪财经, 东方财富快讯, Overseas RSS — Yahoo Finance |
| 📈 股票 | `api/stock.md` | 批量行情, 股票搜索, 昨日涨跌, 腾讯行情 |

| Reference | File |
|-----------|------|
| Full API URL list & params | `references/api-urls.md` |
| Data-source strategy & fallback | `references/data-sources.md` |
| Common errors & fixes | `references/errors.md` |
<!-- AUTO-QUICK-REF END -->
