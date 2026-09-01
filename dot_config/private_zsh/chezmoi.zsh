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
zsh_omz_already_loaded=$+functions[omz]

if (( ! zsh_omz_already_loaded )); then
	if (( ! ${+plugins} )); then
		plugins=(git)
	fi
fi

zsh_local_config=${XDG_CONFIG_HOME:-$HOME/.config}/zsh/local.zsh
if [[ -r $zsh_local_config ]]; then
	source $zsh_local_config
fi

# local.zsh may set machine-specific values, but the shared theme wins. When
# Oh My Zsh was initialized earlier by the machine-owned .zshrc, re-source the
# theme so the override changes the active prompt, not only the variable.
ZSH_THEME=ys
zsh_shared_theme_file=$ZSH/themes/$ZSH_THEME.zsh-theme
if (( zsh_omz_already_loaded )); then
	if [[ -r $zsh_shared_theme_file ]]; then
		source $zsh_shared_theme_file
	fi
elif [[ -r $ZSH/oh-my-zsh.sh ]]; then
	source $ZSH/oh-my-zsh.sh
elif (( ! $+functions[compdef] )); then
	autoload -Uz compinit
	compinit -i
fi
unset zsh_local_config zsh_shared_theme_file zsh_omz_already_loaded
