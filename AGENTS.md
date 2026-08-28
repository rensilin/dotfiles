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
- Treat `.env`, `.env.*`, `id_*`, `*.pem`, `*.key`, `*.p12`, `*.pfx`,
  `credentials*`, `secrets*`, auth cookies, password-manager exports, and cloud
  CLI credential files as forbidden unless the file is an explicitly reviewed
  public example containing placeholders only. Public keys such as `*.pub` must
  still be reviewed before committing.
- Never stage all untracked files blindly. Before every commit and push, inspect
  both the staged file list and staged content. At minimum run:

  ```sh
  git diff --cached --name-status
  git diff --cached --check
  git diff --cached | rg -n -i 'B[E]GIN .*PRIVATE KEY|api[_-]?[k]ey|access[_-]?[t]oken|client[_-]?[s]ecret|[p]assword[[:space:]]*=' || true
  ```

- If any staged file or line might contain a secret, stop before committing or
  pushing. Remove it from the change and use an unmanaged local override, a
  password manager, or chezmoi age encryption instead. Do not weaken this rule
  because the GitHub repository is private.
- If a real secret is ever committed or pushed, assume it is compromised:
  immediately tell the user to revoke or rotate it. Deleting it in a later
  commit is insufficient because it remains in Git history. Rewriting remote
  history requires explicit user approval.
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
