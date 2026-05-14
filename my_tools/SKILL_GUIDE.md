# ARIS Skill 完全使用指南

> 本指南面向新手，力求详尽。如果你刚安装好 ARIS，不知道每个 skill 是干什么的、什么时候用、怎么用，看这一篇就够了。
>
> 建议顺序阅读：先读**前置依赖** → **全局参数** → 按你的工作阶段跳到对应**工作流**。

---

## 目录

- [前置依赖（先装这些）](#前置依赖先装这些)
- [全局参数（所有 skill 通用的开关）](#全局参数所有-skill-通用的开关)
- [工作流 1：找 Idea + 方案精炼](#工作流-1找-idea--方案精炼)
- [工作流 1.5：实验桥接](#工作流-15实验桥接)
- [工作流 2：自动科研循环](#工作流-2自动科研循环)
- [工作流 3：论文写作](#工作流-3论文写作)
- [工作流 4：Rebuttal](#工作流-4rebuttal)
- [文献检索工具](#文献检索工具)
- [知识库与优化](#知识库与优化)
- [专利相关](#专利相关)
- [演讲、海报与可视化](#演讲海报与可视化)
- [辅助与杂项工具](#辅助与杂项工具)
- [完整示例：从 idea 到投稿](#完整示例从-idea-到投稿)

---

## 前置依赖（先装这些）

### 必须安装的

| 软件 | 用途 | 安装命令 | 哪些 skill 需要 |
|------|------|----------|----------------|
| **Claude Code** | 主入口，运行所有 skill | [官网下载](https://docs.anthropic.com/en/docs/claude-code) | 全部 |
| **Git** | 克隆 ARIS 仓库 | [官网下载](https://git-scm.com/download/win) | 全部 |

### 按需安装的

| 软件 | 用途 | 安装命令 | 哪些 skill 需要 |
|------|------|----------|----------------|
| **Codex CLI** | review 类 skill 调用 GPT-5.4 | `npm install -g @openai/codex` | `auto-review-loop`, `auto-paper-improvement-loop`, `research-pipeline`, `rebuttal` |
| **LaTeX** | 工作流 3 编译 PDF | Windows 推荐 [TeX Live](https://tug.org/texlive/) | `paper-writing`, `paper-compile`, `paper-write` |
| **Python** | 实验代码运行 | [官网下载](https://www.python.org/downloads/) | `experiment-bridge`, `run-experiment` |
| **deepxiv-sdk** | DeepXiv 渐进式文献检索 | `pip install deepxiv-sdk` | `deepxiv` |
| **exa-py** | Exa AI 网页搜索 | `pip install exa-py` | `exa-search` |
| **modal** | 无服务器 GPU | `pip install modal && modal setup` | `serverless-modal` |
| **zotero-mcp** | Zotero 文献集成 | `uv tool install zotero-mcp-server` | `research-lit` (sources: zotero) |

### 配置 Codex MCP（review 类 skill 必需）

```bash
# 1. 安装 Codex CLI
npm install -g @openai/codex

# 2. 添加为 Claude Code 的 MCP server
claude mcp add codex -s user -- codex mcp-server

# 3. 配置模型（必须 gpt-5.4）
codex setup
# 提示选模型时选 gpt-5.4
```

### 验证 LaTeX（工作流 3 需要）

```bash
latexmk --version
pdfinfo -v
```

两个命令都有输出说明 LaTeX 装好了。如果报错，去装 TeX Live。

---

## 全局参数（所有 skill 通用的开关）

以下参数**几乎可以在任何 skill 中使用**，用来控制行为强度、预算、审核严格度。

### `effort` — 工作强度

控制 AI 干活的深度和广度，不影响审稿质量。

```bash
/any-skill "args" — effort: lite       # ~0.4x  token，快速探索
/any-skill "args" — effort: balanced  # 默认值，日常用
/any-skill "args" — effort: max       # ~2.5x token，投稿准备
/any-skill "args" — effort: beast     # ~5-8x token，顶会冲刺
```

### `difficulty` — 审稿对抗强度

控制 review 时有多狠。

```bash
/any-skill "args" — difficulty: medium   # 默认，标准 review
/any-skill "args" — difficulty: hard     # 加 reviewer memory + 辩论
/any-skill "args" — difficulty: nightmare # GPT 直接读你代码仓库，极限压测
```

### `assurance` — 审计严格度

```bash
/any-skill "args" — assurance: draft      # 默认，快速迭代
/any-skill "args" — assurance: submission # 强制审计全部通过才标 submission-ready
```

### `reviewer` — 审稿后端

```bash
/any-skill "args" — reviewer: codex       # 默认，Codex MCP (gpt-5.4 xhigh)
/any-skill "args" — reviewer: oracle-pro  # GPT-5.4 Pro，最强审稿
```

### `compact` — 精简模式

```bash
/any-skill "args" — compact: true         # 生成精简摘要，适合长会话恢复
```

### `human checkpoint` — 人工检查点

```bash
/any-skill "args" — human checkpoint: true  # 每轮 review 后暂停等你确认
```

---

## 工作流 1：找 Idea + 方案精炼

> **什么时候用这个工作流？**
> 
> 你有一个模糊的研究方向（比如"我想做扩散模型"），但不知道具体做什么、怎么做。这个工作流帮你：调研文献 → 头脑风暴 idea → 验证 novelty → 精炼方案 → 规划实验。

### `/idea-discovery` — 工作流 1 一键编排

**场景：** 从零开始找研究方向，全自动跑完工作流 1。

**用法：**

```bash
# 最基本：给一个研究方向
/idea-discovery "离散扩散语言模型的 factorized gap"

# 带参考论文
/idea-discovery "改进方法 X" — ref paper: https://arxiv.org/abs/2406.04329

# 带代码仓库（基于现有工作改进）
/idea-discovery "改进方法 X" — ref paper: https://arxiv.org/abs/2406.04329, base repo: https://github.com/org/project

# 每步都等你确认（不自动继续）
/idea-discovery "你的课题" — AUTO_PROCEED: false

# 只搜 Zotero + 网页
/idea-discovery "你的课题" — sources: zotero, web

# 下载最相关的 arXiv PDF
/idea-discovery "你的课题" — arxiv download: true
```

**参数：**

| 参数 | 默认值 | 说明 |
|------|--------|------|
| `AUTO_PROCEED` | `true` | 用户不回复时自动继续。设 `false` 每步都暂停 |
| `ARXIV_DOWNLOAD` | `false` | 设为 `true` 下载最相关的 arXiv PDF |
| `COMPACT` | `false` | 生成精简摘要文件 |
| `REF_PAPER` | `false` | 参考论文 URL/PDF，先总结再基于它找 idea |

**输出：**

- `idea-stage/IDEA_REPORT.md` — 排名后的 idea 列表
- `refine-logs/FINAL_PROPOSAL.md` — 精炼后的研究方案
- `refine-logs/EXPERIMENT_PLAN.md` — 实验路线图

**内部流程：** `/research-lit` → `/idea-creator` → `/novelty-check` → `/research-review` → `/research-refine-pipeline`

---

### `/research-pipeline` — 端到端全流程编排

**场景：** 想一次性跑完从找 idea 到投稿的完整流程。

**用法：**

```bash
# 全自动全流程
/research-pipeline "你的研究方向"

# 在 idea 选择关卡暂停
/research-pipeline "你的课题" — AUTO_PROCEED: false

# 每轮 review 后暂停
/research-pipeline "你的课题" — human checkpoint: true

# 只搜 Zotero + 网络
/research-pipeline "你的课题" — sources: zotero, web

# 加 DeepXiv
/research-pipeline "你的课题" — sources: all, deepxiv

# 加 Exa
/research-pipeline "你的课题" — sources: all, exa

# 下载 arXiv PDF
/research-pipeline "你的课题" — arxiv download: true

# 极限压测
/research-pipeline "你的课题" — difficulty: nightmare

# 自动写论文（工作流 3）
/research-pipeline "你的课题" — auto_write: true, venue: NeurIPS

# 组合使用
/research-pipeline "你的课题" — AUTO_PROCEED: false, human checkpoint: true
```

**参数：**

| 参数 | 默认值 | 说明 |
|------|--------|------|
| `AUTO_PROCEED` | `true` | 自动继续 |
| `ARXIV_DOWNLOAD` | `false` | 下载 arXiv PDF |
| `HUMAN_CHECKPOINT` | `false` | 每轮 review 后暂停 |
| `REVIEWER_DIFFICULTY` | `medium` | 审稿强度 |
| `AUTO_WRITE` | `false` | 自动进入工作流 3 写论文 |
| `VENUE` | `ICLR` | 目标会议（`AUTO_WRITE=true` 时用） |

**内部流程：** `idea-discovery` → 实现 → `run-experiment` → `auto-review-loop` → `paper-writing`（可选）

---

### `/idea-discovery-robot` — 机器人/具身智能版工作流 1

**场景：** 你的研究方向是机器人、具身智能、sim2real。

**用法：**

```bash
/idea-discovery-robot "sim2real 抓取中的域迁移问题"
```

和普通 `idea-discovery` 的区别：它会按 embodiment、sim2real、安全约束来筛选 idea。

---

### `/research-lit` — 文献调研

**场景：** 你想了解某个领域的最新进展、开放问题、反复出现的局限性。

**用法：**

```bash
# 基本用法
/research-lit "discrete diffusion models"

# 指定搜索源
/research-lit "topic" — sources: zotero, web
/research-lit "topic" — sources: all, deepxiv
/research-lit "topic" — sources: all, exa

# 同时下载最相关的 arXiv PDF
/research-lit "topic" — arxiv download: true

# 只下载 3 篇
/research-lit "topic" — arxiv download: true, max download: 3
```

**参数：**

| 参数 | 默认值 | 说明 |
|------|--------|------|
| `PAPER_LIBRARY` | `papers/`, `literature/` | 本地论文目录，先搜这里 |
| `MAX_LOCAL_PAPERS` | `20` | 最多扫描多少本地 PDF |
| `SOURCES` | `all` | 搜索源：`zotero`, `obsidian`, `local`, `web`, `semantic-scholar`, `deepxiv`, `exa`, `all` |
| `ARXIV_DOWNLOAD` | `false` | 下载最相关的 arXiv PDF |
| `ARXIV_MAX_DOWNLOAD` | `5` | 最多下载数量 |

**前置依赖：**

- `sources: deepxiv` → 需 `pip install deepxiv-sdk`
- `sources: exa` → 需 `pip install exa-py`，并设置 `EXA_API_KEY`
- `sources: zotero` → 需安装 [zotero-mcp](https://github.com/54yyyu/zotero-mcp)

**输出：** 全景文献综述，整理成结构化报告。

---

### `/idea-creator` — 头脑风暴 Idea

**场景：** 你已经做了文献调研，想基于已有知识生成具体的研究 idea。

**用法：**

```bash
/idea-creator "DLLMs post training"     # 基于已有文献生成 8-12 个 idea
```

**说明：** 通常被 `idea-discovery` 自动调用，不需要手动运行。但如果你已经有文献综述，想跳过调研直接 brainstorm，可以单独用。

---

### `/novelty-check` — 查新验证

**场景：** 你有一个 idea，想知道有没有人已经做过了。

**用法：**

```bash
/novelty-check "你的 idea 描述"
```

**说明：** 自动搜索相关文献，判断你的 idea 是否已有类似工作。通常被 `idea-discovery` 自动调用。

---

### `/research-review` — 外部批判

**场景：** 你想让外部 LLM（GPT-5.4）批判你的 idea，找出弱点。

**用法：**

```bash
/research-review "你的 idea 描述"
```

**说明：** 这是 devil's advocate review，专门挑毛病。通常被 `idea-discovery` 自动调用。

---

### `/research-refine` — 方案精炼

**场景：** 你有一个初步 idea，想把它打磨成可执行的研究方案。

**用法：**

```bash
/research-refine "你的 idea 描述"
```

**说明：** 冻结问题锚点，通过迭代 review 打磨方法。输出 `refine-logs/FINAL_PROPOSAL.md`。

---

### `/research-refine-pipeline` — 精炼 + 实验规划

**场景：** 一键完成方案精炼 + 实验规划。

**用法：**

```bash
/research-refine-pipeline "你的 idea 描述"
```

**说明：** 这是 `research-refine` + `experiment-plan` 的组合，通常被 `idea-discovery` 自动调用。

---

### `/experiment-plan` — 实验路线图

**场景：** 你已有研究方案，需要规划具体实验。

**用法：**

```bash
/experiment-plan
```

**说明：** 读取 `refine-logs/FINAL_PROPOSAL.md`，生成 claim-driven 实验路线图。输出 `refine-logs/EXPERIMENT_PLAN.md`。

---

### `/run-experiment` — 部署实验

**场景：** 你已有实验代码，需要部署到 GPU 运行。

**用法：**

```bash
/run-experiment "实验描述"
```

**说明：** 通常被 `experiment-bridge` 或 `auto-review-loop` 自动调用。需要在 `CLAUDE.md` 中配置 GPU 服务器信息。

---

### `/dse-loop` — Design-Space Exploration

**场景：** 你需要系统地探索超参数空间（比如学习率、batch size、模型大小的组合）。

**用法：**

```bash
/dse-loop "超参数搜索空间描述"
```

---

## 工作流 1.5：实验桥接

> **什么时候用这个工作流？**
> 
> 你已有实验计划（来自工作流 1 或自己写的），需要：实现代码 → 代码审查 → sanity check → 部署到 GPU → 收集结果。

### `/experiment-bridge` — 工作流 1.5 一键编排

**场景：** 有实验计划了，帮我实现代码、部署、拿初始结果。

**用法：**

```bash
# 自动读取 refine-logs/EXPERIMENT_PLAN.md
/experiment-bridge

# 指定实验计划文件
/experiment-bridge "my_plan.md"

# 基于已有代码仓库改进
/experiment-bridge — base repo: https://github.com/org/project

# 跳过代码审查（快但风险高）
/experiment-bridge — code review: false

# 实现完不自动部署，等你检查
/experiment-bridge — auto deploy: false

# 加 W&B 日志
/experiment-bridge — wandb: true
```

**参数：**

| 参数 | 默认值 | 说明 |
|------|--------|------|
| `CODE_REVIEW` | `true` | GPT-5.4 部署前审查代码 |
| `AUTO_DEPLOY` | `true` | 实现 + 审查后自动部署 |
| `BASE_REPO` | `false` | GitHub 仓库 URL，作为基础代码 |
| `SANITY_FIRST` | `true` | 先跑最小实验发现 bug |
| `MAX_PARALLEL_RUNS` | `4` | 最多并行部署几个实验 |
| `WANDB` | `false` | 自动加 W&B 日志 |

**前置依赖：**

- `wandb: true` → 需在 `CLAUDE.md` 配 `wandb_project`

**输出：** 实验代码 + 初始结果，更新 `refine-logs/EXPERIMENT_TRACKER.md`。

---

### `/monitor-experiment` — 监控实验

**场景：** 实验正在跑，你想看进度和中间结果。

**用法：**

```bash
/monitor-experiment
```

**说明：** 从 W&B 或本地日志拉训练曲线，显示对比表。

---

### `/experiment-audit` — 实验审计

**场景：** 你想审查已跑完的实验，检查是否有问题（数据泄漏、不公平对比等）。

**用法：**

```bash
/experiment-audit "实验结果描述"
```

---

### `/experiment-queue` — 实验队列管理

**场景：** 你有多个实验要跑，需要排队管理。

**用法：**

```bash
/experiment-queue "添加/查看/管理实验队列"
```

---

## 工作流 2：自动科研循环

> **什么时候用这个工作流？**
> 
> 你已有论文初稿或实验结果，想让 AI 自动 review → 找弱点 → 建议实验 → 自动实现 → 重跑 → 再 review，循环到通过为止。你可以睡觉，它自己跑。

### `/auto-review-loop` — 工作流 2 一键编排

**场景：** 帮我 review 论文，修复问题，循环到通过为止。

**用法：**

```bash
# 基本用法（自动推断主题）
/auto-review-loop

# 指定主题
/auto-review-loop "离散扩散语言模型的 factorized gap"

# 指定范围 + 提示
/auto-review-loop "重点看第 3-5 节，CRF 结果偏弱"

# 每轮暂停等你确认
/auto-review-loop "topic" — human checkpoint: true

# 更严格的 review
/auto-review-loop "topic" — difficulty: hard

# 极限压测（GPT 直接读代码仓库）
/auto-review-loop "topic" — difficulty: nightmare
```

**参数：**

| 参数 | 默认值 | 说明 |
|------|--------|------|
| `MAX_ROUNDS` | `4` | 最多 review→修复→再 review 轮数 |
| `POSITIVE_THRESHOLD` | `6/10` | 达到此分数自动停止 |
| `HUMAN_CHECKPOINT` | `false` | 每轮后暂停等你确认 |
| `REVIEWER_DIFFICULTY` | `medium` | 审稿对抗强度 |

**安全机制：**

- 超过 4 GPU-hour 的实验自动跳过
- 优先改叙事而非跑新实验（省钱）
- 上下文压缩恢复（会话不会断）

---

### `/auto-review-loop-llm` — LLM 专用版

**场景：** 你的研究方向是纯大语言模型（LLM）。

**用法：**

```bash
/auto-review-loop-llm "你的 LLM 研究方向"
```

---

### `/auto-review-loop-minimax` — Minimax/博弈论专用版

**场景：** 你的研究方向涉及 minimax、对抗训练、博弈论。

**用法：**

```bash
/auto-review-loop-minimax "你的 minimax 研究方向"
```

---

### `/analyze-results` — 结果分析

**场景：** 实验跑完了，需要分析结果、画图表、找规律。

**用法：**

```bash
/analyze-results "实验结果路径或描述"
```

---

### `/result-to-claim` — 结果转 Claim

**场景：** 你有实验结果，需要把它形式化成可验证的 scientific claim。

**用法：**

```bash
/result-to-claim "实验结果描述"
```

---

### `/ablation-planner` — Ablation 实验规划

**场景：** 你需要规划消融实验（ablation study），验证每个组件的贡献。

**用法：**

```bash
/ablation-planner "你的方法描述"
```

---

### `/training-check` — 训练检查

**场景：** 训练过程出问题了（loss 不下降、过拟合、NaN 等），需要诊断。

**用法：**

```bash
/training-check "训练问题描述"
```

---

## 工作流 3：论文写作

> **什么时候用这个工作流？**
> 
> 你已有实验结果和叙事报告，想把它变成可投稿的 LaTeX PDF。

### `/paper-writing` — 工作流 3 一键编排

**场景：** 从叙事报告到投稿 PDF，全自动。

**用法：**

```bash
# 自动读取 NARRATIVE_REPORT.md
/paper-writing "NARRATIVE_REPORT.md"

# 指定目标会议
/paper-writing "NARRATIVE_REPORT.md" — venue: NeurIPS

# IEEE 期刊
/paper-writing "NARRATIVE_REPORT.md" — venue: IEEE_JOURNAL

# 用 Gemini 生成插图
/paper-writing "NARRATIVE_REPORT.md" — illustration: gemini

# 用 Mermaid 画流程图（免费）
/paper-writing "NARRATIVE_REPORT.md" — illustration: mermaid

# 每步都暂停等你确认
/paper-writing "NARRATIVE_REPORT.md" — AUTO_PROCEED: false
```

**参数：**

| 参数 | 默认值 | 说明 |
|------|--------|------|
| `VENUE` | `ICLR` | 目标会议：`ICLR`, `NeurIPS`, `ICML`, `CVPR`, `ACL`, `AAAI`, `ACM`, `IEEE_JOURNAL`, `IEEE_CONF` |
| `ILLUSTRATION` | `figurespec` | 插图生成：`figurespec`（默认）, `gemini`, `codex-image2`, `mermaid`, `false` |
| `AUTO_PROCEED` | `true` | 自动继续 |
| `HUMAN_CHECKPOINT` | `false` | 改进循环每轮后暂停 |
| `MAX_IMPROVEMENT_ROUNDS` | `2` | 改进循环轮数 |

**前置依赖：**

- LaTeX 环境（`latexmk` + `pdfinfo`）
- `ILLUSTRATION: gemini` → 需 `GEMINI_API_KEY`

**内部流程：** `/paper-plan` → `/paper-figure` → `/paper-write` → `/paper-compile` → `/auto-paper-improvement-loop`

---

### `/paper-plan` — 论文大纲

**场景：** 你已有叙事报告，想生成 claims-evidence 矩阵 + 分节计划。

**用法：**

```bash
/paper-plan "NARRATIVE_REPORT.md"
```

**输出：** `PAPER_PLAN.md` — 论文大纲。

---

### `/paper-figure` — 图表生成

**场景：** 需要生成数据驱动的图表（训练曲线、柱状图、热力图）和 LaTeX 对比表。

**用法：**

```bash
/paper-figure "数据路径或描述"
```

**说明：**

- **能生成：** 训练曲线、柱状图、热力图、LaTeX 对比表
- **不能生成：** 架构图、流程图、模型示意图、生成样本网格（这些需要手动做）
- 典型 ML 论文中 ~60% 图表可自动生成，~40% 需手动

---

### `/paper-write` — 逐节 LaTeX 写作

**场景：** 根据大纲和图表，逐 section 生成 LaTeX。

**用法：**

```bash
/paper-write "PAPER_PLAN.md"
```

**参数：**

| 参数 | 默认值 | 说明 |
|------|--------|------|
| `DBLP_BIBTEX` | `true` | 从 DBLP/CrossRef 拉真实 BibTeX，防幻觉引用 |
| `TARGET_VENUE` | `ICLR` | 目标会议格式 |
| `ANONYMOUS` | `true` | 匿名审稿模式。IEEE 时设 `false` |
| `MAX_PAGES` | `9` | 页数上限 |
| `ILLUSTRATION` | `gemini` | AI 作图方式 |

---

### `/paper-compile` — 编译 PDF

**场景：** LaTeX 写好了，编译 PDF 并修复错误。

**用法：**

```bash
/paper-compile
```

**说明：** 自动运行 `latexmk`，修复编译错误，验证页数。

---

### `/auto-paper-improvement-loop` — 论文改进循环

**场景：** PDF 编译好了，想让 AI 自动 review 内容 + 格式，修复后重编译。

**用法：**

```bash
/auto-paper-improvement-loop "论文主题"
```

**说明：** 内容审稿 ×2 + 格式合规检查。通常被 `paper-writing` 自动调用。

---

### `/paper-illustration` — AI 生成插图

**场景：** 需要生成论文插图（方法示意图、概念图等）。

**用法：**

```bash
/paper-illustration "插图描述"
```

**前置依赖：** 需 `GEMINI_API_KEY`

---

### `/paper-illustration-image2` — Codex 图像生成

**场景：** 用 Codex 生图（不需要外部 API key，用你的 ChatGPT Plus/Pro 额度）。

**用法：**

```bash
/paper-illustration-image2 "插图描述"
```

---

### `/figure-spec` — 确定性图表生成

**场景：** 需要生成精确的架构图、流程图（JSON → SVG）。

**用法：**

```bash
/figure-spec "图表规格描述"
```

**说明：** 确定性渲染，适合需要精确控制的图表。

---

### `/figure-description` — 图表描述生成

**场景：** 你已有图表，需要写 Figure caption。

**用法：**

```bash
/figure-description "图表路径"
```

---

### `/mermaid-diagram` — Mermaid 流程图

**场景：** 需要画流程图，免费，不需要 API key。

**用法：**

```bash
/mermaid-diagram "流程图描述"
```

---

## 工作流 4：Rebuttal

> **什么时候用这个工作流？**
> 
> 论文投出去了，收到审稿意见，需要写 rebuttal。

### `/rebuttal` — Rebuttal 写作

**场景：** 收到审稿意见，需要写回复。

**用法：**

```bash
# 基本用法
/rebuttal "paper/ + reviews"

# 指定会议
/rebuttal "paper/ + reviews" — venue: ICML

# 字符限制（ICML 通常 5000）
/rebuttal "paper/ + reviews" — character limit: 5000

# 只解析审稿意见，不生成回复（先看要什么）
/rebuttal "paper/ + reviews" — quick mode: true

# 自动跑补充实验
/rebuttal "paper/ + reviews" — auto experiment: true
```

**参数：**

| 参数 | 默认值 | 说明 |
|------|--------|------|
| `VENUE` | `ICML` | 目标会议 |
| `CHARACTER_LIMIT` | — | **必填。** 字符限制 |
| `QUICK_MODE` | `false` | 只解析 + 策略，不生成回复 |
| `AUTO_EXPERIMENT` | `false` | 自动跑补充实验 |
| `MAX_STRESS_TEST_ROUNDS` | `1` | 压力测试轮数 |
| `MAX_FOLLOWUP_ROUNDS` | `3` | 每个 reviewer follow-up 上限 |

---

### `/resubmit-pipeline` — 重投流程

**场景：** 被拒了，需要修改后重投。

**用法：**

```bash
/resubmit-pipeline "修改计划描述"
```

---

## 文献检索工具

> 这些 skill 可以单独使用，也可以在工作流中被自动调用。

### `/arxiv` — arXiv 搜索

**场景：** 搜 arXiv 论文。

**用法：**

```bash
/arxiv "diffusion models"
```

---

### `/semantic-scholar` — Semantic Scholar 搜索

**场景：** 用 Semantic Scholar API 搜论文。

**用法：**

```bash
/semantic-scholar "query"
```

---

### `/deepxiv` — DeepXiv 渐进式检索

**场景：** 深度文献检索，渐进式挖掘相关论文。

**用法：**

```bash
/deepxiv "query"
```

**前置依赖：** `pip install deepxiv-sdk`

---

### `/exa-search` — Exa AI 网页搜索

**场景：** 智能网页搜索，覆盖博客、文档、新闻和研究论文。

**用法：**

```bash
/exa-search "query"
```

**前置依赖：** `pip install exa-py`，设置 `EXA_API_KEY`

---

### `/openalex` — OpenAlex 搜索

**场景：** 用 OpenAlex API 搜学术论文。

**用法：**

```bash
/openalex "query"
```

---

### `/alphaxiv` — AlphaXiv 搜索

**场景：** 用 AlphaXiv 搜论文。

**用法：**

```bash
/alphaxiv "query"
```

---

### `/comm-lit-review` — 社区文献综述

**场景：** 协作式文献综述。

**用法：**

```bash
/comm-lit-review "topic"
```

---

### `/prior-art-search` — 在先技术搜索

**场景：** 专利/知识产权相关的在先技术搜索。

**用法：**

```bash
/prior-art-search "技术描述"
```

---

## 知识库与优化

### `/research-wiki` — 研究知识库

**场景：** 想让 ARIS 记住你的研究积累（论文、idea、实验、claim）。

**用法：**

```bash
# 初始化知识库
/research-wiki init

# 添加论文
/research-wiki ingest "论文路径或 URL"

# 查询知识库
/research-wiki query "你的问题"

# 同步更新
/research-wiki sync

# 统计信息
/research-wiki stats
```

**说明：** 没有 wiki 时 ARIS 是无状态的，每次从零开始。有了 wiki 后跨会话积累知识。

---

### `/meta-optimize` — ARIS 自我优化

**场景：** 跑了 5 次以上工作流后，让 ARIS 分析你的使用模式并提改进建议。

**用法：**

```bash
# 分析当前项目
/meta-optimize

# 分析跨项目趋势
/meta-optimize --global
```

**说明：** 读取 `.aris/meta/events.jsonl` 中的使用日志。

---

## 专利相关

### `/patent-pipeline` — 专利全流程

**场景：** 从 idea 到专利申请的全流程。

**用法：**

```bash
/patent-pipeline "你的发明描述"
```

---

### `/patent-novelty-check` — 专利查新

**场景：** 检查你的发明是否已有专利。

**用法：**

```bash
/patent-novelty-check "发明描述"
```

---

### `/patent-review` — 专利审查

**场景：** 审查专利文件的质量。

**用法：**

```bash
/patent-review "专利文件路径"
```

---

## 演讲、海报与可视化

### `/paper-slides` — 会议演讲幻灯片

**场景：** 论文中了，需要准备演讲幻灯片。

**用法：**

```bash
/paper-slides "paper/"
```

**输出：** Beamer PDF + PPTX + 演讲稿 + Q&A 预案。

---

### `/paper-poster` — 会议海报

**场景：** 需要制作会议海报。

**用法：**

```bash
/paper-poster "paper/"
```

**输出：** A0/A1 海报 PDF + 可编辑 PPTX + SVG。

---

### `/paper-talk` — 演讲准备

**场景：** 准备会议演讲的完整流程。

**用法：**

```bash
/paper-talk "paper/"
```

---

### `/slides-polish` — 幻灯片润色

**场景：** 已有幻灯片，需要润色改进。

**用法：**

```bash
/slides-polish "slides.pptx"
```

---

### `/pixel-art` — 像素艺术生成

**场景：** 生成像素风格的插图。

**用法：**

```bash
/pixel-art "描述"
```

---

## 辅助与杂项工具

### `/feishu-notify` — 飞书通知

**场景：** 让 ARIS 把进度推送到飞书。

**用法：**

```bash
/feishu-notify "消息内容"
```

---

### `/overleaf-sync` — Overleaf 同步

**场景：** 把论文同步到 Overleaf。

**用法：**

```bash
/overleaf-sync
```

---

### `/serverless-modal` — Modal 无服务器 GPU

**场景：** 没有 GPU，用 Modal 云 GPU 跑实验。

**用法：**

```bash
/serverless-modal "实验命令"
```

**前置依赖：** `pip install modal && modal setup`

**说明：** $30/月免费额度，无需 SSH/Docker，跑完自动停止。

---

### `/vast-gpu` — Vast.ai GPU 租用

**场景：** 租用 Vast.ai 的便宜 GPU。

**用法：**

```bash
/vast-gpu "实验命令"
```

---

### `/qzcli` — 论文命令行工具

**场景：** 各种论文相关的 CLI 辅助。

**用法：**

```bash
/qzcli "命令"
```

---

### `/gemini-search` — Gemini 搜索

**场景：** 用 Gemini 进行搜索。

**用法：**

```bash
/gemini-search "query"
```

---

### `/kill-argument` — 反驳生成

**场景：** 生成对某个论点的反驳。

**用法：**

```bash
/kill-argument "论点描述"
```

---

### `/grant-proposal` — 基金申请

**场景：** 写基金/项目申请书。

**用法：**

```bash
/grant-proposal "项目描述"
```

---

### `/specification-writing` — 规格说明写作

**场景：** 写技术规格文档。

**用法：**

```bash
/specification-writing "技术描述"
```

---

### `/system-profile` — 系统画像

**场景：** 分析系统特性。

**用法：**

```bash
/system-profile "系统描述"
```

---

### `/writing-systems-papers` — 系统论文写作

**场景：** 写系统类论文（非 ML 模型类，而是工程系统类）。

**用法：**

```bash
/writing-systems-papers "系统描述"
```

---

### `/proof-checker` — 证明验证

**场景：** 验证数学证明的严谨性。

**用法：**

```bash
/proof-checker "证明内容"
```

---

### `/proof-writer` — 证明写作

**场景：** 帮你写数学证明。

**用法：**

```bash
/proof-writer "定理描述"
```

---

### `/formula-derivation` — 公式推导

**场景：** 推导数学公式。

**用法：**

```bash
/formula-derivation "公式描述"
```

---

### `/citation-audit` — 引用审计

**场景：** 检查论文引用是否有问题（漏引、错引、过度自引等）。

**用法：**

```bash
/citation-audit "论文路径"
```

---

### `/paper-claim-audit` — Claim 审计

**场景：** 检查论文中的 claim 是否有实验支撑。

**用法：**

```bash
/paper-claim-audit "论文路径"
```

---

### `/claims-drafting` — Claim 起草

**场景：** 帮你起草论文的 claim 表述。

**用法：**

```bash
/claims-drafting "研究发现"
```

---

### `/embodiment-description` — 具身描述

**场景：** 描述机器人/具身系统的 embodiment。

**用法：**

```bash
/embodiment-description "系统描述"
```

---

### `/invention-structuring` — 发明结构化

**场景：** 把发明构思结构化为技术方案。

**用法：**

```bash
/invention-structuring "发明描述"
```

---

### `/jurisdiction-format` — 管辖格式

**场景：** 法律/知识产权相关的格式处理。

**用法：**

```bash
/jurisdiction-format "内容"
```

---

## 完整示例：从 idea 到投稿

假设你是一名研究生，想写一篇 NeurIPS 论文，方向是"改进扩散模型的采样效率"。

### Step 0：安装和配置

```bash
# 1. 确保 Claude Code 已安装
# 2. 确保 Codex MCP 已配置
# 3. 确保 LaTeX 已安装（因为最终要生成 PDF）

# 4. 在你的项目目录安装 ARIS skill
cd D:\projects\my-paper
D:\BaiduSyncdisk\code\MyDemo\Auto-claude-code-research-in-sleep\my_tools\install_aris_flat.ps1

# 5. 进入项目
claude
```

### Step 1：找 Idea（工作流 1）

```bash
# 全自动找 idea
/idea-discovery "改进扩散模型的采样效率" — effort: max

# 等待输出...
# 你会看到：
# - 文献综述
# - 8-12 个具体 idea
# - 每个 idea 的 novelty 验证
# - pilot 实验结果
# - 排名后的推荐
```

假设它推荐了 "Adaptive Step-size Diffusion Sampling via Error Prediction"。

### Step 2：方案精炼

`idea-discovery` 已经自动跑完了 `/research-refine`，生成了 `refine-logs/FINAL_PROPOSAL.md` 和 `refine-logs/EXPERIMENT_PLAN.md`。

### Step 3：实现实验（工作流 1.5）

```bash
# 自动读取 EXPERIMENT_PLAN.md，实现代码、审查、部署
/experiment-bridge — effort: max

# 等待输出...
# 你会看到：
# - 代码实现
# - GPT-5.4 代码审查结果
# - Sanity check 结果
# - 完整实验部署
# - 初始结果
```

### Step 4：自动改进（工作流 2）

```bash
# 让 AI 自动 review 和改进
/auto-review-loop "Adaptive Step-size Diffusion Sampling" — effort: max, difficulty: hard

# 等待输出...
# 你会看到每轮 review 的分数和修改
# 达到 6/10 或 "accept" 时自动停止
```

### Step 5：写论文（工作流 3）

```bash
# 从叙事报告生成论文
/paper-writing "NARRATIVE_REPORT.md" — venue: NeurIPS, effort: max

# 等待输出...
# 你会得到：
# - paper/ 目录（LaTeX 源码）
# - paper/main.pdf（编译好的 PDF）
```

### Step 6：投稿

把 `paper/main.pdf` 上传到 OpenReview，完成投稿。

### Step 7（可选）：收到审稿意见后写 Rebuttal

```bash
/rebuttal "paper/ + reviews" — venue: NeurIPS, character limit: 5000
```

---

> 以上就是完整流程。每个步骤都可以单独使用，也可以串联。根据你的需求灵活组合即可。
