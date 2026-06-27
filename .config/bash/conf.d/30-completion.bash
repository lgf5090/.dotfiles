case $- in
  *i*)
    for __bash_completion_file in \
      /usr/share/bash-completion/bash_completion \
      /etc/bash_completion \
      /opt/homebrew/etc/profile.d/bash_completion.sh \
      /usr/local/etc/profile.d/bash_completion.sh
    do
      [[ -r $__bash_completion_file ]] && break
      __bash_completion_file=
    done

    if [[ -n $__bash_completion_file ]]; then
      : "${BASH_COMPLETION_LOAD:=lazy}"
      case ${BASH_COMPLETION_LOAD,,} in
        lazy|defer|deferred)
          shopt -s progcomp
          _bash_completion_lazy_load() {
            local __bash_completion_rc
            complete -r -D 2>/dev/null || :
            source "$__bash_completion_file"
            __bash_completion_rc=$?
            (( __bash_completion_rc == 0 )) && return 124
            return "$__bash_completion_rc"
          }
          complete -D -F _bash_completion_lazy_load
          ;;
        none|0|no|false) ;;
        *)
          source "$__bash_completion_file"
          unset __bash_completion_file
          ;;
      esac
    fi
    ;;
esac
