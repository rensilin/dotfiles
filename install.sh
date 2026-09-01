#!/bin/sh

set -eu

SCRIPT_DIR=$(CDPATH= cd -P "$(dirname "$0")" && pwd)
PACKAGE_SCRIPT="$SCRIPT_DIR/install-packages.sh"
REPO_URL=${DOTFILES_REPO_URL:-}

log() {
	printf '\n==> %s\n' "$*"
}

die() {
	printf '\nerror: %s\n' "$*" >&2
	exit 1
}

[ -f "$PACKAGE_SCRIPT" ] || die "package installer not found next to install.sh"

if [ -z "$REPO_URL" ] && command -v git >/dev/null 2>&1; then
	REPO_URL=$(git -C "$SCRIPT_DIR" config --get remote.origin.url 2>/dev/null || true)
fi
REPO_URL=${REPO_URL:-https://github.com/rensilin/dotfiles.git}

if [ "${DOTFILES_SKIP_PACKAGES:-0}" != "1" ]; then
	log "Installing chezmoi and development tools with the system package manager"
	DOTFILES_SKIP_PACKAGES=0 sh "$PACKAGE_SCRIPT"
fi

if command -v chezmoi >/dev/null 2>&1; then
	CHEZMOI=$(command -v chezmoi)
elif [ -x /opt/homebrew/bin/chezmoi ]; then
	CHEZMOI=/opt/homebrew/bin/chezmoi
elif [ -x /usr/local/bin/chezmoi ]; then
	CHEZMOI=/usr/local/bin/chezmoi
else
	die "chezmoi was not found; install it with the system package manager or rerun without DOTFILES_SKIP_PACKAGES=1"
fi

if [ "${DOTFILES_DRY_RUN:-0}" = "1" ]; then
	log "Would apply dotfiles from $REPO_URL with $CHEZMOI"
	exit 0
fi

log "Applying dotfiles from $REPO_URL"
"$CHEZMOI" init --apply "$REPO_URL"

log "Bootstrap complete"
printf 'Restart the shell if newly installed commands are not yet on PATH.\n'
