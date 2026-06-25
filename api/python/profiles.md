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
