__bash_zoxide=
for __bash_zoxide_candidate in \
  "${ZOXIDE_EXE:-}" \
  "$HOME/.local/bin/zoxide" \
  /home/linuxbrew/.linuxbrew/bin/zoxide \
  "$HOME/.linuxbrew/bin/zoxide" \
  /opt/homebrew/bin/zoxide \
  /usr/local/bin/zoxide \
  /usr/bin/zoxide
do
  [[ -n $__bash_zoxide_candidate && -x $__bash_zoxide_candidate ]] || continue
  __bash_zoxide=$__bash_zoxide_candidate
  break
done
unset __bash_zoxide_candidate

if [[ -z $__bash_zoxide && ${BASH_ZOXIDE_DISCOVERY:-0} == 1 ]]; then
  __bash_zoxide=$(command -v zoxide 2>/dev/null || :)
fi

if [[ -n $__bash_zoxide && $- == *i* ]]; then
  __bash_zoxide_cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/bash"
  __bash_zoxide_cache_key=${__bash_zoxide//\//%}
  __bash_zoxide_cache="$__bash_zoxide_cache_dir/zoxide-init-${__bash_zoxide_cache_key}.bash"

  if [[ -s $__bash_zoxide_cache && $__bash_zoxide_cache -nt $__bash_zoxide ]]; then
    source "$__bash_zoxide_cache"
  else
    __bash_zoxide_init=$("$__bash_zoxide" init bash 2>/dev/null || :)
    if [[ -n $__bash_zoxide_init ]]; then
      eval "$__bash_zoxide_init"
      [[ -d $__bash_zoxide_cache_dir ]] || mkdir -p "$__bash_zoxide_cache_dir" 2>/dev/null
      if [[ -d $__bash_zoxide_cache_dir && -w $__bash_zoxide_cache_dir ]]; then
        __bash_zoxide_cache_tmp="$__bash_zoxide_cache.tmp.$$"
        printf '%s\n' "$__bash_zoxide_init" > "$__bash_zoxide_cache_tmp" \
          && mv -f "$__bash_zoxide_cache_tmp" "$__bash_zoxide_cache" 2>/dev/null \
          || rm -f "$__bash_zoxide_cache_tmp" 2>/dev/null
      fi
    fi
  fi
  unset __bash_zoxide_init __bash_zoxide_cache_dir __bash_zoxide_cache_key \
    __bash_zoxide_cache __bash_zoxide_cache_tmp
fi
unset __bash_zoxide
