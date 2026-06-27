if command -v fd >/dev/null 2>&1; then
  export FZF_DEFAULT_COMMAND='fd --type f --hidden --strip-cwd-prefix'
else
  export FZF_DEFAULT_COMMAND='find . -type f'
fi

: "${BASH_FZF_COMPLETION:=0}"
: "${BASH_FZF_KEY_BINDINGS:=1}"
: "${BASH_FZF_CTRL_F:=1}"
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_DEFAULT_OPTS='--height=60% --layout=reverse --border=rounded --preview-window=right:65%:wrap:border-left'

if command -v bat >/dev/null 2>&1; then
  export _FZF_PREVIEW_CMD='bat --color=always --style=plain,numbers --line-range=:500 {}'
else
  export _FZF_PREVIEW_CMD='sed -n "1,200p" {} 2>/dev/null'
fi
export FZF_CTRL_T_OPTS="--preview '$_FZF_PREVIEW_CMD'"

if command -v fzf >/dev/null 2>&1 && [[ $- == *i* && -t 0 && -t 1 ]]; then
  _fzf_dirs=(
    "${HOMEBREW_PREFIX:+$HOMEBREW_PREFIX/opt/fzf/shell}"
    /home/linuxbrew/.linuxbrew/opt/fzf/shell
    /opt/homebrew/opt/fzf/shell
    /usr/local/opt/fzf/shell
    /usr/share/fzf
    /usr/share/doc/fzf/examples
  )

  for _fzf_dir in "${_fzf_dirs[@]}"; do
    [[ -r "$_fzf_dir/key-bindings.bash" || -r "$_fzf_dir/completion.bash" ]] || continue
    case ${BASH_FZF_KEY_BINDINGS,,} in
      1|yes|true|on)
        [[ -r "$_fzf_dir/key-bindings.bash" ]] && source "$_fzf_dir/key-bindings.bash"
        ;;
    esac
    case ${BASH_FZF_COMPLETION,,} in
      1|yes|true|on)
        [[ -r "$_fzf_dir/completion.bash" ]] && source "$_fzf_dir/completion.bash"
        ;;
    esac
    _fzf_loaded=1
    break
  done

  if [[ -z ${_fzf_loaded:-} ]]; then
    _fzf_ver=$(fzf --version 2>/dev/null)
    _fzf_ver=${_fzf_ver%% *}
    if _bver_ge "$_fzf_ver" "0.48.0" && [[ ${BASH_FZF_KEY_BINDINGS,,} =~ ^(1|yes|true|on)$ ]]; then
      eval "$(fzf --bash)"
    fi
  fi
  unset _fzf_dirs _fzf_dir _fzf_loaded _fzf_ver

  _fzf_file_no_hidden() {
    local result
    if command -v fd >/dev/null 2>&1; then
      result=$(fd --type f --strip-cwd-prefix | fzf --preview "$_FZF_PREVIEW_CMD")
    else
      result=$(find . -type f ! -path '*/.*' | sed 's#^\./##' | fzf --preview "$_FZF_PREVIEW_CMD")
    fi
    [[ -z $result ]] && return 0

    READLINE_LINE="${READLINE_LINE:0:READLINE_POINT}$result${READLINE_LINE:READLINE_POINT}"
    READLINE_POINT=$(( READLINE_POINT + ${#result} ))
  }

  case ${BASH_FZF_CTRL_F,,} in
    1|yes|true|on)
      bind -m emacs-standard -x '"\C-f": _fzf_file_no_hidden'
      bind -m vi-insert -x '"\C-f": _fzf_file_no_hidden'
      bind -m vi-command -x '"\C-f": _fzf_file_no_hidden'
      ;;
  esac
fi
