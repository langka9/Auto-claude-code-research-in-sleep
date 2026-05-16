# 我的科研工作流 — ARIS Skill 使用手册

> 这份手册是专属于你的。它只包含你真正会用到的 skill，每一步都告诉你：什么时候用、怎么配置、prompt 怎么写。

---
# 简化版

### 第一步：安装额外依赖

```bash
# DeepXiv 渐进式文献检索
pip install deepxiv-sdk

# AlphaXiv 搜索（可选）
# 直接通过 web 搜索即可，无需额外安装

# Modal 无服务器 GPU（如果你没有远程 GPU，用这个）
pip install modal && modal setup
```

### 第二步：配置 .env 文件

ARIS 的所有配置都通过 `.env` 文件管理，不需要设置系统环境变量。

```bash
# 1. 复制模板文件到你的项目根目录
cp my_tools/.env.example .env

# 2. 编辑 .env，填写你的配置
#    LLM_WIKI_PATH=D:\path\to\your\llm-wiki
#    ARIS_REPO=D:\path\to\Auto-claude-code-research-in-sleep
#    SEMANTIC_SCHOLAR_API_KEY=your-api-key-here
```

`.env` 文件放在哪里？
- **推荐**：和 `install_aris_flat.ps1` 放在同一目录（Bootstrap 时会自动复制）
- **也可以**：放在你的 idea 项目根目录

脚本会**先查找脚本所在目录的 `.env`**，找不到再查找**当前工作目录的 `.env`**。

**配置项说明：**

| 配置项 | 必填 | 说明 |
|--------|------|------|
| `LLM_WIKI_PATH` | 是 | 你的 Obsidian 知识库路径 |
| `ARIS_REPO` | 否 | ARIS 仓库路径。留空会自动检测 |
| `SEMANTIC_SCHOLAR_API_KEY` | 是 | 到 https://www.semanticscholar.org/product/api#api-key-form 免费申请 |

**> 重要：不配置 SEMANTIC_SCHOLAR_API_KEY 也能用，但请求限制很严格（约1次/秒），容易触发 429 错误。强烈建议配置。**

### 第三步：初始化
```bash
mkdir D:\AutoResearch\my-idea
cd D:\AutoResearch\my-idea
D:\BaiduSyncdisk\code\MyDemo\Auto-claude-code-research-in-sleep\my_tools\install_aris_flat.ps1 -Bootstrap
```

### 第四步：配置 CLAUDE.md

在你的项目根目录创建 `CLAUDE.md`，内容见**附录 A**。这是 ARIS 读取配置的入口。

### 第五步：配置 .claude/settings.json
在 `.claude/settings.json` 中配置你的 Anthropic API 相关信息，确保 `ANTHROPIC_MODEL` 设置为 `kimi-for-coding`或者其他模型。

```json
{
  "env": {
    "ANTHROPIC_AUTH_TOKEN": "your-anthropic-api-key"
    "ANTHROPIC_BASE_URL": "https://api.kimi.com/coding/",
    "ANTHROPIC_MODEL": "kimi-for-coding"
    }
}
```

## Step 1: 文献调研（Obsidian + 多源搜索）

```bash
/research-wiki init # 初始化项目专属知识库
/research-wiki ingest "llm-wiki/" # 增量添加论文
/research-wiki sync # 同步索引
/research-wiki query "扩散模型采样效率的最新进展" # 查询知识库（不常用）
/research-lit "扩散模型采样效率" — sources: obsidian, deepxiv, semantic-scholar, web, arxiv download: true, max download: 20 # 多源搜索并下载论文
/research-wiki ingest "papers/" # 把下载的论文加入知识库
/research-wiki sync # 同步索引
/alphaxiv "扩散模型采样效率" # 获取 AlphaXiv 的补充结果

>**ingest 后一定跟着 sync**

## Step 2: 研究方案设计（数学理论 + 证明推导）
### 2.1 形成研究方案

```bash
# 从 idea 开始
/idea-creator "改进扩散模型采样效率的新方向"
# 基于文献调研结果，精炼研究方案
/research-refine @idea-stage\IDEA_REPORT.md 中的 Tier 1
```

### 2.2 数学理论设计

```bash
# 帮我推导核心公式
/formula-derivation @FINAL_PROPOSAL.md "推导FINAL_PROPOSAL.md中的理论，把推导结果和过程记录在 formulas/ 目录下"
# 帮我写证明
/proof-writer "帮我证明 formulas/ 里面的所有定理，证明过程写在 proofs/ 目录下"
# 验证证明的正确性
/proof-checker "检验 proofs/ 中所有证明的正确性，检验过程写进 proofs/ 目录下，并且以 CHECK 为文件前缀"
```

### 2.3 实验规划

```bash
/experiment-plan  @refine-logs/FINAL_PROPOSAL.md  @refine-logs/REFINEMENT_REPORT.md @CLAUDE.md
```

### Step 2 的输出

- `refine-logs/FINAL_PROPOSAL.md` — 精炼后的研究方案
- `refine-logs/EXPERIMENT_PLAN.md` — 实验路线图
- `proofs/` — 证明文档
- `formulas/` — 推导文档

---

## Step 3: 实验执行（远程服务器）

> **什么时候做？**
> > 研究方案确定后，需要验证。你的实验跑在远程服务器上。

### 3.1 配置远程服务器信息
在 `CLAUDE.md` 中配置 GPU 服务器配置：

### 3.2 实现实验代码
```bash
# 自动读取 EXPERIMENT_PLAN.md，实现代码
/experiment-bridge "refine-logs/EXPERIMENT_PLAN.md" 远程服务器配置在 @CLAUDE.md 中
```

---
# 完整版

## 目录

- [准备工作（首次使用必看）](#准备工作首次使用必看)
- [Step 0: 初始化项目 + 知识库](#step-0-初始化项目--知识库)
  - [0.1 创建项目目录结构](#01-创建项目目录结构两种方式)
  - [0.2 连接 Obsidian 知识库](#02-连接你的-obsidian-知识库llm-wiki)
  - [0.3 初始化 ARIS 知识库](#03-初始化-aris-知识库)
  - [0.4 导入 Obsidian 内容](#04-把-obsidian-知识库导入-aris)
  - [0.5 同步策略](#05-同步策略避免重复)
- [Step 1: 文献调研（Obsidian + 多源搜索）](#step-1-文献调研obsidian--多源搜索)
- [Step 2: 研究方案设计（数学理论 + 证明推导）](#step-2-研究方案设计数学理论--证明推导)
- [Step 3: 实验执行（远程服务器）](#step-3-实验执行远程服务器)
- [Step 4: 迭代改进](#step-4-迭代改进)
- [Step 5: 论文写作（IEEE Journal）](#step-5-论文写作ieee-journal)
- [Step 6: 审稿与改进](#step-6-审稿与改进)
- [Step 7: 知识库存档与同步](#step-7-知识库存档与同步)
- [Step 8: 使用模板 (Templates)](#step-8-使用模板-templates)
- [Step 9: Meta-Optimize (ARIS 自我优化)](#step-9-meta-optimize-aris-自我优化)
- [附录 A: CLAUDE.md 配置模板](#附录-a-claudemd-配置模板)
- [附录 B: 项目目录结构模板](#附录-b-项目目录结构模板)
- [附录 C: 远程服务器配置](#附录-c-远程服务器配置)
- [附录 D: 常用 Prompt 速查表](#附录-d-常用-prompt-速查表)

---

## 准备工作（首次使用必看）

### 第一步：安装 ARIS skill

参考 `README.md` 中的说明，在你的项目里运行：

```powershell
D:\BaiduSyncdisk\code\MyDemo\Auto-claude-code-research-in-sleep\my_tools\install_aris_flat.ps1 -Bootstrap
```

### 第二步：配置 .env 文件

ARIS 的所有配置都通过 `.env` 文件管理，不需要设置系统环境变量。

```bash
# 1. 复制模板文件到你的项目根目录
cp my_tools/.env.example .env

