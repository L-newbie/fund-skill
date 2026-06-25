# Fund API Board — 基金接口

## 1. Real-time Valuation 实时估值

```
GET https://fundgz.1234567.com.cn/js/{code}.js?rt={timestamp}
```

- **Transport**: JSONP, fixed callback name `jsonpgz`
- **Concurrency**: Multiple concurrent requests to same fundcode → use jsonpgz dispatcher (see `references/errors.md`)
- **Response**: `{ fundcode, name, gztime, gz, dwjz, gszzl }`
  - `gz` — estimated NAV (估算净值)
  - `gszzl` — estimated change rate % (估算涨跌幅)
  - `dwjz` — last confirmed NAV (单位净值)
- **T+1 / T+2**: Compare `jzrq` (NAV date from F10 lsjz) with `gztime` date to decide if confirmed data is available
- **Retry**: Up to 2 retries with 300ms×attempt delay on network failure
- **Fallback**: On persistent failure → use F10 lsjz (Section 3)

## 2. Fund Detail (pingzhongdata) 基金详情

```
GET https://fund.eastmoney.com/pingzhongdata/{code}.js?rt={timestamp}
```

- **Transport**: `<script>` tag injection — script sets window global variables
- **Concurrency**: MUST serialize requests via queue (see `references/errors.md` — global var overwrite)
- **Key globals after load**:
  - `Data_netWorthTrend` — `[{x: ms_timestamp, y: nav, equityReturn: "rate"}]`
  - `fS_name` — fund name
  - `fS_type` — fund type code ("001" stock, "002" hybrid, "003" bond, "004" index, "005" QDII, "006" FOF, "007" money)
  - `Data_currentFundManager` — `[{name, ...}]`
  - `Data_fluctuationScale` — `[{money, assetMoney, ...}]`
  - `syl_1y / syl_3y / syl_6y / syl_1n` — period returns %
  - `Data_assetAllocation` — `[{assetAllocationList: [{name, ratio}]}]`
  - `Data_fundSharesPositions` — `[{fundSharesPositionsList: [{code, name, ratio}]}]`
  - `Data_holderStructure` — `[{holderStructureList: [{name, ratio}]}]`
  - `Data_rateInSimilarType` — `[{rank: "cur|total"}]`
  - `Data_performanceEvaluation` — `[{title, data}]`
  - `fS_purchaseStatus / fS_redeemStatus`
  - `fund_Rate` — purchase fee rate
  - `fund_minsg` — min purchase amount
- **Cleanup**: Set all read globals to `undefined` after extraction
- **Fallback**: If no `Data_netWorthTrend` → use NAV history range (Section 3). If no `fS_name` → use search API (Section 4)

## 3. Historical NAV (F10 lsjz) 历史净值

```
GET https://fundf10.eastmoney.com/F10DataApi.aspx?type=lsjz&code={code}&page={page}&per={perPage}&sdate={sdate}&edate={edate}
```

- **Transport**: `<script>` tag — sets `window.apidata`, hybrid format (`var apidata = {...}` or `apidata({...})`)
- **Parameters**:
  - `code` — 基金代码（默认: `110011`）
  - `page` — 页码（默认: `1`）
  - `PerPage` — 每页条数（默认: `10`）
  - `sdate` — 开始日期（默认: 空）
  - `edate` — 结束日期（默认: 空）
- **Response**: `{ content: "<table>...</table>", page, records, pages }`
- **Parse**: Extract `<tr>` rows → date / NAV / growth % from HTML table cells
- **Pagination**: Default `per=500`, loop until `batch.length < per`

## 4. Fund Search 基金搜索

```
GET https://fundsuggest.eastmoney.com/FundSearch/api/FundSearchAPI.ashx?m=1&key={keyword}&pageSize=50&callback={cb}
```

- **Transport**: JSONP with custom callback name
- **Response**: `{ Datas: [{ CODE, NAME, FUNDTYPE, FundCode, FundName, FundType }] }`
- **Min query length**: 2 characters
- **Dedup**: Filter entries where `CODE` or `NAME` is empty

## 5. Fund Code Catalog 全量目录

```
GET https://fund.eastmoney.com/js/fundcode_search.js
```

- **Transport**: `<script>` tag — sets `var r = [[code,pinyin,name,type,pinyin_full], ...]`
- **Cache**: 24h localStorage persistence with key `jgb_fund_catalog`
- **Shared promise**: Concurrent calls reuse single in-flight request
- **Usage**: Fund type lookup, name lookup, pinyin autocomplete

## 6. Fund Holdings 基金持仓

```
GET https://fundf10.eastmoney.com/FundArchivesDatas.aspx?type=jjcc&code={code}&topline={topline}&year={year}&month={month}&_={timestamp}
```

- **Transport**: `<script>` tag — sets `window.apidata` (hybrid format)
- **Parameters**:
  - `code` — 基金代码（默认: `110011`）
  - `topline` — 条数，`10`=前10持仓（季报），`200`=全部（年报/中报）（默认: `10`）
  - `year` — 年份，空=最新季度（默认: 空）
  - `month` — 季度编号：1=Q1, 2=H1, 3=Q3, 4=年报（默认: 空）
- **Response**: `{ content: "<table>...</table>" }` — parse `<thead>` columns + `<tbody>` rows
- **Parse**: Dynamic column mapping (detect "股票代码"/"证券代码"/"基金代码" in `<th>`), extract code/name/ratio/emMarketCode from links
- **Market resolve**: After parsing, call `market-resolve` board to supplement `emMarketCode` for each holding
- **Report type detection**: Report month → Q1(03)/H1(06)/Q3(09)/Annual(12); H1 & Annual = full holdings

## 7. Intraday Estimate 盘中估值走势

```
GET https://stock.finance.sina.com.cn/fundInfo/api/openapi.php/FdFundService.getEstimateNetworthPic?symbol={code}&callback={cb}
```

- **Transport**: JSONP with custom callback name
- **Response**: `{ result: { data: { networth: [{min_time, pre_nav}] } } }`
- **Filter**: `min_time` must exist and `pre_nav > 0`
