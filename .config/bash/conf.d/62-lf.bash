[[ -f "$XDG_CONFIG_HOME/lf/icons" ]] \
  && export LF_ICONS="$(tr '\n' ':' < "$XDG_CONFIG_HOME/lf/icons")"

if command -v lf >/dev/null 2>&1; then
  lf() {
    local tmp dir rc
    tmp=$(mktemp "${TMPDIR:-/tmp}/lf-cwd.XXXXXX") || return

    command lf -last-dir-path="$tmp" "$@"
    rc=$?

    if [[ -s $tmp ]]; then
      dir=$(< "$tmp")
      [[ -d $dir && $dir != "$PWD" ]] && builtin cd -- "$dir"
    fi
    rm -f -- "$tmp"
    return "$rc"
  }
fi
