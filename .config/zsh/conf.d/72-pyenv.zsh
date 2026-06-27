if [[ -n ${PYENV_ROOT:-} ]]; then
  _zpath_prepend "$PYENV_ROOT/bin"
fi

__zsh_pyenv=
if [[ -n ${PYENV_ROOT:-} && -x $PYENV_ROOT/bin/pyenv ]]; then
  __zsh_pyenv=$PYENV_ROOT/bin/pyenv
elif [[ ${ZSH_PYENV_DISCOVERY:-0} == 1 ]] && (( $+commands[pyenv] )); then
  __zsh_pyenv=${commands[pyenv]}
fi

if [[ -n $__zsh_pyenv ]]; then
  __zsh_pyenv_init=$("$__zsh_pyenv" init - zsh 2>/dev/null || "$__zsh_pyenv" init - 2>/dev/null || :)
  [[ -n $__zsh_pyenv_init ]] && eval "$__zsh_pyenv_init"
  unset __zsh_pyenv_init

  __zsh_pyenv_virtualenv_init=$("$__zsh_pyenv" virtualenv-init - zsh 2>/dev/null || "$__zsh_pyenv" virtualenv-init - 2>/dev/null || :)
  [[ -n $__zsh_pyenv_virtualenv_init ]] && eval "$__zsh_pyenv_virtualenv_init"
  unset __zsh_pyenv_virtualenv_init
fi
unset __zsh_pyenv
