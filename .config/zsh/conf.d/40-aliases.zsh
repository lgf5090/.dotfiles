case $SHELLS_OS in
  linux|wsl|cygwin|windows) alias ls='ls --color=auto' ;;
  macos|freebsd) alias ls='ls -G' ;;
esac

alias ll='ls -alFh'
alias la='ls -A'
alias l='ls -CF'
alias lt='ls -alFht'

alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'

alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias md='mkdir -p'
alias now='date +%Y-%m-%dT%H:%M:%S%z'
alias cls='clear'
alias reload='source "$ZSH_CONFIG_DIR/config.zsh"'

alias nvl='NVIM_APPNAME=nvim-lite nvim'
alias nvd='NVIM_APPNAME=nvim-dev nvim'
alias nvlz='NVIM_APPNAME=nvim-lazy nvim'

# alias dotfiles='/usr/bin/git --git-dir="$HOME/.dotfiles/" --work-tree="$HOME"'
alias dotfiles='git --git-dir="$HOME/.dotfiles/" --work-tree="$HOME"'