for __bash_env_manager_spec in rbenv:RBENV_ROOT nodenv:NODENV_ROOT goenv:GOENV_ROOT; do
  __bash_env_manager=${__bash_env_manager_spec%%:*}
  __bash_env_root_var=${__bash_env_manager_spec#*:}
  __bash_env_root=${!__bash_env_root_var:-}
  __bash_env_manager_exe=

  if [[ -n $__bash_env_root && -x $__bash_env_root/bin/$__bash_env_manager ]]; then
    __bash_env_manager_exe=$__bash_env_root/bin/$__bash_env_manager
  elif [[ ${BASH_ENV_MANAGER_DISCOVERY:-0} == 1 ]]; then
    __bash_env_manager_exe=$(command -v "$__bash_env_manager" 2>/dev/null || :)
  fi

  if [[ -n $__bash_env_manager_exe ]]; then
    __bash_env_manager_init=$("$__bash_env_manager_exe" init - bash 2>/dev/null || "$__bash_env_manager_exe" init - 2>/dev/null || :)
    [[ -n $__bash_env_manager_init ]] && eval "$__bash_env_manager_init"
    unset __bash_env_manager_init
  fi
done
unset __bash_env_manager_spec __bash_env_manager __bash_env_root_var \
  __bash_env_root __bash_env_manager_exe

__bash_jenv=
if [[ -n ${JENV_ROOT:-} && -x $JENV_ROOT/bin/jenv ]]; then
  __bash_jenv=$JENV_ROOT/bin/jenv
elif [[ ${BASH_ENV_MANAGER_DISCOVERY:-0} == 1 ]]; then
  __bash_jenv=$(command -v jenv 2>/dev/null || :)
fi

if [[ -n $__bash_jenv ]]; then
  __bash_jenv_init=$("$__bash_jenv" init - 2>/dev/null || :)
  [[ -n $__bash_jenv_init ]] && eval "$__bash_jenv_init"
  unset __bash_jenv_init
fi
unset __bash_jenv
