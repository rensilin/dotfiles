# dotfiles

使用 [chezmoi](https://www.chezmoi.io/) 管理的个人 Neovim、tmux 和 Zsh 配置，目标环境：

- macOS
- Arch Linux 桌面
- 其他 Linux 发行版和无图形界面的服务器

## 在新机器上初始化

这是公开仓库，新机器只需先准备好 Git，不需要配置 GitHub SSH 密钥。

### 1. 使用包管理器安装 chezmoi

macOS 如果尚未安装 Homebrew，执行官方一键安装命令：

```sh
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

按照安装器最后输出的提示把 Homebrew 加入 `PATH`，然后安装 chezmoi：

```sh
brew install chezmoi
```

Arch Linux：

```sh
sudo pacman -Syu chezmoi
```

Debian / Ubuntu：

```sh
sudo apt update
sudo apt install chezmoi
```

Fedora：

```sh
sudo dnf install chezmoi
```

RHEL（需要 EPEL）：

```sh
sudo dnf install epel-release
sudo dnf install chezmoi
```

openSUSE：

```sh
sudo zypper install chezmoi
```

Alpine Linux：

```sh
sudo apk add chezmoi
```

Void Linux：

```sh
sudo xbps-install -S chezmoi
```

其他发行版请优先通过其包管理器安装，具体可参考
[chezmoi 官方安装文档](https://www.chezmoi.io/install/)。

### 2. 初始化 dotfiles

先克隆公开仓库并初始化 chezmoi，不立即修改当前配置：

```sh
chezmoi init https://github.com/rensilin/dotfiles.git
```

预览将要发生的变化：

```sh
chezmoi diff
```

`chezmoi diff` 默认也会展示待运行脚本的内容。只想检查配置文件差异时使用：

```sh
chezmoi diff --exclude=scripts
```

确认无误后应用配置：

```sh
chezmoi apply -v
```

`chezmoi apply` 只应用配置和声明的外部依赖，不会自动运行包管理器、请求 sudo 或升级
系统。首次应用时会联网下载 Oh My Tmux 和 Oh My Zsh；Neovim 会在首次启动时下载插件。

仓库不会整体托管或覆盖 `~/.zshrc`。chezmoi 的 `modify_` 文件只会确保其中存在一个
带标记的加载块，用来加载托管的 `~/.config/zsh/chezmoi.zsh`。已有 `.zshrc` 的其他
内容保持不变；加载块存在后，后续 `chezmoi apply` 计算出的内容相同，不会反复修改文件。
这是 chezmoi 官方提供的“修改现有文件”目标类型：
[Modify file](https://www.chezmoi.io/reference/target-types/#modify-file)。

可选的 `local.zsh` 会作为机器专属配置加载，并且不会上传仓库。共享配置会强制使用
Oh My Zsh 的 `ys` 主题，机器配置中的其他主题设置不会覆盖它。

Linux 上如果当前默认 shell 不是 Zsh，可以在确认 `command -v zsh` 有输出后切换：

```sh
chsh -s "$(command -v zsh)"
```

注销并重新登录后生效。macOS 默认已使用 Zsh，一般无需执行这一步。

以后刷新配置及外部依赖：

```sh
chezmoi update -v
chezmoi -R apply -v
```

手动预览安装脚本而不执行包管理器：

```sh
DOTFILES_DRY_RUN=1 sh "$(chezmoi source-path)/install-packages.sh"
```

需要时可以显式安装仓库声明的依赖。脚本会探测 macOS、Arch、Debian/Ubuntu、
Fedora/RHEL、openSUSE、Alpine 或 Void Linux，并调用对应包管理器：

```sh
sh "$(chezmoi source-path)/install-packages.sh"
```

## 日常修改

直接修改实际配置后同步回仓库：

```sh
chezmoi re-add ~/.config/nvim ~/.tmux.conf.local ~/.config/zsh/chezmoi.zsh
chezmoi cd
git status --short
git add dot_config/nvim dot_tmux.conf.local dot_config/private_zsh/chezmoi.zsh
git diff --cached
git commit -m "update configuration"
git push
```

`~/.tmux.conf` 是指向 Oh My Tmux 上游配置的托管软链接，不应 `re-add`。
`~/.zshrc` 是机器所有的文件，也不应 `re-add`；仓库只通过 `modify_dot_zshrc` 维护其中
的共享配置加载块。需要修改共享 Zsh 设置时也可以直接运行：

```sh
chezmoi edit ~/.config/zsh/chezmoi.zsh
chezmoi apply ~/.config/zsh/chezmoi.zsh
```

## 机器专属配置

Neovim 会可选加载以下未托管文件：

```text
~/.config/nvim/lua/machine.lua
```

适合放置工作机代理、机器路径或只在某台机器启用的设置。例如：

```lua
vim.g.machine_role = "work"
```

Zsh 会可选加载以下未托管文件：

```text
~/.config/zsh/local.zsh
```

机器专属的 PATH、语言运行时、SDK、代理或环境变量建议写在这里；已有 `.zshrc` 也
保持为本机文件，不会被上传。例如当前机器需要用户级命令目录时，可以只在本地配置中加入：

```zsh
path=(~/.local/bin $path)
typeset -U path PATH
```

即使仓库当前是公开的，也不要把 Token、密码或其他密钥直接写进托管配置。

不要把密码、Token 或私钥提交到本仓库。需要同步敏感信息时，应使用密码管理器或
chezmoi 的 age 加密。

## 让 AI 帮你创建自己的 dotfiles 仓库

在已经保存了个人配置的电脑上启动一个能够读写文件、运行终端命令并操作 GitHub
的 AI 编程助手。先替换下面提示词中的尖括号内容，再把整段提示词交给 AI。不要在
提示词中填写真实密码、Token、私钥或公司内部地址。

```text
你是我的 dotfiles 配置工程师。请在当前环境中实际完成下面的工作，不要只给出操作建议。

我的信息：
- GitHub 用户名：<你的 GitHub 用户名>
- 仓库名称：<dotfiles，或你喜欢的名称>
- 需要同步的配置：<例如 Neovim、tmux、Zsh>
- 目标机器：macOS、Arch Linux、其他常见 Linux 发行版和无图形界面的服务器

目标：
使用 chezmoi 创建一个 GitHub dotfiles 仓库，使我能够在新机器上先通过系统包管理器
安装 chezmoi，再运行 `chezmoi init`、预览差异并应用配置。

请遵守以下要求：

1. 先只读检查当前系统、Git/GitHub 登录状态、已有 dotfiles 和相关配置文件。列出建议同步、
   忽略以及需要人工确认的文件，不要立刻上传任何内容。
2. 在读取配置时主动检查密钥风险。不得提交密码、访问令牌、API Key、SSH/GPG 私钥、
   `.env`、云服务凭据、登录 Cookie、代理账号、公司内部地址、Shell 历史、缓存、会话、
   插件安装目录或其他机器身份信息。发现疑似密钥时立即停止该文件的同步并告诉我。
3. 使用当前系统的包管理器安装 chezmoi，例如 macOS 使用 Homebrew、Arch 使用 pacman、
   Debian/Ubuntu 使用 apt、Fedora/RHEL 使用 dnf。不要使用 chezmoi 的远程 shell 安装脚本。
   如果 macOS 没有 Homebrew，可以在 README 中使用 Homebrew 官网提供的一键安装命令。
4. 创建 chezmoi source state，并把确认安全的现有配置迁移进去。保留我的主要使用习惯，
   但去掉示例注释、重复 PATH 和机器专属内容。不要直接复制整个 HOME 目录。
5. 配置必须默认兼容 macOS 和 Linux。不要硬编码用户名、HOME、主机名、CPU 架构、
   `/Users/...`、`/home/...` 或 Homebrew 安装前缀；优先使用 `$HOME`、XDG 目录、PATH
   命令探测和功能探测。缺少可选软件、剪贴板或 GUI 时应安全降级。
6. 为机器专属配置设计不入库的本地覆盖文件，例如 Neovim 的
   `~/.config/nvim/lua/machine.lua` 和 Zsh 的 `~/.config/zsh/local.zsh`。
   不要整体托管或上传 `.zshrc`；把共享 Zsh 配置放在单独的托管文件中，并使用 chezmoi
   官方 `modify_` 目标类型，只在现有 `.zshrc` 中幂等地维护一段带标记的 `source` 引用。
   已有内容必须原样保留，引用已存在时不得再次修改文件。
7. 大型上游配置或框架使用 chezmoi externals 管理，插件目录不要提交；需要锁定版本的
   插件只提交锁文件。
8. 如需自动安装 Neovim、tmux、Zsh、ripgrep、fd 等依赖，编写幂等、非交互、支持 dry-run
   的 POSIX sh 脚本，并根据可用包管理器选择命令。不能支持的系统要给出清晰错误和手动方案。
9. 在仓库根目录创建 AGENTS.md，明确跨平台约束和防止密钥入库的规则。要求每次提交前
   显式检查暂存文件列表、暂存差异和常见密钥模式；禁止盲目执行 `git add .`。
10. 编写中文 README，至少说明：各系统如何安装 chezmoi、公开仓库的 HTTPS 或私有仓库的
    SSH 前置条件、`chezmoi init`、`chezmoi diff`、`chezmoi apply`、`chezmoi update`、
    日常修改流程、机器专属覆盖方式、Linux 切换默认 shell 的方法，以及密钥安全注意事项。
11. 创建 GitHub 仓库前先确认仓库名、当前登录账号和公开/私有选择。任何需要登录、授权、
    推送或改变可见性的操作都应暂停并向我请求授权，不要把认证信息写进仓库。
12. 提交前运行与配置对应的语法和启动检查，并验证 chezmoi 能正确渲染目标文件。
    逐个暂存确定的文件，检查 `git diff --cached` 和密钥模式，确认安全后再提交并推送。
13. 不要删除或覆盖我现有的配置。需要应用新配置时，先运行 `chezmoi diff` 给我审阅；
    遇到冲突时保留备份并说明恢复方法。

完成后请报告：仓库地址、提交号、纳入管理的文件、被排除的文件、验证结果，以及我在另一台
新机器上需要执行的完整命令。
```

AI 给出首次检查结果后，应重点确认它准备纳入仓库的文件列表，以及是否发现机器路径、
账号信息或疑似密钥。确认范围无误后，再授权它创建私有仓库和推送代码。最后最好用一台
没有现有配置的虚拟机或测试账号执行 README 中的新机器流程，验证可以安全复现环境。
