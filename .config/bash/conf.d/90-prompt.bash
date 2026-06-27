[[ $- == *i* && -z ${SHELLS_NO_PROMPT:-} ]] || return 0

__bash_starship=
for __bash_starship_candidate in \
  "${STARSHIP_EXE:-}" \
  "$HOME/.local/bin/starship" \
  /home/linuxbrew/.linuxbrew/bin/starship \
  "$HOME/.linuxbrew/bin/starship" \
  /opt/homebrew/bin/starship \
  /usr/local/bin/starship \
  /usr/bin/starship
do
  [[ -n $__bash_starship_candidate && -x $__bash_starship_candidate ]] || continue
  __bash_starship=$__bash_starship_candidate
  break
done
unset __bash_starship_candidate

if [[ -z $__bash_starship && ${BASH_STARSHIP_DISCOVERY:-0} == 1 ]]; then
  __bash_starship=$(command -v starship 2>/dev/null || :)
fi

if [[ -n $__bash_starship ]]; then
  eval "$("$__bash_starship" init bash)"
  unset __bash_starship
  return 0
fi
unset __bash_starship

__bash_prompt_git=
for __bash_prompt_git_candidate in \
  "${GIT_EXE:-}" \
  /home/linuxbrew/.linuxbrew/bin/git \
  "$HOME/.linuxbrew/bin/git" \
  /opt/homebrew/bin/git \
  /usr/local/bin/git \
  /usr/bin/git
do
  [[ -n $__bash_prompt_git_candidate && -x $__bash_prompt_git_candidate ]] || continue
  __bash_prompt_git=$__bash_prompt_git_candidate
  break
done
unset __bash_prompt_git_candidate

if [[ -z $__bash_prompt_git && ${BASH_GIT_DISCOVERY:-0} == 1 ]]; then
  __bash_prompt_git=$(command -v git 2>/dev/null || :)
fi

__bash_prompt_extra=
__bash_prompt_rc=
__bash_prompt_c_red=$'\001\e[31m\002'
__bash_prompt_c_magenta=$'\001\e[35m\002'
__bash_prompt_c_cyan=$'\001\e[36m\002'
__bash_prompt_c_reset=$'\001\e[0m\002'

_bash_prompt_update() {
  local rc=$?
  local d branch dirty

  if (( rc != 0 )); then
    __bash_prompt_rc=" ${__bash_prompt_c_red}[$rc]${__bash_prompt_c_reset}"
  else
    __bash_prompt_rc=
  fi

  if [[ -n $VIRTUAL_ENV ]]; then
    __bash_prompt_extra=" ${__bash_prompt_c_cyan}(${VIRTUAL_ENV##*/})${__bash_prompt_c_reset}"
  elif [[ -n $CONDA_DEFAULT_ENV && $CONDA_DEFAULT_ENV != base ]]; then
    __bash_prompt_extra=" ${__bash_prompt_c_cyan}($CONDA_DEFAULT_ENV)${__bash_prompt_c_reset}"
  else
    __bash_prompt_extra=
  fi

  if [[ -n $__bash_prompt_git ]]; then
    d=$PWD
    while [[ -n $d && $d != / ]]; do
      if [[ -e $d/.git ]]; then
        branch=$("$__bash_prompt_git" symbolic-ref --short HEAD 2>/dev/null) \
          || branch=$("$__bash_prompt_git" rev-parse --short HEAD 2>/dev/null)
        if [[ -n $branch ]]; then
          dirty=
          "$__bash_prompt_git" diff-index --quiet HEAD -- 2>/dev/null || dirty='*'
          __bash_prompt_extra+=" ${__bash_prompt_c_magenta}${branch}${dirty}${__bash_prompt_c_reset}"
        fi
        break
      fi
      d=${d%/*}
    done
  fi
}

_bprompt_add _bash_prompt_update

PS1='\[\e[90m\][\t]\[\e[0m\] \[\e[32m\]\u\[\e[97m\]@\h\[\e[0m\] \[\e[34m\][\w]\[\e[0m\]${__bash_prompt_extra}${__bash_prompt_rc}\n\[\e[36m\]\$\[\e[0m\] '
