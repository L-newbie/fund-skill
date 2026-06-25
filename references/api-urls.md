# API Index — 接口快速索引

每个条目指向源文件的具体章节，点击链接查看完整参数、响应格式、注意事项。

<!-- AUTO-API-INDEX START -->
## 🌐 browser

### 1. 实时估值 实时估值 → [browser/fund.md#1](../api/browser/fund.md)
`GET https://fundgz.1234567.com.cn/js/{code}.js?rt={timestamp}` · JSONP cb=jsonpgz · 无需认证

### 2. 基金详情 基金详情 → [browser/fund.md#2](../api/browser/fund.md)
`GET https://fund.eastmoney.com/pingzhongdata/{code}.js?rt={timestamp}` · script · 无需认证

### 3. 历史净值 历史净值 → [browser/fund.md#3](../api/browser/fund.md)
`GET https://fundf10.eastmoney.com/F10DataApi.aspx?type=lsjz&code={code}&page={page}&per={perPage}&sdate={sdate}&edate={edate}` · script (apidata) · 无需认证

### 4. 基金搜索 基金搜索 → [browser/fund.md#4](../api/browser/fund.md)
`GET https://fundsuggest.eastmoney.com/FundSearch/api/FundSearchAPI.ashx?m=1&key={keyword}&pageSize=50&callback={cb}` · JSONP · 无需认证

### 5. 全量目录 全量目录 → [browser/fund.md#5](../api/browser/fund.md)
`GET https://fund.eastmoney.com/js/fundcode_search.js` · script · 无需认证

### 6. 基金持仓 基金持仓 → [browser/fund.md#6](../api/browser/fund.md)
`GET https://fundf10.eastmoney.com/FundArchivesDatas.aspx?type=jjcc&code={code}&topline={topline}&year={year}&month={month}&_={timestamp}` · script (apidata) · 无需认证

### 7. 盘中估值走势 盘中估值走势 → [browser/fund.md#7](../api/browser/fund.md)
`GET https://stock.finance.sina.com.cn/fundInfo/api/openapi.php/FdFundService.getEstimateNetworthPic?symbol={code}&callback={cb}` · JSONP · 无需认证

---

### 8. A-Share Indices → [browser/global-index.md](../api/browser/global-index.md)
`GET https://push2.eastmoney.com/api/qt/ulist.np/get?fltt=2&secids={secids}&fields=f2,f3,f4,f12,f14&cb={callback}` · JSONP · 无需认证

---

### 9. 腾讯智能搜索 腾讯智能搜索 → [browser/market-resolve.md](../api/browser/market-resolve.md)
`GET https://smartbox.gtimg.cn/s3/?q={keyword}&t=all` · script · 无需认证

---

### 10. 新浪财经 新浪财经 → [browser/news.md#1](../api/browser/news.md)
`GET https://feed.mix.sina.com.cn/api/roll/get?pageid=153&lid={lid}&k=&num=50&page={page}&callback={callback}` · JSONP · 无需认证

### 11. 东方财富快讯 东方财富快讯 → [browser/news.md#2](../api/browser/news.md)
`GET https://push2.eastmoney.com/api/qt/clist/get?cb={callback}&fid=ctime&po=1&pz=50&pn={page}&np=1&fltt=2&invt=2&fs={fs}&fields=f12,f14,f16,f17,f20` · JSONP · 无需认证

### 12. Overseas RSS — Yahoo Finance → [browser/news.md#3](../api/browser/news.md)
`GET https://api.rss2json.com/v1/api.json?rss_url={encodedFeedUrl}` · fetch · 无需认证

---

### 13. 批量行情 批量行情 → [browser/stock.md#1](../api/browser/stock.md)
`GET https://push2.eastmoney.com/api/qt/ulist.np/get?fltt=2&secids={secids}&fields=f2,f3,f4,f12,f14&cb={callback}` · JSONP · 无需认证

### 14. 股票搜索 股票搜索 → [browser/stock.md#2](../api/browser/stock.md)
`GET https://searchapi.eastmoney.com/api/suggest/get?input={keyword}&type=14&token=D43BF722C8E33BDC906FB84D85E326E8&count=10&cb={callback}` · JSONP · 无需认证

### 15. 昨日涨跌 昨日涨跌 → [browser/stock.md#3](../api/browser/stock.md)
`GET https://push2his.eastmoney.com/api/qt/stock/kline/get?secid={secid}&fields1=f1,f2,f3,f4,f5,f6&fields2=f51,f52,f53,f54,f55,f56,f57&klt=101&fqt=0&end=20500101&lmt=6&cb={callback}` · JSONP · 无需认证

### 16. 腾讯行情 腾讯行情 → [browser/stock.md#4](../api/browser/stock.md)
`GET https://qt.gtimg.cn/q={codes}` · fetch-gbk · 无需认证

---

## 🐍 python

### 17. 实时ETF估值 实时ETF估值 → [python/fund.md#1](../api/python/fund.md)
→akshare · `ak.fund_etf_spot_em()` · realtime · 无需认证

### 18. 历史净值 历史净值 → [python/fund.md#2](../api/python/fund.md)
→akshare · `ak.fund_open_fund_info_em(symbol="{code}", indicator="单位净值走势")` · delayed · 无需认证

### 19. 基金基本信息 基金基本信息 → [python/fund.md#3](../api/python/fund.md)
→akshare · `ak.fund_individual_basic_info_xq(symbol="{code}")` · static · 无需认证

### 20. 基金排行 基金排行 → [python/fund.md#4](../api/python/fund.md)
→akshare · `ak.fund_open_fund_rank_em()` · delayed · 无需认证

### 21. 基金持仓 基金持仓 → [python/fund.md#5](../api/python/fund.md)
→akshare · `ak.fund_portfolio_hold_em(symbol="{code}", date="{yyyy}")` · delayed · 无需认证

### 22. 基金经理 基金经理 → [python/fund.md#6](../api/python/fund.md)
→akshare · `ak.fund_manager_em()` · delayed · 无需认证

---

### 23. A股实时行情 A股实时行情 → [python/stock.md#1](../api/python/stock.md)
→akshare · `ak.stock_zh_a_spot_em()` · realtime · 无需认证

### 24. 历史K线 历史K线 → [python/stock.md#2](../api/python/stock.md)
→akshare · `ak.stock_zh_a_hist(symbol="{code}", period="daily", start_date="{sdate}", end_date="{edate}", adjust="qfq")` · historical · 无需认证

### 25. 股票基本信息 股票基本信息 → [python/stock.md#3](../api/python/stock.md)
→akshare · `ak.stock_individual_info_em(symbol="{code}")` · static · 无需认证

### 26. 股票搜索 股票搜索 → [python/stock.md#4](../api/python/stock.md)
→akshare · `ak.stock_zh_a_spot_em()` 全量筛选 · realtime · 无需认证

### 27. 指数行情 指数行情 → [python/stock.md#5](../api/python/stock.md)
→akshare · `ak.index_zh_a_hist(symbol="{code}", period="daily", start_date="{sdate}", end_date="{edate}")` · historical · 无需认证
<!-- AUTO-API-INDEX END -->
