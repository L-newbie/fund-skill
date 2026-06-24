# News API Board — 财经资讯接口

Multi-source aggregation: Sina + EastMoney + overseas RSS. Any source failure does not affect others.

## 1. Sina Finance 新浪财经

```
GET https://feed.mix.sina.com.cn/api/roll/get?pageid=153&lid={lid:2509}&k=&num=50&page={page:1}&callback={cb}
```

- **Transport**: JSONP with custom callback name
- **lid categories**:
  | lid | Category |
  |-----|----------|
  | 2509 | 财经要闻 |
  | 2510 | 宏观 |
  | 2511 | 行业 |
  | 2512 | 公司 |
  | 2513 | 市场 |
- **Response**: `{ result: { data: [{ title, url, ctime, media_name }] } }`
  - `ctime` — Unix timestamp (seconds)
- **Filter**: Only include items where `ctime` date = today
- **Deep pagination**: Pages 5–10 for "load more"; stop when no today items

## 2. EastMoney 24h News 东方财富快讯

```
GET https://push2.eastmoney.com/api/qt/clist/get?cb={cb}&fid=ctime&po=1&pz=50&pn={page:1}&np=1&fltt=2&invt=2&fs={fs:m:0+t:6,m:0+t:80,m:1+t:2,m:1+t:23}&fields=f12,f14,f16,f17,f20
```

- **Transport**: JSONP
- **fs filter codes** (comma-join):
  | fs | Category |
  |----|----------|
  | m:0+t:6+f:!2 | 财经 |
  | m:0+t:13+f:!2 | 宏观 |
  | m:0+t:80+f:!2 | 行业 |
  | m:1+t:2+f:!2 | 公司 |
  | m:1+t:23+f:!2 | 市场 |
  | m:0+t:7+f:!2 | 债券 |
  | m:1+t:3+f:!2 | 全球 |
- **Response fields**:
  - `f12` — unique ID
  - `f14` — title
  - `f16` — source
  - `f17` — time (timestamp or "YYYY-MM-DD HH:mm:ss")
  - `f20` — URL
- **Time parsing**: `f17` may be timestamp (>1000000000) or date string; handle both
- **Filter**: Today only; dedup by title

## 3. Overseas RSS — Yahoo Finance

Proxy via rss2json.com:

```
GET https://api.rss2json.com/v1/api.json?rss_url={encodedFeedUrl:https%3A%2F%2Ffinance.yahoo.com%2Fnews%2Frssindex}
```

- **Transport**: `fetch` with 5s timeout
- **Feed**: https://finance.yahoo.com/news/rssindex
- **Response**: `{ status: "ok", items: [{ title, pubDate, link, author }] }`
- **Filter**: Today only; fail silently

## 4. Overseas RSS — CNBC

Same proxy pattern as Section 3:

- **Feed**: https://search.cnbc.com/rs/search/combinedcms/view.xml?partnerId=wrss01&id=100003114
- **Filter**: Today only; fail silently

### Aggregation

1. Fetch Sina + EastMoney in parallel; optionally add overseas RSS
2. Merge all arrays, sort by `ctime` descending
3. Dedup by title (`Set<string>`)
4. Return top N items

### Load More

- `fetchMoreNews(beforeCtime)` — fetch deeper pages from Sina (5–10) and EastMoney (4–8)
- Filter: `ctime < beforeCtime` AND today's date
