# dotfiles

使用 [chezmoi](https://www.chezmoi.io/) 管理的个人 Neovim 和 tmux 配置，目标环境：

- macOS
- Arch Linux 桌面
- 其他 Linux 发行版和无图形界面的服务器

## 新机器一键安装

因为这是私有仓库，新机器需要先准备好：

- 可用的 `curl`
- 已添加到 GitHub 账号的 SSH 密钥，并且 `ssh -T git@github.com` 能识别账号
- 当前用户拥有 `sudo` 权限，或者已经是 root

然后以普通用户执行一条命令：

```sh
sh -c "$(curl -fsLS https://get.chezmoi.io/lb)" -- init --apply git@github.com:rensilin/dotfiles.git
```

该命令会安装 chezmoi，然后仓库中的 `run_onchange_before_10-install-packages.sh` 会自动：

- 识别 macOS、Arch、Debian/Ubuntu、Fedora/RHEL、openSUSE、Alpine 或 Void Linux
- 使用 Homebrew、pacman、apt、dnf、zypper、apk 或 xbps 安装软件
- 安装 Git、Neovim、tmux、ripgrep、fd、curl、unzip 和本机构建工具
- 在 glibc Linux 的 Neovim 版本低于 0.11 时，安装官方稳定版到 `~/.local/opt/nvim`
- 拉取 Oh My Tmux 并应用全部配置；Neovim 插件在首次启动时自动安装

Arch Linux 会执行完整的 `pacman -Syu`，其他发行版也会更新包索引；运行过程中可能要求输入 sudo 密码。脚本是幂等的，chezmoi 仅在脚本首次出现或内容改变后执行它。

安装完成后建议确保用户级命令目录在 `PATH` 中：

```sh
export PATH="$HOME/.local/bin:$PATH"
```

如果机器上的软件已经由其他方式管理，只应用配置：

```sh
DOTFILES_SKIP_PACKAGES=1 sh -c "$(curl -fsLS https://get.chezmoi.io/lb)" -- init --apply git@github.com:rensilin/dotfiles.git
```

首次启动 Neovim 和 tmux 时可能需要网络下载插件。刷新配置及外部依赖：

```sh
chezmoi update -v
chezmoi -R apply -v
```

手动预览安装脚本而不执行包管理器：

```sh
DOTFILES_DRY_RUN=1 sh "$(chezmoi source-path)/run_onchange_before_10-install-packages.sh"
```

如果首次安装时使用了 `DOTFILES_SKIP_PACKAGES=1`，之后可以手动执行：

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