# 2. 编辑 .env，填写你的配置
#    LLM_WIKI_PATH=D:\path\to\your\llm-wiki
#    ARIS_REPO=D:\path\to\Auto-claude-code-research-in-sleep
#    SEMANTIC_SCHOLAR_API_KEY=your-api-key-here
```

`.env` 文件放在哪里？
- **推荐**：和 `install_aris_flat.ps1` 放在同一目录（Bootstrap 时会自动复制）
- **也可以**：放在你的 idea 项目根目录

脚本会**先查找脚本所在目录的 `.env`**，找不到再查找**当前工作目录的 `.env`**。

**配置项说明：**

| 配置项 | 必填 | 说明 |
|--------|------|------|
| `LLM_WIKI_PATH` | 是 | 你的 Obsidian 知识库路径 |
| `ARIS_REPO` | 否 | ARIS 仓库路径。留空会自动检测 |
| `SEMANTIC_SCHOLAR_API_KEY` | 是 | 到 https://www.semanticscholar.org/product/api#api-key-form 免费申请 |

**> 重要：不配置 SEMANTIC_SCHOLAR_API_KEY 也能用，但请求限制很严格（约1次/秒），容易触发 429 错误。强烈建议配置。**

### 第三步：安装额外依赖

```bash
# DeepXiv 渐进式文献检索
pip install deepxiv-sdk

# AlphaXiv 搜索（可选）
# 直接通过 web 搜索即可，无需额外安装

# Modal 无服务器 GPU（如果你没有远程 GPU，用这个）
pip install modal && modal setup
```

### 第四步：配置 CLAUDE.md

在你的项目根目录创建 `CLAUDE.md`，内容见**附录 A**。这是 ARIS 读取配置的入口。

### 第五步：配置 .claude/settings.json
在 `.claude/settings.json` 中配置你的 Anthropic API 相关信息，确保 `ANTHROPIC_MODEL` 设置为 `kimi-for-coding`或者其他模型。

```json
{
  "env": {
    "ANTHROPIC_AUTH_TOKEN": "your-anthropic-api-key"
    "ANTHROPIC_BASE_URL": "https://api.kimi.com/coding/",
    "ANTHROPIC_MODEL": "kimi-for-coding"
    }
}
```

---

## Step 0: 初始化项目 + 知识库

> **什么时候做？**
> 
> **项目第一天就做。** 在任何研究工作开始之前。这样 ARIS 从一开始就能记住你的积累。

### 0.1 创建项目目录结构（两种方式）

#### 方式 A：一键 Bootstrap（推荐）

运行安装脚本时加上 `-Bootstrap` 参数，自动创建完整的研究项目：

```powershell
# 方法 1：先创建项目目录，再进入运行
mkdir D:\AutoResearch\my-idea
cd D:\AutoResearch\my-idea
D:\BaiduSyncdisk\code\MyDemo\Auto-claude-code-research-in-sleep\my_tools\install_aris_flat.ps1 -Bootstrap

# 方法 2：直接指定路径
D:\BaiduSyncdisk\code\MyDemo\Auto-claude-code-research-in-sleep\my_tools\install_aris_flat.ps1 -Bootstrap D:\AutoResearch\my-idea
```

Bootstrap 会自动创建：
- 完整的目录结构（见**附录 B**）
- `llm-wiki/` 软链接指向你的 Obsidian 知识库
- `CLAUDE.md` 配置模板（预填了你的 llm-wiki 路径）
- `README.md` 模板
- `my_tools/` 目录（复制三本使用手册）
- 安装所有 ARIS skills

#### 方式 B：手动创建

在你的项目根目录按**附录 B** 创建目录。

关键目录说明：

| 目录 | 用途 | 谁创建 |
|------|------|--------|
| `research-wiki/` | ARIS 知识库存放处（项目专属） | `/research-wiki init` 自动创建 |
| `llm-wiki/` | 共享 Obsidian 知识库（软链接） | Bootstrap 或手动创建 |
| `idea-stage/` | Idea 相关输出 | `idea-discovery` 自动创建 |
| `refine-logs/` | 方案精炼和实验计划 | `research-refine` 自动创建 |
| `paper/` | 论文 LaTeX 源码 | `paper-writing` 自动创建 |
| `experiments/` | 实验代码和结果 | `experiment-bridge` 自动创建 |
| `figures/` | 论文图表 | 你自己或 `paper-figure` |

### 0.2 连接你的 Obsidian 知识库（llm-wiki）

你的 Obsidian 知识库路径在 `.env` 文件的 `LLM_WIKI_PATH` 中配置。结构如下：

```
llm-wiki/
├── README.md          # 知识库总览和使用说明
├── SCHEMA.md          # 实体类型定义和字段规范
├── entities/          # 所有实体记录（论文、作者、概念等）
│   ├── papers/
│   ├── authors/
│   └── concepts/
└── extracted/         # PDF 提取的原始内容
    ├── paper1/
    └── paper2/
