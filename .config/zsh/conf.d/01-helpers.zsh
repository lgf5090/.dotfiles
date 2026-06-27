_zpath_prepend() {
  local dir
  for dir in "$@"; do
    [[ -d $dir ]] || continue
    path=("$dir" "${path[@]:#$dir}")
  done
}

_zpath_append() {
  local dir
  for dir in "$@"; do
    [[ -d $dir ]] || continue
    path=("${path[@]:#$dir}" "$dir")
  done
}

typeset -g _ZLOCAL_LOADER_VERSION=1

_zpath_prepend_value() {
  local value=$1 part new_path=
  local -a parts old_parts
  local -A seen

  parts=(${(s.:.)value})
  old_parts=("${path[@]}")
  seen=()

  for part in "${parts[@]}" "${old_parts[@]}"; do
    [[ -n $part && -d $part ]] || continue
    [[ -n ${seen[$part]:-} ]] && continue
    seen[$part]=1
    new_path="${new_path:+$new_path:}$part"
  done

  PATH=$new_path
}

_zload_envs() {
  local file=$1 line key val
  [[ -r $file ]] || return 0

  while IFS= read -r line || [[ -n $line ]]; do
    line=${line#${line%%[![:space:]]*}}
    case $line in
      ''|'#'*) continue ;;
      export[[:space:]]*)
        line=${line#export}
        line=${line#${line%%[![:space:]]*}}
        ;;
    esac
    [[ $line == *=* ]] || continue

    key=${line%%=*}
    val=${line#*=}
    key=${key%${key##*[![:space:]]}}
    val=${val#${val%%[![:space:]]*}}
    val=${val%${val##*[![:space:]]}}
    case $key in
      ''|[0-9]*|*[!A-Za-z0-9_]*) continue ;;
    esac

    if (( ${#val} >= 2 )); then
      case "${val[1]}${val[-1]}" in
        '""'|"''") val=${val[2,-2]} ;;
      esac
    fi
    val=${val//\{HOME\}/$HOME}
    val=${val//\{PATH\}/$PATH}

    if [[ $key == PATH ]]; then
      _zpath_prepend_value "$val"
    else
      export "$key=$val"
    fi
  done < "$file"
}

_zload_aliases() {
  local file=$1 line name body alias_def
  local cache_dir cache_key cache tmp use_cache=0
  [[ -r $file ]] || return 0

  cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/zsh"
  cache_key=${file:A}
  cache_key=${cache_key//\//%}
  cache_key=${cache_key//[^A-Za-z0-9_.%-]/_}
  cache="$cache_dir/local-aliases-${cache_key}.zsh"

  if [[ -s $cache && $cache -nt $file ]]; then
    source "$cache"
    return 0
  fi

  if [[ -d $cache_dir || -w ${cache_dir:h} ]]; then
    [[ -d $cache_dir ]] || mkdir -p "$cache_dir" 2>/dev/null
    if [[ -d $cache_dir && -w $cache_dir ]]; then
      tmp="$cache.tmp.$$"
      : > "$tmp" 2>/dev/null && use_cache=1
    fi
  fi

  while IFS= read -r line || [[ -n $line ]]; do
    line=${line#${line%%[![:space:]]*}}
    case $line in
      ''|'#'*) continue ;;
    esac
    [[ $line == *=* ]] || continue

    name=${line%%=*}
    body=${line#*=}
    name=${name%${name##*[![:space:]]}}
    body=${body#${body%%[![:space:]]*}}
    body=${body%${body##*[![:space:]]}}
    case $name in
      ''|[0-9-]*|*[!A-Za-z0-9_-]*) continue ;;
    esac

    if (( ${#body} >= 2 )); then
      case "${body[1]}${body[-1]}" in
        '""'|"''") body=${body[2,-2]} ;;
      esac
    fi
    alias_def="$name=$body"
    alias -- "$alias_def"
    (( use_cache )) && print -r -- "alias -- ${(qqq)alias_def}" >> "$tmp"
  done < "$file"

  if (( use_cache )); then
    command mv -f "$tmp" "$cache" 2>/dev/null || command rm -f "$tmp"
  fi
}

_zver_ge() {
  local i n1 n2
  local -a v1=(${(s:.:)1}) v2=(${(s:.:)2})

  for i in 1 2 3; do
    n1=${v1[i]:-0}
    n2=${v2[i]:-0}
    n1=${n1%%[^0-9]*}
    n2=${n2%%[^0-9]*}
    n1=${n1:-0}
    n2=${n2:-0}

    (( n1 > n2 )) && return 0
    (( n1 < n2 )) && return 1
  done

  return 0
}

: "${ZSH_PLUGIN_DIR:=${XDG_DATA_HOME:-$HOME/.local/share}/zsh/plugins}"
: "${ZSH_PLUGIN_AUTO_INSTALL:=1}"
typeset -gA _ZPLUGIN_LOADED

_zplugin() {
  local owner=$1 repo=$2 entry plugin_dir

  if [[ -z $owner || -z $repo ]]; then
    print -u2 -- "usage: _zplugin <owner> <repo>"
    return 2
  fi

  [[ -n ${_ZPLUGIN_LOADED[$repo]:-} ]] && return 0
  plugin_dir="$ZSH_PLUGIN_DIR/$repo"

  if [[ ! -d $plugin_dir ]]; then
    if [[ $ZSH_PLUGIN_AUTO_INSTALL != 1 ]]; then
      print -u2 -- "zsh: plugin missing, skip $repo"
      return 0
    fi
    if (( ! $+commands[git] )); then
      print -u2 -- "zsh: git not found, skip $repo"
      return 1
    fi
    mkdir -p "$ZSH_PLUGIN_DIR" || return
    git clone --depth=1 "https://github.com/$owner/$repo" "$plugin_dir" \
      || { print -u2 -- "zsh: failed to install $repo"; return 1; }
  fi

  for entry in "$plugin_dir/$repo.plugin.zsh" "$plugin_dir/$repo.zsh" "$plugin_dir"/*.plugin.zsh(N-.); do
    [[ -r $entry ]] || continue
    source "$entry"
    _ZPLUGIN_LOADED[$repo]=1
    return 0
  done

  print -u2 -- "zsh: no plugin entry found for $repo"
  return 1
}

zplugin-update() {
  local dir

  (( $+commands[git] )) || { print -u2 -- "zsh: git not found"; return 1; }
  for dir in "$ZSH_PLUGIN_DIR"/*(/N); do
    [[ -d "$dir/.git" ]] || continue
    print -r -- "Updating ${dir:t}..."
    git -C "$dir" pull --ff-only
  done
}
