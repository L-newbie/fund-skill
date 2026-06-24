# API URLs Complete Reference

<!-- AUTO-API-URLS START -->
## 基金 Board

### 1. Real-time Valuation 实时估值
| Field | Value |
|-------|-------|
| URL | `https://fundgz.1234567.com.cn/js/{code}.js?rt={timestamp}` |
| Method | JSONP |
| Callback | `jsonpgz` (fixed, not customizable) |
| Auth | None |
| Transport | : JSONP, fixed callback name `jsonpgz` |
| Concurrency | : Multiple concurrent requests to same fundcode → use jsonpgz dispatcher (see `references/errors.md`) |
| Response | : `{ fundcode, name, gztime, gz, dwjz, gszzl }` |
| T+1 / T+2 | : Compare `jzrq` (NAV date from F10 lsjz) with `gztime` date to decide if confirmed data is available |
| Retry | : Up to 2 retries with 300ms×attempt delay on network failure |
| Fallback | : On persistent failure → use F10 lsjz (Section 3) |

### 2. Fund Detail (pingzhongdata) 基金详情
| Field | Value |
|-------|-------|
| URL | `https://fund.eastmoney.com/pingzhongdata/{code}.js?rt={timestamp}` |
| Method | `<script>` tag |
| Auth | None |
| Transport | : `<script>` tag injection — script sets window global variables |
| Concurrency | : MUST serialize requests via queue (see `references/errors.md` — global var overwrite) |
| Key globals after load | : |
| Cleanup | : Set all read globals to `undefined` after extraction |
| Fallback | : If no `Data_netWorthTrend` → use NAV history range (Section 3). If no `fS_name` → use search API (Section 4) |

### 3. Historical NAV (F10 lsjz) 历史净值
| Field | Value |
|-------|-------|
| URL | `https://fundf10.eastmoney.com/F10DataApi.aspx?type=lsjz&code={code}&page={page:1}&per={perPage:10}&sdate={sdate:}&edate={edate:}` |
| Method | `<script>` tag |
| Auth | None |
| Transport | : `<script>` tag — sets `window.apidata`, hybrid format (`var apidata = {...}` or `apidata({...})`) |
| Response | : `{ content: "<table>...</table>", page, records, pages }` |
| Parse | : Extract `<tr>` rows → date / NAV / growth % from HTML table cells |
| Pagination | : Default `per=500`, loop until `batch.length < per` |

### 4. Fund Search 基金搜索
| Field | Value |
|-------|-------|
| URL | `https://fundsuggest.eastmoney.com/FundSearch/api/FundSearchAPI.ashx?m=1&key={keyword}&pageSize=50&callback={cb}` |
| Method | JSONP |
| Auth | None |
| Transport | : JSONP with custom callback name |
| Response | : `{ Datas: [{ CODE, NAME, FUNDTYPE, FundCode, FundName, FundType }] }` |
| Min query length | : 2 characters |
| Dedup | : Filter entries where `CODE` or `NAME` is empty |

### 5. Fund Code Catalog 全量目录
| Field | Value |
|-------|-------|
| URL | `https://fund.eastmoney.com/js/fundcode_search.js` |
| Method | `<script>` tag |
| Auth | None |
| Transport | : `<script>` tag — sets `var r = [[code,pinyin,name,type,pinyin_full], ...]` |
| Cache | : 24h localStorage persistence with key `jgb_fund_catalog` |
| Shared promise | : Concurrent calls reuse single in-flight request |
| Usage | : Fund type lookup, name lookup, pinyin autocomplete |

### 6. Fund Holdings 基金持仓
| Field | Value |
|-------|-------|
| URL | `https://fundf10.eastmoney.com/FundArchivesDatas.aspx?type=jjcc&code={code}&topline={topline:10}&year={year:}&month={month:}&_={timestamp}` |
| Method | `<script>` tag |
| Auth | None |
| Transport | : `<script>` tag — sets `window.apidata` (hybrid format) |
| Parameters | : |
| Response | : `{ content: "<table>...</table>" }` — parse `<thead>` columns + `<tbody>` rows |
| Parse | : Dynamic column mapping (detect "股票代码"/"证券代码"/"基金代码" in `<th>`), extract code/name/ratio/emMarketCode from links |
| Market resolve | : After parsing, call `market-resolve` board to supplement `emMarketCode` for each holding |
| Report type detection | : Report month → Q1(03)/H1(06)/Q3(09)/Annual(12); H1 & Annual = full holdings |

### 7. Intraday Estimate 盘中估值走势
| Field | Value |
|-------|-------|
| URL | `https://stock.finance.sina.com.cn/fundInfo/api/openapi.php/FdFundService.getEstimateNetworthPic?symbol={code}&callback={cb}` |
| Method | JSONP |
| Auth | None |
| Transport | : JSONP with custom callback name |
| Response | : `{ result: { data: { networth: [{min_time, pre_nav}] } } }` |
| Filter | : `min_time` must exist and `pre_nav > 0` |