```

**ARIS 会这样读取你的 llm-wiki：**

1. 先读 `README.md` —— 了解知识库的整体结构和用途
2. 再读 `SCHEMA.md` —— 了解有哪些实体类型、每个类型有什么字段
3. 遍历 `entities/` —— 读取所有论文、作者、概念等记录
4. 按需读取 `extracted/` —— 当你询问某篇论文的具体内容时

**连接方式：**

**方案 A：软链接（推荐，Obsidian 和 ARIS 实时同步）**

```powershell
# Bootstrap 会自动创建这个软链接（读取 .env 中的 LLM_WIKI_PATH）
# 如果你手动创建：
New-Item -ItemType Junction -Path "D:\AutoResearch\my-idea\llm-wiki" -Target "$env:LLM_WIKI_PATH"
```

**方案 B：复制（Obsidian 和 ARIS 独立，不推荐）**

```powershell
# 定期手动同步（会导致数据重复，不推荐）
Copy-Item -Recurse "$env:LLM_WIKI_PATH\*" "D:\AutoResearch\my-idea\llm-wiki\"
```

**> 重要：llm-wiki 是共享的只读参考。所有 idea 项目都通过软链接指向同一个 llm-wiki，不复制。每个项目有自己的 `research-wiki/` 存放 idea 专属知识。**

### 0.3 初始化 ARIS 知识库

```bash
# 进入你的项目
claude

# 初始化知识库
/research-wiki init
```

这会在项目里创建 `research-wiki/` 目录，结构如下：

```
research-wiki/
  index.md              # 分类索引（自动生成）
  log.md                # 时间线日志
  gap_map.md            # 领域空白地图
  papers/               # 论文条目
  ideas/                # 想法条目
  experiments/          # 实验条目
  claims/               # 声明条目
  graph/
    edges.jsonl         # 关系图谱
```

### 0.4 把 Obsidian 知识库导入 ARIS

```bash
# 导入整个 llm-wiki（读取 README.md → SCHEMA.md → entities/ → extracted/）
/research-wiki ingest "llm-wiki/"

# 或者只导入特定类型的实体
/research-wiki ingest "llm-wiki/entities/papers/"

# 或者导入特定笔记
/research-wiki ingest "llm-wiki/entities/papers/重要论文.md"
```

**> 重要：llm-wiki 是共享的，不要从 ARIS 侧修改它。只在 Obsidian 中编辑，所有项目自动看到更新。**

### 0.5 同步策略（避免重复）

你的知识库架构是这样的：

```
D:\BaiduSyncdisk\obsidian_projects\llm-wiki/     ← 物理文件（Obsidian 管理）
    ↑
    | 软链接（Junction）
    |
D:\AutoResearch\idea-a\llm-wiki/                  ← 项目 A 看到的内容
D:\AutoResearch\idea-b\llm-wiki/                  ← 项目 B 看到的内容
D:\AutoResearch\idea-c\llm-wiki/                  ← 项目 C 看到的内容
```

**核心原则：**

| 位置 | 用途 | 修改权限 |
|------|------|----------|
| `llm-wiki/` | 共享知识库（Obsidian 管理） | 只在 Obsidian 中编辑 |
| `research-wiki/` | 项目专属知识库（ARIS 管理） | ARIS 自动创建和更新 |

**当 llm-wiki 更新后，如何同步到当前项目：**

```bash
# llm-wiki 有更新时，重新导入到当前项目的 research-wiki
/research-wiki ingest "llm-wiki/"

# 只导入新添加的论文
/research-wiki ingest "llm-wiki/entities/papers/"

# 同步索引
/research-wiki sync
```

**> 注意：`/research-wiki ingest` 是增量导入。已存在的条目不会重复，只会更新。**

---

## Step 1: 文献调研（Obsidian + 多源搜索）

> **什么时候做？**
> 
> 产生了一个新想法，需要了解：
> 1. 你的 Obsidian 知识库里有没有相关积累
> 2. 互联网上最新的相关论文
> 3. 这些论文的核心观点和创新点
> 4. 哪些文献值得深入学习

### 1.1 查询你的知识库 + 互联网

```bash
# 方法 1：先查知识库，再查互联网（推荐）
/research-wiki query "扩散模型采样效率的最新进展"

# 方法 2：直接用 research-lit 同时搜索多个源
/research-lit "扩散模型采样效率" — sources: obsidian, deepxiv, semantic-scholar, web

# 方法 3：下载最相关的 arXiv PDF 到本地
/research-lit "扩散模型采样效率" — sources: obsidian, deepxiv, semantic-scholar, web, arxiv download: true, max download: 10
```

**参数详解：**

| 参数 | 你需要的值 | 说明 |
|------|-----------|------|
| `sources` | `obsidian, deepxiv, semantic-scholar, web` | 搜索你的 Obsidian + DeepXiv + Semantic Scholar + 网页 |
| `arxiv download` | `true` | 自动下载最相关的 arXiv PDF |
| `max download` | `10` | 最多下载 10 篇 |
| `PAPER_LIBRARY` | `papers/, llm-wiki/papers/` | 本地论文目录 |

### 1.2 获取 AlphaXiv 的补充结果

```bash
/alphaxiv "扩散模型采样效率"
```

### 1.3 把搜索结果加入知识库

```bash
# 导入下载的论文
/research-wiki ingest "papers/"

# 同步知识库索引
/research-wiki sync
```

### 1.4 查看知识库的关联图谱

```bash
# 查看某篇论文的关联
/research-wiki query "paper:diffusion-sampling-2024"

# 查看某个 idea 的实验支撑
/research-wiki query "idea:adaptive-step-size"
```

### Step 1 的输出

- `research-wiki/papers/` — 自动创建的论文条目
- `research-wiki/log.md` — 本次文献调研的时间线
- `papers/` — 下载的 PDF 文件
- 一份结构化文献综述报告

---

## Step 2: 研究方案设计（数学理论 + 证明推导）

> **什么时候做？**
> 
003e 文献调研完成后，你对领域有了全景认识。现在需要：
> 1. 形成具体的研究方案
> 2. 设计深度数学理论
> 3. 进行严谨的证明和推导
> 4. 规划验证实验

### 2.1 形成研究方案

```bash
# 基于文献调研结果，精炼研究方案
/research-refine "基于误差预测的自适应步长扩散采样"

