# Common Errors & Fixes 常见错误与修复

## 1. JSONP `jsonpgz` Callback Collision

**Problem**: The valuation API (`fundgz.1234567.com.cn`) uses a fixed callback name `jsonpgz`. When multiple components request valuations concurrently, later requests overwrite the global callback, causing earlier responses to be lost.

**Fix**: Install a permanent `window.jsonpgz` dispatcher that routes responses by `data.fundcode` to the correct Promise.

```javascript
const pendingGzEntries = new Map() // fundCode → [entry]

window.jsonpgz = (data) => {
  const fundCode = data?.fundcode ?? ''
  const entries = pendingGzEntries.get(fundCode)
  if (entries) {
    pendingGzEntries.delete(fundCode)
    entries.forEach(e => { clearTimeout(e.timer); e.resolve(data) })
  }
  // Unmatched → discard (avoid cross-fund pollution)
}
```

**Key**: Never fall back to a "dispatch to latest" pattern — it causes data contamination between funds.

## 2. `pingzhongdata` Global Variable Overwrite

**Problem**: Loading `pingzhongdata/{code}.js` sets ~20 window globals (`Data_netWorthTrend`, `fS_name`, etc.). Concurrent loads clobber each other's data.

**Fix**: Serialize all pingzhongdata loads through a FIFO queue.

```javascript
let pzQueue = []
let pzLoading = false

function enqueuePzLoad(code) {
  return new Promise((resolve, reject) => {
    pzQueue.push({ code, resolve, reject })
    if (!pzLoading) processPzQueue()
  })
}
```

**Also**: Clean up globals (`window.Data_netWorthTrend = undefined`, etc.) after each load to prevent stale data leaks.

## 3. `fundcode_search.js` Size & Redundancy

**Problem**: The catalog file is ~3MB. Multiple concurrent calls waste bandwidth.

**Fix**: Single-flight promise pattern + 24h localStorage cache.

```javascript
let cachedCatalog = null
let catalogPromise = null

async function fetchFundCodeCatalog() {
  if (cachedCatalog) return cachedCatalog
  if (catalogPromise) return catalogPromise
  catalogPromise = _doFetchCatalog()
  try { return await catalogPromise }
  finally { catalogPromise = null }
}
```

## 4. GBK Encoding (Tencent Quotes)

**Problem**: `qt.gtimg.cn` returns GBK-encoded text. Standard `response.text()` produces garbled characters.

**Fix**: Use `ArrayBuffer` + `TextDecoder('gbk')`.

```javascript
const buffer = await response.arrayBuffer()
const text = new TextDecoder('gbk').decode(buffer)
```

## 5. `window.apidata` Hybrid Format

**Problem**: Some EastMoney F10 endpoints return `var apidata = {...}` (variable declaration) while others return `apidata({...})` (JSONP callback). Reading only one format misses the other.

**Fix**: Register `window.apidata` as both a callback function and a data reader.

```javascript
// Register callback (supports JSONP format)
window.apidata = (data) => { resolve(data) }

// On script load, check if it's a plain object (var declaration format)
script.onload = () => {
  const val = window.apidata
  if (typeof val === 'object' && !(val instanceof Function)) {
    resolve(val) // var apidata = {...} format
  }
}
```

## 6. CORS Restrictions

**Problem**: Browser blocks cross-origin requests to EastMoney/Tencent APIs.

**Fix**: All EastMoney/TianTianFund APIs use JSONP or `<script>` tag injection (not `fetch`). Only Tencent quotes and overseas RSS use `fetch` — both allow CORS.

## 7. Rate Limiting

**Problem**: Aggressive polling causes IP bans or throttled responses.

**Fix**:
- Fund valuation: ≤5 concurrent, 60s refresh interval
- Stock quotes: ≤50 per batch, 100ms inter-batch delay
- News: ≤1 page per source per refresh
- Smartbox: ≤80ms between sequential resolves
