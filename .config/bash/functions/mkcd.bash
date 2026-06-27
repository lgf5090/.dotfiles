mkcd() {
  [[ $# -eq 1 ]] || { printf 'usage: mkcd <dir>\n' >&2; return 2; }
  mkdir -p -- "$1" && builtin cd -- "$1"
}