# 或者从 idea 开始
/idea-creator "改进扩散模型采样效率的新方向"
```

**Prompt 模板：**

```
我的研究方向是：[填写你的方向]

基于以下文献洞察：
1. [文献1的核心观点]
2. [文献2的核心观点]
3. [文献3的局限性]

我想解决的具体问题是：[具体问题]

请帮我：
1. 提出 3-5 个具体的研究 idea
2. 评估每个 idea 的可行性和创新性
3. 推荐最值得深入的一个
```

### 2.2 数学理论设计

```bash
# 帮我推导核心公式
/formula-derivation "自适应步长的误差上界"

# 帮我写证明
/proof-writer "证明：自适应步长策略保证收敛"

# 验证证明的正确性
/proof-checker "proofs/convergence_proof.tex"
```

**Prompt 模板（公式推导）：**

```
请帮我推导以下公式的完整过程：

目标：证明自适应步长扩散采样满足 |x_{t+1} - x_t| ≤ ε

已知条件：
- 扩散过程：dx = f(x,t)dt + g(t)dw
- 步长策略：h_t = min(h_max, C/||∇log p(x_t)||)
- 误差度量：e_t = ||x_t - x̃_t||

要求：
1. 给出详细的推导步骤
2. 说明每个假设的作用
3. 给出最终的误差上界表达式
4. 讨论收敛条件
```

**Prompt 模板（证明写作）：**

```
请帮我撰写以下定理的完整证明：

定理：[定理陈述]

背景：[研究背景]

要求：
1. 使用标准的数学证明格式
2. 每个步骤都要有充分的理由
3. 引用相关引理和定义
4. 最后给出证明的直观解释
```

### 2.3 方案精炼 + 实验规划

```bash
# 精炼方案
/research-refine-pipeline "自适应步长扩散采样方案"

# 或者分步做
/experiment-plan
```

### Step 2 的输出

- `refine-logs/FINAL_PROPOSAL.md` — 精炼后的研究方案
- `refine-logs/EXPERIMENT_PLAN.md` — 实验路线图
- `proofs/` — 证明文档
- `formulas/` — 推导文档

---

## Step 3: 实验执行（远程服务器）

> **什么时候做？**
> > 研究方案确定后，需要验证。你的实验跑在远程服务器上。

### 3.1 配置远程服务器信息

在 `CLAUDE.md` 中配置（见**附录 A**）：

```markdown
# GPU 服务器配置
remote_host: your-server-ip
remote_user: your-username
remote_workspace: /home/username/experiments
python_env: /home/username/miniconda3/envs/myenv/bin/python
dataset_path: /data/datasets
pretrained_weights: /data/pretrained
```

### 3.2 实现实验代码

```bash
# 自动读取 EXPERIMENT_PLAN.md，实现代码
/experiment-bridge

# 或者手动指定
/experiment-bridge "refine-logs/EXPERIMENT_PLAN.md"
```

**你需要提前告诉 ARIS 的信息：**

```bash
# 在运行 experiment-bridge 之前，确保项目中有以下文件：
# - README.md（描述数据集位置、环境配置）
```

### 3.3 部署到远程服务器

```bash
# experiment-bridge 会自动部署
# 但你需要确保远程服务器已配置好：
# 1. SSH 免密登录
# 2. Python 环境已创建
# 3. 数据集已下载
# 4. 预训练权重已放置

# 手动部署（如果自动失败）
/run-experiment "experiments/adaptive_step_size/"
```

### 3.4 监控实验进度

```bash
# 查看训练曲线和日志
/monitor-experiment
```

### 3.5 实验审计

```bash
# 检查实验是否有问题
/experiment-audit "experiments/adaptive_step_size/results/"
```

### Step 3 的输出

- `experiments/` — 实验代码
- `experiments/results/` — 实验结果
- `refine-logs/EXPERIMENT_TRACKER.md` — 实验跟踪表

---

## Step 4: 迭代改进

> **什么时候做？**
> 
003e 实验结果出来了，但可能不够好。需要：
003e 1. 分析结果
003e 2. 改进研究方案
003e 3. 重新跑实验
003e 4. 直到满意

### 4.1 分析实验结果

```bash
# 分析结果
/analyze-results "experiments/adaptive_step_size/results/"

# 结果转 claim
/result-to-claim "实验结果表明自适应步长将采样步数减少了 40%"
```

### 4.2 自动改进循环

```bash
# 启动自动 review 循环
/auto-review-loop "自适应步长扩散采样" — difficulty: hard

# 或者更严格的
/auto-review-loop "自适应步长扩散采样" — difficulty: nightmare, human checkpoint: true
```

**这个循环会：**

1. GPT-5.4 审阅你的方案和结果
2. 找出弱点
3. 建议改进（可能是新的实验、更好的理论、更清晰的叙事）
4. 自动实现改进
5. 重新部署实验
6. 再 review

**你可以随时停止：** 当分数达到你的目标（比如 6/10）或你觉得够了。

### 4.3 规划消融实验

```bash
# 设计消融实验
/ablation-planner "自适应步长扩散采样方案"
```

### Step 4 的输出

- `review-stage/AUTO_REVIEW.md` — Review 记录
- 改进后的实验代码
- 新的实验结果

---

## Step 5: 论文写作（IEEE Journal）

> **什么时候做？**
> > 实验结果满意了，开始写论文。你的目标期刊是 IEEE Journal。

### 5.1 准备叙事报告

先写或更新 `NARRATIVE_REPORT.md`，描述：

- 研究动机
- 核心贡献
- 数学理论
- 实验设计
- 主要结果
- 图表描述

模板见 `templates/NARRATIVE_REPORT_TEMPLATE.md`。

### 5.2 一键生成论文

```bash
# 全自动生成 IEEE Journal 论文
/paper-writing "NARRATIVE_REPORT.md" — venue: IEEE_JOURNAL, effort: max
```

**关键参数：**

| 参数 | 值 | 说明 |
|------|-----|------|
| `venue` | `IEEE_JOURNAL` | IEEE 期刊格式 |
| `ANONYMOUS` | `false` | IEEE 期刊不匿名 |
| `MAX_PAGES` | `12` | 根据期刊要求调整 |
| `ILLUSTRATION` | `figurespec` | 用确定性图表（推荐） |

### 5.3 数学证明写作

```bash
# 把证明部分写得更严谨
/proof-writer "proofs/convergence_proof.tex" — target: IEEE_JOURNAL

