#!/bin/sh

set -eu

DRY_RUN=${DOTFILES_DRY_RUN:-0}
TARGET_HOME=${DOTFILES_HOME:-$HOME}
TARGET_CONFIG_HOME=${DOTFILES_CONFIG_HOME:-${XDG_CONFIG_HOME:-$TARGET_HOME/.config}}
ZSHRC=$TARGET_HOME/.zshrc
LOCAL_DIR=$TARGET_CONFIG_HOME/zsh
LOCAL_CONFIG=$LOCAL_DIR/local.zsh
BACKUP_DIR=$LOCAL_DIR/backups
MANAGED_MARKER='# chezmoi: managed-zshrc'
MIGRATED_MARKER='# chezmoi: migrated-zshrc'
TEMP_FILE=

cleanup() {
	if [ -n "$TEMP_FILE" ] && [ -f "$TEMP_FILE" ]; then
		rm -f -- "$TEMP_FILE"
	fi
}

trap cleanup EXIT HUP INT TERM

[ -f "$ZSHRC" ] || exit 0

FIRST_LINE=$(sed -n '1p' "$ZSHRC")
[ "$FIRST_LINE" != "$MANAGED_MARKER" ] || exit 0

if [ -f "$LOCAL_CONFIG" ]; then
	LOCAL_FIRST_LINE=$(sed -n '1p' "$LOCAL_CONFIG")
	[ "$LOCAL_FIRST_LINE" != "$MIGRATED_MARKER" ] || exit 0
fi

if [ "$DRY_RUN" = "1" ]; then
	printf 'Would migrate existing %s to unmanaged %s and retain a local backup\n' \
		"$ZSHRC" "$LOCAL_CONFIG"
	exit 0
fi

umask 077
mkdir -p "$LOCAL_DIR" "$BACKUP_DIR"
TEMP_FILE=$(mktemp "$LOCAL_DIR/.local.zsh.XXXXXX")

{
	printf '%s\n' "$MIGRATED_MARKER"
	printf '# Preserved by chezmoi from the .zshrc that existed before apply.\n'
	cat "$ZSHRC"
	if [ -f "$LOCAL_CONFIG" ]; then
		printf '\n# Local configuration that existed before .zshrc migration.\n'
		cat "$LOCAL_CONFIG"
	fi
} >"$TEMP_FILE"

BACKUP_FILE=$BACKUP_DIR/zshrc.$(date +%Y%m%d%H%M%S).$$
cp "$ZSHRC" "$BACKUP_FILE"
chmod 600 "$BACKUP_FILE"
mv "$TEMP_FILE" "$LOCAL_CONFIG"
TEMP_FILE=

printf 'Migrated existing .zshrc to %s\n' "$LOCAL_CONFIG"
printf 'Original .zshrc backup: %s\n' "$BACKUP_FILE"
