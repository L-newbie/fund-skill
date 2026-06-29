# Python Fund SDK

Profiles: [→ profiles.md](profiles.md)

---

## 1. Real-time ETF Valuation 实时ETF估值

| Channel | Transport | Call | Freshness |
|---------|-----------|------|-----------|
| akshare | →akshare | `ak.fund_etf_spot_em()` | realtime |

- **Fallback**: akshare (only channel)
- **Response**: `DataFrame[代码, 名称, 最新价, 涨跌幅, 涨跌额, 成交量, 成交额, ...]`
- **Usage**: 全市场 ETF 实时数据，按 code 筛选目标基金
- **Notes**: 交易时段返回实时数据，非交易时段返回上一交易日收盘数据

---

## 2. Historical NAV 历史净值

| Channel | Transport | Call | Freshness |
|---------|-----------|------|-----------|
| akshare | →akshare | `ak.fund_open_fund_info_em(symbol="{code}", indicator="单位净值走势")` | delayed |

- **Fallback**: akshare (only channel)
- **Requires**: `pip install akshare`
- **Parameters**:
  - `{code}` — 基金代码（默认: `110011`）
- **Response**: `DataFrame[净值日期, 单位净值, 日增长率]`
- **Notes**: indicator 参数：`"单位净值走势"` / `"累计净值走势"` / `"累计收益率走势"`

---

## 3. Fund Basic Info 基金基本信息

| Channel | Transport | Call | Freshness |
|---------|-----------|------|-----------|
| akshare | →akshare | `ak.fund_individual_basic_info_xq(symbol="{code}")` | static |

- **Fallback**: akshare (only channel)
- **Requires**: `pip install akshare`
- **Parameters**:
  - `{code}` — 基金代码（默认: `110011`）
- **Response**: `DataFrame[基金代码, 基金简称, 基金类型, 成立日期, 基金经理, ...]`

---

## 4. Fund Rankings 基金排行

| Channel | Transport | Call | Freshness |
|---------|-----------|------|-----------|
| akshare | →akshare | `ak.fund_open_fund_rank_em()` | delayed |

- **Fallback**: akshare (only channel)
- **Requires**: `pip install akshare`
- **Response**: `DataFrame[代码, 名称, 日期, 单位净值, 累计净值, 日增长率, 近1周, 近1月, 近3月, 近6月, 近1年, 近2年, 近3年, 今年以来, 成立以来, ...]`
- **Notes**: 返回全市场开放式基金排行，数据量大，注意内存占用

---

## 5. Fund Holdings 基金持仓

| Channel | Transport | Call | Freshness |
|---------|-----------|------|-----------|
| akshare | →akshare | `ak.fund_portfolio_hold_em(symbol="{code}", date="{yyyy}")` | delayed |

- **Fallback**: akshare (only channel)
- **Requires**: `pip install akshare`
- **Parameters**:
  - `{code}` — 基金代码（默认: `110011`）
  - `{yyyy}` — 年份（默认: `2025`）
- **Response**: `DataFrame[季度, 股票代码, 股票名称, 占净值比例, 持股数, 持仓市值, ...]`
- **Notes**: date 参数为年份如 `"2025"`，返回该年各季度持仓数据

---

## 6. Fund Manager 基金经理

| Channel | Transport | Call | Freshness |
|---------|-----------|------|-----------|
| akshare | →akshare | `ak.fund_manager_em()` | delayed |

- **Fallback**: akshare (only channel)
- **Requires**: `pip install akshare`
- **Response**: `DataFrame[姓名, 从业时间, 现任基金, 任职期间最佳回报, 任职期间最差回报, ...]`
- **Notes**: 返回全市场基金经理数据，按 code 筛选目标基金经理

---

## 7. ETF Listing ETF列表

| Channel | Transport | Call | Freshness |
|---------|-----------|------|-----------|
| finance-datareader | →finance-datareader | `fdr.StockListing("ETF/KR")` | static |

- **Fallback**: finance-datareader (only channel)
- **Requires**: `pip install finance-datareader`
- **Response**: `DataFrame[Symbol, Name, ...]`
- **Notes**: 返回韩国市场 ETF 列表；底层数据源为 Naver
