: "${MISE_DATA_DIR:=${XDG_DATA_HOME:-$HOME/.local/share}/mise}"
: "${BASH_MISE_ACTIVATE:=shims}"
export MISE_DATA_DIR

if [[ -z ${MISE_CACHE_DIR:-} ]]; then
  __bash_mise_cache="${XDG_CACHE_HOME:-$HOME/.cache}/mise"
  if { [[ -d $__bash_mise_cache ]] || mkdir -p "$__bash_mise_cache" 2>/dev/null; } && [[ -w $__bash_mise_cache ]]; then
    :
  else
    __bash_mise_cache="${TMPDIR:-/tmp}/mise-${UID:-$USER}"
    [[ -d $__bash_mise_cache ]] || mkdir -p "$__bash_mise_cache" 2>/dev/null
  fi
  export MISE_CACHE_DIR="$__bash_mise_cache"
  unset __bash_mise_cache
fi

__bash_mise=
for __bash_mise_candidate in \
  "${MISE_EXE:-}" \
  "$HOME/.local/bin/mise" \
  /home/linuxbrew/.linuxbrew/bin/mise \
  "$HOME/.linuxbrew/bin/mise" \
  /opt/homebrew/bin/mise \
  /usr/local/bin/mise \
  /opt/mise/bin/mise
do
  [[ -n $__bash_mise_candidate && -x $__bash_mise_candidate ]] || continue
  __bash_mise=$__bash_mise_candidate
  break
done

case ${SHELLS_OS:-unknown} in
  windows)
    for __bash_mise_candidate in \
      "$HOME/scoop/shims/mise.exe" \
      "${PROGRAMDATA:+$PROGRAMDATA/scoop/shims/mise.exe}" \
      "${LOCALAPPDATA:+$LOCALAPPDATA/Microsoft/WinGet/Links/mise.exe}"
    do
      [[ -z $__bash_mise && -n $__bash_mise_candidate && -x $__bash_mise_candidate ]] || continue
      __bash_mise=$__bash_mise_candidate
      break
    done
    ;;
esac
unset __bash_mise_candidate

if [[ -z $__bash_mise && ${BASH_MISE_DISCOVERY:-0} == 1 ]]; then
  __bash_mise=$(command -v mise 2>/dev/null)
fi

case ${BASH_MISE_ACTIVATE,,} in
  full|1|yes|true)
    if [[ -n $__bash_mise && -x $__bash_mise ]]; then
      eval "$("$__bash_mise" activate bash)"
    fi
    ;;
esac
unset __bash_mise

case ${BASH_MISE_ACTIVATE,,} in
  none|0|no|false) ;;
  *) _bpath_prepend "$HOME/.mise/shims" "$MISE_DATA_DIR/shims" ;;
esac
