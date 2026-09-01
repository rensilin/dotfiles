#!/bin/sh

set -eu

ROOT=$(CDPATH= cd -P "$(dirname "$0")/.." && pwd)
SCRIPT="$ROOT/modify_dot_gitconfig"
TEST_DIR=$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-gitconfig-test.XXXXXX")
DEFAULT_LG="log --color --graph --pretty=format:'%C(bold yellow)%h%Creset -%C(auto)%d%Creset %s %C(green)(%cr) %C(bold cyan)<%an>%Creset' --abbrev-commit"

cleanup() {
	rm -rf -- "$TEST_DIR"
}

fail() {
	printf 'FAIL: %s\n' "$*" >&2
	exit 1
}

assert_value() {
	FILE=$1
	KEY=$2
	EXPECTED=$3
	ACTUAL=$(git config --file "$FILE" --get "$KEY") || fail "$KEY is missing"
	[ "$ACTUAL" = "$EXPECTED" ] || fail "$KEY: expected '$EXPECTED', got '$ACTUAL'"
}

render() {
	HOME_DIR=$1
	INPUT=$2
	OUTPUT=$3
	mkdir -p "$HOME_DIR/.config"
	HOME="$HOME_DIR" XDG_CONFIG_HOME="$HOME_DIR/.config" \
		GIT_CONFIG_NOSYSTEM=1 sh "$SCRIPT" <"$INPUT" >"$OUTPUT"
}

trap cleanup EXIT HUP INT TERM
unset GIT_CONFIG_GLOBAL GIT_CONFIG_SYSTEM

EMPTY="$TEST_DIR/empty"
FIRST="$TEST_DIR/first"
: >"$EMPTY"
render "$TEST_DIR/home-empty" "$EMPTY" "$FIRST"
assert_value "$FIRST" user.name rensilin
assert_value "$FIRST" user.email scgyrsl@gmail.com
assert_value "$FIRST" alias.lg "$DEFAULT_LG"

EXISTING="$TEST_DIR/existing"
cat >"$EXISTING" <<'EOF'
[user]
	name = existing-user
	email = existing@example.com
[alias]
	lg = log --oneline
[core]
	editor = vim
EOF
UNCHANGED="$TEST_DIR/unchanged"
render "$TEST_DIR/home-existing" "$EXISTING" "$UNCHANGED"
cmp -s "$EXISTING" "$UNCHANGED" || fail 'complete existing config was modified'

PARTIAL="$TEST_DIR/partial"
cat >"$PARTIAL" <<'EOF'
[user]
	name = existing-user
EOF
COMPLETED="$TEST_DIR/completed"
render "$TEST_DIR/home-partial" "$PARTIAL" "$COMPLETED"
assert_value "$COMPLETED" user.name existing-user
assert_value "$COMPLETED" user.email scgyrsl@gmail.com
assert_value "$COMPLETED" alias.lg "$DEFAULT_LG"

SECOND="$TEST_DIR/second"
render "$TEST_DIR/home-idempotent" "$COMPLETED" "$SECOND"
cmp -s "$COMPLETED" "$SECOND" || fail 'second render was not idempotent'

printf 'Git config integration tests passed\n'
