_randstr_usage() {
  printf '%s\n' \
    'usage:' \
    '  randstr [LENGTH] [COUNT]' \
    '  randstr -l LENGTH -n COUNT [options]' \
    '  randstr -h | --help' \
    '' \
    'Generate random strings using zsh builtins.' \
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
  emulate -L zsh
  [[ $1 == <-> && $1 -gt 0 ]]
}

_randstr_generate_one() {
  emulate -L zsh
  local length=$1 alphabet=$2 prefix=$3 suffix=$4
  local alphabet_len=${#alphabet} out= i idx

  for (( i = 0; i < length; i++ )); do
    idx=$(( ((RANDOM << 1) ^ RANDOM) % alphabet_len ))
    out+=${alphabet:$idx:1}
  done

  print -r -- "$prefix$out$suffix"
}

randstr() {
  emulate -L zsh
  local length=16 count=1
  local alphabet=ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789
  local prefix= suffix= positional=0
  local i

  while (( $# )); do
    case $1 in
      -h | --help)
        _randstr_usage
        return 0
        ;;
      -l | --length)
        if (( $# < 2 )) || ! _randstr_positive_int "$2"; then
          print -u2 -- "randstr: $1 requires a positive integer"
          return 2
        fi
        length=$2
        shift 2
        ;;
      -n | --count)
        if (( $# < 2 )) || ! _randstr_positive_int "$2"; then
          print -u2 -- "randstr: $1 requires a positive integer"
          return 2
        fi
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
        if (( $# < 2 )) || [[ -z $2 ]]; then
          print -u2 -- 'randstr: --alphabet requires CHARS'
          return 2
        fi
        alphabet=$2
        shift 2
        ;;
      --prefix)
        if (( $# < 2 )); then
          print -u2 -- 'randstr: --prefix requires TEXT'
          return 2
        fi
        prefix=$2
        shift 2
        ;;
      --suffix)
        if (( $# < 2 )); then
          print -u2 -- 'randstr: --suffix requires TEXT'
          return 2
        fi
        suffix=$2
        shift 2
        ;;
      --)
        shift
        while (( $# )); do
          if (( positional == 0 )); then
            if ! _randstr_positive_int "$1"; then
              print -u2 -- 'randstr: LENGTH requires a positive integer'
              return 2
            fi
            length=$1
          elif (( positional == 1 )); then
            if ! _randstr_positive_int "$1"; then
              print -u2 -- 'randstr: COUNT requires a positive integer'
              return 2
            fi
            count=$1
          else
            print -u2 -- "randstr: unexpected argument: $1"
            return 2
          fi
          (( positional++ ))
          shift
        done
        ;;
      -*)
        print -u2 -- "randstr: unknown option: $1"
        return 2
        ;;
      *)
        if (( positional == 0 )); then
          if ! _randstr_positive_int "$1"; then
            print -u2 -- 'randstr: LENGTH requires a positive integer'
            return 2
          fi
          length=$1
        elif (( positional == 1 )); then
          if ! _randstr_positive_int "$1"; then
            print -u2 -- 'randstr: COUNT requires a positive integer'
            return 2
          fi
          count=$1
        else
          print -u2 -- "randstr: unexpected argument: $1"
          return 2
        fi
        (( positional++ ))
        shift
        ;;
    esac
  done

  if [[ -z $alphabet ]]; then
    print -u2 -- 'randstr: alphabet must not be empty'
    return 2
  fi

  for (( i = 0; i < count; i++ )); do
    _randstr_generate_one "$length" "$alphabet" "$prefix" "$suffix"
  done
}

_randstr_completion() {
  emulate -L zsh
  local prev="${words[CURRENT-1]}"
  local -a opts lengths counts

  opts=(-h --help -l --length -n --count --lower --upper --alpha --digits --alnum --hex --safe --symbols --alphabet --prefix --suffix)
  lengths=(8 12 16 24 32 48 64)
  counts=(1 2 3 5 10 20 50 100)

  case $prev in
    -l | --length)
      _describe -t lengths 'length' lengths
      return
      ;;
    -n | --count)
      _describe -t counts 'count' counts
      return
      ;;
    --alphabet | --prefix | --suffix)
      return
      ;;
  esac

  _describe -t options 'option' opts
}

_randstr_register_completion() {
  emulate -L zsh
  (( ${+functions[compdef]} )) || return 0
  compdef _randstr_completion randstr 2>/dev/null
  (( ${+functions[add-zsh-hook]} )) && add-zsh-hook -d precmd _randstr_register_completion 2>/dev/null
}

if [[ -o interactive ]]; then
  autoload -Uz add-zsh-hook 2>/dev/null
  if (( ${+functions[compdef]} )); then
    _randstr_register_completion
  elif (( ${+functions[add-zsh-hook]} )); then
    add-zsh-hook precmd _randstr_register_completion 2>/dev/null
  fi
fi