---

## 全球指数 Board

### 8. A-Share Indices
| Field | Value |
|-------|-------|
| URL | `https://push2.eastmoney.com/api/qt/ulist.np/get?fltt=2&secids={secids:1.000001}&fields=f2,f3,f4,f12,f14&cb={callback}` |
| Method | JSONP |
| Auth | None |
| Transport | : JSONP |
| Matching | : push2 returns `f12` — match by secid first, fallback to code |
| Fallback | : Missing quotes → fill with zero values + preset name |

**Response**:

| Index | Field | Description |
|-------|-------|-------------|
| secid | | Code |
| Market | | |------- |
| 000001 | | 上证指数 |
| 399001 | | 深证成指 |
| 399006 | | 创业板指 |
| 000688 | | 科创50 |
| 000300 | | 沪深300 |
| 000905 | | 中证500 |
| 000016 | | 上证50 |
| 399673 | | 创业板50 |

---

## 市场解析 Board

### 9. Tencent Smartbox 腾讯智能搜索
| Field | Value |
|-------|-------|
| URL | `https://smartbox.gtimg.cn/s3/?q={keyword}&t=all` |
| Method | `<script>` tag |
| Auth | None |
| Transport | : `<script>` tag — sets `window.v_hint` global variable |
| Timeout | : 5000ms |
| Response format | : `name~code~tencentMarket^name~code~tencentMarket^...` |
| Parse | : Split by `^`, then split each entry by `~`, extract `{name, code, tencentMarket}` |

---

## 财经资讯 Board

### 10. Sina Finance 新浪财经
| Field | Value |
|-------|-------|
| URL | `https://feed.mix.sina.com.cn/api/roll/get?pageid=153&lid={lid:2509}&k=&num=50&page={page:1}&callback={cb}` |
| Method | JSONP |
| Auth | None |
| Transport | : JSONP with custom callback name |
| lid categories | : |
| Response | : `{ result: { data: [{ title, url, ctime, media_name }] } }` |
| Filter | : Only include items where `ctime` date = today |
| Deep pagination | : Pages 5–10 for "load more"; stop when no today items |

**Response**:

| Index | Field | Description |
|-------|-------|-------------|
| lid | | Category |
| 2509 | | 财经要闻 |
| 2510 | | 宏观 |
| 2511 | | 行业 |
| 2512 | | 公司 |
| 2513 | | 市场 |

### 11. EastMoney 24h News 东方财富快讯
| Field | Value |
|-------|-------|
| URL | `https://push2.eastmoney.com/api/qt/clist/get?cb={cb}&fid=ctime&po=1&pz=50&pn={page:1}&np=1&fltt=2&invt=2&fs={fs:m:0+t:6,m:0+t:80,m:1+t:2,m:1+t:23}&fields=f12,f14,f16,f17,f20` |
| Method | JSONP |
| Auth | None |
| Transport | : JSONP |
| fs filter codes | (comma-join): |
| Response fields | : |
| Time parsing | : `f17` may be timestamp (>1000000000) or date string; handle both |
| Filter | : Today only; dedup by title |

**Response**:

| Index | Field | Description |
|-------|-------|-------------|
| fs | | Category |

### 12. Overseas RSS — Yahoo Finance
| Field | Value |
|-------|-------|
| URL | `https://api.rss2json.com/v1/api.json?rss_url={encodedFeedUrl:https%3A%2F%2Ffinance.yahoo.com%2Fnews%2Frssindex}` |
| Method | `fetch` |
| Auth | None |
| Transport | : `fetch` with 5s timeout |
| Feed | : https://finance.yahoo.com/news/rssindex |
| Response | : `{ status: "ok", items: [{ title, pubDate, link, author }] }` |
| Filter | : Today only; fail silently |

---

## 股票 Board

### 13. Batch Stock Quotes 批量行情
| Field | Value |
|-------|-------|
| URL | `https://push2.eastmoney.com/api/qt/ulist.np/get?fltt=2&secids={secids:1.000001}&fields=f2,f3,f4,f12,f14&cb={callback}` |
| Method | JSONP |
| Auth | None |
| Transport | : JSONP with custom callback name |
| secids format | : comma-separated `{market}.{code}` pairs, e.g. `1.600519,0.000001,116.00700` |
| Market code mapping | : |
| Batch size | : Max 50 per request; split larger arrays |
| Response fields | : |
| Full quotes | : Add fields `f2,f3,f4,f12,f14` for basic; `f2,f3,f4,f12,f14,f15,f16,f17,f18` for extended |

**Response**:

| Index | Field | Description |
|-------|-------|-------------|
| Market | | Code |
| 1 | | | 深A |
| 116 | | | 美股 |
| 124 | | | 韩股 |
| 118 | | | 德股 |
| 156 | | | 英股 |
| 173 | | | 印度 |
| 175 | | | 澳股 |

### 14. Stock Search 股票搜索
| Field | Value |
|-------|-------|
| URL | `https://searchapi.eastmoney.com/api/suggest/get?input={keyword}&type=14&token=D43BF722C8E33BDC906FB84D85E326E8&count=10&cb={callback}` |
| Method | JSONP |
| Auth | None |
| Transport | : JSONP with custom callback name |
| Features | : Fuzzy match by code, name, or pinyin; covers A/HK/US/JP/KR/TW/EU |
| Response | : `{ QuotationCodeTable: { Data: [{ Code, Name, MktNum }] } }` |
| Market label map | (`MktNum` → label): |
| Max results | : Limit to 15, deduplicate by `code|market` |

**Response**:

| Index | Field | Description |
|-------|-------|-------------|
| MktNum | | Label |
| 1 | | 沪 |
| 0 | | 深 |
| 116 | | 港 |
| 124 | | 日 |
| 130 | | 韩 |
| 118 | | 台 |
| 155 | | 德 |
| 156 | | 法 |
| 157 | | 英 |
| 173 | | 巴 |
| 174 | | 印 |
| 175 | | 新 |
| 177 | | 澳 |

### 15. Yesterday's Change (A-share) 昨日涨跌
| Field | Value |
|-------|-------|
| URL | `https://push2his.eastmoney.com/api/qt/stock/kline/get?secid={secid:1.600519}&fields1=f1,f2,f3,f4,f5,f6&fields2=f51,f52,f53,f54,f55,f56,f57&klt=101&fqt=0&end=20500101&lmt=6&cb={callback}` |
| Method | JSONP |
| Auth | None |
| Transport | : JSONP |
| Domain | : `push2his` for A-share/JP/KR/TW |
| Response | : `{ data: { klines: ["date,open,close,high,low,volume,amount", ...] } }` |
| Calculate | : Find latest non-today row → `changeRate = (close_today - close_prev) / close_prev × 100` |
| Batch | : Process ≤5 stocks concurrently, 50ms inter-batch delay |

### 16. Tencent Quotes 腾讯行情
| Field | Value |
|-------|-------|
| URL | `https://qt.gtimg.cn/q={codes:sh600519}` |
| Method | `fetch` (GBK encoded) |
| Auth | None |
| Transport | : `fetch` — response is GBK-encoded text |
| Decode | : `new TextDecoder('gbk').decode(arrayBuffer)` |
| codes format | : `{prefix}{code}`, prefix mapping: |
| Parse | : Split by `\n`, match `v_{code}="field~field~..."`, fields[32] = change rate %, fields[5] = fallback change rate |
| Usage | : Primary source for US/EU/other markets where EastMoney push2 lacks support |

**Response**:

| Index | Field | Description |
|-------|-------|-------------|
| Market | | Prefix |
| sh | | | A (深) |
| HK | | hk |
| US | | us |
| JP | | jp |
| KR | | kr |
| TW | | t_ |
| DE | | r_de |
| FR | | r_fr |
| UK | | r_uk |
| SG | | r_sg |
| AU | | r_au |
<!-- AUTO-API-URLS END -->

---

## Fund Board

### 1. Valuation 估值
| Field | Value |
|-------|-------|
| URL | `https://fundgz.1234567.com.cn/js/{fundCode}.js?rt={timestamp}` |
| Method | JSONP |
| Callback | `jsonpgz` (fixed, not customizable) |
| Auth | None |
| Rate | ≤5 concurrent; no explicit rate limit |

**Response**:
```json
{
  "fundcode": "110011",
  "name": "易方达中小盘混合",
  "gztime": "2024-01-15 15:00",
  "gz": "4.5678",
  "dwjz": "4.5500",
  "gszzl": "0.39"
}
```

### 2. Fund Detail 详情
| Field | Value |
|-------|-------|
| URL | `https://fund.eastmoney.com/pingzhongdata/{fundCode}.js?rt={timestamp}` |
| Method | `<script>` tag |
| Global Vars | `Data_netWorthTrend`, `fS_name`, `fS_type`, etc. |
| Auth | None |

### 3. Historical NAV 历史净值
| Field | Value |
|-------|-------|
| URL | `https://fundf10.eastmoney.com/F10DataApi.aspx` |
| Params | `type=lsjz`, `code={fundCode}`, `page={n}`, `per={n}`, `sdate=YYYY-MM-DD`, `edate=YYYY-MM-DD` |
| Method | `<script>` tag (hybrid: `var apidata = {...}` or `apidata({...})`) |
| Global Var | `window.apidata` |

