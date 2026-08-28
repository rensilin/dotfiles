# dotfiles

使用 [chezmoi](https://www.chezmoi.io/) 管理的个人 Neovim 和 tmux 配置，目标环境：

- macOS
- Arch Linux 桌面
- 其他 Linux 发行版和无图形界面的服务器

## 前置依赖

- Git
- chezmoi
- Neovim 0.11 或更新版本
- tmux 3.2 或更新版本

Neovim 插件由 lazy.nvim 自动安装。tmux 使用 Oh My Tmux，并由 chezmoi external 自动拉取。系统剪贴板属于可选功能：macOS 使用 `pbcopy`；Wayland 可使用 `wl-copy`；X11 可使用 `xclip` 或 `xsel`；服务器未安装这些命令时配置仍可正常加载。

## 新机器安装

安装 chezmoi 后执行：

```sh
chezmoi init git@github.com:rensilin/dotfiles.git
chezmoi diff
chezmoi apply -v
```

首次启动 Neovim 和 tmux 时需要网络下载插件。刷新配置及外部依赖：

```sh
chezmoi update -v
chezmoi -R apply -v
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
