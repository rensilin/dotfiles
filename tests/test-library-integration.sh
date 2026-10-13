#!/bin/sh

set -eu

REPO_DIR=$(CDPATH= cd -P "$(dirname "$0")/.." && pwd)
TEST_ROOT=$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-library-integration.XXXXXX")

cleanup() {
	rm -rf -- "$TEST_ROOT"
}

fail() {
	printf 'FAIL: %s\n' "$*" >&2
	exit 1
}

trap cleanup EXIT HUP INT TERM

# Use the real source entries without unrelated scripts or external downloads.
SOURCE_DIR=$TEST_ROOT/source
mkdir -p "$SOURCE_DIR/dot_config"
cp "$REPO_DIR/.chezmoiignore" "$SOURCE_DIR/"
cp -R "$REPO_DIR/private_Library" "$REPO_DIR/.chezmoitemplates" "$SOURCE_DIR/"
cp -R "$REPO_DIR/dot_config/Code" "$SOURCE_DIR/dot_config/"

run_chezmoi() {
	chezmoi --config /dev/null --config-format toml --source "$SOURCE_DIR" \
		--destination "$DEST_DIR" --persistent-state "$TEST_ROOT/state.boltdb" \
		--override-data "{\"chezmoi\":{\"os\":\"$TARGET_OS\",\"homeDir\":\"$DEST_DIR\"}}" "$@"
}

# Directory-only apply reproduces the empty Library even without VS Code.
for TARGET_OS in linux windows; do
	DEST_DIR=$TEST_ROOT/$TARGET_OS
	mkdir -p "$DEST_DIR"
	run_chezmoi apply --include dirs
	[ ! -e "$DEST_DIR/Library" ] || fail "$TARGET_OS apply created Library"
	MANAGED=$(run_chezmoi managed --include dirs,files)
	if printf '%s\n' "$MANAGED" | grep -Eq '^Library(/|$)'; then
		fail "$TARGET_OS still manages Library entries"
	fi
done

# Linux must retain its own VS Code configuration when the app directory exists.
TARGET_OS=linux
DEST_DIR=$TEST_ROOT/linux
mkdir -p "$DEST_DIR/.config/Code/User"
MANAGED=$(run_chezmoi managed --include dirs,files)
printf '%s\n' "$MANAGED" | grep -Fxq '.config/Code/User/settings.json' || \
	fail 'Linux VS Code settings are no longer managed'

# macOS must retain the native Library path for installed VS Code.
TARGET_OS=darwin
DEST_DIR=$TEST_ROOT/darwin
mkdir -p "$DEST_DIR/Library/Application Support/Code/User"
MANAGED=$(run_chezmoi managed --include dirs,files)
printf '%s\n' "$MANAGED" | grep -Fxq 'Library/Application Support/Code/User/settings.json' || \
	fail 'macOS VS Code settings are no longer managed'

printf 'Library integration tests passed\n'
