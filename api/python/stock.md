# Python Stock SDK

Profiles: [→ profiles.md](profiles.md)

---

## 1. Real-time A-share Quotes A股实时行情

| Channel | Transport | Call | Freshness |
|---------|-----------|------|-----------|
| akshare | →akshare | `ak.stock_zh_a_spot_em()` | realtime |

- **Fallback**: akshare (only channel for full market real-time)
- **Requires**: `pip install akshare`
- **Response**: `DataFrame[代码, 名称, 最新价, 涨跌幅, 涨跌额, 成交量, 成交额, 振幅, 最高, 最低, 今开, 昨收, ...]`
- **Notes**: 返回全市场 A 股实时行情，按代码筛选目标股票

---

## 2. Historical K-line 历史K线

| Channel | Transport | Call | Freshness |
|---------|-----------|------|-----------|
| akshare | →akshare | `ak.stock_zh_a_hist(symbol="{code}", period="daily", start_date="{sdate}", end_date="{edate}", adjust="qfq")` | historical |
| finance-datareader | →finance-datareader | `fdr.DataReader("{code}", "{sdate}", "{edate}")` | historical |

- **Fallback**: akshare → finance-datareader（按运行环境自动跳过不可用 Channel）
- **Requires**:
  - akshare: `pip install akshare`
  - finance-datareader: `pip install finance-datareader`
- **Parameters**:
  - `{code}` — 股票代码（默认: `000001`）；finance-datareader 支持多市场代码
  - `{sdate}` — 开始日期（默认: `20250101`）
  - `{edate}` — 结束日期（默认: `20261231`）
- **Response**:
  - akshare: `DataFrame[日期, 开盘, 收盘, 最高, 最低, 成交量, 成交额, 振幅, 涨跌幅, 涨跌额, 换手率, ...]`
  - finance-datareader: `DataFrame[Open, High, Low, Close, Volume, Change]`
- **Notes**:
  - akshare period: `"daily"` / `"weekly"` / `"monthly"`；adjust: `"qfq"` (前复权) / `"hfq"` (后复权) / `""` (不复权)
  - finance-datareader 自动识别代码：韩国6位数字 → Naver，海外 ticker → Yahoo；也可显式指定源 `"KRX:005930"` / `"YAHOO:AAPL"` / `"SSE:600519"`

---

## 3. Stock Basic Info 股票基本信息

| Channel | Transport | Call | Freshness |
|---------|-----------|------|-----------|
| akshare | →akshare | `ak.stock_individual_info_em(symbol="{code}")` | static |

- **Fallback**: akshare (only channel)
- **Requires**: `pip install akshare`
- **Parameters**:
  - `{code}` — 股票代码（默认: `000001`）
- **Response**: `DataFrame[item, value]` (键值对：总市值、流通市值、行业等)

---

## 4. Stock Search 股票搜索

| Channel | Transport | Call | Freshness |
|---------|-----------|------|-----------|
| akshare | →akshare | `ak.stock_zh_a_spot_em()` 全量筛选 | realtime |

- **Fallback**: akshare (only channel)
- **Requires**: `pip install akshare`
- **Usage**: 获取全市场行情 DataFrame，按代码或名称模糊匹配
- **Notes**: 数据量大（5000+ 行），建议缓存后本地搜索；或直接使用浏览器端的 `market-resolve` 板块

---

## 5. Index Quotes 指数行情

| Channel | Transport | Call | Freshness |
|---------|-----------|------|-----------|
| akshare | →akshare | `ak.index_zh_a_hist(symbol="{code}", period="daily", start_date="{sdate}", end_date="{edate}")` | historical |
| finance-datareader | →finance-datareader | `fdr.DataReader("{index}", "{sdate}", "{edate}")` | historical |

- **Fallback**: akshare → finance-datareader（按运行环境自动跳过不可用 Channel）
- **Requires**:
  - akshare: `pip install akshare`
  - finance-datareader: `pip install finance-datareader`
