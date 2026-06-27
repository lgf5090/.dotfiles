_uuid_usage() {
  printf '%s\n' \
    'usage:' \
    '  uuid' \
    '  uuid -n COUNT' \
    '  uuid -h | --help' \
    '' \
    'Generate RFC 4122 version 4 UUIDs using shell builtins. On Linux, this reads' \
    '/proc/sys/kernel/random/uuid with the shell builtin read; otherwise it falls' \
    "back to zsh's RANDOM."
}

_uuid_rand16() {
  emulate -L zsh
  printf '%d' $(( ((RANDOM << 1) ^ RANDOM) & 0xffff ))
}

_uuid_v4() {
  emulate -L zsh
  local uuid
  if [[ -r /proc/sys/kernel/random/uuid ]] &&
    IFS= read -r uuid < /proc/sys/kernel/random/uuid &&
    [[ $uuid == ????????-????-????-????-???????????? ]]; then
    printf '%s\n' "$uuid"
    return 0
  fi

  local a b c d e f g h
  a=$(_uuid_rand16)
  b=$(_uuid_rand16)
  c=$(_uuid_rand16)
  d=$(_uuid_rand16)
  e=$(_uuid_rand16)
  f=$(_uuid_rand16)
  g=$(_uuid_rand16)
  h=$(_uuid_rand16)
  (( c = 0x4000 | (c & 0x0fff) ))
  (( d = 0x8000 | (d & 0x3fff) ))

  printf '%04x%04x-%04x-%04x-%04x-%04x%04x%04x\n' "$a" "$b" "$c" "$d" "$e" "$f" "$g" "$h"
}

uuid() {
  emulate -L zsh
  local count=1 i

  while (( $# )); do
    case $1 in
      -h | --help)
        _uuid_usage
        return 0
        ;;
      -n | --count)
        if (( $# < 2 )) || [[ -z $2 || $2 == *[!0-9]* || $2 == 0 ]]; then
          print -u2 -- "uuid: $1 requires a positive integer"
          return 2
        fi
        count=$2
        shift 2
        ;;
      --)
        shift
        if (( $# )); then
          print -u2 -- "uuid: unexpected argument: $1"
          return 2
        fi
        ;;
      -*)
        print -u2 -- "uuid: unknown option: $1"
        return 2
        ;;
      *)
        print -u2 -- "uuid: unexpected argument: $1"
        return 2
        ;;
    esac
  done

  for (( i = 0; i < count; i++ )); do
    _uuid_v4
  done
}

_uuid_completion() {
  emulate -L zsh
  local prev="${words[CURRENT-1]}"
  local -a opts counts
  opts=(-h --help -n --count)
  counts=(1 2 3 5 10 20 50 100)

  if [[ $prev == -n || $prev == --count ]]; then
    _describe -t counts 'count' counts
    return
  fi

  _describe -t options 'option' opts
}

_uuid_register_completion() {
  emulate -L zsh
  (( ${+functions[compdef]} )) || return 0
  compdef _uuid_completion uuid 2>/dev/null
  (( ${+functions[add-zsh-hook]} )) && add-zsh-hook -d precmd _uuid_register_completion 2>/dev/null
}

if [[ -o interactive ]]; then
  autoload -Uz add-zsh-hook 2>/dev/null
  if (( ${+functions[compdef]} )); then
    _uuid_register_completion
  elif (( ${+functions[add-zsh-hook]} )); then
    add-zsh-hook precmd _uuid_register_completion 2>/dev/null
  fi
fi
