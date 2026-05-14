#Requires -Version 5.1
<#
.SYNOPSIS
    Project-local ARIS skill installation via flat junctions (Windows).

.DESCRIPTION
    Each ARIS skill is junctioned into <project>/.claude/skills/<skill-name> so
    Claude Code's slash-command discovery (one-level scan) finds it.
    A manifest at <project>/.aris/installed-skills.txt tracks every entry this
    installer created — uninstall and reconcile read from the manifest and never
    touch user-owned skills with the same name.

    Actions (mutually exclusive, default: auto):
        default      install if no manifest, else reconcile
        -Uninstall    remove only entries in manifest; delete manifest

    Options:
        -ArisRepo PATH    override aris-repo discovery
        -DryRun           show plan, no writes
        -NoDoc            skip CLAUDE.md update
        -FromOld          migrate from legacy nested install (.claude/skills/aris/)

.PARAMETER ProjectPath
    Path to project root. Defaults to current directory.

.PARAMETER ArisRepo
    Override path to ARIS repo.

.PARAMETER DryRun
    Print plan without making changes.

.PARAMETER Uninstall
    Remove managed entries and manifest.

.PARAMETER FromOld
    Migrate from legacy nested .claude/skills/aris/ layout.

.PARAMETER NoDoc
    Skip CLAUDE.md / AGENTS.md update.

.EXAMPLE
    .\my_tools\install_aris_flat.ps1
    .\my_tools\install_aris_flat.ps1 C:\projects\my-paper
    .\my_tools\install_aris_flat.ps1 -DryRun
    .\my_tools\install_aris_flat.ps1 -Uninstall
    .\my_tools\install_aris_flat.ps1 -FromOld
#>

[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [string]$ProjectPath = (Get-Location).Path,

    [string]$ArisRepo = '',

    [switch]$DryRun,
    [switch]$Uninstall,
    [switch]$FromOld,
    [switch]$NoDoc,
    [switch]$Bootstrap
)

$ErrorActionPreference = 'Stop'

# ─── .env loader ──────────────────────────────────────────────────────────────
function Read-DotEnv {
    param([string]$Path)
    if (-not (Test-Path $Path)) { return }
    foreach ($line in Get-Content $Path -Encoding UTF8) {
        $line = $line.Trim()
        if ($line -eq '' -or $line.StartsWith('#')) { continue }
        if ($line -match '^([A-Za-z_][A-Za-z0-9_]*)\s*=\s*(.*)$') {
            $name = $matches[1]
            $value = $matches[2].Trim()
            # Remove surrounding quotes if present
            if (($value.StartsWith('"') -and $value.EndsWith('"')) -or
                ($value.StartsWith("'") -and $value.EndsWith("'"))) {
                $value = $value.Substring(1, $value.Length - 2)
            }
            [Environment]::SetEnvironmentVariable($name, $value, 'Process')
        }
    }
}

# Load .env from script directory first, then cwd
$scriptDotEnv = Join-Path $PSScriptRoot '.env'
$cwdDotEnv = Join-Path (Get-Location).Path '.env'
if (Test-Path $scriptDotEnv) {
    Read-DotEnv $scriptDotEnv
    Write-Host "Loaded config: $scriptDotEnv" -ForegroundColor Cyan
} elseif (Test-Path $cwdDotEnv) {
    Read-DotEnv $cwdDotEnv
    Write-Host "Loaded config: $cwdDotEnv" -ForegroundColor Cyan
}

