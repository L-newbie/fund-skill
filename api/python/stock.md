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

- **Fallback**: akshare (only channel)
- **Requires**: `pip install akshare`
- **Parameters**:
  - `{code}` — 股票代码（默认: `000001`）
  - `{sdate}` — 开始日期 YYYYMMDD（默认: `20250101`）
  - `{edate}` — 结束日期 YYYYMMDD（默认: `20261231`）
- **Response**: `DataFrame[日期, 开盘, 收盘, 最高, 最低, 成交量, 成交额, 振幅, 涨跌幅, 涨跌额, 换手率, ...]`
- **Notes**:
  - period: `"daily"` / `"weekly"` / `"monthly"`
  - adjust: `"qfq"` (前复权) / `"hfq"` (后复权) / `""` (不复权)

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

- **Fallback**: akshare (only channel)
- **Requires**: `pip install akshare`
- **Parameters**:
  - `{code}` — 指数代码（默认: `000001`）
  - `{sdate}` — 开始日期 YYYYMMDD（默认: `20250101`）
  - `{edate}` — 结束日期 YYYYMMDD（默认: `20261231`）
- **Response**: `DataFrame[日期, 开盘, 收盘, 最高, 最低, 成交量, 成交额, ...]`
