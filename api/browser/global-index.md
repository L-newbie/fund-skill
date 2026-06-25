# Global Index API Board — 全球指数接口

## Overview

All global indices use the EastMoney push2 batch quote API via `secid`. No separate endpoint needed — reuse the Stock board's batch quotes API.

## A-Share Indices

指数列表：

| secid | Code | Name | Market |
|-------|------|------|--------|
| 1.000001 | 000001 | 上证指数 | sh |
| 0.399001 | 399001 | 深证成指 | sz |
| 0.399006 | 399006 | 创业板指 | sz |
| 1.000688 | 000688 | 科创50 | sh |
| 1.000300 | 000300 | 沪深300 | sh |
| 1.000905 | 000905 | 中证500 | sh |
| 1.000016 | 000016 | 上证50 | sh |
| 0.399673 | 399673 | 创业板50 | sz |

```
GET https://push2.eastmoney.com/api/qt/ulist.np/get?fltt=2&secids={secids}&fields=f2,f3,f4,f12,f14&cb={callback}
```

- **Transport**: JSONP
- **Parameters**:
  - `secids` — 逗号分隔的 `{market}.{code}` 对（默认: `1.000001`）
  - `callback` — JSONP 回调函数名
- **Matching**: push2 returns `f12` — match by secid first, fallback to code
- **Fallback**: Missing quotes → fill with zero values + preset name

## HK Indices

| secid | Code | Name |
|-------|------|------|
| 100.HSI | HSI | 恒生指数 |
| 100.HSCEI | HSCEI | 国企指数 |
| 124.HSTECH | HSTECH | 恒生科技 |

## US Indices

| secid | Code | Name |
|-------|------|------|
| 100.DJIA | DJIA | 道琼斯 |
| 100.NDX | NDX | 纳斯达克 |
| 100.SPX | SPX | 标普500 |

## Asia-Pacific Indices

| secid | Code | Name |
|-------|------|------|
| 100.N225 | N225 | 日经225 |
| 100.KS11 | KS11 | 韩国KOSPI |
| 100.TWII | TWII | 台湾加权 |

## Europe Indices

| secid | Code | Name |
|-------|------|------|
| 100.FTSE | FTSE | 英国富时100 |
| 100.GDAXI | GDAXI | 德国DAX30 |
| 100.FCHI | FCHI | 法国CAC40 |

### Default Selection
推荐默认展示：`1.000001`, `0.399001`, `0.399006`, `100.HSI`, `100.DJIA`, `100.NDX`
