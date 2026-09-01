# Shared Zsh configuration for macOS and Linux. Its parent directory is private
# because the unmanaged local.zsh beside it may contain machine-only values.
# Keep machine-specific paths, environment variables, and credentials in the
# unmanaged local.zsh file loaded at the end of this file.

if [[ -z ${EDITOR:-} ]]; then
	if (( $+commands[nvim] )); then
		export EDITOR=nvim
	else
		export EDITOR=vi
	fi
fi

if [[ -z ${VISUAL:-} ]]; then
	export VISUAL=$EDITOR
fi

if (( $+commands[nvim] )) && ! alias vim >/dev/null 2>&1; then
	alias vim=nvim
fi

# Oh My Zsh is managed by chezmoi as an external. Prevent its own updater from
# changing that managed checkout, and do not initialize it twice when an
# existing machine-owned .zshrc already loaded it.
if (( ! $+functions[omz] )); then
	if [[ -z ${ZSH:-} ]]; then
		ZSH=$HOME/.oh-my-zsh
	fi
	export ZSH
	zstyle ':omz:update' mode disabled

	if [[ -z ${ZSH_THEME+x} ]]; then
		ZSH_THEME=ys
	fi
	if (( ! ${+plugins} )); then
		plugins=(git)
	fi

	if [[ -r $ZSH/oh-my-zsh.sh ]]; then
		source $ZSH/oh-my-zsh.sh
	elif (( ! $+functions[compdef] )); then
		autoload -Uz compinit
		compinit -i
	fi
fi

zsh_local_config=${XDG_CONFIG_HOME:-$HOME/.config}/zsh/local.zsh
zsh_local_first_line=
if [[ -r $zsh_local_config ]]; then
	IFS= read -r zsh_local_first_line < $zsh_local_config || true
	# Older versions of this repository migrated the complete original .zshrc
	# here. modify_dot_zshrc restores that content, so do not source it twice.
	if [[ $zsh_local_first_line != '# chezmoi: migrated-zshrc' ]]; then
		source $zsh_local_config
	fi
fi
unset zsh_local_config zsh_local_first_line
