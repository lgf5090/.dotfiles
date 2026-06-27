: "${MISE_DATA_DIR:=${XDG_DATA_HOME:-$HOME/.local/share}/mise}"
: "${ZSH_MISE_ACTIVATE:=shims}"
export MISE_DATA_DIR

if [[ -z ${MISE_CACHE_DIR:-} ]]; then
  __zsh_mise_cache="${XDG_CACHE_HOME:-$HOME/.cache}/mise"
  if ! { [[ -d $__zsh_mise_cache ]] || mkdir -p "$__zsh_mise_cache" 2>/dev/null; } || [[ ! -w $__zsh_mise_cache ]]; then
    __zsh_mise_cache="${TMPDIR:-/tmp}/mise-${UID:-$USER}"
    mkdir -p "$__zsh_mise_cache" 2>/dev/null
  fi
  export MISE_CACHE_DIR="$__zsh_mise_cache"
  unset __zsh_mise_cache
fi

__zsh_mise=
for __zsh_mise_candidate in \
  "${MISE_EXE:-}" \
  "$HOME/.local/bin/mise" \
  /home/linuxbrew/.linuxbrew/bin/mise \
  "$HOME/.linuxbrew/bin/mise" \
  /opt/homebrew/bin/mise \
  /usr/local/bin/mise \
  /opt/mise/bin/mise
do
  [[ -n $__zsh_mise_candidate && -x $__zsh_mise_candidate ]] || continue
  __zsh_mise=$__zsh_mise_candidate
  break
done

case ${SHELLS_OS:-unknown} in
  windows)
    for __zsh_mise_candidate in \
      "$HOME/scoop/shims/mise.exe" \
      "${PROGRAMDATA:+$PROGRAMDATA/scoop/shims/mise.exe}" \
      "${LOCALAPPDATA:+$LOCALAPPDATA/Microsoft/WinGet/Links/mise.exe}"
    do
      [[ -n $__zsh_mise || -z $__zsh_mise_candidate || ! -x $__zsh_mise_candidate ]] && continue
      __zsh_mise=$__zsh_mise_candidate
      break
    done
    ;;
esac
unset __zsh_mise_candidate

if [[ -z $__zsh_mise && ${ZSH_MISE_DISCOVERY:-0} == 1 ]]; then
  __zsh_mise=$(command -v mise 2>/dev/null)
fi

case ${ZSH_MISE_ACTIVATE:l} in
  full|1|yes|true)
    if [[ -n $__zsh_mise && -x $__zsh_mise ]]; then
      eval "$("$__zsh_mise" activate zsh)"
    fi
    ;;
esac
unset __zsh_mise

case ${ZSH_MISE_ACTIVATE:l} in
  none|0|no|false) ;;
  *) _zpath_prepend "$HOME/.mise/shims" "$MISE_DATA_DIR/shims" ;;
esac
