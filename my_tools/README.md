# install_aris_flat.ps1 - Windows 项目级 ARIS 技能安装器

## 这个脚本是干什么的？

这个脚本把 ARIS 的技能（skills）安装到你的项目里，让你可以在项目中使用 ARIS 的 slash command（比如 `/paper-write`、`/research-lit` 等）。

### 为什么要用这个脚本？

ARIS 仓库自带了一个 `tools/install_aris.ps1`，但它有**已知 bug**：它创建一个**嵌套文件夹** `.claude/skills/aris/`，而 Claude Code 只扫描一级目录，所以根本找不到你的技能，slash command 不会自动补全。

这个 `install_aris_flat.ps1` 修复了这个问题：它为**每个 skill 单独创建一个 junction**（Windows 的链接），直接放在 `.claude/skills/` 下，Claude Code 能正常发现。

---

## 前置条件

### 1. 开启 Windows 开发者模式

创建 junction 需要开发者模式或管理员权限。**推荐开开发者模式**，这样以后不用每次都右键"以管理员身份运行"。

**检查是否已开启：**

1. 按 `Win + R`，输入 `regedit`，回车
2. 地址栏粘贴：`计算机\HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock`
3. 看右边有没有 `AllowDevelopmentWithoutDevLicense`，值为 `1`
4. 如果有且为 `1`，说明已开启，**跳过下面的步骤**

**如果没开启，按下面步骤开启：**

**方法一（推荐）：设置里开**

1. 按 `Win + I` 打开设置
2. 左侧选"隐私和安全性"
3. 右侧找到"开发者模式"（Developer mode）
4. 开关打开
5. 弹窗问"是否打开？"，点"是"

**方法二：命令行开（需要管理员权限 PowerShell）**

1. 右键开始菜单 → "终端(管理员)" 或 "Windows PowerShell (管理员)"
2. 粘贴下面命令，回车：

```powershell
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock" /v AllowDevelopmentWithoutDevLicense /t REG_DWORD /d 1 /f
```

3. 显示"操作成功完成"即可

### 2. 确认 ARIS 仓库位置

这个脚本需要知道你的 ARIS 仓库在哪。它会在以下位置自动找：

1. 你手动指定的路径（`-ArisRepo` 参数）
2. 环境变量 `$env:ARIS_REPO`
3. 脚本所在目录的父目录（也就是这个脚本在 `aris_repo/my_tools/` 里，它就自动找到 `aris_repo`）
4. 以下常见位置：
   - `C:\Users\你的用户名\aris_repo`
   - `C:\Users\你的用户名\Desktop\aris_repo`
   - `C:\Users\你的用户名\.aris`
   - `C:\Users\你的用户名\Desktop\Auto-claude-code-research-in-sleep`
   - `C:\Users\你的用户名\.codex\Auto-claude-code-research-in-sleep`
   - `C:\Users\你的用户名\.claude\Auto-claude-code-research-in-sleep`

**如果你把 ARIS 仓库下到了 `D:\BaiduSyncdisk\code\MyDemo\Auto-claude-code-research-in-sleep`，建议这样做：**

把这个仓库目录记录到环境变量里，以后不用每次都写路径：

```powershell
[Environment]::SetEnvironmentVariable("ARIS_REPO", "D:\BaiduSyncdisk\code\MyDemo\Auto-claude-code-research-in-sleep", "User")
```

**注意：** 设置完环境变量后，**重启你的终端**才能生效。

---

## 使用方式

### 场景一：在新项目里安装 ARIS（最常用）

假设你的新项目在 `D:\projects\my-paper`，ARIS 仓库在 `D:\BaiduSyncdisk\code\MyDemo\Auto-claude-code-research-in-sleep`。

**步骤：**

1. 打开 PowerShell（普通权限即可，因为开了开发者模式）

2. 进入你的新项目目录：

```powershell
cd D:\projects\my-paper
```

3. 运行安装脚本：

```powershell
# 如果 ARIS 仓库在环境变量里，直接运行：
D:\BaiduSyncdisk\code\MyDemo\Auto-claude-code-research-in-sleep\my_tools\install_aris_flat.ps1

# 如果不在环境变量里，手动指定：
D:\BaiduSyncdisk\code\MyDemo\Auto-claude-code-research-in-sleep\my_tools\install_aris_flat.ps1 -ArisRepo "D:\BaiduSyncdisk\code\MyDemo\Auto-claude-code-research-in-sleep"
```

4. 看到类似下面的输出就是成功了：

```
ARIS Flat Junction Install
  Project:    D:\projects\my-paper
  ARIS repo:  D:\BaiduSyncdisk\code\MyDemo\Auto-claude-code-research-in-sleep
  Skills dir: D:\projects\my-paper\.claude\skills
  Mode:       APPLY

Plan:
  CREATE:        75  (new junctions)
  ...

Install complete. 75 changes applied.
```

5. 验证安装成功：

```powershell
# 看看 .claude/skills 下面是不是有很多独立文件夹
Get-ChildItem .claude\skills

# 应该看到类似：
# ablation-planner
# arxiv
# paper-write
# research-lit
# ...
# 而不是一个名叫 "aris" 的文件夹
```

6. 进入项目，启动 Claude Code，按 `/` 应该能看到 ARIS 的 slash command：

```bash
claude
```

---

### 场景二：只想看看会做什么，不真的安装（试跑）

```powershell
D:\BaiduSyncdisk\code\MyDemo\Auto-claude-code-research-in-sleep\my_tools\install_aris_flat.ps1 -DryRun
```

加 `-DryRun` 后脚本不会创建任何文件，只会显示计划。适合第一次用的时候先看看效果。

---

