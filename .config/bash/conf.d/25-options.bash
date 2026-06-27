shopt -s checkwinsize
shopt -s globstar 2>/dev/null || true

case $- in
  *i*) set -o vi ;;
esac
