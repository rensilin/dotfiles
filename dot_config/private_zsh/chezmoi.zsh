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
# existing machine-owned .zshrc already loaded it. The shared theme is
# intentionally authoritative across machines.
if [[ -z ${ZSH:-} ]]; then
	ZSH=$HOME/.oh-my-zsh
fi
export ZSH
zstyle ':omz:update' mode disabled
ZSH_THEME=ys

if (( ! $+functions[omz] )); then
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

# local.zsh may set other machine-specific values, but the shared theme wins.
# Re-source it when Oh My Zsh was initialized earlier by the machine-owned
# .zshrc so the override changes the active prompt, not only the variable.
ZSH_THEME=ys
zsh_shared_theme_file=$ZSH/themes/$ZSH_THEME.zsh-theme
if (( $+functions[omz] )) && [[ -r $zsh_shared_theme_file ]]; then
	source $zsh_shared_theme_file
fi
unset zsh_local_config zsh_local_first_line zsh_shared_theme_file
