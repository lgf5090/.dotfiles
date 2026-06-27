if (( $+commands[fd] )); then
  export FZF_DEFAULT_COMMAND='fd --type f --hidden --strip-cwd-prefix'
else
  export FZF_DEFAULT_COMMAND='find . -type f'
fi

export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_DEFAULT_OPTS='--height=60% --layout=reverse --border=rounded --preview-window=right:65%:wrap:border-left'
: "${ZSH_FZF_CTRL_F:=1}"

if (( $+commands[bat] )); then
  export _FZF_PREVIEW_CMD='bat --color=always --style=plain,numbers --line-range=:500 {}'
else
  export _FZF_PREVIEW_CMD='sed -n "1,200p" {} 2>/dev/null'
fi
export FZF_CTRL_T_OPTS="--preview '$_FZF_PREVIEW_CMD'"

_fzf_load_shell_integration() {
  (( ${+__zsh_fzf_loaded} )) && return 0
  typeset -g __zsh_fzf_loaded=1

  local _fzf_dir _fzf_ver
  local -a _fzf_dirs
  _fzf_dirs=(
    "${commands[fzf]:A:h:h}/shell"
    "${HOMEBREW_PREFIX:+$HOMEBREW_PREFIX/opt/fzf/shell}"
    /home/linuxbrew/.linuxbrew/opt/fzf/shell
    /opt/homebrew/opt/fzf/shell
    /usr/local/opt/fzf/shell
    /usr/share/fzf
    /usr/share/doc/fzf/examples
  )

  for _fzf_dir in "${_fzf_dirs[@]}"; do
    [[ -r $_fzf_dir/key-bindings.zsh || -r $_fzf_dir/completion.zsh ]] || continue
    source "$_fzf_dir/key-bindings.zsh" 2>/dev/null
    source "$_fzf_dir/completion.zsh" 2>/dev/null
    return 0
  done

  _fzf_ver=${$(fzf --version 2>/dev/null)%% *}
  if _zver_ge "$_fzf_ver" "0.48.0"; then
    source <(fzf --zsh)
  fi
}

if (( $+commands[fzf] )) && [[ -o interactive && -t 0 && -t 1 ]]; then
  _fzf_file_no_hidden() {
    local result
    if (( $+commands[fd] )); then
      result=$(fd --type f --strip-cwd-prefix | fzf --preview "$_FZF_PREVIEW_CMD")
    else
      result=$(find . -type f ! -path '*/.*' | sed 's#^\./##' | fzf --preview "$_FZF_PREVIEW_CMD")
    fi
    [[ -n $result ]] && LBUFFER+="$result"
    zle reset-prompt
  }
  zle -N _fzf_file_no_hidden

  case ${ZSH_FZF_CTRL_F:-1} in
    1|yes|true|on)
      bindkey -M emacs '^F' _fzf_file_no_hidden
      bindkey -M viins '^F' _fzf_file_no_hidden
      bindkey -M vicmd '^F' _fzf_file_no_hidden
      ;;
  esac

  case ${ZSH_FZF_LOAD:-defer} in
    none|0|no|false) ;;
    sync|eager|1|yes|true)
      _fzf_load_shell_integration
      ;;
    *)
      autoload -Uz add-zle-hook-widget
      _fzf_load_deferred() {
        add-zle-hook-widget -d zle-line-init _fzf_load_deferred 2>/dev/null
        _fzf_load_shell_integration
        zle reset-prompt 2>/dev/null || true
      }
      add-zle-hook-widget zle-line-init _fzf_load_deferred 2>/dev/null \
        || _fzf_load_shell_integration
      ;;
  esac
fi
