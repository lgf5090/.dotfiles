# Git Bare Repository 管理 Dotfiles 完全指南

## 概述

Dotfiles（以点开头的配置文件，如 `.bashrc`、`.vimrc`、`.zshrc` 等）是 Unix/Linux 系统中用户级应用程序的配置文件。使用版本控制系统（如 Git）来管理这些文件，可以追踪配置变更、在不同主机间同步配置。

**Git Bare Repository 方法**（也称“bare repository and alias method”）是一种极其优雅的 dotfiles 管理方案，由 Hacker News 用户 StreakyCobra 推广。其核心优势在于：

- **无需额外工具**——仅需 Git 本身
- **无需符号链接**——文件直接存放在 HOME 目录
- **不干扰其他 Git 仓库**——bare 仓库位于独立目录
- **支持多分支**——可为不同机器使用不同分支
- **新系统快速恢复**——一条命令即可克隆配置

---

## 方法原理

传统方法是在 `$HOME` 目录下直接初始化 Git 仓库，但这种方法存在两个严重缺陷：

1. **容易混淆**——当 HOME 目录下还有其它 Git 仓库时，可能误操作
2. **无法区分 untracked 文件**——因为所有文件都被 `.gitignore` 的 `*` 模式忽略

**Bare Repository 方法**的解决思路是：

- 在 `$HOME` 下的一个“旁路”文件夹（如 `~/.cfg` 或 `~/.dotfiles`）中创建一个 **bare Git 仓库**
- 通过**自定义别名**让 Git 命令针对该仓库执行，而非默认的 `.git` 目录
- 将 `$HOME` 设置为工作树（work-tree），从而可以直接在 HOME 目录下管理文件

---

## 详细设置步骤

### 前提条件

- 系统已安装 Git
- 基本的终端操作能力

### 第一步：创建 Bare 仓库

```bash
git init --bare $HOME/.dotfiles
```

这会在 `~/.dotfiles` 目录下创建一个 bare Git 仓库。Bare 仓库没有工作树，只存储 Git 的对象和引用数据。

> **命名说明**：你可以使用任何名称，如 `~/.cfg`、`~/.dotfiles`或 `~/.myconfig`。本文统一使用 `~/.dotfiles`。

### 第二步：创建命令别名

为了不与常规 `git` 命令冲突，需要创建一个专用别名：

```bash
alias dotfiles='/usr/bin/git --git-dir="$HOME/.dotfiles/" --work-tree="$HOME"'
```

这个别名的作用是：
- `--git-dir="$HOME/.dotfiles/"` —— 指定 Git 仓库位置
- `--work-tree="$HOME"` —— 指定工作树为 HOME 目录

### 第三步：隐藏未追踪文件

为了避免 `dotfiles status` 时显示大量未追踪文件，设置以下配置：

```bash
dotfiles config --local status.showUntrackedFiles no
```

这会将配置写入 `~/.dotfiles/config` 文件中。

### 第四步：持久化别名

将别名添加到 shell 配置文件中，使其永久生效：

**Bash 用户：**
```bash
echo "alias dotfiles='/usr/bin/git --git-dir=\"\$HOME/.dotfiles/\" --work-tree=\"\$HOME\"'" >> $HOME/.bashrc
```

**Zsh 用户：**
```bash
echo "alias dotfiles='/usr/bin/git --git-dir=\"\$HOME/.dotfiles/\" --work-tree=\"\$HOME\"'" >> $HOME/.zshrc
```

**Fish 用户：**
```bash
echo "alias dotfiles='/usr/bin/git --git-dir=\"\$HOME/.dotfiles/\" --work-tree=\"\$HOME\"'" >> $HOME/.config/fish/config.fish
```

然后重新加载配置文件：
```bash
source ~/.bashrc   # 或 ~/.zshrc
```

---

## 日常使用

设置完成后，使用 `dotfiles` 别名代替 `git` 命令来管理你的配置文件。

### 常用命令

| 操作 | 命令 |
|------|------|
| 查看状态 | `dotfiles status` |
| 添加文件 | `dotfiles add .vimrc` |
| 提交更改 | `dotfiles commit -m "更新 vim 配置"` |
| 推送远程 | `dotfiles push` |
| 拉取更新 | `dotfiles pull` |
| 查看日志 | `dotfiles log` |
| 查看分支 | `dotfiles branch` |
| 切换分支 | `dotfiles checkout branch-name` |

### 添加新配置文件

```bash
# 编辑配置文件
vim ~/.bashrc

# 追踪该文件
dotfiles add ~/.bashrc

# 提交
dotfiles commit -m "添加 bashrc 配置"

# 推送到远程仓库（如果有）
dotfiles push
```

### 添加远程仓库

```bash
dotfiles remote add origin https://github.com/lgf5090/.dotfiles
dotfiles push -u origin main
```

---

## 在新系统上恢复配置