# 验证所有证明
/proof-checker "paper/sections/proofs.tex"
```

### 5.4 编译 PDF

```bash
# 编译论文
/paper-compile
```

### Step 5 的输出

- `paper/` — LaTeX 源码
- `paper/main.pdf` — 编译好的 PDF

---

## Step 6: 审稿与改进

> **什么时候做？**
003e 
003e 论文写完了，投稿前或收到审稿意见后。

### 6.1 投稿前自检

```bash
# 自动改进循环
/auto-paper-improvement-loop "自适应步长扩散采样" — effort: max

# 引用审计
/citation-audit "paper/"

# Claim 审计
/paper-claim-audit "paper/"
```

### 6.2 收到审稿意见后

```bash
# 写 rebuttal
/rebuttal "paper/ + reviews" — venue: IEEE_JOURNAL, character limit: 5000
```

### Step 6 的输出

- 改进后的论文
- Rebuttal 文档（如果需要）

---

## Step 7: 知识库存档与同步

> **什么时候做？**
> 
> **初始化和导入论文的时候做。** 其他时候会根据调用的skill而自动积累入库。

### 7.1 存档项目产出到 research-wiki

初始化和导入论文的时候，把项目专属内容存入 `research-wiki/`：

```bash
# 初始化
/research-wiki init

# 文献调研后
/research-wiki ingest "papers/"
/research-wiki ingest "research-wiki/papers/"

# 同步索引
/research-wiki sync
```

### 7.2 同步共享的 llm-wiki

当你在 Obsidian 中更新了 llm-wiki（比如读了新论文、添加了笔记），需要把更新同步到当前项目的 research-wiki：

```bash
# 重新导入整个 llm-wiki（增量同步，不会重复）
/research-wiki ingest "llm-wiki/"

# 或者只导入新添加的论文实体
/research-wiki ingest "llm-wiki/entities/papers/"

# 同步索引
/research-wiki sync
```

**> 同步时机：**
- Obsidian 中添加了重要笔记后
- 开始新项目时（导入已有积累）
- 产生新 idea 前（确保 ARIS 知道最新的知识库状态）

### 7.3 查询历史积累

当你有新想法时，先查一下知识库：

```bash
# 查看之前有没有类似的想法
/research-wiki query "类似自适应步长的想法"

# 查看某个实验的结果
/research-wiki query "exp:adaptive-step-size-2024"

# 查看知识库统计
/research-wiki stats
```

### 7.4 跨项目借鉴

多个项目的 `research-wiki/` 是独立的，但共享同一个 `llm-wiki/`：

```bash
# 在项目 A 的 research-wiki 中找到有价值的 idea
# 手动复制 research-wiki/ideas/ 中的条目到项目 B

# 在项目 B 中导入
/research-wiki ingest "path/to/project-a/research-wiki/ideas/"
```

---

## Step 8: 使用模板 (Templates)

> **什么时候做？**
>
> Bootstrap 完成后，你开始某个工作流之前。模板不是必须填的，但当你想用"一份详细的文档"代替"一句话 prompt"时，模板给你提供了标准结构，让 ARIS 更准确地理解你的需求。

### 8.1 什么是 Templates？

Templates 是 ARIS 每个工作流的**输入模板**。你可以把它们理解为"填表式的 prompt"。

比如，你想做文献调研寻找 idea，你可以直接说：

```bash
/idea-discovery "扩散模型采样效率"
```

这样也可以，但 ARIS 对你的了解很少。更好的方式是先填写 `RESEARCH_BRIEF_TEMPLATE.md`，把你研究的领域、已读论文、尝试过但失败的方法、计算资源限制、目标期刊等信息都写清楚，然后：

```bash
/idea-discovery "templates/RESEARCH_BRIEF_TEMPLATE.md"
```

这样 ARIS 就能基于**完整的上下文**给你更精准的建议。

### 8.2 Bootstrap 为你准备了哪些模板？

运行 Bootstrap 后，项目根目录会出现 `templates/` 文件夹，里面包含：

| 模板文件 | 对应工作流 | 用途 |
|---------|-----------|------|
| `RESEARCH_BRIEF_TEMPLATE.md` | 工作流 1 (`/idea-discovery`) | 详细研究简报，替代一句话 prompt |
| `RESEARCH_BRIEF_TEMPLATE_CN.md` | 工作流 1 | 同上，中文版 |
| `RESEARCH_CONTRACT_TEMPLATE.md` | 工作流 1 | 定义问题边界、非目标、时间线 |
| `IDEA_CANDIDATES_TEMPLATE.md` | 工作流 1 | Idea 候选池，记录多个备选方向 |
| `IDEA_CANDIDATES_TEMPLATE_CN.md` | 工作流 1 | 同上，中文版 |
| `EXPERIMENT_PLAN_TEMPLATE.md` | 工作流 1.5 (`/experiment-bridge`) | Claim 驱动的实验路线图 |
| `EXPERIMENT_PLAN_TEMPLATE_CN.md` | 工作流 1.5 | 同上，中文版 |
| `NARRATIVE_REPORT_TEMPLATE.md` | 工作流 3 (`/paper-writing`) | 研究叙事报告，包含 Claims、实验、结果 |
| `PAPER_PLAN_TEMPLATE.md` | 工作流 3 | 预制的论文大纲，跳过规划阶段 |
| `CLAUDE_MD_TEMPLATE.md` | 所有工作流 | 项目仪表盘，记录 Pipeline 状态 |
| `MANIFEST_TEMPLATE.md` | 所有工作流 | 输出跟踪清单（skill 自动维护） |
| `INVENTION_BRIEF_TEMPLATE.md` | 专利流程 (`/patent-pipeline`) | 发明披露，技术问题、方案、优点 |
| `PATENT_CLAIMS_TEMPLATE.md` | `/claims-drafting` | 权利要求层次表 |
| `PATENT_SPECIFICATION_TEMPLATE.md` | `/specification-writing` | 说明书骨架 |
| `EXPERIMENT_LOG_TEMPLATE.md` | 紧凑模式 | 结构化实验记录 |
| `FINDINGS_TEMPLATE.md` | 紧凑模式 | 发现日志 |

### 8.3 怎么用模板？（三步走）

**第一步：从 templates/ 复制到工作目录**

不要直接在 `templates/` 里编辑，因为那是"原始模板"，方便你将来新建项目时复用。你应该复制一份到实际工作目录：

```bash
# 示例：准备研究简报
Copy-Item templates/RESEARCH_BRIEF_TEMPLATE.md idea-stage/RESEARCH_BRIEF.md

