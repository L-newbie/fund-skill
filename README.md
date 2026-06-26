<div align="center">

# 📈 Funds-Skills

**基金 · 股票 · 资讯 — 一站式数据接口 Skill**

[![](https://img.shields.io/badge/EastMoney-EA4335?style=flat-square&logo=eastmoney)](https://www.eastmoney.com)
[![](https://img.shields.io/badge/TTFund-FF6600?style=flat-square&logo=eastmoney)](https://fund.eastmoney.com)
[![](https://img.shields.io/badge/Tencent-07C160?style=flat-square&logo=tencentqq)](https://www.tencent.com)
[![](https://img.shields.io/badge/Sina-E6162D?style=flat-square&logo=sinaweibo)](https://www.sina.com.cn)
[![](https://img.shields.io/badge/RSS-6366F1?style=flat-square&logo=rss)](https://www.yahoo.com/news/rssindex)

</div>

---

## 📁 项目结构

<!-- AUTO-PROJECT-TREE START -->
```
fund-skill/
├── 📄 SKILL.md                ← Skill 主入口（含 Project Maintenance 规则）
├── 📂 api/                    ← 接口定义（按语言分目录）
│   ├── 📂 browser/              ← 🌐 browser 接口
│   │   ├── 📊 fund.md
│   │   ├── 🌍 global-index.md
│   │   ├── 🔍 market-resolve.md
│   │   ├── 📰 news.md
│   │   └── 📈 stock.md
│   └── 📂 python/              ← 🐍 python 接口
│       ├── 🐍 profiles.md     SDK 元信息
│       ├── 📊 fund.md
│       └── 📈 stock.md
├── 📂 references/             ← 深度参考文档
│   ├── 🔗 api-urls.md         接口指针索引（→ 链接到源文件）
│   ├── 🔄 data-sources.md     数据源策略与兜底方案
│   └── ⚠️ errors.md           常见错误与修复
├── 📂 pending/                ← 验证待确认接口暂存
├── 📂 scripts/                ← 工具脚本
│   └── 🐚 sync.sh             极简扫描版（零依赖）
├── 📂 .git/                   ← Git 仓库数据
├── 📄 .gitignore              ← Git 忽略规则
└── 📄 README.md
```
<!-- AUTO-PROJECT-TREE END -->

---

## 📊 板块说明

接口按语言分目录：`browser/` (前端 HTTP) → `python/` (Python SDK) → 未来扩展

<!-- AUTO-BOARD-TABLE START -->
| 板块 | 文件 | 接口 | 核心能力 |
|:----:|:----:|:----:|:--------|
| 🌐 基金 | `api/browser/fund.md` | **7** | 实时估值 · 基金详情 · 历史净值 · 基金搜索 · 全量目录 · 基金持仓 · 盘中估值走势 |
| 🌐 全球指数 | `api/browser/global-index.md` | **1** | A-Share Indices |
| 🌐 市场解析 | `api/browser/market-resolve.md` | **1** | 腾讯智能搜索 |
| 🌐 财经资讯 | `api/browser/news.md` | **3** | 新浪财经 · 东方财富快讯 · Overseas RSS — Yahoo Finance |
| 🌐 股票 | `api/browser/stock.md` | **4** | 批量行情 · 股票搜索 · 昨日涨跌 · 腾讯行情 |
| 🐍 基金 | `api/python/fund.md` | **6** | 实时ETF估值 · 历史净值 · 基金基本信息 · 基金排行 · 基金持仓 · 基金经理 |
| 🐍 股票 | `api/python/stock.md` | **5** | A股实时行情 · 历史K线 · 股票基本信息 · 股票搜索 · 指数行情 |
<!-- AUTO-BOARD-TABLE END -->

---

## 🚀 快速开始

### 安装 Skill

<!-- tabs:start -->

**🐧 Linux / macOS**

```bash
# 克隆到项目 skill 目录（仅当前项目可用）
git clone https://github.com/L-newbie/fund-skill.git .claude/skills/fund-skill

# 或克隆到用户级目录（所有项目可用）
git clone https://github.com/L-newbie/fund-skill.git ~/.claude/skills/fund-skill
```

**🪟 Windows (PowerShell)**

```powershell
# 克隆到项目 skill 目录（仅当前项目可用）
git clone https://github.com/L-newbie/fund-skill.git .claude\skills\fund-skill

# 或克隆到用户级目录（所有项目可用）
git clone https://github.com/L-newbie/fund-skill.git "$env:USERPROFILE\.claude\skills\fund-skill"
```

<!-- tabs:end -->

### 开始使用

安装后在 Claude Code 中直接对话即可，也可将接口文档用于任何 AI 编码工具（如 Cursor、Copilot 等）作为上下文参考：

| | 示例对话 |
|:---:|:--------|
| 📊 | 帮我查一下 **110011** 这只基金今天的估值 |
| 🔍 | 搜索**沪深300**相关的基金 |
| 💹 | 查一下**贵州茅台**的最新行情 |
| 📰 | 今天有什么**财经新闻**？ |
| 🌍 | 全球主要指数现在是什么情况？ |

### 💬 启动预览

> 启动 `/fund-skill` 后，你会看到以下欢迎界面：

```
Fund Skill 已加载 ✅

我可以帮你完成以下操作：

查询类
- 📊 基金 — 实时估值、历史净值、基金详情、持仓、搜索
- 📈 股票 — 批量行情、股票搜索、昨日涨跌、K线数据
- 🌍 全球指数 — A股、港股、美股、日韩、欧洲等指数
- 📰 财经资讯 — 新浪财经、东方财富快讯、海外 RSS

项目维护类
- 📝 提交新接口 — 提供原始 API 信息，我按 5 步流程整理、验证、写入
- 🔄 同步下游文件 — 修改 api/ 后自动更新 api-urls.md、SKILL.md、README.md
- ✅ 验证接口 — 检测所有已录入 API 是否可用

你想做什么？
```

---

## 🤝 参与贡献

欢迎提交 PR 扩展接口和板块，让数据源更丰富！

### 🔄 自动转换流程

提供接口信息后，Claude Code 会自动完成以下步骤：

```
💬 提供接口信息（对话 / 原始文件，格式随意）
       ↓
🤖 Claude Code 自动处理
  1. 📖 整理 — 解析 + 归类（只读，不写文件）
  2. 🔍 验证 — HTTP 请求 → ✅/❌
  3. ✋ 确认 — 展示结果，用户决定是否继续
  4. ✍️ 写入 — 仅 ✅ API → api/*.md → Project Maintenance → 更新下游文件
  5. 📋 报告 — 分析报告 + 修改记录 + 结论
       ↓
✅ 完成（原始文件自动清理）
```

> 💡 默认只写入验证通过的接口。如需写入失败接口，请明确告知。

### 📦 Pending 暂存机制

验证失败的接口会按失败类型自动判断是否暂存到 `pending/` 目录：

| 失败类型 | 行为 | 说明 |
|:--------:|:----:|:-----|
| `network` | ✅ 暂存 | Connection reset / ECONNREFUSED / ENETUNREACH |
| `timeout` | ✅ 暂存 | ETIMEDOUT / Timeout |
| `unknown` | ✅ 暂存 | 其他不明显原因 |
| `confirmed-dead` | ❌ 不暂存 | HTTP 404/410、DNS 解析失败 |

暂存文件记录了时间、提交者、失败原因、重试次数等信息。下次执行 Project Maintenance 时会自动重试 pending 接口：

- **验证通过** → 自动合并到 `api/*.md` + 删除 pending 文件
- **验证仍失败** → 更新 Retry Count +1 和 Date
- **Retry Count ≥ 5** → 自动标记为 `confirmed-dead`

### 📌 提供接口信息

对话中描述或提供原始文件均可，格式随意：

- **对话中描述** — 直接告诉 Claude Code，例如：

  > "我找到一个基金排名接口：请求 https://fund.eastmoney.com/data/rankhandler.aspx?op=ph&dt=kf&ft=all&sc=6yzf&st=desc&pi=1&pn=50，用 script 标签加载，返回 var rankData={datas:[...]}，每条数据逗号分隔，包含代码、名称、日期、净值、日增长率等"

- **提供原始文件** — 把接口信息放到项目根目录（如 `my-apis.md`），例如：

  ```
  基金排行
  请求地址: https://fund.eastmoney.com/data/rankhandler.aspx?op=ph&sc=6yzf&st=desc&pi=1&pn=50
  用script标签调用，返回 var rankData = {datas:["代码,名称,..."], allRecords:1234}
  ```

### ✅ 接口验证

接口验证由 Claude Code 通过 Project Maintenance 规则自动执行（使用 curl / pip / python3），无需手动运行脚本：

| 状态 | 含义 |
|:----:|:-----|
| ✅ 可用 | 接口返回数据且验证通过 |
| ⚠️ 未安装 | SDK 未安装，提示安装或自动安装 |
| ❌ 失败 | 接口无响应或返回数据不符合预期 |

> 💡 如果手动编辑了 `api/*/*.md`，告诉 Claude Code "运行维护" 即可更新所有下游文件并验证接口。

### 🚀 提交 PR

| 项目 | 规范 |
|:----:|:----:|
| 标题 | `[板块名] 简短描述`，如 `[fund] 添加基金排行接口` |
| 截图 | 终端验证输出截图（可选） |
| 格式 | 接口文档需含 **URL · Transport · Response** 要素 |

---

## 🔄 持续更新

本项目 **长期维护、持续迭代** 🚀

- 📡 **接口跟进**：数据源变动时及时适配，失效接口快速修复或替换
- 🧩 **板块扩展**：持续收录新的数据源与接口，覆盖更多金融场景
- 🛠️ **体验优化**：验证工具、文档结构不断打磨
- 🙋 **社区驱动**：每一个 PR 都会让项目变得更好，你的贡献就是我们前进的动力

> 💡 有想要的新接口？发现某个接口挂了？欢迎提 [Issue](https://github.com/L-newbie/fund-skill/issues) 或直接 PR，我会第一时间响应 ✨

---

<div align="center">

**⚠️ 免责声明**：本项目仅供学习与研究使用，接口数据来源于公开网络，不构成任何投资建议。使用时请遵守各数据源的服务条款。

</div>
