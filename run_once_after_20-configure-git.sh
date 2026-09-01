#!/bin/sh

set -eu

DEFAULT_LG="log --color --graph --pretty=format:'%C(bold yellow)%h%Creset -%C(auto)%d%Creset %s %C(green)(%cr) %C(bold cyan)<%an>%Creset' --abbrev-commit"

command -v git >/dev/null 2>&1 || {
	printf 'chezmoi: git is required to configure Git defaults\n' >&2
	exit 1
}

set_if_missing() {
	KEY=$1
	DEFAULT_VALUE=$2
	STATUS=0
	CURRENT_VALUE=$(git config --global --get "$KEY" 2>/dev/null) || STATUS=$?

	case "$STATUS" in
	0)
		if [ -n "$CURRENT_VALUE" ]; then
			return
		fi
		;;
	1) ;;
	*)
		printf 'chezmoi: cannot read global Git setting %s\n' "$KEY" >&2
		exit "$STATUS"
		;;
	esac

	git config --global "$KEY" "$DEFAULT_VALUE"
	printf 'Configured default Git setting: %s\n' "$KEY"
}

set_if_missing user.name rensilin
set_if_missing user.email scgyrsl@gmail.com
set_if_missing alias.lg "$DEFAULT_LG"
