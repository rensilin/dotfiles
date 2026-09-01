#!/bin/sh

set -eu

REPO_DIR=$(CDPATH= cd -P "$(dirname "$0")/.." && pwd)
MODIFIER=$REPO_DIR/modify_dot_zshrc
SHARED_CONFIG=$REPO_DIR/dot_config/private_zsh/chezmoi.zsh
TEST_ROOT=$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-zsh-integration.XXXXXX")

cleanup() {
	case $TEST_ROOT in
		*/dotfiles-zsh-integration.*) rm -rf -- "$TEST_ROOT" ;;
	esac
}

fail() {
	printf 'FAIL: %s\n' "$*" >&2
	exit 1
}

modify() {
	HOME=$1 XDG_CONFIG_HOME=$2 sh "$MODIFIER" <"$3" >"$4"
}

trap cleanup EXIT HUP INT TERM

# A clean machine receives only the small shared-config loader.
CLEAN_HOME=$TEST_ROOT/clean-home
CLEAN_CONFIG=$TEST_ROOT/clean-config
mkdir -p "$CLEAN_HOME" "$CLEAN_CONFIG"
: >"$TEST_ROOT/empty"
modify "$CLEAN_HOME" "$CLEAN_CONFIG" "$TEST_ROOT/empty" "$TEST_ROOT/clean-output"
grep -Fqx '# >>> chezmoi shared zsh >>>' "$TEST_ROOT/clean-output" || \
	fail "clean machine is missing loader marker"

# Existing machine-owned content is preserved, and a second pass is identical.
EXISTING_HOME=$TEST_ROOT/existing-home
EXISTING_CONFIG=$TEST_ROOT/existing-config
mkdir -p "$EXISTING_HOME" "$EXISTING_CONFIG"
printf '%s\n' 'export MACHINE_ONLY=1' 'alias local-only=true' >"$TEST_ROOT/existing"
modify "$EXISTING_HOME" "$EXISTING_CONFIG" "$TEST_ROOT/existing" "$TEST_ROOT/first-pass"
grep -Fqx 'export MACHINE_ONLY=1' "$TEST_ROOT/first-pass" || fail "existing export was lost"
grep -Fqx 'alias local-only=true' "$TEST_ROOT/first-pass" || fail "existing alias was lost"
[ "$(grep -Fxc '# >>> chezmoi shared zsh >>>' "$TEST_ROOT/first-pass")" = 1 ] || \
	fail "loader was not added exactly once"
modify "$EXISTING_HOME" "$EXISTING_CONFIG" "$TEST_ROOT/first-pass" "$TEST_ROOT/second-pass"
cmp -s "$TEST_ROOT/first-pass" "$TEST_ROOT/second-pass" || fail "modifier is not idempotent"

# A partially edited loader block fails safely instead of duplicating content.
printf '%s\n' '# >>> chezmoi shared zsh >>>' >"$TEST_ROOT/partial-block"
if modify "$EXISTING_HOME" "$EXISTING_CONFIG" \
	"$TEST_ROOT/partial-block" "$TEST_ROOT/partial-output" 2>/dev/null; then
	fail "incomplete loader block was accepted"
fi

# Upgrade from the previous layout by restoring the old .zshrc from local.zsh.
LEGACY_HOME=$TEST_ROOT/legacy-home
LEGACY_CONFIG=$TEST_ROOT/legacy-config
mkdir -p "$LEGACY_HOME" "$LEGACY_CONFIG/zsh"
printf '%s\n' '# chezmoi: managed-zshrc' 'old shared entrypoint' >"$TEST_ROOT/legacy-zshrc"
printf '%s\n' '# chezmoi: migrated-zshrc' \
	'# Preserved by chezmoi from the .zshrc that existed before apply.' \
	'export RESTORED_FROM_LEGACY=1' >"$LEGACY_CONFIG/zsh/local.zsh"
modify "$LEGACY_HOME" "$LEGACY_CONFIG" "$TEST_ROOT/legacy-zshrc" "$TEST_ROOT/legacy-output"
grep -Fqx 'export RESTORED_FROM_LEGACY=1' "$TEST_ROOT/legacy-output" || \
	fail "legacy .zshrc was not restored"
if grep -Fq 'old shared entrypoint' "$TEST_ROOT/legacy-output"; then
	fail "legacy managed entrypoint was retained"
fi

# Normal local overrides load after shared defaults; legacy migrated content is
# skipped because it has already been restored to .zshrc.
NORMAL_CONFIG=$TEST_ROOT/normal-config
mkdir -p "$NORMAL_CONFIG/zsh"
printf '%s\n' 'export LOCAL_OVERRIDE_LOADED=1' >"$NORMAL_CONFIG/zsh/local.zsh"
XDG_CONFIG_HOME=$NORMAL_CONFIG ZSH=$TEST_ROOT/missing-oh-my-zsh \
	zsh -f -c 'source "$1"; [ "$LOCAL_OVERRIDE_LOADED" = 1 ]; [ "$ZSH_THEME" = ys ]' \
	test-zsh "$SHARED_CONFIG" || fail "normal local override was not loaded"

MIGRATED_CONFIG=$TEST_ROOT/migrated-config
mkdir -p "$MIGRATED_CONFIG/zsh"
printf '%s\n' '# chezmoi: migrated-zshrc' 'export MUST_NOT_LOAD=1' \
	>"$MIGRATED_CONFIG/zsh/local.zsh"
XDG_CONFIG_HOME=$MIGRATED_CONFIG ZSH=$TEST_ROOT/missing-oh-my-zsh \
	zsh -f -c 'source "$1"; [ -z "${MUST_NOT_LOAD:-}" ]' \
	test-zsh "$SHARED_CONFIG" || fail "legacy migrated content loaded twice"

printf 'Zsh integration tests passed\n'