- **Parameters**:
  - `{code}` — A股指数代码（默认: `000001`）；finance-datareader 用 `{index}` 标识符
  - `{sdate}` — 开始日期 YYYYMMDD（默认: `20250101`）
  - `{edate}` — 结束日期 YYYYMMDD（默认: `20261231`）
- **Response**:
  - akshare: `DataFrame[日期, 开盘, 收盘, 最高, 最低, 成交量, 成交额, ...]`
  - finance-datareader: `DataFrame[Open, High, Low, Close, Volume, Change]`
- **Notes**:
  - finance-datareader 全球指数标识符：`DJI` (道琼斯), `IXIC` (纳斯达克), `S&P500` (标普500), `HSI` (恒生), `N225` (日经225), `SSEC` (上证), `FTSE` (英国富时), `GDAXI` (德国DAX), `FCHI` (法国CAC), `VIX` (恐慌指数), `US10YT` (美国10年国债) 等
  - 也支持韩国指数：`KOSPI` / `KS11`, `KOSDAQ` / `KQ11`, `KPI200` / `KS200`

---

## 7. Multi-market Stock Listing 多市场股票列表

| Channel | Transport | Call | Freshness |
|---------|-----------|------|-----------|
| finance-datareader | →finance-datareader | `fdr.StockListing("{market}")` | static |

- **Fallback**: finance-datareader (only channel)
- **Requires**: `pip install finance-datareader`
- **Parameters**:
  - `{market}` — 市场代码（默认: `"KRX"`）
- **Supported Markets**:
  - 韩国: `KRX` / `KOSPI` / `KOSDAQ` / `KONEX` / `KRX-MARCAP` / `KRX-DESC` / `KOSPI-DESC` / `KOSDAQ-DESC` / `KRX-DELISTING` / `KRX-ADMINISTRATIVE`
  - 美国: `NASDAQ` / `NYSE` / `AMEX` / `S&P500`
  - 中国: `SSE` (上交所) / `SZSE` (深交所)
  - 香港: `HKEX`
  - 日本: `TSE`
  - 越南: `HOSE`
  - ETF: `ETF/KR` (韩国ETF列表)
- **Response**: `DataFrame[Code, Name, Market, ...]` (字段因市场而异)
- **Notes**:
  - 底层数据源：韩国市场 → KRX，美国/中国/香港/日本/越南 → Naver，S&P500 → Wikipedia
  - 韩国市场支持详细描述信息（板块、行业、上市日期、代表者等）
  - KRX 数据需要可访问 `data.krx.co.kr`，部分公司网络可能受限

---

## 8. Snap Data 快照数据

| Channel | Transport | Call | Freshness |
|---------|-----------|------|-----------|
| finance-datareader | →finance-datareader | `fdr.SnapDataReader("{ticker}")` | snapshot |

- **Fallback**: finance-datareader (only channel)
- **Requires**: `pip install finance-datareader`
- **Parameters**:
  - `{ticker}` — 快照路径（默认: `"KRX/INDEX/LIST"`）
- **Supported Tickers**:
  - `KRX/INDEX/LIST` — KRX 指数列表
  - `KRX/INDEX/STOCK/{idx}` — 指数成分股（`1001`=KOSPI, `2001`=KOSDAQ, `1028`=KOSPI200）
  - `ECOS/KEYSTAT/LIST` — 韩国 100 大经济指标列表
  - `NAVER/STOCK/{code}/FINSTATE` — 财务报表
  - `NAVER/STOCK/{code}/FOREIGN` — 外资持股比例
  - `NAVER/STOCK/{code}/INVSTORS` — 投资者交易动向
  - `DART/CORP_CODES` — 韩国 DART 企业代码
- **Response**: `DataFrame` (结构因 ticker 而异)
- **Notes**: 底层数据源：KRX / ECOS / Naver / DART；适合获取非行情类结构化数据
