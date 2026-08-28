# Repository instructions

This repository is a chezmoi source state for one user across macOS, Arch
Linux, and heterogeneous Linux servers. Keep every change portable by default.

## Portability contract

- Support macOS and Linux. Do not assume a particular Linux distribution,
  init system, desktop environment, package manager, CPU architecture, or
  interactive shell.
- Prefer capability detection (`command -v`, Neovim feature checks, tmux
  version checks) over operating-system or distribution checks.
- Never hard-code usernames, home directories, hostnames, `/Users/...`,
  `/home/...`, Homebrew prefixes, or machine-specific paths. Use `$HOME`, XDG
  variables, `stdpath()`, and commands discovered from `PATH`.
- Shell snippets must be POSIX `sh` unless a script explicitly declares and
  genuinely requires another interpreter.
- A missing optional command or GUI clipboard provider must degrade cleanly,
  especially on headless servers.
- Keep shared configuration in the repository. Put host-only settings in
  unmanaged local overrides such as `~/.config/nvim/lua/machine.lua`.

## Safety and scope

- Never commit credentials, access tokens, private keys, company endpoints,
  proxy settings, machine identities, history, caches, sessions, or generated
  plugin directories. A private repository is not a secrets manager.
- Do not vendor plugin installations. Pin Neovim plugins with
  `lazy-lock.json`; manage large upstream trees with chezmoi externals.
- Do not add automatic package installation unless it is idempotent, clearly
  documented, non-interactive, and has safe behavior for every supported
  platform. Prefer documenting prerequisites.
- Preserve existing key bindings and behavior unless a change explicitly asks
  for a behavioral change.

## Validation

Before committing, run the checks that are available on the current machine:

```sh
sh -n install.sh
DOTFILES_DRY_RUN=1 sh install.sh
sh -n run_onchange_before_10-install-packages.sh
DOTFILES_DRY_RUN=1 sh run_onchange_before_10-install-packages.sh
chezmoi verify
chezmoi diff
nvim --headless '+lua vim.defer_fn(function() vim.cmd("qa") end, 1000)' || true
tmux -f "$HOME/.tmux.conf" -L dotfiles-check new-session -d && tmux -L dotfiles-check kill-server
```

Also inspect staged changes for secrets and absolute, machine-specific paths.
