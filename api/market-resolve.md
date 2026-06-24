# Market Resolve API Board — 市场代码补全

## Tencent Smartbox 腾讯智能搜索

```
GET https://smartbox.gtimg.cn/s3/?q={keyword}&t=all
```

- **Transport**: `<script>` tag — sets `window.v_hint` global variable
- **Timeout**: 5000ms
- **Response format**: `name~code~tencentMarket^name~code~tencentMarket^...`
  - Entries separated by `^`
  - Fields within entry separated by `~`
- **Parse**: Split by `^`, then split each entry by `~`, extract `{name, code, tencentMarket}`

## Tencent Market Prefix → EM Market Code Mapping

| Tencent Prefix | EM Market Code | Market |
|----------------|---------------|--------|
| sh | 1 | 沪A |
| sz | 0 | 深A |
| hk | 116 | 港股 |
| us | 105 | 美股 |
| kr | 130 | 韩股 |
| jp | 124 | 日股 |
| t_ | 118 | 台股 |
| r_de | 155 | 德股 |
| r_fr | 156 | 法股 |
| r_uk | 157 | 英股 |
| r_sg | 175 | 新加坡 |
| r_au | 177 | 澳股 |

### Resolution Strategy

1. Search by stock name via smartbox
2. Match entries: first try `code === targetCode`, then try `name === targetName`
3. Convert matched `code` prefix to EM market code using mapping above
4. Construct `secid = {emMarketCode}.{cleanCode}`

### Reliable EM Codes

Only these EM market codes are considered reliable for quote queries:
- `1` (沪), `0` (深), `116` (港), `105` (美), `106` (美ADR), `118` (台)

For other markets, the resolved code serves as a best-effort fallback.