这是该方法最强大的功能之一——在新系统上可以快速恢复完整配置。

### 标准恢复流程

```bash
# 1. 克隆 bare 仓库
git clone --bare https://github.com/lgf5090/.dotfiles $HOME/.dotfiles

# 2. 定义别名
alias dotfiles='/usr/bin/git --git-dir="$HOME/.dotfiles/" --work-tree="$HOME"'

# 3. 检出配置文件
dotfiles checkout

# 4. 如果检出时遇到冲突（已有同名文件），可以先备份或强制覆盖
dotfiles checkout -f   # 强制覆盖

# 5. 隐藏未追踪文件
dotfiles config --local status.showUntrackedFiles no
```

### 处理已有配置文件冲突

如果新系统已存在一些默认配置文件（如 `.bashrc`），检出时可能会报错。解决方案：

**方案一：备份后强制覆盖**
```bash
mkdir -p ~/.dotfiles-backup
dotfiles checkout 2>&1 | egrep "\s+\." | awk {'print $1'} | xargs -I{} mv {} ~/.dotfiles-backup/{}
dotfiles checkout
```

**方案二：使用 `-f` 强制覆盖**
```bash
dotfiles checkout -f
```

### 使用 Git Bundle（无远程仓库时）

如果没有远程仓库，可以使用 `git bundle` 在机器间传输配置：

**源机器上创建 bundle：**
```bash
dotfiles bundle create --progress dotfiles.bundle --all
```

**目标机器上恢复：**
```bash
git clone --bare dotfiles.bundle $HOME/.dotfiles
alias dotfiles='/usr/bin/git --git-dir="$HOME/.dotfiles/" --work-tree="$HOME"'
dotfiles checkout
dotfiles config --local status.showUntrackedFiles no
```

---

## 高级技巧

### 1. 多主机使用不同分支

可以为不同机器使用不同分支：

```bash
# 为笔记本电脑创建分支
dotfiles checkout -b laptop

# 为台式机创建分支
dotfiles checkout -b desktop

# 在特定机器上切换
dotfiles checkout laptop
```

### 2. 使用 `.gitignore` 排除特定文件

在 HOME 目录下创建 `.gitignore` 文件，排除不需要追踪的文件：

```
# 排除 dotfiles 仓库目录本身
.dotfiles/

# 排除临时文件
*.swp
*.tmp

# 排除敏感文件
.secrets
.env
```

### 3. 快速初始化脚本

Atlassian 提供了一个一键初始化脚本：

```bash
curl -Lks http://bit.do/cfg-init | /bin/bash
```

> **注意**：使用前请先审查脚本内容，确保安全。

### 4. 将别名与补全结合

为了让 `dotfiles` 命令也享受 Git 的自动补全，可以将以下内容添加到 shell 配置中：

```bash
# 让 dotfiles 命令继承 git 的补全
complete -o bashdefault -o default -o nospace -F __git_wrap__git_main dotfiles 2>/dev/null \
    || complete -o default -o nospace -F _git dotfiles 2>/dev/null
```

---

## 注意事项与常见问题

### 1. 文件权限问题

Git **不存储文件权限**（除可执行位外）。如果某些配置文件需要特定权限（如 `600`），需要在恢复后手动设置，或使用其他工具辅助。

### 2. 不要追踪敏感信息

**切勿将密码、API 密钥、SSH 私钥等敏感信息提交到 dotfiles 仓库**。可以使用环境变量或单独的加密方案（如 `gpg`、`pass`）来处理敏感配置。

### 3. 仓库目录本身需要被忽略

确保 `.dotfiles/` 目录被 `.gitignore` 忽略，避免递归问题：

```bash
echo ".dotfiles/" >> ~/.gitignore
```

### 4. 别名未生效

如果 `dotfiles` 命令找不到，检查：
- 别名是否已添加到正确的 shell 配置文件
- 配置文件是否已重新加载（`source ~/.bashrc`）
- 是否使用了正确的 shell（如 zsh 用户却修改了 `.bashrc`）

### 5. 检出时文件被覆盖

使用 `dotfiles checkout -f` 可以强制覆盖，但建议先备份重要文件。

---

## 总结

Git Bare Repository 方法是一种**极简、优雅、强大**的 dotfiles 管理方案。核心要点：

1. **初始化**：`git init --bare ~/.dotfiles`
2. **别名**：创建 `dotfiles` 别名指向 bare 仓库 + HOME 工作树
3. **配置**：设置 `status.showUntrackedFiles no`
4. **使用**：用 `dotfiles` 代替 `git` 管理配置文件
5. **恢复**：`git clone --bare` + `dotfiles checkout`

这种方法无需额外工具、无需符号链接，仅凭 Git 自身就能实现高效、可移植的配置管理。无论你是在多台机器间同步配置，还是在新系统上快速重建开发环境，这都是一个值得尝试的方案。
