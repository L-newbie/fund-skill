# Python SDK Profiles

## akshare
- **Transport**: pip
- **Install**: `pip install akshare`
- **Env**: python
- **Auth**: none
- **Param Mapping**: `{code}` → `symbol="{prefix}{code}"` (sz=深A, sh=沪A, bj=京A)
- **Rate Limit**: none (高频请求可能被封 IP，建议间隔 ≥500ms)
- **Response**: pandas DataFrame
- **Notes**:
  - 接口名后缀 `_em` = 东方财富数据源，`sina` = 新浪数据源
  - 部分接口依赖每日更新，非交易时段可能返回空数据
  - akshare 版本迭代快，建议定期 `pip install --upgrade akshare`

## finance-datareader
- **Transport**: pip
- **Install**: `pip install finance-datareader`
- **Import**: `import FinanceDataReader as fdr`
- **Env**: python
- **Auth**: none
- **Param Mapping**: `{code}` → 韩国股票用6位数字码（如 `005930`），海外股票用 ticker（如 `AAPL`）；`{market}` → `"KRX"/"NASDAQ"/"NYSE"/"SSE"/"SZSE"/"HKEX"/"TSE"/"HOSE"/"S&P500"`
- **Rate Limit**: none (依赖上游 Naver/Yahoo/KRX，建议间隔 ≥500ms)
- **Response**: pandas DataFrame
- **Notes**:
  - 核心入口 `DataReader()` 通过 symbol 前缀指定数据源：`"KRX:"` / `"NAVER:"` / `"YAHOO:"` / `"INVESTING:"` / `"FRED:"` / `"NASDAQ:"` / `"SSE:"` / `"HKEX:"` 等
  - 无前缀时自动识别：韩国股票代码 → Naver，海外 ticker → Yahoo
  - 韩国市场数据源：Naver（每日行情）、KRX（韩国交易所）
  - 全球指数通过 Yahoo Finance 获取（DJI, IXIC, S&P500, HSI, N225, SSEC, FTSE, GDAXI, FCHI 等）
  - `StockListing()` 支持多市场股票列表，底层数据源为 KRX/Naver/Wikipedia
  - `SnapDataReader()` 提供快照数据（财报、外资持股、指数成分股、经济指标等）
  - 韩国交易所 KRX 数据需要可访问 `data.krx.co.kr`，部分公司网络可能受限
  - 适合需要多市场统一接口的场景，尤其是韩国市场（包名 FinanceDataReader 源于韩国金融数据社区）
