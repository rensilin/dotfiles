#!/bin/sh

set -eu

# Explicit package-management helper used by install.sh or run manually. It is
# not a chezmoi run script, so applying configuration never invokes sudo or
# changes system packages unexpectedly.

DRY_RUN=${DOTFILES_DRY_RUN:-0}
TEMP_DIR=""

log() {
	printf '\n==> %s\n' "$*"
}

die() {
	printf '\nerror: %s\n' "$*" >&2
	exit 1
}

cleanup() {
	if [ -n "$TEMP_DIR" ] && [ -d "$TEMP_DIR" ]; then
		rm -rf -- "$TEMP_DIR"
	fi
}

trap cleanup EXIT HUP INT TERM

run() {
	if [ "$DRY_RUN" = "1" ]; then
		printf '+ '
		printf '%s ' "$@"
		printf '\n'
		return 0
	fi
	"$@"
}

run_as_root() {
	if [ "$(id -u)" -eq 0 ]; then
		run "$@"
	elif command -v sudo >/dev/null 2>&1; then
		run sudo "$@"
	else
		die "system packages are missing and sudo is unavailable; install them manually or run as a user with sudo access"
	fi
}

install_homebrew() {
	if command -v brew >/dev/null 2>&1; then
		BREW=$(command -v brew)
		return
	fi

	command -v curl >/dev/null 2>&1 || die "curl is required to install Homebrew"
	log "Installing Homebrew"

	if [ "$DRY_RUN" = "1" ]; then
		printf '+ download and run the official Homebrew installer\n'
		BREW=brew
		return
	fi

	TEMP_DIR=$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-homebrew.XXXXXX")
	curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh -o "$TEMP_DIR/install.sh"
	NONINTERACTIVE=1 /bin/bash "$TEMP_DIR/install.sh"
	cleanup
	TEMP_DIR=""

	if [ -x /opt/homebrew/bin/brew ]; then
		BREW=/opt/homebrew/bin/brew
	elif [ -x /usr/local/bin/brew ]; then
		BREW=/usr/local/bin/brew
	else
		die "Homebrew was installed but brew was not found in a standard prefix"
	fi
}

install_macos_packages() {
	install_homebrew
	log "Installing macOS packages"
	run "$BREW" install chezmoi git neovim tmux ripgrep fd curl unzip
	PATH=$(dirname "$BREW"):$PATH
	export PATH
}

install_linux_packages() {
	if command -v pacman >/dev/null 2>&1; then
		log "Installing Arch Linux packages"
		run_as_root pacman -Syu --needed --noconfirm \
			base-devel ca-certificates chezmoi curl fd git gzip neovim ripgrep tar tmux unzip zsh
	elif command -v apt-get >/dev/null 2>&1; then
		log "Installing Debian/Ubuntu packages"
		run_as_root apt-get update
		run_as_root env DEBIAN_FRONTEND=noninteractive apt-get install -y \
			build-essential ca-certificates chezmoi curl fd-find git gzip neovim ripgrep tar tmux unzip zsh
	elif command -v dnf >/dev/null 2>&1; then
		log "Installing Fedora/RHEL packages"
		run_as_root dnf install -y \
			ca-certificates chezmoi curl fd-find gcc gcc-c++ git gzip make neovim ripgrep tar tmux unzip zsh
	elif command -v zypper >/dev/null 2>&1; then
		log "Installing openSUSE packages"
		run_as_root zypper --non-interactive install \
			ca-certificates chezmoi curl fd gcc gcc-c++ git gzip make neovim ripgrep tar tmux unzip zsh
	elif command -v apk >/dev/null 2>&1; then
		log "Installing Alpine Linux packages"
		run_as_root apk add --no-cache \
			bash build-base ca-certificates chezmoi curl fd git gzip neovim ripgrep tar tmux unzip zsh
	elif command -v xbps-install >/dev/null 2>&1; then
		log "Installing Void Linux packages"
		run_as_root xbps-install -Sy \
			base-devel ca-certificates chezmoi curl fd git gzip neovim ripgrep tar tmux unzip zsh
	else
		die "unsupported package manager; install chezmoi, git, curl, neovim, tmux, zsh, ripgrep, fd, unzip, and C build tools manually"
	fi
}