# ─── Bootstrap ────────────────────────────────────────────────────────────────
function Bootstrap-Project {
    param([string]$ProjPath, [string]$RepoPath)

    $llmWikiSource = $env:LLM_WIKI_PATH
    if (-not $llmWikiSource) {
        Write-ErrorExit "LLM_WIKI_PATH not set. Create a .env file with LLM_WIKI_PATH=D:\\path\\to\\llm-wiki"
    }

    Write-Log ''
    Write-Log 'ARIS Project Bootstrap' -ForegroundColor Cyan
    Write-Log "  Project:  $ProjPath"
    Write-Log "  ARIS:     $RepoPath"
    Write-Log "  llm-wiki: $llmWikiSource"
    Write-Log ''

    if ($DryRun) {
        Write-Log '(dry-run) would create directory structure and config files' -ForegroundColor Yellow
        return
    }

    # Create directories
    $dirs = @(
        '.claude/skills',
        'research-wiki',
        'papers',
        'papers/downloaded',
        'idea-stage',
        'refine-logs',
        'experiments',
        'proofs',
        'formulas',
        'figures',
        'paper',
        'review-stage',
        'templates',
        'my_tools'
    )
    foreach ($d in $dirs) {
        $full = Join-Path $ProjPath $d
        if (-not (Test-Path $full)) {
            New-Item -ItemType Directory -Path $full -Force | Out-Null
            Write-Log "Created: $d" -ForegroundColor Green
        }
    }

    # Junction to shared llm-wiki
    $llmWikiLink = Join-Path $ProjPath 'llm-wiki'
    if (-not (Test-Path $llmWikiLink)) {
        if (Test-Path $llmWikiSource) {
            New-Item -ItemType Junction -Path $llmWikiLink -Target $llmWikiSource | Out-Null
            Write-Log "Created junction: llm-wiki -> $llmWikiSource" -ForegroundColor Green
        } else {
            Write-Warn "llm-wiki source not found at $llmWikiSource"
            Write-Warn "Please create it manually or update the path in the script"
        }
    }

    # Copy guide files
    $guideFiles = @('COMMON_SKILL_GUIDE.md', 'README.md', 'SKILL_GUIDE.md')
    foreach ($f in $guideFiles) {
        $src = Join-Path (Join-Path $RepoPath 'my_tools') $f
        $dst = Join-Path (Join-Path $ProjPath 'my_tools') $f
        if (Test-Path $src) {
            Copy-Item $src $dst -Force
            Write-Log "Copied: my_tools/$f" -ForegroundColor Green
        } else {
            Write-Warn "Source not found: $src"
        }
    }

    # Copy templates
    $templatesSource = Join-Path $RepoPath 'templates'
    $templatesDest = Join-Path $ProjPath 'templates'
    if (Test-Path $templatesSource) {
        # Copy .md templates
        foreach ($f in Get-ChildItem $templatesSource -Filter '*.md') {
            $dst = Join-Path $templatesDest $f.Name
            if (Test-Path $dst) {
                Write-Log "Skipped (exists): templates/$($f.Name)" -ForegroundColor DarkGray
            } else {
                Copy-Item $f.FullName $dst -Force
                Write-Log "Copied: templates/$($f.Name)" -ForegroundColor Green
            }
        }
        # Copy claude-hooks subdirectory
        $hooksSource = Join-Path $templatesSource 'claude-hooks'
        $hooksDest = Join-Path $templatesDest 'claude-hooks'
        if (Test-Path $hooksSource) {
            if (-not (Test-Path $hooksDest)) {
                New-Item -ItemType Directory -Path $hooksDest -Force | Out-Null
            }
            foreach ($f in Get-ChildItem $hooksSource -File) {
                $dst = Join-Path $hooksDest $f.Name
                if (Test-Path $dst) {
                    Write-Log "Skipped (exists): templates/claude-hooks/$($f.Name)" -ForegroundColor DarkGray
                } else {
                    Copy-Item $f.FullName $dst -Force
                    Write-Log "Copied: templates/claude-hooks/$($f.Name)" -ForegroundColor Green
                }
            }
        }
    } else {
        Write-Warn "Templates source not found: $templatesSource"
    }

    # Deploy Meta-Optimize hooks
    $metaOptSource = Join-Path $RepoPath 'tools/meta_opt'
    $metaOptDest = Join-Path $ProjPath 'tools/meta_opt'
    $claudeDir = Join-Path $ProjPath '.claude'
    $arisMetaDir = Join-Path $ProjPath '.aris/meta'

    if (-not (Test-Path $arisMetaDir)) {
        New-Item -ItemType Directory -Path $arisMetaDir -Force | Out-Null
        Write-Log "Created: .aris/meta/" -ForegroundColor Green
    }

    if (Test-Path $metaOptSource) {
        if (-not (Test-Path $metaOptDest)) {
            New-Item -ItemType Directory -Path $metaOptDest -Force | Out-Null
        }
        foreach ($f in Get-ChildItem $metaOptSource -File) {
            $dst = Join-Path $metaOptDest $f.Name
            if (Test-Path $dst) {
                Write-Log "Skipped (exists): tools/meta_opt/$($f.Name)" -ForegroundColor DarkGray
            } else {
                Copy-Item $f.FullName $dst -Force
                Write-Log "Copied: tools/meta_opt/$($f.Name)" -ForegroundColor Green
            }
        }
    } else {
        Write-Warn "Meta-Optimize source not found: $metaOptSource"
    }

    $hooksJsonSource = Join-Path $templatesSource 'claude-hooks/meta_logging.json'
    $hooksJsonDest = Join-Path $claudeDir 'settings.json'
    if (Test-Path $hooksJsonSource) {
        if (Test-Path $hooksJsonDest) {
            Write-Log "Skipped (exists): .claude/settings.json" -ForegroundColor DarkGray
        } else {
            if (-not (Test-Path $claudeDir)) {
                New-Item -ItemType Directory -Path $claudeDir -Force | Out-Null
            }
            Copy-Item $hooksJsonSource $hooksJsonDest -Force
            Write-Log "Created: .claude/settings.json (Meta-Optimize hooks enabled)" -ForegroundColor Green
        }
    } else {
        Write-Warn "Meta-Optimize hooks JSON not found: $hooksJsonSource"
    }

    # Generate CLAUDE.md
    $claudeMd = Join-Path $ProjPath 'CLAUDE.md'
    $claudeContent = @"
# 项目配置

## 研究方向
field: [填写你的研究方向，例如：扩散模型采样效率优化]

## 目标期刊
venue: IEEE_JOURNAL

## 匿名模式
anonymous: false

## 页数限制
max_pages: 12

## 知识库
obsidian_vault: llm-wiki/
paper_library: papers/, llm-wiki/entities/

## GPU 服务器配置（请填写你的远程服务器信息）
remote_host: [服务器IP]
remote_user: [用户名]
remote_workspace: /home/[用户名]/experiments
python_env: /home/[用户名]/miniconda3/envs/myenv/bin/python
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

## 数学证明
proof_style: rigorous
theorem_environment: IEEE

## 插图
illustration: figurespec

<!-- ARIS:BEGIN -->
## ARIS Skill Scope
ARIS skills installed in this project. Manifest: `.aris/installed-skills.txt`.
For ARIS workflows, prefer the project-local skills under `.claude/skills/` over global skills.
Do not modify or delete files inside any skill that is a junction.

Update skills: <code>cd $RepoPath; git pull</code>
Re-run installer after upstream adds/removes skills.
<!-- ARIS:END -->
"@
    Set-Content -Path $claudeMd -Value $claudeContent -Encoding UTF8
    Write-Log "Created: CLAUDE.md" -ForegroundColor Green

    # Generate project README.md
    $readmeMd = Join-Path $ProjPath 'README.md'
    $readmeContent = @"
# [项目名称]

## 研究方向
[简要描述]

## 目录结构

- ``llm-wiki/``      — Obsidian 知识库（软链接，共享）
- ``research-wiki/`` — ARIS 知识库（项目专属）
- ``papers/``       — 下载的 PDF
- ``idea-stage/``   — Idea 相关输出
- ``refine-logs/``  — 方案精炼和实验计划
- ``experiments/``  — 实验代码和结果
- ``proofs/``      — 数学证明
- ``formulas/``    — 公式推导
- ``figures/``     — 论文图表
- ``paper/``       — LaTeX 论文源码
- ``review-stage/`` — Review 记录

## 快速开始

1. 编辑 ``CLAUDE.md`` 填写你的配置
2. 运行 ``/research-wiki init`` 初始化知识库
3. 运行 ``/research-wiki ingest llm-wiki/`` 导入 Obsidian 笔记
4. 开始你的研究：
   - Step 1: ``/research-lit`` 文献调研
   - Step 2: ``/research-refine`` 方案设计
   - Step 3: ``/experiment-bridge`` 实验执行
   - Step 4: ``/auto-review-loop`` 迭代改进
   - Step 5: ``/paper-writing`` 论文写作

## 使用手册

见 <code>my_tools/COMMON_SKILL_GUIDE.md</code>
"@
    Set-Content -Path $readmeMd -Value $readmeContent -Encoding UTF8
    Write-Log "Created: README.md" -ForegroundColor Green

    Write-Log ''
    Write-Log 'Bootstrap complete!' -ForegroundColor Green
    Write-Log 'Next steps:' -ForegroundColor Cyan
    Write-Log '  1. Edit CLAUDE.md and fill in your configuration'
    Write-Log '  2. Run: claude'
    Write-Log '  3. Inside Claude Code: /research-wiki init'
    Write-Log '  4. Then: /research-wiki ingest llm-wiki/'
    Write-Log ''
}


