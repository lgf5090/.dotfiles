__bash_direnv=
for __bash_direnv_candidate in \
  "${DIRENV_EXE:-}" \
  "$HOME/.local/bin/direnv" \
  /home/linuxbrew/.linuxbrew/bin/direnv \
  "$HOME/.linuxbrew/bin/direnv" \
  /opt/homebrew/bin/direnv \
  /usr/local/bin/direnv \
  /usr/bin/direnv
do
  [[ -n $__bash_direnv_candidate && -x $__bash_direnv_candidate ]] || continue
  __bash_direnv=$__bash_direnv_candidate
  break
done
unset __bash_direnv_candidate

if [[ -z $__bash_direnv && ${BASH_DIRENV_DISCOVERY:-0} == 1 ]]; then
  __bash_direnv=$(command -v direnv 2>/dev/null || :)
fi

if [[ -n $__bash_direnv && $- == *i* ]]; then
  __bash_direnv_cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/bash"
  __bash_direnv_cache_key=${__bash_direnv//\//%}
  __bash_direnv_cache="$__bash_direnv_cache_dir/direnv-hook-${__bash_direnv_cache_key}.bash"

  if [[ -s $__bash_direnv_cache && $__bash_direnv_cache -nt $__bash_direnv ]]; then
    source "$__bash_direnv_cache"
  else
    __bash_direnv_hook=$("$__bash_direnv" hook bash 2>/dev/null || :)
    if [[ -n $__bash_direnv_hook ]]; then
      eval "$__bash_direnv_hook"
      [[ -d $__bash_direnv_cache_dir ]] || mkdir -p "$__bash_direnv_cache_dir" 2>/dev/null
      if [[ -d $__bash_direnv_cache_dir && -w $__bash_direnv_cache_dir ]]; then
        __bash_direnv_cache_tmp="$__bash_direnv_cache.tmp.$$"
        printf '%s\n' "$__bash_direnv_hook" > "$__bash_direnv_cache_tmp" \
          && mv -f "$__bash_direnv_cache_tmp" "$__bash_direnv_cache" 2>/dev/null \
          || rm -f "$__bash_direnv_cache_tmp" 2>/dev/null
      fi
    fi
  fi
  unset __bash_direnv_hook __bash_direnv_cache_dir __bash_direnv_cache_key \
    __bash_direnv_cache __bash_direnv_cache_tmp
fi
unset __bash_direnv