nvim_is_supported() {
	command -v nvim >/dev/null 2>&1 || return 1
	NVIM_VERSION=$(nvim --version 2>/dev/null | sed -n '1s/^NVIM v//p')
	NVIM_MAJOR=${NVIM_VERSION%%.*}
	NVIM_REST=${NVIM_VERSION#*.}
	NVIM_MINOR=${NVIM_REST%%.*}

	case "$NVIM_MAJOR:$NVIM_MINOR" in
		*[!0-9:]* | :* | *:) return 1 ;;
	esac

	[ "$NVIM_MAJOR" -gt 0 ] || [ "$NVIM_MINOR" -ge 11 ]
}

install_current_neovim_on_linux() {
	if nvim_is_supported; then
		return
	fi

	if [ "$DRY_RUN" = "1" ]; then
		log "Would install the current Neovim release if the packaged version is older than 0.11"
		return
	fi

	if ldd --version 2>&1 | grep -qi musl; then
		die "Neovim 0.11+ is required, but the installed musl-compatible package is older; upgrade the distribution package"
	fi

	case $(uname -m) in
		x86_64 | amd64) NVIM_ARCH=x86_64 ;;
		aarch64 | arm64) NVIM_ARCH=arm64 ;;
		*) die "Neovim 0.11+ is required and no official user-local binary is configured for $(uname -m)" ;;
	esac

	log "Installing the current Neovim release in the user profile"
	TEMP_DIR=$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-neovim.XXXXXX")
	NVIM_ARCHIVE="nvim-linux-$NVIM_ARCH.tar.gz"
	curl -fL "https://github.com/neovim/neovim/releases/latest/download/$NVIM_ARCHIVE" \
		-o "$TEMP_DIR/$NVIM_ARCHIVE"
	mkdir -p "$TEMP_DIR/extract" "$HOME/.local/bin" "$HOME/.local/opt"
	tar -xzf "$TEMP_DIR/$NVIM_ARCHIVE" -C "$TEMP_DIR/extract"

	NVIM_DEST="$HOME/.local/opt/nvim"
	if [ -e "$NVIM_DEST" ]; then
		NVIM_BACKUP="$NVIM_DEST.backup.$(date +%Y%m%d%H%M%S)"
		mv "$NVIM_DEST" "$NVIM_BACKUP"
		log "Previous user-local Neovim moved to $NVIM_BACKUP"
	fi
	mv "$TEMP_DIR/extract/nvim-linux-$NVIM_ARCH" "$NVIM_DEST"

	if [ -e "$HOME/.local/bin/nvim" ] && [ ! -L "$HOME/.local/bin/nvim" ]; then
		mv "$HOME/.local/bin/nvim" "$HOME/.local/bin/nvim.backup.$(date +%Y%m%d%H%M%S)"
	fi
	ln -sfn "$NVIM_DEST/bin/nvim" "$HOME/.local/bin/nvim"
	PATH=$HOME/.local/bin:$PATH
	export PATH

	cleanup
	TEMP_DIR=""
	nvim_is_supported || die "the user-local Neovim installation did not start successfully"
}

create_fd_compatibility_link() {
	if command -v fd >/dev/null 2>&1 || ! command -v fdfind >/dev/null 2>&1; then
		return
	fi
	log "Creating fd compatibility link for Debian/Ubuntu"
	run mkdir -p "$HOME/.local/bin"
	run ln -sfn "$(command -v fdfind)" "$HOME/.local/bin/fd"
}

verify_environment() {
	if [ "$DRY_RUN" = "1" ]; then
		return
	fi

	MISSING=""
	for COMMAND in chezmoi git nvim rg tmux zsh; do
		if ! command -v "$COMMAND" >/dev/null 2>&1; then
			MISSING="$MISSING $COMMAND"
		fi
	done
	if ! command -v fd >/dev/null 2>&1 && ! command -v fdfind >/dev/null 2>&1; then
		MISSING="$MISSING fd"
	fi
	[ -z "$MISSING" ] || die "required commands are still missing:$MISSING"

	log "Environment ready"
	printf 'Neovim: %s\n' "$(nvim --version | sed -n '1p')"
	printf 'tmux:    %s\n' "$(tmux -V)"
	printf 'Git:     %s\n' "$(git --version)"
}

if [ "${DOTFILES_SKIP_PACKAGES:-0}" = "1" ]; then
	log "Skipping package installation because DOTFILES_SKIP_PACKAGES=1"
	exit 0
fi

case $(uname -s) in
	Darwin) install_macos_packages ;;
	Linux)
		install_linux_packages
		install_current_neovim_on_linux
		;;
	*) die "unsupported operating system: $(uname -s)" ;;
esac

create_fd_compatibility_link
verify_environment
