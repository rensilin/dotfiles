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

# If the machine-owned .zshrc already initialized Oh My Zsh, reload the shared
# theme so the active prompt is replaced as well as the variable.
LOADED_ZSH=$TEST_ROOT/loaded-oh-my-zsh
mkdir -p "$LOADED_ZSH/themes"
printf '%s\n' 'export LOADED_THEME=$ZSH_THEME' >"$LOADED_ZSH/themes/ys.zsh-theme"
ZSH=$LOADED_ZSH ZSH_THEME=machine-theme \
	zsh -f -c 'omz() { :; }; source "$1"; [ "$ZSH_THEME" = ys ]; [ "$LOADED_THEME" = ys ]' \
	test-zsh "$SHARED_CONFIG" || fail "shared theme did not replace loaded machine theme"

printf 'Zsh integration tests passed\n'