# ─── Constants ────────────────────────────────────────────────────────────────
$MANIFEST_VERSION = '1'
$MANIFEST_NAME = 'installed-skills.txt'
$MANIFEST_PREV_NAME = 'installed-skills.txt.prev'
$ARIS_DIR_NAME = '.aris'
$SKILLS_REL = '.claude/skills'
$DOC_FILE_NAME = 'CLAUDE.md'
$BLOCK_BEGIN = '<!-- ARIS:BEGIN -->'
$BLOCK_END = '<!-- ARIS:END -->'
$SAFE_NAME_REGEX = '^[A-Za-z0-9][A-Za-z0-9._-]*$'
$SUPPORT_NAMES = @('shared-references')
$EXCLUDE_TOP_NAMES = @('skills-codex', 'skills-codex.bak', 'skills-codex-claude-review', 'skills-codex-gemini-review')

# ─── Helpers ──────────────────────────────────────────────────────────────────
function Write-Log {
    param([string]$Message, [string]$ForegroundColor = 'White')
    Write-Host $Message -ForegroundColor $ForegroundColor
}
function Write-Warn {
    param([string]$Message)
    Write-Host "warning: $Message" -ForegroundColor Yellow
}
function Write-ErrorExit {
    param([string]$Message)
    Write-Host "error: $Message" -ForegroundColor Red
    exit 1
}