# 示例：准备实验计划
Copy-Item templates/EXPERIMENT_PLAN_TEMPLATE.md refine-logs/EXPERIMENT_PLAN.md

# 示例：准备论文叙事报告
Copy-Item templates/NARRATIVE_REPORT_TEMPLATE.md paper/NARRATIVE_REPORT.md
```

**第二步：填写内容**

打开复制后的文件，把方括号 `[填写内容]` 里的占位符替换成你自己的实际信息。

以 `RESEARCH_BRIEF_TEMPLATE.md` 为例：

```markdown
## Problem Statement
[2-3 paragraphs: What is broken/missing in current approaches?]
```

改成：

```markdown
## Problem Statement
当前扩散模型采样需要 50-1000 步，速度太慢无法实时应用。
现有加速方法（如 DDIM、DPM-Solver）在步数减少时质量显著下降，
且缺乏对误差的理论分析...
```

**第三步：运行 skill，传入填好的文件路径**

```bash
# 文献调研 + idea 发现
/idea-discovery "idea-stage/RESEARCH_BRIEF.md"

# 实验执行
/experiment-bridge "refine-logs/EXPERIMENT_PLAN.md"

# 论文写作
/paper-writing "paper/NARRATIVE_REPORT.md"
```

### 8.4 什么时候必须用模板，什么时候可以不用？

| 场景 | 建议 | 原因 |
|------|------|------|
| 刚接触这个领域，需要 ARIS 帮你梳理方向 | **用模板** | 模板里的"已读论文""失败尝试"能帮 ARIS 避免重复建议 |
| 已经有清晰 idea，只需要实现 | 可以不用 | 直接 `/experiment-bridge` 即可 |
| 要写论文，有完整实验结果 | **用模板** | `NARRATIVE_REPORT_TEMPLATE.md` 的结构确保论文不缺章节 |
| 快速尝试一个想法 | 可以不用 | 直接一句话 prompt，快速验证 |
| 投稿顶会前 | **用模板** | 完整的 `RESEARCH_CONTRACT` 能防止 scope creep |

> **记忆口诀**：信息越多越用模板，越快越不用。

### 8.5 CLAUDE_MD_TEMPLATE.md — 项目仪表盘

这个模板比较特殊，它不是某个工作流的输入，而是**整个项目的仪表盘**。建议每个项目创建一次：

```bash
Copy-Item templates/CLAUDE_MD_TEMPLATE.md CLAUDE_DASHBOARD.md
```

填写内容：

```yaml
stage: idea-discovery     # 当前阶段
idea: "自适应步长扩散采样"
contract: "idea-stage/research_contract.md"
current_branch: "main"
baseline: "DDIM 50 steps: FID 4.2"
training_status: idle
language: zh
active_tasks: ["实验 1: CIFAR-10", "证明收敛性"]
next: "完成实验 1 的代码实现"
last_updated: "2026-05-14 10:00"
```

ARIS 会自动读取这个文件，了解项目当前状态，不需要你每次重复说明。

---

## Step 9: Meta-Optimize (ARIS 自我优化)

> **什么时候做？**
>
> 这不是研究工作流的一部分，而是**维护工作流**。像 `git gc` 一样定期运行。
> - 累积了 5 次以上 skill 调用后（hooks 自动提醒）
> - 感觉某个 skill 的参数总需要手动调整
> - 某个 skill 反复失败
> - 一个项目快结束时，做一次总结优化

### 9.1 什么是 Meta-Optimize？

Meta-Optimize 是 ARIS 的**自我优化能力**。它分析你的使用模式，然后提出改进 ARIS 自身 skill 的建议。

打个比方：
- **工作流 1-4**（文献调研 → 实验 → 审稿 → 论文）优化的是**你的研究产物**（论文、代码）
- **Meta-Optimize** 优化的是 **ARIS 本身**（skill 的 prompt、默认参数、收敛规则）

举个例子：
- 你发现每次运行 `/auto-review-loop` 都要手动覆盖 `difficulty: hard`
- Meta-Optimize 会记录到这一点，建议把该 skill 的默认 difficulty 改成 hard
- 你批准后，以后运行就不需要手动指定了

### 9.2 Bootstrap 已经帮你部署好了

运行 Bootstrap 时，以下 Meta-Optimize 组件已自动安装：

| 组件 | 位置 | 作用 |
|------|------|------|
| `.claude/settings.json` | 项目根目录 | Claude Code hooks 配置，每次调用 skill 自动记录事件 |
| `tools/meta_opt/log_event.sh` | 项目目录 | 事件记录脚本，把调用信息写入日志 |
| `tools/meta_opt/check_ready.sh` | 项目目录 | 检查是否积累了足够数据，提醒你做优化 |
| `.aris/meta/events.jsonl` | 项目目录 | 项目级事件日志（每次 skill 调用、失败、参数覆盖） |
| `~/.aris/meta/events.jsonl` | 用户主目录 | 全局事件日志（带项目标签，用于跨项目分析） |

**你不需要做任何手动配置。** 只要正常使用 ARIS，hooks 就会静默记录。

### 9.3 怎么用 Meta-Optimize？

**基本用法（项目级分析）：**

```bash
# 分析当前项目的使用模式，提出改进建议
/meta-optimize
```

运行后，ARIS 会：
1. 读取 `.aris/meta/events.jsonl`
2. 分析高频参数覆盖、重复失败、分数停滞
3. 对相关的 SKILL.md 生成最小修改 + 数据支撑的理由
4. GPT-5.4 审核每个 patch 是否安全
5. 列出建议清单，等你批准

**聚焦单个 skill：**

```bash
# 只分析 auto-review-loop 的使用情况
/meta-optimize "auto-review-loop"
```

**跨项目分析：**

```bash
# 分析你所有 ARIS 项目的使用趋势
/meta-optimize --global
```

这会用 `~/.aris/meta/events.jsonl`（全局日志），帮你发现跨项目的共性需求。

**应用建议：**

```bash
# 应用第 1 条建议
/meta-optimize apply 1
```

> **注意**：Meta-Optimize **永远不会自动应用修改**，必须经过你的批准。这是安全设计。

### 9.4 什么时候 hooks 会提醒你？

每次 Claude Code 会话结束时，`check_ready.sh` 会自动检查：

- 如果自上次运行 `/meta-optimize` 以来，skill 调用了 **5 次以上**
- 它会在你的终端输出提醒：

```
📊 ARIS has logged 8 skill runs since last optimization. Run /meta-optimize to check for improvement opportunities.
```

看到这个提醒，就说明数据够了，可以运行 `/meta-optimize` 了。

### 9.5 Meta-Optimize 能优化什么？

| 可以优化 | 示例 |
|---------|------|
| Skill prompt | 发现你总是需要补充某个上下文，建议把它加入默认 prompt |
| 默认参数 | 你总是覆盖 `difficulty: hard`，建议改默认值为 hard |
| 收敛规则 | `auto-review-loop` 跑了 8 轮还没收敛，建议调整停止条件 |
| 错误处理 | 某个 skill 在特定场景下反复失败，建议添加错误处理 |

| **不会优化** | 说明 |
|-------------|------|
| 研究产物 | 论文内容、实验代码、公式推导 —— 那是 W1-W4 的工作 |
| 自动执行 | 所有修改都要你批准，不会偷偷改你的配置 |

### 9.6 工作原理（简单版）

```
正常使用 ARIS (W1-W4)
        |
        |  (hooks 被动记录每次调用)
        v
