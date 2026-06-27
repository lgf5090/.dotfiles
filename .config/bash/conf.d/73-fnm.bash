if [[ -n ${FNM_DIR:-} ]]; then
  _bpath_prepend "$FNM_DIR"
fi

: "${BASH_FNM_ACTIVATE:=default}"

case ${BASH_FNM_ACTIVATE,,} in
  full|use-on-cd|1|yes|true)
    if command -v fnm >/dev/null 2>&1; then
      __bash_fnm_env=$(fnm env --use-on-cd --shell bash 2>/dev/null || :)
      [[ -n $__bash_fnm_env ]] && eval "$__bash_fnm_env"
      unset __bash_fnm_env
    fi
    ;;
  env)
    if command -v fnm >/dev/null 2>&1; then
      __bash_fnm_env=$(fnm env --shell bash 2>/dev/null || :)
      [[ -n $__bash_fnm_env ]] && eval "$__bash_fnm_env"
      unset __bash_fnm_env
    fi
    ;;
  none|0|no|false) ;;
  *)
    [[ -n ${FNM_DIR:-} ]] && _bpath_prepend "$FNM_DIR/aliases/default/bin"
    ;;
esac
