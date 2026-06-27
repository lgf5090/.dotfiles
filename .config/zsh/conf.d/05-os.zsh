case ${OSTYPE:l} in
  linux*) SHELLS_OS=linux ;;
  darwin*) SHELLS_OS=macos ;;
  freebsd*) SHELLS_OS=freebsd ;;
  cygwin*) SHELLS_OS=cygwin ;;
  msys*|mingw*) SHELLS_OS=windows ;;
  *) SHELLS_OS=unknown ;;
esac

if [[ $SHELLS_OS == linux && -r /proc/version ]]; then
  IFS= read -r __zsh_proc_version < /proc/version
  case ${__zsh_proc_version:l} in
    *microsoft*|*wsl*) SHELLS_OS=wsl ;;
  esac
  unset __zsh_proc_version
fi

export SHELLS_OS
