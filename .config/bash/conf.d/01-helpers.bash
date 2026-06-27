_bpath_remove() {
  local remove=$1 part
  local old_ifs=$IFS new_path=

  IFS=:
  for part in $PATH; do
    [[ $part == "$remove" ]] && continue
    new_path=${new_path:+$new_path:}$part
  done
  IFS=$old_ifs

  PATH=$new_path
}

_bpath_prepend() {
  local dir
  for dir in "$@"; do
    [[ -d $dir ]] || continue
    _bpath_remove "$dir"
    PATH="$dir${PATH:+:$PATH}"
  done
  export PATH
}

_bpath_append() {
  local dir
  for dir in "$@"; do
    [[ -d $dir ]] || continue
    _bpath_remove "$dir"
    PATH="${PATH:+$PATH:}$dir"
  done
  export PATH
}

_bver_ge() {
  local i n1 n2
  local v1 v2

  IFS=. read -r -a v1 <<< "$1"
  IFS=. read -r -a v2 <<< "$2"

  for i in 0 1 2; do
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

_BLOCAL_LOADER_VERSION=2

_bpath_prepend_value() {
  local value=$1 old_path=$PATH part old_ifs new_path=
  local -a parts=() old_parts=()
  local -A seen=()

  old_ifs=$IFS
  IFS=:
  read -r -a parts <<< "$value"
  read -r -a old_parts <<< "$old_path"
  IFS=$old_ifs

  for part in "${parts[@]}" "${old_parts[@]}"; do
    [[ -n $part && -d $part ]] || continue
    [[ ${seen[$part]+set} ]] && continue
    seen[$part]=1
    new_path="${new_path:+$new_path:}$part"
  done

  PATH=$new_path
  export PATH
}

_bload_envs() {
  local file=$1 line key val
  [[ -r $file ]] || return 0

  while IFS= read -r line || [[ -n $line ]]; do
    line=${line#"${line%%[![:space:]]*}"}
    case $line in
      ''|'#'*) continue ;;
      export[[:space:]]*)
        line=${line#export}
        line=${line#"${line%%[![:space:]]*}"}
        ;;
    esac
    [[ $line == *=* ]] || continue

    key=${line%%=*}
    val=${line#*=}
    key=${key%"${key##*[![:space:]]}"}
    val=${val#"${val%%[![:space:]]*}"}
    val=${val%"${val##*[![:space:]]}"}
    [[ $key =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]] || continue

    if (( ${#val} >= 2 )); then
      case "${val:0:1}${val: -1}" in
        '""'|"''") val=${val:1:${#val}-2} ;;
      esac
    fi
    val=${val//\{HOME\}/$HOME}
    val=${val//\{PATH\}/$PATH}

    if [[ $key == PATH ]]; then
      _bpath_prepend_value "$val"
    else
      export "$key=$val"
    fi
  done < "$file"
}

_bload_aliases() {
  local file=$1 line name body
  [[ -r $file ]] || return 0

  local cache_root=${XDG_CACHE_HOME:-$HOME/.cache}/bash
  if [[ ! -d $cache_root ]]; then
    mkdir -p "$cache_root" 2>/dev/null || true
  fi
  if [[ ! -w $cache_root ]]; then
    cache_root="${TMPDIR:-/tmp}/bash-${UID:-$USER}"
    [[ -d $cache_root ]] || mkdir -p "$cache_root" 2>/dev/null || true
  fi

  local cache_id=${file//[^[:alnum:]_]/_}
  local cache_file="$cache_root/local-aliases-$cache_id.bash"
  if [[ -r $cache_file && $cache_file -nt $file ]]; then
    source "$cache_file"
    return 0
  fi

  local cache_tmp="$cache_file.tmp.$$.$RANDOM"
  if {
    printf '# generated from %q\n' "$file"
    while IFS= read -r line || [[ -n $line ]]; do
      line=${line#"${line%%[![:space:]]*}"}
      case $line in
        ''|'#'*) continue ;;
      esac
      [[ $line == *=* ]] || continue

      name=${line%%=*}
      body=${line#*=}
      name=${name%"${name##*[![:space:]]}"}
      body=${body#"${body%%[![:space:]]*}"}
      body=${body%"${body##*[![:space:]]}"}
      [[ $name =~ ^[A-Za-z_][A-Za-z0-9_-]*$ ]] || continue

      if (( ${#body} >= 2 )); then
        case "${body:0:1}${body: -1}" in
          '""'|"''") body=${body:1:${#body}-2} ;;
        esac
      fi
      printf 'alias %s=%q\n' "$name" "$body"
    done < "$file"
  } > "$cache_tmp" && [[ -s $cache_tmp ]] && mv -f "$cache_tmp" "$cache_file" 2>/dev/null; then
    source "$cache_file"
    return 0
  fi
  rm -f "$cache_tmp" 2>/dev/null

  while IFS= read -r line || [[ -n $line ]]; do
    line=${line#"${line%%[![:space:]]*}"}
    case $line in
      ''|'#'*) continue ;;
    esac
    [[ $line == *=* ]] || continue

    name=${line%%=*}
    body=${line#*=}
    name=${name%"${name##*[![:space:]]}"}
    body=${body#"${body%%[![:space:]]*}"}
    body=${body%"${body##*[![:space:]]}"}
    [[ $name =~ ^[A-Za-z_][A-Za-z0-9_-]*$ ]] || continue

    if (( ${#body} >= 2 )); then
      case "${body:0:1}${body: -1}" in
        '""'|"''") body=${body:1:${#body}-2} ;;
      esac
    fi
    alias "$name=$body"
  done < "$file"
}

_bprompt_add() {
  local cmd=$1
  local prompt_decl

  prompt_decl=$(declare -p PROMPT_COMMAND 2>/dev/null || :)
  if [[ $prompt_decl == declare\ -*a* ]]; then
    local item
    for item in "${PROMPT_COMMAND[@]}"; do
      [[ $item == "$cmd" ]] && return 0
    done
    PROMPT_COMMAND+=("$cmd")
    return 0
  fi

  case ";${PROMPT_COMMAND:-};" in
    *";$cmd;"*) return 0 ;;
  esac
  PROMPT_COMMAND="${PROMPT_COMMAND:+$PROMPT_COMMAND; }$cmd"
}

: "${BASH_PLUGIN_DIR:=${XDG_DATA_HOME:-$HOME/.local/share}/bash/plugins}"
: "${BASH_PLUGIN_AUTO_INSTALL:=1}"
: "${_BPLUGIN_LOADED_LIST:=:}"

_bplugin() {
  local owner=$1 repo=$2 entry plugin_dir

  if [[ -z $owner || -z $repo ]]; then
    printf 'usage: _bplugin <owner> <repo>\n' >&2
    return 2
  fi

  case $_BPLUGIN_LOADED_LIST in
    *":$repo:"*) return 0 ;;
  esac
  plugin_dir="$BASH_PLUGIN_DIR/$repo"

  if [[ ! -d $plugin_dir ]]; then
    if [[ $BASH_PLUGIN_AUTO_INSTALL != 1 ]]; then
      printf 'bash: plugin missing, skip %s\n' "$repo" >&2
      return 0
    fi
    if ! command -v git >/dev/null 2>&1; then
      printf 'bash: git not found, skip %s\n' "$repo" >&2
      return 1
    fi
    mkdir -p "$BASH_PLUGIN_DIR" || return
    git clone --depth=1 "https://github.com/$owner/$repo" "$plugin_dir" \
      || { printf 'bash: failed to install %s\n' "$repo" >&2; return 1; }
  fi

  for entry in "$plugin_dir/$repo.bash" "$plugin_dir/$repo.sh" "$plugin_dir"/*.bash "$plugin_dir"/*.sh; do
    [[ -r $entry ]] || continue
    source "$entry"
    _BPLUGIN_LOADED_LIST="$_BPLUGIN_LOADED_LIST$repo:"
    return 0
  done

  printf 'bash: no plugin entry found for %s\n' "$repo" >&2
  return 1
}

bplugin-update() {
  local dir nullglob_was_set

  command -v git >/dev/null 2>&1 || { printf 'bash: git not found\n' >&2; return 1; }
  shopt -q nullglob
  nullglob_was_set=$?
  shopt -s nullglob
  for dir in "$BASH_PLUGIN_DIR"/*; do
    [[ -d $dir/.git ]] || continue
    printf 'Updating %s...\n' "${dir##*/}"
    git -C "$dir" pull --ff-only
  done
  (( nullglob_was_set == 0 )) || shopt -u nullglob
}