### 4. Fund Search 搜索
| Field | Value |
|-------|-------|
| URL | `https://fundsuggest.eastmoney.com/FundSearch/api/FundSearchAPI.ashx` |
| Params | `m=1`, `key={keyword}`, `pageSize=50`, `callback={cb}` |
| Method | JSONP |

### 5. Fund Catalog 目录
| Field | Value |
|-------|-------|
| URL | `https://fund.eastmoney.com/js/fundcode_search.js` |
| Method | `<script>` tag |
| Global Var | `var r = [...]` |
| Size | ~3MB |

### 6. Fund Holdings 持仓
| Field | Value |
|-------|-------|
| URL | `https://fundf10.eastmoney.com/FundArchivesDatas.aspx` |
| Params | `type=jjcc`, `code={fundCode}`, `topline={10|200}`, `year={YYYY}`, `month={n}`, `_={timestamp}` |
| Method | `<script>` tag (hybrid apidata) |

### 7. Intraday Estimate 盘中走势
| Field | Value |
|-------|-------|
| URL | `https://stock.finance.sina.com.cn/fundInfo/api/openapi.php/FdFundService.getEstimateNetworthPic` |
| Params | `symbol={fundCode}`, `callback={cb}` |
| Method | JSONP |

---

## Stock Board

### 8. Batch Quotes 批量行情
| Field | Value |
|-------|-------|
| URL | `https://push2.eastmoney.com/api/qt/ulist.np/get` |
| Params | `fltt=2`, `secids={market.code,...}`, `fields=f2,f3,f4,f12,f14`, `cb={cb}` |
| Method | JSONP |
| Batch | ≤50 secids per request |

### 9. Stock Search 搜索
| Field | Value |
|-------|-------|
| URL | `https://searchapi.eastmoney.com/api/suggest/get` |
| Params | `input={keyword}`, `type=14`, `token=D43BF722C8E33BDC906FB84D85E326E8`, `count=10`, `cb={cb}` |
| Method | JSONP |

### 10. A-share K-line (yesterday change)
| Field | Value |
|-------|-------|
| URL | `https://push2his.eastmoney.com/api/qt/stock/kline/get` |
| Params | `secid={market.code}`, `fields1=f1,f2,f3,f4,f5,f6`, `fields2=f51,f52,f53,f54,f55,f56,f57`, `klt=101`, `fqt=0`, `end=20500101`, `lmt=6`, `cb={cb}` |
| Method | JSONP |
| Domain | `push2his` for A/JP/KR/TW |

### 11. HK K-line (yesterday change)
| Field | Value |
|-------|-------|
| URL | `https://push2.eastmoney.com/api/qt/stock/kline/get` |
| Params | Same as #10 but `secid=116.{code5}` |
| Method | JSONP |
| Domain | `push2` (push2his does not support HK) |

### 12. Tencent Quotes 腾讯行情
| Field | Value |
|-------|-------|
| URL | `https://qt.gtimg.cn/q={prefix}{code},...` |
| Method | `fetch` (GBK encoded) |
| Decode | `TextDecoder('gbk')` |
| Rate | 10s timeout |
| Fields | `v_{prefix}{code}="~field~..."` — field[32]=changeRate, field[5]=fallback |

---

## Global Index Board

### 13. Index Quotes
Same as #8. Use secids from INDEX_PRESETS table.

---

## News Board

### 14. Sina Finance 新浪财经
| Field | Value |
|-------|-------|
| URL | `https://feed.mix.sina.com.cn/api/roll/get` |
| Params | `pageid=153`, `lid={2509-2513}`, `num=50`, `page={n}`, `callback={cb}` |
| Method | JSONP |

### 15. EastMoney News 东方财富快讯
| Field | Value |
|-------|-------|
| URL | `https://push2.eastmoney.com/api/qt/clist/get` |
| Params | `cb={cb}`, `fid=ctime`, `po=1`, `pz=50`, `pn={n}`, `np=1`, `fltt=2`, `invt=2`, `fs={fs}`, `fields=f12,f14,f16,f17,f20` |
| Method | JSONP |

### 16. Overseas RSS (rss2json proxy)
| Field | Value |
|-------|-------|
| URL | `https://api.rss2json.com/v1/api.json?rss_url={encoded}` |
| Method | `fetch` |
| Timeout | 5s |
| Sources | Yahoo Finance, CNBC, MarketWatch |

---

## Market Resolve Board

### 17. Tencent Smartbox
| Field | Value |
|-------|-------|
| URL | `https://smartbox.gtimg.cn/s3/?q={keyword}&t=all` |
| Method | `<script>` tag |
| Global Var | `window.v_hint` |
| Timeout | 5s |