function Test-SafeName {
    param([string]$Name)
    return $Name -cmatch $SAFE_NAME_REGEX
}

function Resolve-ArisRepo {
    if ($ArisRepo) {
        $p = Resolve-Path $ArisRepo -ErrorAction SilentlyContinue
        if (-not $p) { Write-ErrorExit "-ArisRepo path not found: $ArisRepo" }
        if (-not (Test-Path (Join-Path $p 'skills'))) { Write-ErrorExit "-ArisRepo has no skills/ subdir: $p" }
        return $p.Path
    }

    # Parent of script dir
    $scriptDir = Split-Path $PSScriptRoot -Parent
    if (Test-Path (Join-Path $scriptDir 'skills')) { return $scriptDir }

    # Env override
    if ($env:ARIS_REPO -and (Test-Path (Join-Path $env:ARIS_REPO 'skills'))) {
        return (Resolve-Path $env:ARIS_REPO).Path
    }

    # Guesses
    $guesses = @(
        (Join-Path $env:USERPROFILE 'aris_repo'),
        (Join-Path $env:USERPROFILE 'Desktop\aris_repo'),
        (Join-Path $env:USERPROFILE '.aris'),
        (Join-Path $env:USERPROFILE 'Desktop\Auto-claude-code-research-in-sleep'),
        (Join-Path $env:USERPROFILE '.codex\Auto-claude-code-research-in-sleep'),
        (Join-Path $env:USERPROFILE '.claude\Auto-claude-code-research-in-sleep')
    )
    foreach ($g in $guesses) {
        if (Test-Path (Join-Path $g 'skills')) { return (Resolve-Path $g).Path }
    }

    Write-ErrorExit "Cannot find ARIS repo. Use -ArisRepo PATH or set `$env:ARIS_REPO."
}

function Build-UpstreamInventory {
    param([string]$Repo)
    $skillsDir = Join-Path $Repo 'skills'
    $entries = @()

    foreach ($d in Get-ChildItem $skillsDir -Directory) {
        $name = $d.Name

        # Skip excluded names
        if ($EXCLUDE_TOP_NAMES -contains $name) { continue }

        # Skip unsafe names
        if (-not (Test-SafeName $name)) {
            Write-Warn "skipping unsafe upstream name: $name"
            continue
        }

        # Check if support entry
        $isSupport = $SUPPORT_NAMES -contains $name

        # For skills, require SKILL.md
        if (-not $isSupport -and -not (Test-Path (Join-Path $d.FullName 'SKILL.md'))) {
            continue
        }

        $kind = if ($isSupport) { 'support' } else { 'skill' }
        $entries += [PSCustomObject]@{
            Kind = $kind
            Name = $name
            Source = $d.FullName
            SourceRel = "skills/$name"
            TargetRel = "$SKILLS_REL/$name"
        }
    }
    return $entries
}

