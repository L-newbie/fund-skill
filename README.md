<div align="center">

# 📈 Funds-Skills

**基金 · 股票 · 资讯 — 一站式数据接口 Skill**

聚合东方财富 / 天天基金 / 腾讯 / 新浪 / 海外 RSS 等多数据源

<a href="https://L-newbie.github.io/real-time-valuation/">
  <img src="https://img.shields.io/badge/🚀_在线体验-基金管理-4da6ff?style=for-the-badge&logo=github&logoColor=white&labelColor=1a1d27" />
</a>
<a href="https://l-newbie.github.io/fund-skill/validator/">
  <img src="https://img.shields.io/badge/🔍_接口验证-API_Validator-a78bfa?style=for-the-badge&logo=github&logoColor=white&labelColor=1a1d27" />
</a>

</div>

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

---

## 📊 板块说明

<!-- AUTO-BOARD-TABLE START -->
| 板块 | 文件 | 接口 | 核心能力 |
|:----:|:----:|:----:|:--------|
| 📊 基金 | `api/fund.md` | **7** | 实时估值 · 基金详情 · 历史净值 · 基金搜索 · 全量目录 · 基金持仓 · 盘中估值走势 |
| 🌍 全球指数 | `api/global-index.md` | **1** | A-Share Indices |
| 🔍 市场解析 | `api/market-resolve.md` | **1** | 腾讯智能搜索 |
| 📰 财经资讯 | `api/news.md` | **3** | 新浪财经 · 东方财富快讯 · Overseas RSS — Yahoo Finance |
| 📈 股票 | `api/stock.md` | **4** | 批量行情 · 股票搜索 · 昨日涨跌 · 腾讯行情 |
<!-- AUTO-BOARD-TABLE END -->

---

## 🔧 接口调用约定

| 数据源 | 调用方式 | 说明 |
|:------:|:--------:|:----:|
| 东方财富 / 天天基金 | `JSONP` | `cb=` 自定义回调名，或固定 `jsonpgz` |
| pingzhongdata / fundcode_search | `<script>` 标签 | 注入后读取 window 全局变量 |
| 腾讯行情 | `fetch` | 需 `TextDecoder('gbk')` 解码 |
| 海外 RSS | `fetch` | 通过 rss2json.com 代理 |

> 💡 所有接口均 **无需 API Key**（海外 RSS 代理在免费额度内也无需 Key）

---

## 🤝 参与贡献

欢迎提交 PR 扩展接口和板块，让数据源更丰富！

### 📌 提供接口信息

有两种方式，都很简单：

**方式一：对话中描述**

在 Claude Code 对话中直接描述接口，例如：

> "我找到一个基金排名接口：请求 https://fund.eastmoney.com/data/rankhandler.aspx?op=ph&dt=kf&ft=all&sc=6yzf&st=desc&pi=1&pn=50，用 script 标签加载，返回 var rankData={datas:[...]}，每条数据逗号分隔，包含代码、名称、日期、净值、日增长率等"

**方式二：提供原始文件**

把收集到的接口信息放到项目根目录（如 `my-apis.md`），格式随意：

```
基金排行
请求地址: https://fund.eastmoney.com/data/rankhandler.aspx?op=ph&sc=6yzf&st=desc&pi=1&pn=50
用script标签调用，返回 var rankData = {datas:["代码,名称,..."], allRecords:1234}
```

### 🔄 自动转换流程

提供接口信息后，Claude Code 会自动完成以下步骤：

```
💬 提供接口信息（对话 / 原始文件，格式随意）
       ↓
🤖 Claude Code 自动转换
  1. 判断归属板块（fund/stock/global-index/news/market-resolve/或新建）
  2. 转换为标准格式写入 api/*.md
  3. 运行同步脚本 → 依次更新所有下游文件：
     ✦ validator/index.html  （前端验证页面 + 后端预验证）
     ✦ references/api-urls.md（API URL 清单）
     ✦ SKILL.md              （Skill Quick Reference）
     ✦ README.md             （板块说明 + 项目结构）
  4. 后端预验证 fetch 类接口（失败不阻断，仅提示）
       ↓
✅ 转换完成，可删除原始文件
       ↓
🌐 启动验证页面进行完整验证和截图
```

### ✅ 本地验证

自动转换流程或同步脚本运行后，接口会自动出现在验证页面中，可直接测试接口是否可用：

```bash
cd validator
python3 -m http.server 8080
# 浏览器打开 http://localhost:8080
```

