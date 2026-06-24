# Stock API Board — 股票接口

## 1. Batch Stock Quotes 批量行情

```
GET https://push2.eastmoney.com/api/qt/ulist.np/get?fltt=2&secids={secids:1.000001}&fields=f2,f3,f4,f12,f14&cb={callback}
```

- **Transport**: JSONP with custom callback name
- **secids format**: comma-separated `{market}.{code}` pairs, e.g. `1.600519,0.000001,116.00700`
- **Market code mapping**:
  | Market | Code |
  |--------|------|
  | 沪A | 1 |
  | 深A | 0 |
  | 港股 | 116 |
  | 美股 | 105/106 |
  | 日股 | 124 |
  | 韩股 | 130 |
  | 台股 | 118 |
  | 德股 | 155 |
  | 法股 | 156 |
  | 英股 | 157 |
  | 巴西 | 173 |
  | 印度 | 174 |
  | 新加坡 | 175 |
  | 澳股 | 177 |
- **Batch size**: Max 50 per request; split larger arrays
- **Response fields**:
  - `f2` — current price
  - `f3` — change rate %
  - `f4` — change amount
  - `f12` — stock code
  - `f14` — stock name
- **Full quotes**: Add fields `f2,f3,f4,f12,f14` for basic; `f2,f3,f4,f12,f14,f15,f16,f17,f18` for extended

## 2. Stock Search 股票搜索

```
GET https://searchapi.eastmoney.com/api/suggest/get?input={keyword}&type=14&token=D43BF722C8E33BDC906FB84D85E326E8&count=10&cb={callback}
```

- **Transport**: JSONP with custom callback name
- **Features**: Fuzzy match by code, name, or pinyin; covers A/HK/US/JP/KR/TW/EU
- **Response**: `{ QuotationCodeTable: { Data: [{ Code, Name, MktNum }] } }`
- **Market label map** (`MktNum` → label):

  | MktNum | Label |
  |--------|-------|
  | 1 | 沪 |
  | 0 | 深 |
  | 116 | 港 |
  | 105/106 | 美 |
  | 124 | 日 |
  | 130 | 韩 |
  | 118 | 台 |
  | 155 | 德 |
  | 156 | 法 |
  | 157 | 英 |
  | 173 | 巴 |
  | 174 | 印 |
  | 175 | 新 |
  | 177 | 澳 |

- **Max results**: Limit to 15, deduplicate by `code|market`

## 3. Yesterday's Change (A-share) 昨日涨跌

```
GET https://push2his.eastmoney.com/api/qt/stock/kline/get?secid={secid:1.600519}&fields1=f1,f2,f3,f4,f5,f6&fields2=f51,f52,f53,f54,f55,f56,f57&klt=101&fqt=0&end=20500101&lmt=6&cb={callback}
```

- **Transport**: JSONP
- **Domain**: `push2his` for A-share/JP/KR/TW
- **Response**: `{ data: { klines: ["date,open,close,high,low,volume,amount", ...] } }`
- **Calculate**: Find latest non-today row → `changeRate = (close_today - close_prev) / close_prev × 100`
- **Batch**: Process ≤5 stocks concurrently, 50ms inter-batch delay

## 4. Tencent Quotes 腾讯行情

```
GET https://qt.gtimg.cn/q={codes:sh600519}
```

- **Transport**: `fetch` — response is GBK-encoded text
- **Decode**: `new TextDecoder('gbk').decode(arrayBuffer)`
- **codes format**: `{prefix}{code}`, prefix mapping:

  | Market | Prefix |
  |--------|--------|
  | A (沪) | sh |
  | A (深) | sz |
  | HK | hk |
  | US | us |
  | JP | jp |
  | KR | kr |
  | TW | t_ |
  | DE | r_de |
  | FR | r_fr |
  | UK | r_uk |
  | SG | r_sg |
  | AU | r_au |

- **Parse**: Split by `\n`, match `v_{code}="field~field~..."`, fields[32] = change rate %, fields[5] = fallback change rate
- **Usage**: Primary source for US/EU/other markets where EastMoney push2 lacks support

## Code Normalization 代码规范化

- **Strip suffixes**: `.US`, `.HK`, `.SZ`, `.SH` (case-insensitive)
- **Strip Tencent prefixes**: `sh`, `sz`, `hk`, `us`, `jp`, `kr`, `t_`, `r_de`, `r_fr`, `r_uk`, `r_sg`, `r_au`
- **Strip EM market prefixes**: `105.`, `106.`, `116.`, `124.`, `130.`, `118.`, `155.`, `156.`, `157.`, `173.`, `174.`, `175.`, `177.`
- **secid construction**: `{market}.{normalized_code}`
  - 6-digit code starting 6/30/68 → `1.{code}` (沪A)
  - 6-digit code starting 0/3 → `0.{code}` (深A)
  - 5-digit code → `116.{code padded to 5}` (港)
  - Alpha code → `105.{upper}` (美)