function Load-Manifest {
    param([string]$Path)
    if (-not (Test-Path $Path)) { return @() }

    $lines = Get-Content $Path -Encoding UTF8
    $entries = @()
    $inBody = $false

    foreach ($line in $lines) {
        $parts = $line -split "`t"

        if ($parts[0] -eq 'version') {
            if ($parts[1] -ne $MANIFEST_VERSION) {
                Write-ErrorExit "manifest version mismatch (file: $($parts[1]), expected: $MANIFEST_VERSION)"
            }
            continue
        }

        if ($parts[0] -eq 'kind' -and $parts[1] -eq 'name') {
            $inBody = $true
            continue
        }

        if ($inBody -and $parts.Count -ge 5) {
            $entries += [PSCustomObject]@{
                Kind = $parts[0]
                Name = $parts[1]
                SourceRel = $parts[2]
                TargetRel = $parts[3]
                Mode = $parts[4]
            }
        }
    }
    return $entries
}

function Compute-Plan {
    param([array]$Upstream, [array]$Manifest)
    $plan = @()

    # Phase 1: upstream entries
    foreach ($u in $Upstream) {
        $targetPath = Join-Path $ProjectPath $u.TargetRel
        $expectedTarget = $u.Source

        $mEntry = $Manifest | Where-Object { $_.Name -eq $u.Name }

        if (Test-Path $targetPath) {
            $item = Get-Item $targetPath -Force
            if ($item.LinkType -in @('Junction', 'SymbolicLink')) {
                $currentTarget = $item.Target | Select-Object -First 1
                # Resolve relative target to absolute
                if (-not [System.IO.Path]::IsPathRooted($currentTarget)) {
                    $currentTarget = Join-Path (Split-Path $targetPath -Parent) $currentTarget
                    $resolved = Resolve-Path $currentTarget -ErrorAction SilentlyContinue
                    if ($resolved) { $currentTarget = $resolved.Path }
                }

                if ($currentTarget -eq $expectedTarget) {
                    if ($mEntry) { $action = 'REUSE' }
                    else { $action = 'ADOPT' }
                } else {
                    if ($mEntry) { $action = 'UPDATE_TARGET' }
                    else { $action = 'CONFLICT' }
                }
            } else {
                $action = 'CONFLICT'
            }
        } else {
            $action = 'CREATE'
        }

        $extra = ''
        if ($action -eq 'CONFLICT') {
            if (Test-Path $targetPath) {
                $item = Get-Item $targetPath -Force
                if ($item.LinkType -in @('Junction', 'SymbolicLink')) {
                    $extra = "junction exists but points to different target"
                } else {
                    $extra = "path exists but is not a junction (it's a $($item.GetType().Name))"
                }
            }
        }

        $plan += [PSCustomObject]@{
            Action = $action
            Kind = $u.Kind
            Name = $u.Name
            Source = $u.Source
            SourceRel = $u.SourceRel
            TargetRel = $u.TargetRel
            Extra = $extra
        }
    }

    # Phase 2: manifest entries no longer upstream
    foreach ($m in $Manifest) {
        $u = $Upstream | Where-Object { $_.Name -eq $m.Name }
        if (-not $u) {
            $plan += [PSCustomObject]@{
                Action = 'REMOVE'
                Kind = $m.Kind
                Name = $m.Name
                Source = ''
                SourceRel = $m.SourceRel
                TargetRel = $m.TargetRel
                Extra = ''
            }
        }
    }

    return $plan
}

function Print-Plan {
    param([array]$Plan)

    $counts = @{
        CREATE = ($Plan | Where-Object { $_.Action -eq 'CREATE' }).Count
        UPDATE_TARGET = ($Plan | Where-Object { $_.Action -eq 'UPDATE_TARGET' }).Count
        REUSE = ($Plan | Where-Object { $_.Action -eq 'REUSE' }).Count
        ADOPT = ($Plan | Where-Object { $_.Action -eq 'ADOPT' }).Count
        REMOVE = ($Plan | Where-Object { $_.Action -eq 'REMOVE' }).Count
        CONFLICT = ($Plan | Where-Object { $_.Action -eq 'CONFLICT' }).Count
    }

    Write-Log ""
    Write-Log "Plan:"
    Write-Log "  CREATE:        $($counts.CREATE)  (new junctions)"
    Write-Log "  UPDATE_TARGET: $($counts.UPDATE_TARGET)  (managed junctions with stale target)"
    Write-Log "  REUSE:         $($counts.REUSE)   (already correct, no-op)"
    Write-Log "  ADOPT:         $($counts.ADOPT)   (non-managed junctions pointing to correct target)"
    Write-Log "  REMOVE:        $($counts.REMOVE)  (in old manifest, no longer upstream)"
    Write-Log "  CONFLICT:      $($counts.CONFLICT)  (must be resolved before apply)"

    if ($counts.CONFLICT -gt 0) {
        Write-Log ""
        Write-Log "Conflicts:" -ForegroundColor Red
        foreach ($p in ($Plan | Where-Object { $_.Action -eq 'CONFLICT' })) {
            Write-Log "  - $($p.Name): $($p.Extra)" -ForegroundColor Red
        }
        Write-ErrorExit "resolve conflicts before applying"
    }
}

