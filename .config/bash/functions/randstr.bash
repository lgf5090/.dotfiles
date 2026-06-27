_randstr_usage() {
  printf '%s\n' \
    'usage:' \
    '  randstr [LENGTH] [COUNT]' \
    '  randstr -l LENGTH -n COUNT [options]' \
    '  randstr -h | --help' \
    '' \
    'Generate random strings using bash builtins.' \
    '' \
    'options:' \
    '  -l, --length N        characters per string, default: 16' \
    '  -n, --count N         number of strings, default: 1' \
    '  --lower               use a-z' \
    '  --upper               use A-Z' \
    '  --alpha               use A-Za-z' \
    '  --digits              use 0-9' \
    '  --alnum               use A-Za-z0-9, default' \
    '  --hex                 use 0-9a-f' \
    '  --safe                use A-Za-z0-9_-' \
    '  --symbols             use shell-friendly symbols' \
    '  --alphabet CHARS      use a custom character set' \
    '  --prefix TEXT         prepend TEXT to each string' \
    '  --suffix TEXT         append TEXT to each string'
}

_randstr_positive_int() {
  [[ $1 =~ ^[1-9][0-9]*$ ]]
}

_randstr_generate_one() {
  local length=$1 alphabet=$2 prefix=$3 suffix=$4
  local alphabet_len=${#alphabet} out= i idx

  for (( i = 0; i < length; i++ )); do
    idx=$(( ((RANDOM << 1) ^ RANDOM) % alphabet_len ))
    out+=${alphabet:idx:1}
  done

  printf '%s%s%s\n' "$prefix" "$out" "$suffix"
}

randstr() {
  local length=16 count=1
  local alphabet=ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789
  local prefix= suffix= positional=0
  local i

  while (($#)); do
    case $1 in
      -h | --help)
        _randstr_usage
        return 0
        ;;
      -l | --length)
        [[ $# -ge 2 ]] && _randstr_positive_int "$2" || {
          printf 'randstr: %s requires a positive integer\n' "$1" >&2
          return 2
        }
        length=$2
        shift 2
        ;;
      -n | --count)
        [[ $# -ge 2 ]] && _randstr_positive_int "$2" || {
          printf 'randstr: %s requires a positive integer\n' "$1" >&2
          return 2
        }
        count=$2
        shift 2
        ;;
      --lower)
        alphabet=abcdefghijklmnopqrstuvwxyz
        shift
        ;;
      --upper)
        alphabet=ABCDEFGHIJKLMNOPQRSTUVWXYZ
        shift
        ;;
      --alpha)
        alphabet=ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz
        shift
        ;;
      --digits)
        alphabet=0123456789
        shift
        ;;
      --alnum)
        alphabet=ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789
        shift
        ;;
      --hex)
        alphabet=0123456789abcdef
        shift
        ;;
      --safe)
        alphabet=ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_-
        shift
        ;;
      --symbols)
        alphabet='!#$%&()*+,-./:;<=>?@[]^_{|}~'
        shift
        ;;
      --alphabet)
        [[ $# -ge 2 && -n $2 ]] || {
          printf 'randstr: --alphabet requires CHARS\n' >&2
          return 2
        }
        alphabet=$2
        shift 2
        ;;
      --prefix)
        [[ $# -ge 2 ]] || {
          printf 'randstr: --prefix requires TEXT\n' >&2
          return 2
        }
        prefix=$2
        shift 2
        ;;
      --suffix)
        [[ $# -ge 2 ]] || {
          printf 'randstr: --suffix requires TEXT\n' >&2
          return 2
        }
        suffix=$2
        shift 2
        ;;
      --)
        shift
        while (($#)); do
          if (( positional == 0 )); then
            _randstr_positive_int "$1" || {
              printf 'randstr: LENGTH requires a positive integer\n' >&2
              return 2
            }
            length=$1
          elif (( positional == 1 )); then
            _randstr_positive_int "$1" || {
              printf 'randstr: COUNT requires a positive integer\n' >&2
              return 2
            }
            count=$1
          else
            printf 'randstr: unexpected argument: %s\n' "$1" >&2
            return 2
          fi
          ((positional++))
          shift
        done
        ;;
      -*)
        printf 'randstr: unknown option: %s\n' "$1" >&2
        return 2
        ;;
      *)
        if (( positional == 0 )); then
          _randstr_positive_int "$1" || {
            printf 'randstr: LENGTH requires a positive integer\n' >&2
            return 2
          }
          length=$1
        elif (( positional == 1 )); then
          _randstr_positive_int "$1" || {
            printf 'randstr: COUNT requires a positive integer\n' >&2
            return 2
          }
          count=$1
        else
          printf 'randstr: unexpected argument: %s\n' "$1" >&2
          return 2
        fi
        ((positional++))
        shift
        ;;
    esac
  done

  [[ -n $alphabet ]] || {
    printf 'randstr: alphabet must not be empty\n' >&2
    return 2
  }

  for (( i = 0; i < count; i++ )); do
    _randstr_generate_one "$length" "$alphabet" "$prefix" "$suffix"
  done
}

_randstr_complete() {
  local cur=${COMP_WORDS[COMP_CWORD]} prev=${COMP_WORDS[COMP_CWORD-1]}
  local options='-h --help -l --length -n --count --lower --upper --alpha --digits --alnum --hex --safe --symbols --alphabet --prefix --suffix'

  case $prev in
    -l | --length)
      COMPREPLY=($(compgen -W '8 12 16 24 32 48 64' -- "$cur"))
      return 0
      ;;
    -n | --count)
      COMPREPLY=($(compgen -W '1 2 3 5 10 20 50 100' -- "$cur"))
      return 0
      ;;
    --alphabet | --prefix | --suffix)
      return 0
      ;;
  esac

  COMPREPLY=($(compgen -W "$options" -- "$cur"))
}

complete -F _randstr_complete randstr 2>/dev/null || true
