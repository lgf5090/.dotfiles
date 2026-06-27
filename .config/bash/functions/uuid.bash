_uuid_usage() {
  printf '%s\n' \
    'usage:' \
    '  uuid' \
    '  uuid -n COUNT' \
    '  uuid -h | --help' \
    '' \
    'Generate RFC 4122 version 4 UUIDs using shell builtins. On Linux, this reads' \
    '/proc/sys/kernel/random/uuid with the shell builtin read; otherwise it falls' \
    "back to bash's RANDOM."
}

_uuid_rand16() {
  printf '%d' $(( ((RANDOM << 1) ^ RANDOM) & 0xffff ))
}

_uuid_v4() {
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
  local count=1 i

  while (($#)); do
    case $1 in
      -h | --help)
        _uuid_usage
        return 0
        ;;
      -n | --count)
        [[ $# -ge 2 && $2 =~ ^[1-9][0-9]*$ ]] || {
          printf 'uuid: %s requires a positive integer\n' "$1" >&2
          return 2
        }
        count=$2
        shift 2
        ;;
      --)
        shift
        [[ $# -eq 0 ]] || {
          printf 'uuid: unexpected argument: %s\n' "$1" >&2
          return 2
        }
        ;;
      -*)
        printf 'uuid: unknown option: %s\n' "$1" >&2
        return 2
        ;;
      *)
        printf 'uuid: unexpected argument: %s\n' "$1" >&2
        return 2
        ;;
    esac
  done

  for (( i = 0; i < count; i++ )); do
    _uuid_v4
  done
}

_uuid_complete() {
  local cur=${COMP_WORDS[COMP_CWORD]} prev=${COMP_WORDS[COMP_CWORD-1]}
  if [[ $prev == -n || $prev == --count ]]; then
    COMPREPLY=($(compgen -W '1 2 3 5 10 20 50 100' -- "$cur"))
    return 0
  fi
  COMPREPLY=($(compgen -W '-h --help -n --count' -- "$cur"))
}

complete -F _uuid_complete uuid 2>/dev/null || true