.aris/meta/events.jsonl  ← 记录 skill 调用、失败、参数覆盖
        |
        |  (运行 /meta-optimize)
        v
   分析模式 → 生成 Patch → GPT-5.4 审核
        |
        v
   用户批准？ → 是：应用修改
              → 否：跳过
```

### 9.7 常见问题

**Q：我不想用 Meta-Optimize，怎么关闭？**

删除或重命名 `.claude/settings.json` 即可。hooks 停止记录，不影响其他功能。

**Q：日志文件会很大吗？**

每次 skill 调用只记录几十字节的 JSON，1000 次调用约几百 KB，不必担心。

**Q：日志里记录了什么？会泄露隐私吗？**

只记录：**skill 名称、调用时间、参数覆盖、成功/失败**。不记录论文内容、代码、对话内容。

**Q：可以手动删除日志吗？**

可以，直接删除 `.aris/meta/events.jsonl` 即可。下次使用会自动重建。

---

## 附录 A: CLAUDE.md 配置模板

在你的项目根目录创建 `CLAUDE.md`，内容如下：

```markdown
# 项目配置

## 研究方向
field: 扩散模型采样效率优化

## 目标期刊
venue: IEEE_JOURNAL

## 匿名模式
anonymous: false

## 页数限制
max_pages: 12

## 知识库
obsidian_vault: llm-wiki/                      # 共享 Obsidian 知识库（软链接）
paper_library: papers/, llm-wiki/entities/papers/  # 本地论文 + Obsidian 中的论文实体

## GPU 服务器配置
remote_host: your-server-ip
remote_user: your-username
remote_workspace: /home/username/experiments
python_env: /home/username/miniconda3/envs/myenv/bin/python
dataset_path: /data/datasets
pretrained_weights: /data/pretrained

## 实验配置
wandb: false
wandb_project: ""
code_review: true
auto_deploy: true
sanity_first: true
max_parallel_runs: 4

## Review 配置
reviewer_model: gpt-5.4
difficulty: hard
max_rounds: 4
positive_threshold: 6/10

## 文献搜索配置
sources: obsidian, deepxiv, semantic-scholar, web
arxiv_download: true
arxiv_max_download: 10

## 外部服务 API KEY（在 .env 文件中配置）
# Semantic Scholar API KEY — 到 https://www.semanticscholar.org/product/api#api-key-form 免费申请
# 填写到项目根目录的 .env 文件中：SEMANTIC_SCHOLAR_API_KEY=your-api-key-here

## 数学证明
proof_style: rigorous
theorem_environment: IEEE

## 插图
illustration: figurespec
```

---

## 附录 B: 项目目录结构模板

### 推荐布局：AutoResearch/{idea}/

把所有研究项目放在一个根目录下，每个 idea 一个独立项目：

```
D:\AutoResearch/
├── idea-diffusion-sampling/          # 项目 A
│   ├── CLAUDE.md
│   ├── .env                          # 项目专属配置
│   ├── llm-wiki/ → %LLM_WIKI_PATH%   (软链接，从 .env 读取)
│   ├── research-wiki/                # ARIS 知识库（项目专属）
│   ├── papers/
│   ├── experiments/
│   └── ...
│
├── idea-llm-reasoning/               # 项目 B
│   ├── CLAUDE.md
│   ├── .env
│   ├── llm-wiki/ → %LLM_WIKI_PATH%   (软链接)
│   ├── research-wiki/
│   ├── papers/
│   ├── experiments/
│   └── ...
│
└── idea-multimodal-fusion/           # 项目 C
    ├── CLAUDE.md
    ├── .env
    ├── llm-wiki/ → %LLM_WIKI_PATH%   (软链接)
    ├── research-wiki/
    ├── papers/
    ├── experiments/
    └── ...
