#!/bin/sh

set -eu

REPO_DIR=$(CDPATH= cd -P "$(dirname "$0")/.." && pwd)
MIGRATION_SCRIPT=$REPO_DIR/run_before_05-migrate-zshrc.sh
TEST_ROOT=$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-zsh-migration.XXXXXX")

cleanup() {
	case $TEST_ROOT in
		*/dotfiles-zsh-migration.*) rm -rf -- "$TEST_ROOT" ;;
	esac
}

fail() {
	printf 'FAIL: %s\n' "$*" >&2
	exit 1
}

run_migration() {
	DOTFILES_HOME=$1 DOTFILES_CONFIG_HOME=$2 sh "$MIGRATION_SCRIPT"
}

trap cleanup EXIT HUP INT TERM

# A clean machine is left untouched.
CLEAN_HOME=$TEST_ROOT/clean-home
CLEAN_CONFIG=$TEST_ROOT/clean-config
mkdir -p "$CLEAN_HOME"
run_migration "$CLEAN_HOME" "$CLEAN_CONFIG"
[ ! -e "$CLEAN_CONFIG/zsh/local.zsh" ] || fail "clean machine created local.zsh"

# An existing .zshrc is preserved, migrated, backed up, and not duplicated.
EXISTING_HOME=$TEST_ROOT/existing-home
EXISTING_CONFIG=$TEST_ROOT/existing-config
mkdir -p "$EXISTING_HOME" "$EXISTING_CONFIG/zsh"
printf '%s\n' 'export MACHINE_ONLY=1' >"$EXISTING_HOME/.zshrc"
printf '%s\n' 'alias local-only=true' >"$EXISTING_CONFIG/zsh/local.zsh"
run_migration "$EXISTING_HOME" "$EXISTING_CONFIG"

[ "$(sed -n '1p' "$EXISTING_CONFIG/zsh/local.zsh")" = '# chezmoi: migrated-zshrc' ] || \
	fail "migration marker missing"
grep -Fqx 'export MACHINE_ONLY=1' "$EXISTING_CONFIG/zsh/local.zsh" || \
	fail "existing .zshrc content missing"
grep -Fqx 'alias local-only=true' "$EXISTING_CONFIG/zsh/local.zsh" || \
	fail "existing local.zsh content missing"
[ "$(cat "$EXISTING_HOME/.zshrc")" = 'export MACHINE_ONLY=1' ] || \
	fail "existing .zshrc changed before chezmoi apply"
BACKUP_COUNT=$(find "$EXISTING_CONFIG/zsh/backups" -type f -name 'zshrc.*' | wc -l | tr -d ' ')
[ "$BACKUP_COUNT" = 1 ] || fail "expected one backup, found $BACKUP_COUNT"

run_migration "$EXISTING_HOME" "$EXISTING_CONFIG"
BACKUP_COUNT=$(find "$EXISTING_CONFIG/zsh/backups" -type f -name 'zshrc.*' | wc -l | tr -d ' ')
[ "$BACKUP_COUNT" = 1 ] || fail "migration was not idempotent"
[ "$(grep -Fxc 'export MACHINE_ONLY=1' "$EXISTING_CONFIG/zsh/local.zsh")" = 1 ] || \
	fail "existing content was duplicated"

# A managed .zshrc is never migrated.
MANAGED_HOME=$TEST_ROOT/managed-home
MANAGED_CONFIG=$TEST_ROOT/managed-config
mkdir -p "$MANAGED_HOME"
printf '%s\n' '# chezmoi: managed-zshrc' >"$MANAGED_HOME/.zshrc"
run_migration "$MANAGED_HOME" "$MANAGED_CONFIG"
[ ! -e "$MANAGED_CONFIG/zsh/local.zsh" ] || fail "managed .zshrc was migrated"

# Dry-run reports work without changing the destination.
DRY_HOME=$TEST_ROOT/dry-home
DRY_CONFIG=$TEST_ROOT/dry-config
mkdir -p "$DRY_HOME"
printf '%s\n' 'export DRY_RUN_ONLY=1' >"$DRY_HOME/.zshrc"
DOTFILES_DRY_RUN=1 DOTFILES_HOME=$DRY_HOME DOTFILES_CONFIG_HOME=$DRY_CONFIG \
	sh "$MIGRATION_SCRIPT" >/dev/null
[ ! -e "$DRY_CONFIG/zsh/local.zsh" ] || fail "dry-run changed local config"

# The shared entrypoint treats migrated content as the complete configuration.
MIGRATED_ZDOTDIR=$TEST_ROOT/migrated-zdotdir
mkdir -p "$MIGRATED_ZDOTDIR"
printf '%s\n' '# chezmoi: migrated-zshrc' 'export MIGRATED_CONFIG_LOADED=1' \
	>"$MIGRATED_ZDOTDIR/local.zsh"
ZDOTDIR=$MIGRATED_ZDOTDIR ZSH=$TEST_ROOT/missing-oh-my-zsh \
	zsh -f -c 'source "$1"; [ "$MIGRATED_CONFIG_LOADED" = 1 ]; [ -z "${ZSH_THEME:-}" ]' \
	test-zsh "$REPO_DIR/dot_zshrc" || fail "migrated config did not replace shared defaults"

# A normal local file is layered after the portable shared defaults.
LAYERED_ZDOTDIR=$TEST_ROOT/layered-zdotdir
mkdir -p "$LAYERED_ZDOTDIR"
printf '%s\n' 'export LOCAL_OVERRIDE_LOADED=1' >"$LAYERED_ZDOTDIR/local.zsh"
ZDOTDIR=$LAYERED_ZDOTDIR ZSH=$TEST_ROOT/missing-oh-my-zsh \
	zsh -f -c 'source "$1"; [ "$LOCAL_OVERRIDE_LOADED" = 1 ]; [ "$ZSH_THEME" = ys ]' \
	test-zsh "$REPO_DIR/dot_zshrc" || fail "normal local config was not layered"

printf 'Zsh migration tests passed\n'
