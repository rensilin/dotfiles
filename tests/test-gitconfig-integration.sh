#!/bin/sh

set -eu

ROOT=$(CDPATH= cd -P "$(dirname "$0")/.." && pwd)
SCRIPT="$ROOT/run_once_after_20-configure-git.sh"
TEST_DIR=$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-gitconfig-test.XXXXXX")
DEFAULT_LG="log --color --graph --pretty=format:'%C(bold yellow)%h%Creset -%C(auto)%d%Creset %s %C(green)(%cr) %C(bold cyan)<%an>%Creset' --abbrev-commit"

cleanup() {
	rm -rf -- "$TEST_DIR"
}

fail() {
	printf 'FAIL: %s\n' "$*" >&2
	exit 1
}

assert_global_value() {
	HOME_DIR=$1
	KEY=$2
	EXPECTED=$3
	ACTUAL=$(HOME="$HOME_DIR" XDG_CONFIG_HOME="$HOME_DIR/.config" \
		GIT_CONFIG_NOSYSTEM=1 git config --global --get "$KEY") || fail "$KEY is missing"
	[ "$ACTUAL" = "$EXPECTED" ] || fail "$KEY: expected '$EXPECTED', got '$ACTUAL'"
}

configure() {
	HOME_DIR=$1
	mkdir -p "$HOME_DIR/.config"
	HOME="$HOME_DIR" XDG_CONFIG_HOME="$HOME_DIR/.config" \
		GIT_CONFIG_NOSYSTEM=1 sh "$SCRIPT"
}

trap cleanup EXIT HUP INT TERM
unset GIT_CONFIG_GLOBAL GIT_CONFIG_SYSTEM

EMPTY_HOME="$TEST_DIR/home-empty"
configure "$EMPTY_HOME"
assert_global_value "$EMPTY_HOME" user.name rensilin
assert_global_value "$EMPTY_HOME" user.email scgyrsl@gmail.com
assert_global_value "$EMPTY_HOME" alias.lg "$DEFAULT_LG"
HOME="$EMPTY_HOME" XDG_CONFIG_HOME="$EMPTY_HOME/.config" GIT_CONFIG_NOSYSTEM=1 \
	GIT_PAGER=cat git -C "$ROOT" --no-pager lg -1 >/dev/null

EXISTING_HOME="$TEST_DIR/home-existing"
mkdir -p "$EXISTING_HOME"
cat >"$EXISTING_HOME/.gitconfig" <<'EOF'
[user]
	name = existing-user
	email = existing@example.com
[alias]
	lg = log --oneline
[core]
	editor = vim
EOF
cp "$EXISTING_HOME/.gitconfig" "$TEST_DIR/existing-before"
configure "$EXISTING_HOME"
cmp -s "$TEST_DIR/existing-before" "$EXISTING_HOME/.gitconfig" || \
	fail 'complete existing config was modified'

PARTIAL_HOME="$TEST_DIR/home-partial"
mkdir -p "$PARTIAL_HOME"
cat >"$PARTIAL_HOME/.gitconfig" <<'EOF'
[user]
	name = existing-user
EOF
configure "$PARTIAL_HOME"
assert_global_value "$PARTIAL_HOME" user.name existing-user
assert_global_value "$PARTIAL_HOME" user.email scgyrsl@gmail.com
assert_global_value "$PARTIAL_HOME" alias.lg "$DEFAULT_LG"

cp "$PARTIAL_HOME/.gitconfig" "$TEST_DIR/partial-before-second-run"
configure "$PARTIAL_HOME"
cmp -s "$TEST_DIR/partial-before-second-run" "$PARTIAL_HOME/.gitconfig" || \
	fail 'second run was not idempotent'

printf 'Git config integration tests passed\n'
