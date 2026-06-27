[[ -o interactive && -z ${SHELLS_NO_PROMPT:-} ]] || return 0

if (( $+commands[starship] )); then
  eval "$(starship init zsh)"
  return 0
fi

(( $+commands[git] )) && typeset -g __zprompt_has_git=1
setopt PROMPT_SUBST

typeset -g __zprompt_extra='' __zprompt_rc=''

__zprompt_precmd() {
  local rc=$?
  local d branch dirty

  (( rc != 0 )) && __zprompt_rc=" %F{red}[$rc]%f" || __zprompt_rc=''

  if [[ -n $VIRTUAL_ENV ]]; then
    __zprompt_extra=" %F{cyan}(${VIRTUAL_ENV:t})%f"
  elif [[ -n $CONDA_DEFAULT_ENV && $CONDA_DEFAULT_ENV != base ]]; then
    __zprompt_extra=" %F{cyan}($CONDA_DEFAULT_ENV)%f"
  else
    __zprompt_extra=''
  fi

  if (( ${+__zprompt_has_git} )); then
    d=$PWD
    while [[ -n $d && $d != / ]]; do
      if [[ -e $d/.git ]]; then
        branch=$(git symbolic-ref --short HEAD 2>/dev/null) \
          || branch=$(git rev-parse --short HEAD 2>/dev/null)
        if [[ -n $branch ]]; then
          dirty=''
          git diff-index --quiet HEAD -- 2>/dev/null || dirty='*'
          __zprompt_extra+=" %F{magenta}${branch}${dirty}%f"
        fi
        break
      fi
      d=${d%/*}
    done
  fi
}

if [[ -z ${precmd_functions[(r)__zprompt_precmd]} ]]; then
  precmd_functions+=(__zprompt_precmd)
fi

PROMPT=$'%F{8}[%D{%H:%M:%S}]%f %F{green}%n%F{15}@%m%f %F{blue}[%~]%f${__zprompt_extra}${__zprompt_rc}\n%F{cyan}$%f '
