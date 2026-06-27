if (( $+commands[zoxide] )) && [[ -o interactive ]]; then
  __zsh_zoxide=${commands[zoxide]}
  __zsh_zoxide_cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/zsh"
  __zsh_zoxide_cache_key=${__zsh_zoxide:A}
  __zsh_zoxide_cache_key=${__zsh_zoxide_cache_key//\//%}
  __zsh_zoxide_cache="$__zsh_zoxide_cache_dir/zoxide-init-${__zsh_zoxide_cache_key}.zsh"

  if [[ -s $__zsh_zoxide_cache && $__zsh_zoxide_cache -nt $__zsh_zoxide ]]; then
    source "$__zsh_zoxide_cache"
  else
    __zsh_zoxide_init=$("$__zsh_zoxide" init zsh 2>/dev/null || :)
    if [[ -n $__zsh_zoxide_init ]]; then
      eval "$__zsh_zoxide_init"
      if [[ -d $__zsh_zoxide_cache_dir || -w ${__zsh_zoxide_cache_dir:h} ]]; then
        [[ -d $__zsh_zoxide_cache_dir ]] || mkdir -p "$__zsh_zoxide_cache_dir" 2>/dev/null
        if [[ -d $__zsh_zoxide_cache_dir && -w $__zsh_zoxide_cache_dir ]]; then
          __zsh_zoxide_cache_tmp="$__zsh_zoxide_cache.tmp.$$"
          print -r -- "$__zsh_zoxide_init" > "$__zsh_zoxide_cache_tmp" \
            && command mv -f "$__zsh_zoxide_cache_tmp" "$__zsh_zoxide_cache" 2>/dev/null \
            || command rm -f "$__zsh_zoxide_cache_tmp"
        fi
      fi
    fi
  fi
  unset __zsh_zoxide __zsh_zoxide_init __zsh_zoxide_cache_dir \
    __zsh_zoxide_cache_key __zsh_zoxide_cache __zsh_zoxide_cache_tmp
fi
