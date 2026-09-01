# Shared Zsh configuration for macOS and Linux. Keep machine-specific paths,
# environment variables, and credentials in the machine-owned ~/.zshrc.

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
if [[ -z ${ZSH:-} ]]; then
	ZSH=$HOME/.oh-my-zsh
fi
export ZSH
zstyle ':omz:update' mode disabled
zsh_omz_already_loaded=$+functions[omz]
ZSH_THEME=ys

if (( ! zsh_omz_already_loaded )); then
	if (( ! ${+plugins} )); then
		plugins=(git)
	fi
fi

# If the machine-owned .zshrc initialized Oh My Zsh earlier, re-source the
# shared theme so the configured theme also changes the active prompt.
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
unset zsh_shared_theme_file zsh_omz_already_loaded