验证页面会自动加载所有接口，点击「▶ 全部验证」即可批量测试，也可单独点击某个接口的「验证」按钮。状态说明：

| 状态 | 含义 |
|:----:|:-----|
| ✅ 可用 | 接口返回数据且验证通过 |
| ❌ 失败 | 接口无响应或返回数据不符合预期 |
| ⏳ 待检测 | 尚未运行验证 |

> 💡 如果是手动编辑了 `api/*.md`，需先运行同步脚本再验证：
>
> | 语言 | 命令 | 说明 |
> |:----:|:----:|:----:|
> | Node.js | `node scripts/sync.js` | 推荐 |
> | Python | `python3 scripts/sync.py` | — |
> | Bash | `bash scripts/sync.sh` | 零依赖 |

### 📸 截图

验证通过后，需要截图作为 PR 证明：

1. 按上述步骤启动验证页面
2. 点击「▶ 全部验证」等待全部接口完成
3. 确认新增/修改的接口显示为 ✅ 可用
4. 截取浏览器完整页面截图（需包含顶部状态栏的可用/总数）

### 🚀 提交 PR

| 项目 | 规范 |
|:----:|:----:|
| 标题 | `[板块名] 简短描述`，如 `[fund] 添加基金排行接口` |
| 截图 | validator 页面验证截图（必须，见上方截图步骤） |
| 格式 | 接口文档需含 **URL · Transport · Response** 要素 |

---

## 📁 项目结构

<!-- AUTO-PROJECT-TREE START -->
```
fund-skill/
├── 📄 SKILL.md                ← Skill 主入口
├── 📂 api/                    ← 接口定义（按板块分文件）
│   ├── 📊 fund.md
│   ├── 🌍 global-index.md
│   ├── 🔍 market-resolve.md
│   ├── 📰 news.md
│   ├── 📈 stock.md
├── 📂 references/             ← 深度参考文档
│   ├── 🔗 api-urls.md         完整 API URL 清单
│   ├── 🔄 data-sources.md     数据源策略与兜底方案
│   └── ⚠️ errors.md           常见错误与修复
├── 📂 scripts/                ← 同步脚本
│   ├── 📜 sync.js             Node.js 版（推荐）
│   ├── 🐍 sync.py             Python 版
│   └── 🐚 sync.sh             Bash 版（零依赖）
├── 📂 validator/              ← 前端验证页面
│   └── 🖥️ index.html          单文件 SPA
├── 📂 .git/                   ← Git 仓库数据
├── 📄 .gitignore              ← Git 忽略规则
└── 📄 README.md
```
<!-- AUTO-PROJECT-TREE END -->

---

## 🙏 数据源

### 🇨🇳 国内

| 数据源 | 提供能力 |
|:------:|:--------|
| [东方财富](https://www.eastmoney.com/) | 基金详情 · 行情 · 快讯 |
| [天天基金网](https://fund.eastmoney.com/) | 基金实时估值 |
| [腾讯财经](https://gu.qq.com/) | 股票行情 · Smartbox 搜索 |
| [新浪财经](https://finance.sina.com.cn/) | 财经快讯 · 盘中估值走势 |

### 🌏 海外

| 数据源 | 提供能力 |
|:------:|:--------|
| [Yahoo Finance](https://finance.yahoo.com/) | 海外财经资讯 |
| [CNBC](https://www.cnbc.com/) | 海外财经资讯 |
| [MarketWatch](https://www.marketwatch.com/) | 海外财经资讯 |

### 🔧 工具服务

| 数据源 | 提供能力 |
|:------:|:--------|
| [rss2json](https://rss2json.com/) | 海外 RSS 代理 |

---

## 🔄 持续更新

本项目 **长期维护、持续迭代** 🚀

- 📡 **接口跟进**：数据源变动时及时适配，失效接口快速修复或替换
- 🧩 **板块扩展**：持续收录新的数据源与接口，覆盖更多金融场景
- 🛠️ **体验优化**：验证工具、同步脚本、文档结构不断打磨
- 🙋 **社区驱动**：每一个 PR 都会让项目变得更好，你的贡献就是我们前进的动力

> 💡 有想要的新接口？发现某个接口挂了？欢迎提 [Issue](https://github.com/L-newbie/fund-skill/issues) 或直接 PR，我会第一时间响应 ✨

---

<div align="center">

**⚠️ 免责声明**：本项目仅供学习与研究使用，接口数据来源于公开网络，不构成任何投资建议。使用时请遵守各数据源的服务条款。

</div>
