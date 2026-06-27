mkcd() {
  [[ $# -eq 1 ]] || { print -u2 -- "usage: mkcd <dir>"; return 2; }
  mkdir -p -- "$1" && builtin cd -- "$1"
}
