if [[ -n ${FNM_DIR:-} ]]; then
  _zpath_prepend "$FNM_DIR"
fi

: "${ZSH_FNM_ACTIVATE:=default}"

case ${ZSH_FNM_ACTIVATE:l} in
  full|use-on-cd|1|yes|true)
    if (( $+commands[fnm] )); then
      __zsh_fnm_env=$(fnm env --use-on-cd --shell zsh 2>/dev/null || :)
      [[ -n $__zsh_fnm_env ]] && eval "$__zsh_fnm_env"
      unset __zsh_fnm_env
    fi
    ;;
  env)
    if (( $+commands[fnm] )); then
      __zsh_fnm_env=$(fnm env --shell zsh 2>/dev/null || :)
      [[ -n $__zsh_fnm_env ]] && eval "$__zsh_fnm_env"
      unset __zsh_fnm_env
    fi
    ;;
  none|0|no|false) ;;
  *)
    [[ -n ${FNM_DIR:-} ]] && _zpath_prepend "$FNM_DIR/aliases/default/bin"
    ;;
esac
