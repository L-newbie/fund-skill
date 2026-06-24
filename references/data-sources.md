# Data Source Strategy 数据源策略

## Fund Valuation 估值

```
fundgz (primary) ──→ F10 lsjz (fallback) ──→ return null
     │                     │
     │                     └─ Provides confirmed dwjz + real gszzl
     │                        when fundgz times out or for T+2 funds
     │
     └─ Provides live estimate gz + estimated gszzl
        during trading hours
```

**Merge logic**:
- Both succeed → compare lsjz.jzrq with gztime date:
  - T+1 fund: `jzrq >= gzDate` → use lsjz data (confirmed), mark `isEstimated: false`
  - T+2 fund: `jzrq >= prevTradingDay` → use lsjz data, mark `isEstimated: false`
  - Otherwise → keep fundgz estimate, fill dwjz/jzrq from lsjz
- Only fundgz → use estimate values, mark `isEstimated: true`
- Only lsjz → fill dwjz/jzrq, set gszzl=0 (no stale rates shown)
- Both fail → return `null`

## Stock Quotes 股票行情

```
Market Detection
    │
    ├── A股 / JP / KR / TW ──→ push2his K-line (yesterday change)
    │
    ├── HK ──→ push2 K-line (yesterday change)
    │           (push2his does NOT support HK)
    │
    └── US / EU / Other ──→ Tencent Quotes (real-time rate)
```

**Market detection priority**:
1. `emMarketCode` from holdings data → direct mapping
2. Code suffix (`.US`, `.HK`, etc.) → market inference
3. Code pattern (6-digit → A-share, 5-digit → HK, alpha → US)
4. EastMoney suggest API search as last resort

## News Aggregation 资讯聚合

```
Sina (5 categories × 1 page) ──┐
EastMoney (7 filters × 1 page) ──┼──→ Merge → Sort by ctime ↓ → Dedup by title → Return
Overseas RSS (3 feeds, optional) ──┘
```

**Dedup**: Use `Set<string>` on title text. First occurrence wins (latest by sort).
**Deep pagination**: Only triggered by "load more" action; fetch pages 5–10 (Sina) / 4–8 (EastMoney).

## Holdings Estimation 持仓推算

```
Quarter Report (top 10 only)
    │
    ├── Full report available (annual/semi-annual)?
    │   └── Yes → Return full holdings directly, no estimation needed
    │
    └── No → Find nearest full report from prior years
        │
        ├── Proportional scaling as baseline
        │   (non-top-10 stocks scaled proportionally from full report)
        │
        └── Single-day NAV constraint optimization
            (adjusts weights to match fund's daily return)
            - Requires: NAV change rate + stock change rates
            - Skipped if stock coverage < 5 or data weight < 20%
```

## Caching Strategy 缓存

| Data Type | Cache Duration | Storage |
|-----------|---------------|---------|
| Fund valuation | 24h (same trading day) | memory |
| Fund catalog | 24h | localStorage |
| Fund detail | 4h | memory → localStorage |
| Stock quotes | No cache (real-time) | — |
| News | No cache (real-time) | sessionStorage (validated only) |
