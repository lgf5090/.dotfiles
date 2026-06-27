for __zsh_env_manager_spec in rbenv:RBENV_ROOT nodenv:NODENV_ROOT goenv:GOENV_ROOT; do
  __zsh_env_manager=${__zsh_env_manager_spec%%:*}
  __zsh_env_root_var=${__zsh_env_manager_spec#*:}
  __zsh_env_root=${(P)__zsh_env_root_var}
  __zsh_env_manager_exe=

  if [[ -n $__zsh_env_root && -x $__zsh_env_root/bin/$__zsh_env_manager ]]; then
    __zsh_env_manager_exe=$__zsh_env_root/bin/$__zsh_env_manager
  elif [[ ${ZSH_ENV_MANAGER_DISCOVERY:-0} == 1 ]] && (( $+commands[$__zsh_env_manager] )); then
    __zsh_env_manager_exe=${commands[$__zsh_env_manager]}
  fi

  if [[ -n $__zsh_env_manager_exe ]]; then
    __zsh_env_manager_init=$("$__zsh_env_manager_exe" init - zsh 2>/dev/null || "$__zsh_env_manager_exe" init - 2>/dev/null || :)
    [[ -n $__zsh_env_manager_init ]] && eval "$__zsh_env_manager_init"
    unset __zsh_env_manager_init
  fi
done
unset __zsh_env_manager_spec __zsh_env_manager __zsh_env_root_var \
  __zsh_env_root __zsh_env_manager_exe

__zsh_jenv=
if [[ -n ${JENV_ROOT:-} && -x $JENV_ROOT/bin/jenv ]]; then
  __zsh_jenv=$JENV_ROOT/bin/jenv
elif [[ ${ZSH_ENV_MANAGER_DISCOVERY:-0} == 1 ]] && (( $+commands[jenv] )); then
  __zsh_jenv=${commands[jenv]}
fi

if [[ -n $__zsh_jenv ]]; then
  __zsh_jenv_init=$("$__zsh_jenv" init - 2>/dev/null || :)
  [[ -n $__zsh_jenv_init ]] && eval "$__zsh_jenv_init"
  unset __zsh_jenv_init
fi
unset __zsh_jenv