### 场景三：从旧版安装迁移到新版

如果你之前运行过旧的 `install_aris.ps1`，会有一个嵌套的 `.claude/skills/aris` 文件夹：

```powershell
# 先清理旧版，再安装新版
D:\BaiduSyncdisk\code\MyDemo\Auto-claude-code-research-in-sleep\my_tools\install_aris_flat.ps1 -FromOld
```

`-FromOld` 会自动：
1. 删除旧的嵌套 junction `.claude/skills/aris`
2. 重新安装为扁平布局

---

### 场景四：卸载 ARIS

如果你不想在这个项目里用 ARIS 了：

```powershell
D:\BaiduSyncdisk\code\MyDemo\Auto-claude-code-research-in-sleep\my_tools\install_aris_flat.ps1 -Uninstall
```

这会：
1. 删除所有 ARIS 创建的 junction（只删 junction，不删你其他文件）
2. 删除 manifest 文件
3. 把 manifest 备份为 `.aris/installed-skills.txt.prev`

**注意：** 卸载不会删除你的 CLAUDE.md 文件，只是里面的 ARIS 管理块会留在那里，你可以手动删除。

---

### 场景五：更新技能

因为安装的是 junction（链接），不是复制：

```powershell
# 只需要 pull 上游更新
cd D:\BaiduSyncdisk\code\MyDemo\Auto-claude-code-research-in-sleep
git pull
```

已经安装的 skill 会自动指向最新内容。

**但如果上游新增或删除了 skill**，你需要重跑安装器来同步：

```powershell
cd D:\projects\my-paper
D:\BaiduSyncdisk\code\MyDemo\Auto-claude-code-research-in-sleep\my_tools\install_aris_flat.ps1
```

脚本会自动 reconcile：新增的建立 junction，删除的清理掉。

---

## 完整参数列表

| 参数 | 写法示例 | 说明 |
|------|----------|------|
| `ProjectPath` | `脚本.ps1 D:\projects\my-paper` | 项目路径，不写就默认当前目录 |
| `-ArisRepo` | `-ArisRepo "D:\...\Auto-claude-code-research-in-sleep"` | 手动指定 ARIS 仓库位置 |
| `-DryRun` | `-DryRun` | 只显示计划，不真的创建文件 |
| `-Uninstall` | `-Uninstall` | 卸载这个项目里的 ARIS |
| `-FromOld` | `-FromOld` | 先清理旧版嵌套安装再安装 |
| `-NoDoc` | `-NoDoc` | 不更新 CLAUDE.md |

---

## 常见问题

### Q1: 报错 "project path does not exist"

你写的项目路径不对。检查路径是否存在：

```powershell
Test-Path "你写的路径"
```

返回 `False` 说明路径错了，检查拼写。

### Q2: 报错 "Cannot find ARIS repo"

脚本找不到 ARIS 仓库。解决方法：

```powershell
# 方法1：每次手动指定
脚本.ps1 -ArisRepo "D:\BaiduSyncdisk\code\MyDemo\Auto-claude-code-research-in-sleep"

# 方法2：设置环境变量（一劳永逸）
[Environment]::SetEnvironmentVariable("ARIS_REPO", "D:\BaiduSyncdisk\code\MyDemo\Auto-claude-code-research-in-sleep", "User")
# 设置完后重启终端
```

### Q3: 报错关于 junction 创建失败

**原因：** 没开开发者模式，且当前 PowerShell 不是管理员。

**解决：**

- 推荐：开启开发者模式（见上面的"前置条件"）
- 或者：右键 PowerShell → "以管理员身份运行"，再执行脚本

### Q4: Claude Code 里还是看不到 slash command

1. 先确认安装成功：

```powershell
Get-ChildItem .claude\skills
```

应该看到很多独立文件夹，**不是一个叫 `aris` 的文件夹**。

2. 如果看到 `aris` 文件夹，说明旧版安装还在，运行：

```powershell
脚本.ps1 -FromOld
```

3. 重启 Claude Code：

```bash
# 在 Claude Code 里按 Ctrl+C 退出，再重新进入
claude
```

### Q5: 安装后项目的 `.claude/skills` 里还有其他我自己的 skill，会被影响吗？

**不会。** 这个脚本只动 manifest 里记录的 ARIS skill。你自己的 skill 完全不受影响。

manifest 文件在 `.aris/installed-skills.txt` 里，你可以打开看看它记录了哪些 skill。

### Q6: 我想临时禁用 ARIS，不想卸载

直接重命名 `.claude` 文件夹：

```powershell
Rename-Item .claude .claude.bak
```

想恢复时改回来就行。

---

## 文件说明

安装后你的项目里会多出这些：

```
your-project/
├── .claude/
│   └── skills/
│       ├── ablation-planner      ← junction（链接）到 ARIS 仓库
│       ├── arxiv                 ← junction
│       ├── paper-write           ← junction
│       └── ...                   ← 其他 skill
├── .aris/
│   ├── installed-skills.txt      ← 记录安装了哪些 skill
│   └── installed-skills.txt.prev ← 上一次的 manifest（卸载时备份）
└── CLAUDE.md                      ← 多了 ARIS 管理块（可选）
```

**注意：** `.claude/skills/` 里的每个 skill 都是一个 **junction**（类似快捷方式），不是真的复制了文件。所以：
- 不占额外空间
- 随上游 `git pull` 自动更新
- 不要在里面修改文件（修改会改到 ARIS 仓库里）

---

## 如果还有问题

1. 先加 `-DryRun` 跑一遍，看看计划是否符合预期
2. 检查开发者模式是否开启
3. 检查 ARIS 仓库路径是否正确
4. 看看报错信息，对照上面的"常见问题"