```

**> 关键点：所有项目共享同一个 llm-wiki（通过软链接），但每个项目有自己的 research-wiki。**

### 单个项目的完整目录

```
my-research/
├── CLAUDE.md                    # 项目配置
├── README.md                    # 项目说明（数据集、环境等）
│
├── llm-wiki/                    # 共享 Obsidian 知识库（软链接）
│   ├── README.md                # 知识库总览
│   ├── SCHEMA.md                # 实体类型定义
│   ├── entities/                # 实体记录
│   │   ├── papers/
│   │   ├── authors/
│   │   └── concepts/
│   └── extracted/               # PDF 提取内容
│
├── research-wiki/               # ARIS 知识库（自动创建，项目专属）
│   ├── index.md
│   ├── log.md
│   ├── gap_map.md
│   ├── papers/
│   ├── ideas/
│   ├── experiments/
│   └── claims/
│
├── my_tools/                    # ARIS 使用手册（Bootstrap 复制）
│   ├── COMMON_SKILL_GUIDE.md
│   ├── README.md
│   └── SKILL_GUIDE.md
│
├── papers/                      # 下载的 PDF
│   └── downloaded/
│
├── idea-stage/                  # Idea 相关（自动创建）
│   ├── IDEA_REPORT.md
│   └── IDEA_CANDIDATES.md
│
├── refine-logs/                 # 方案精炼（自动创建）
│   ├── FINAL_PROPOSAL.md
│   ├── EXPERIMENT_PLAN.md
│   └── EXPERIMENT_TRACKER.md
│
├── proofs/                      # 数学证明
│   ├── convergence_proof.tex
│   └── error_bound_derivation.tex
│
├── formulas/                    # 公式推导
│   └── derivations.md
│
├── experiments/                 # 实验代码和结果（自动创建）
│   ├── adaptive_step_size/
│   │   ├── train.py
│   │   ├── config.yaml
│   │   └── results/
│   └── baseline/
│
├── figures/                     # 论文图表
│   ├── training_curves.pdf
│   └── comparison_table.tex
│
├── paper/                       # 论文 LaTeX（自动创建）
│   ├── main.tex
│   ├── sections/
│   ├── figures/
│   └── main.pdf
│
├── review-stage/                # Review 记录（自动创建）
│   └── AUTO_REVIEW.md
│
├── templates/                   # 模板文件（Bootstrap 复制，见 Step 8）
│   ├── RESEARCH_BRIEF_TEMPLATE.md
│   ├── RESEARCH_BRIEF_TEMPLATE_CN.md
│   ├── EXPERIMENT_PLAN_TEMPLATE.md
│   ├── EXPERIMENT_PLAN_TEMPLATE_CN.md
│   ├── NARRATIVE_REPORT_TEMPLATE.md
│   ├── PAPER_PLAN_TEMPLATE.md
│   ├── CLAUDE_MD_TEMPLATE.md
│   └── claude-hooks/
│       └── meta_logging.json    # Meta-Optimize hooks 配置源文件
│
├── .claude/                     # Claude Code 配置（Bootstrap 创建）
│   ├── settings.json            # Meta-Optimize hooks 已启用
│   └── skills/                  # ARIS skills（junction 链接）
│
├── .aris/                       # ARIS 管理目录
│   ├── installed-skills.txt     # 已安装 skill 清单
│   └── meta/                    # Meta-Optimize 事件日志
│       └── events.jsonl         # 自动记录，见 Step 9
│
└── tools/                       # 工具脚本
    └── meta_opt/                # Meta-Optimize 脚本（Bootstrap 复制）
        ├── log_event.sh         # 事件记录脚本
        └── check_ready.sh       # 就绪检查脚本
```

---

## 附录 C: 远程服务器配置

### C.1 SSH 免密登录

```bash
# 本地生成密钥（如果没有）
ssh-keygen -t rsa -b 4096

# 复制公钥到远程服务器
ssh-copy-id username@your-server-ip

# 测试
ssh username@your-server-ip
```

### C.2 远程服务器环境准备

```bash
# 登录远程服务器
ssh username@your-server-ip

# 创建 Python 环境
conda create -n myenv python=3.10
conda activate myenv

# 安装依赖
pip install torch torchvision torchaudio
pip install diffusers transformers
pip install wandb

# 创建数据集目录
mkdir -p /data/datasets
mkdir -p /data/pretrained

# 上传数据集和预训练权重
# 使用 scp 或 rsync
```

### C.3 本地配置 SSH config

在本地 `~/.ssh/config` 添加：

```
Host research-gpu
    HostName your-server-ip
    User your-username
    IdentityFile ~/.ssh/id_rsa
```

这样你就可以用 `ssh research-gpu` 登录。

---

## 附录 D: 常用 Prompt 速查表

### D.1 文献调研 Prompt

```
请帮我调研"[主题]"的最新进展。

要求：
1. 搜索我的 Obsidian 知识库（llm-wiki）中的相关笔记
2. 搜索 DeepXiv、Semantic Scholar 和互联网
3. 输出完整的文献列表，按相关程度排序
4. 每篇文献标注：核心观点、创新点、与我的研究的相关性
5. 最后告诉我：哪些文献值得深入学习
```

### D.2 研究方案 Prompt

```
基于以下文献洞察，请帮我设计一个具体的研究方案：

文献洞察：
1. [文献1] 提出了 X，但没有解决 Y
2. [文献2] 解决了 Y，但方法复杂度高
3. [文献3] 在 Z 上取得了好结果

我想解决的问题：[具体问题]

要求：
1. 提出 3-5 个具体的研究 idea
2. 评估可行性和创新性
3. 推荐最值得深入的一个
4. 给出初步的数学框架
```

### D.3 数学推导 Prompt

```
请帮我推导以下公式的完整过程：

目标：[目标公式]
已知：[已知条件]

要求：
1. 详细的推导步骤
2. 每个假设的作用
3. 最终表达式
4. 收敛条件讨论
```

### D.4 证明写作 Prompt

```
请帮我撰写定理 [定理名] 的完整证明。

定理陈述：[定理内容]
背景：[研究背景]

要求：
1. 标准数学证明格式
2. 每个步骤都有充分理由
3. 引用相关引理
4. 直观解释
```

### D.5 实验设计 Prompt

```
请帮我设计验证以下研究方案的实验：

研究方案：[方案描述]

要求：
1. 实验列表（baseline、ablation、main）
2. 数据集和评估指标
3. 预期结果
4. 消融实验设计
```

### D.6 论文写作 Prompt

```
请根据以下叙事报告撰写 IEEE Journal 格式的论文。

叙事报告：[NARRATIVE_REPORT.md 路径]

要求：
1. 严格遵循 IEEE 期刊格式
2. 数学证明放在附录
3. 图表清晰
4. 语言严谨
```

---

> 以上就是你专属的科研工作流手册。每一步都对应具体的 ARIS skill，每个 skill 都有详细的用法和 Prompt 模板。根据你的需要灵活组合即可。
