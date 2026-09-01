---
name: chezmoi-dotfiles
description: Safely modify configuration already managed by chezmoi, apply and validate the target state, then commit and push only the related dotfiles changes to the configured GitHub remote. Use when a requested configuration change belongs to chezmoi; do not use for unmanaged machine-only configuration or read-only questions.
---

# Chezmoi Dotfiles

Use the active chezmoi source repository as the only dotfiles working copy. A
request to change managed configuration invokes the complete workflow below,
including apply, commit, and push, unless the user explicitly limits a step.

## Establish ownership and scope

1. Run `chezmoi source-path` to locate the source directory. Do not assume its
   path and do not work in an older clone.
2. Read the source repository's `AGENTS.md` completely before editing.
3. Resolve each requested destination with `chezmoi managed` and
   `chezmoi source-path <target>`. If it is unmanaged, do not add it unless the
   user explicitly asks to put it under chezmoi management.
4. Inspect `chezmoi status` and `git status --short --branch` before editing.
   Preserve pre-existing work and never include unrelated changes in the
   commit. If the requested edit cannot be separated safely, stop and explain.

Machine-owned or ignored overrides remain local even when a nearby shared file
is managed. In particular, follow the repository's rules for `.zshrc`, local
Neovim overrides, secrets, caches, generated plugins, and upstream frameworks.

## Modify the source state

- Prefer editing the path returned by `chezmoi source-path <target>`, including
  its template or source-state attributes. Do not flatten templates, replace
  managed symlinks with regular files, or edit generated target contents and
  blindly `re-add` them.
- Use `chezmoi add` or `chezmoi re-add` only when intentionally importing the
  current destination state. Review the source diff immediately afterward.
- Keep the change limited to the user's request and preserve portability across
  every platform named by the repository.

## Validate and apply

1. Review `git diff` and `chezmoi diff` before applying. Treat unexpected
   changes as a reason to investigate, not something to force through.
2. Run the focused syntax checks or tests required by `AGENTS.md` and the
   changed configuration.
3. Apply only the affected targets first with `chezmoi apply <target>` when
   practical, then run `chezmoi verify`. Confirm `chezmoi status` and
   `chezmoi diff` contain no unexplained pending changes.
4. Do not run package installers, destructive commands, or unrelated migration
   scripts merely because they exist in the source repository.

## Commit and sync

1. Inspect the final working-tree diff. Stage only explicit paths from this
   task; never use `git add .` or `git add -A`.
2. Run every staged-file, staged-content, secret, and machine-specific path
   check required by `AGENTS.md`. Never commit credentials, tokens, private
   keys, machine identities, private endpoints, proxies, or local environment
   values. Encryption is not a substitute for reviewing what is staged.
3. Create a focused commit with the repository's configured personal identity.
   Do not create an empty commit when the requested state already exists.
4. Push the current branch to its existing upstream. Never force-push. If the
   remote moved, fetch and integrate it without discarding local or remote
   work, re-run validation, and push normally. Stop and report any conflict or
   authentication failure that cannot be resolved safely.

Report the applied targets, validation performed, commit hash, and pushed
remote branch. If nothing changed or upload did not complete, say so plainly.
