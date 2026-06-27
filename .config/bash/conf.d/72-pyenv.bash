if [[ -n ${PYENV_ROOT:-} ]]; then
  _bpath_prepend "$PYENV_ROOT/bin"
fi

__bash_pyenv=
if [[ -n ${PYENV_ROOT:-} && -x $PYENV_ROOT/bin/pyenv ]]; then
  __bash_pyenv=$PYENV_ROOT/bin/pyenv
elif [[ ${BASH_PYENV_DISCOVERY:-0} == 1 ]]; then
  __bash_pyenv=$(command -v pyenv 2>/dev/null || :)
fi

if [[ -n $__bash_pyenv ]]; then
  __bash_pyenv_init=$("$__bash_pyenv" init - bash 2>/dev/null || "$__bash_pyenv" init - 2>/dev/null || :)
  [[ -n $__bash_pyenv_init ]] && eval "$__bash_pyenv_init"
  unset __bash_pyenv_init

  __bash_pyenv_virtualenv_init=$("$__bash_pyenv" virtualenv-init - bash 2>/dev/null || "$__bash_pyenv" virtualenv-init - 2>/dev/null || :)
  [[ -n $__bash_pyenv_virtualenv_init ]] && eval "$__bash_pyenv_virtualenv_init"
  unset __bash_pyenv_virtualenv_init
fi
unset __bash_pyenv