function Apply-Plan {
    param([array]$Plan)

    foreach ($p in $Plan) {
        $targetPath = Join-Path $ProjectPath $p.TargetRel

        switch ($p.Action) {
            'REUSE' {
                Write-Log "  REUSE $($p.Name)"
            }
            'ADOPT' {
                Write-Log "  ADOPT $($p.Name)"
            }
            'CREATE' {
                if ($DryRun) {
                    Write-Log "  (dry-run) CREATE $($p.Name) -> $($p.Source)"
                } else {
                    New-Item -ItemType Junction -Path $targetPath -Target $p.Source | Out-Null
                    Write-Log "  CREATE $($p.Name)" -ForegroundColor Green
                }
            }
            'UPDATE_TARGET' {
                if ($DryRun) {
                    Write-Log "  (dry-run) UPDATE_TARGET $($p.Name) -> $($p.Source)"
                } else {
                    Remove-Item $targetPath -Force
                    New-Item -ItemType Junction -Path $targetPath -Target $p.Source | Out-Null
                    Write-Log "  UPDATE_TARGET $($p.Name)" -ForegroundColor Yellow
                }
            }
            'REMOVE' {
                if ($DryRun) {
                    Write-Log "  (dry-run) REMOVE $($p.Name)"
                } else {
                    if (-not (Test-Path $targetPath)) { continue }

                    $item = Get-Item $targetPath -Force
                    if ($item.LinkType -notin @('Junction', 'SymbolicLink')) {
                        Write-Warn "skip REMOVE $($p.Name): not a junction"
                        continue
                    }

                    $currentTarget = $item.Target | Select-Object -First 1
                    if (-not [System.IO.Path]::IsPathRooted($currentTarget)) {
                        $currentTarget = Join-Path (Split-Path $targetPath -Parent) $currentTarget
                        $resolved = Resolve-Path $currentTarget -ErrorAction SilentlyContinue
                        if ($resolved) { $currentTarget = $resolved.Path }
                    }

                    $repoPath = (Resolve-Path $ArisRepoResolved).Path
                    if (-not $currentTarget.StartsWith($repoPath)) {
                        Write-Warn "skip REMOVE $($p.Name): target outside aris-repo"
                        continue
                    }

                    # Use cmd /c rmdir to avoid PowerShell Remove-Item quirks with junctions
                    $rmdirOutput = cmd /c "rmdir `"$targetPath`"" 2`>`&1
                    if ($LASTEXITCODE -ne 0) {
                        Write-Warn "failed to remove $($p.Name): $rmdirOutput"
                        continue
                    }
                    Write-Log "  REMOVE $($p.Name)" -ForegroundColor Yellow
                }
            }
        }
    }
}

function Write-ManifestTmp {
    param([array]$Plan, [string]$OutPath)
    $lines = @()
    $lines += "version`t$MANIFEST_VERSION"
    $lines += "repo_root`t$ArisRepoResolved"
    $lines += "project_root`t$ProjectPath"
    $lines += "generated`t$((Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ'))"
    $lines += "kind`tname`tsource_rel`ttarget_rel`tmode"

    $managed = $Plan | Where-Object { $_.Action -in @('REUSE','ADOPT','CREATE','UPDATE_TARGET') }
    foreach ($p in $managed) {
        $lines += "$($p.Kind)`t$($p.Name)`t$($p.SourceRel)`t$($p.TargetRel)`tjunction"
    }

    $lines | Set-Content -Path $OutPath -Encoding UTF8
}

function Commit-Manifest {
    param([string]$TmpPath)
    if ($DryRun) {
        Write-Log "  (dry-run) would commit manifest"
        return
    }
    if (Test-Path $MANIFEST_PATH) {
        Copy-Item $MANIFEST_PATH $MANIFEST_PREV_PATH -Force
    }
    Move-Item $TmpPath $MANIFEST_PATH -Force
}

function Update-DocFile {
    if ($NoDoc) { return }

    $docPath = Join-Path $ProjectPath $DOC_FILE_NAME
    $count = (Load-Manifest -Path $MANIFEST_PATH).Count

    $blockBody = @"
$BLOCK_BEGIN
## ARIS Skill Scope
ARIS skills installed in this project: $count entries.
Manifest: ``$ARIS_DIR_NAME/$MANIFEST_NAME`` (lists every skill ARIS installed and its upstream target).
For ARIS workflows, prefer the project-local skills under ``$SKILLS_REL/`` over global skills.
Do not modify or delete files inside any skill that is a junction (junctions point into ``$ArisRepoResolved``).

Update skills: <code>cd $ArisRepoResolved; git pull</code>
Re-run installer after upstream adds/removes skills.
$BLOCK_END
"@

    if ((Test-Path $docPath) -and ((Get-Content $docPath -Raw -Encoding UTF8) -match [regex]::Escape($BLOCK_BEGIN))) {
        $text = Get-Content $docPath -Raw -Encoding UTF8
        $pattern = [regex]::Escape($BLOCK_BEGIN) + '.*?' + [regex]::Escape($BLOCK_END)
        $new = [regex]::Replace($text, $pattern, $blockBody, [System.Text.RegularExpressions.RegexOptions]::Singleline)
        Set-Content -Path $docPath -Value $new -NoNewline -Encoding UTF8
        Write-Log "  Updated managed ARIS block in: $docPath" -ForegroundColor Green
    } else {
        if ((Test-Path $docPath) -and ((Get-Item $docPath).Length -gt 0)) {
            Add-Content -Path $docPath -Value "" -Encoding UTF8
        }
        Add-Content -Path $docPath -Value $blockBody -Encoding UTF8
        Write-Log "  Appended managed ARIS block to: $docPath" -ForegroundColor Green
    }
}

function Do-Uninstall {
    if (-not (Test-Path $MANIFEST_PATH)) {
        Write-ErrorExit "no manifest at $MANIFEST_PATH; nothing to uninstall"
    }

    $manifest = Load-Manifest -Path $MANIFEST_PATH
    Write-Log ""
    Write-Log "Uninstall plan:"
    foreach ($m in $manifest) {
        Write-Log "  - $($m.Name) ($($m.Kind))"
    }

    if (-not $DryRun) {
        foreach ($m in $manifest) {
            $targetPath = Join-Path $ProjectPath $m.TargetRel
            if (-not (Test-Path $targetPath)) { continue }

            $item = Get-Item $targetPath -Force
            if ($item.LinkType -notin @('Junction', 'SymbolicLink')) {
                Write-Warn "skip $($m.Name): not a junction"
                continue
            }

            $currentTarget = @($item.Target) | Where-Object { $_ } | Select-Object -First 1
            if (-not $currentTarget) {
                Write-Warn "skip $($m.Name): cannot determine junction target"
                continue
            }
            if (-not [System.IO.Path]::IsPathRooted($currentTarget)) {
                $currentTarget = Join-Path (Split-Path $targetPath -Parent) $currentTarget
                $resolved = Resolve-Path $currentTarget -ErrorAction SilentlyContinue
                if ($resolved) { $currentTarget = $resolved.Path }
            }

            $repoPath = (Resolve-Path $ArisRepoResolved).Path
            if (-not $currentTarget.StartsWith($repoPath)) {
                Write-Warn "skip $($m.Name): target outside aris-repo"
                continue
            }

            # Use cmd /c rmdir to avoid PowerShell Remove-Item quirks with junctions
            $rmdirOutput = cmd /c "rmdir `"$targetPath`"" 2`>`&1
            if ($LASTEXITCODE -ne 0) {
                Write-Warn "failed to remove $($m.Name): $rmdirOutput"
                continue
            }
            Write-Log "  - removed $($m.Name)" -ForegroundColor Yellow
        }

        if (Test-Path $MANIFEST_PATH) {
            Move-Item $MANIFEST_PATH $MANIFEST_PREV_PATH -Force
        }
        Write-Log "  Uninstalled (manifest preserved as $MANIFEST_PREV_NAME)" -ForegroundColor Green
    }
}

function Do-FromOld {
    $oldNested = Join-Path $ProjectPath "$SKILLS_REL/aris"
    if (Test-Path $oldNested) {
        $item = Get-Item $oldNested -Force
        if ($item.LinkType -in @('Junction', 'SymbolicLink')) {
            if (-not $DryRun) {
                Remove-Item $oldNested -Force
                Write-Log "  Removed old nested junction: $oldNested" -ForegroundColor Yellow
            } else {
                Write-Log "  (dry-run) would remove old nested junction: $oldNested"
            }
        } else {
            Write-Warn "Old nested path exists but is not a junction: $oldNested"
            Write-Warn "Please remove it manually before running flat install."
        }
    } else {
        Write-Log "  No old nested install found at $oldNested"
    }
}

# ─── Main ─────────────────────────────────────────────────────────────────────

# Resolve paths
if (-not (Test-Path $ProjectPath -PathType Container)) {
    Write-ErrorExit "project path does not exist: $ProjectPath"
}
$ProjectPath = (Resolve-Path $ProjectPath).Path

$ArisRepoResolved = Resolve-ArisRepo

# Bootstrap mode: create project structure before installing skills
if ($Bootstrap) {
    Bootstrap-Project -ProjPath $ProjectPath -RepoPath $ArisRepoResolved
}

$SKILLS_DIR = Join-Path $ProjectPath $SKILLS_REL
$ARIS_DIR = Join-Path $ProjectPath $ARIS_DIR_NAME
$MANIFEST_PATH = Join-Path $ARIS_DIR $MANIFEST_NAME
$MANIFEST_PREV_PATH = Join-Path $ARIS_DIR $MANIFEST_PREV_NAME

# Ensure directories exist
if (-not (Test-Path $SKILLS_DIR)) {
    New-Item -ItemType Directory -Path $SKILLS_DIR -Force | Out-Null
}
if (-not (Test-Path $ARIS_DIR)) {
    New-Item -ItemType Directory -Path $ARIS_DIR -Force | Out-Null
}

Write-Log ""
Write-Log "ARIS Flat Junction Install" -ForegroundColor Cyan
Write-Log "  Project:    $ProjectPath"
Write-Log "  ARIS repo:  $ArisRepoResolved"
Write-Log "  Skills dir: $SKILLS_DIR"
if ($DryRun) { Write-Log "  Mode:       DRY-RUN" -ForegroundColor Yellow }
elseif ($Uninstall) { Write-Log "  Mode:       UNINSTALL" -ForegroundColor Magenta }
else { Write-Log "  Mode:       APPLY" -ForegroundColor Green }
Write-Log ""

# From-old migration
if ($FromOld) {
    Do-FromOld
}

# Uninstall
if ($Uninstall) {
    Do-Uninstall
    exit 0
}

# Build upstream inventory
$upstream = Build-UpstreamInventory -Repo $ArisRepoResolved
if ($upstream.Count -eq 0) {
    Write-ErrorExit "upstream inventory empty (broken aris-repo?)"
}

# Load manifest
$manifest = Load-Manifest -Path $MANIFEST_PATH

# Compute plan
$plan = Compute-Plan -Upstream $upstream -Manifest $manifest

# Print plan
Print-Plan -Plan $plan

# Check if there's anything to do
$changes = $plan | Where-Object { $_.Action -notin @('REUSE','ADOPT') }
if ($changes.Count -eq 0) {
    Write-Log ""
    Write-Log "Already up to date. $($plan.Count) entries managed." -ForegroundColor Green
    Update-DocFile
    exit 0
}

if ($DryRun) {
    Write-Log ""
    Write-Log "(dry-run) no changes made." -ForegroundColor Yellow
    exit 0
}

# Apply
Write-Log ""
Write-Log "Applying:"
Apply-Plan -Plan $plan

# Write and commit manifest
$manifestTmp = Join-Path $ARIS_DIR "$MANIFEST_NAME.tmp"
Write-ManifestTmp -Plan $plan -OutPath $manifestTmp
Commit-Manifest -TmpPath $manifestTmp

# Update doc
Update-DocFile

$changeCount = ($plan | Where-Object { $_.Action -in @('CREATE','UPDATE_TARGET','REMOVE') }).Count
Write-Log ""
Write-Log "Install complete. $changeCount changes applied." -ForegroundColor Green
Write-Log "Update with: cd $ArisRepoResolved; git pull" -ForegroundColor Cyan
