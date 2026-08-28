# dotfiles

使用 [chezmoi](https://www.chezmoi.io/) 管理的个人 Neovim 和 tmux 配置，目标环境：

- macOS
- Arch Linux 桌面
- 其他 Linux 发行版和无图形界面的服务器

## 在新机器上初始化

因为这是私有仓库，新机器需要先准备好 Git，以及能够访问仓库的 GitHub SSH 密钥：

```sh
ssh -T git@github.com
```

### 1. 使用包管理器安装 chezmoi

macOS（Homebrew）：

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

先克隆私有仓库并初始化 chezmoi，不立即修改当前配置：

```sh
chezmoi init git@github.com:rensilin/dotfiles.git
```

预览将要发生的变化：

```sh
chezmoi diff
```

确认无误后应用配置：

```sh
chezmoi apply -v
```

应用时，仓库中的安装脚本会识别 macOS、Arch、Debian/Ubuntu、Fedora/RHEL、
openSUSE、Alpine 或 Void Linux，并通过对应包管理器安装 Neovim、tmux、
ripgrep、fd 等依赖。运行过程中可能要求输入 sudo 密码。首次启动 Neovim 和
tmux 时可能需要联网下载插件。

如果这台机器的软件已经由其他方式管理，只应用配置：

```sh
DOTFILES_SKIP_PACKAGES=1 chezmoi apply -v
```

安装完成后建议确保用户级命令目录在 `PATH` 中：

```sh
export PATH="$HOME/.local/bin:$PATH"
```

以后刷新配置及外部依赖：

```sh
chezmoi update -v
chezmoi -R apply -v
```

手动预览安装脚本而不执行包管理器：

```sh
DOTFILES_DRY_RUN=1 sh "$(chezmoi source-path)/run_onchange_before_10-install-packages.sh"
```

使用了 `DOTFILES_SKIP_PACKAGES=1` 后，也可以在需要时手动安装仓库声明的依赖：

```sh
sh "$(chezmoi source-path)/run_onchange_before_10-install-packages.sh"
```

## 日常修改

直接修改实际配置后同步回仓库：

```sh
chezmoi re-add ~/.config/nvim ~/.tmux.conf.local
chezmoi cd
git diff
git add .
git commit -m "update configuration"
git push
```

`~/.tmux.conf` 是指向 Oh My Tmux 上游配置的托管软链接，不应 `re-add`。

## 机器专属配置

Neovim 会可选加载以下未托管文件：

```text
~/.config/nvim/lua/machine.lua
```

适合放置工作机代理、机器路径或只在某台机器启用的设置。例如：

```lua
vim.g.machine_role = "work"
```

不要把密码、Token 或私钥提交到本仓库。需要同步敏感信息时，应使用密码管理器或 chezmoi 的 age 加密。
