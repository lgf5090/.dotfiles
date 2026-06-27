# Language and toolchain environment variables used by 15-path.bash.
# Existing values are respected so ~/.envs or parent shells can override.

: "${NPM_CONFIG_PREFIX:=$HOME/.npm-global}"
: "${PNPM_HOME:=$HOME/.pnpm-global}"
export NPM_CONFIG_PREFIX PNPM_HOME

if [[ -z ${FNM_DIR:-} ]]; then
  for __bash_fnm_dir in "${XDG_DATA_HOME:-$HOME/.local/share}/fnm" "$HOME/.fnm"; do
    [[ -d $__bash_fnm_dir ]] || continue
    FNM_DIR=$__bash_fnm_dir
    break
  done
  unset __bash_fnm_dir
fi
[[ -n ${FNM_DIR:-} ]] && export FNM_DIR

[[ -d $HOME/.volta ]] && export VOLTA_HOME="$HOME/.volta"
[[ -d $HOME/.bun ]] && export BUN_INSTALL="$HOME/.bun"
[[ -d $HOME/.deno ]] && export DENO_INSTALL="$HOME/.deno"

: "${GOPATH:=$HOME/go}"
export GOPATH

if [[ -z ${GOROOT:-} ]]; then
  for __bash_goroot in \
    /home/linuxbrew/.linuxbrew/opt/go/libexec \
    /opt/homebrew/opt/go/libexec \
    /usr/local/go \
    "$HOME/.local/go"
  do
    [[ -d $__bash_goroot ]] || continue
    GOROOT=$__bash_goroot
    export GOROOT
    break
  done
  unset __bash_goroot
fi

if [[ -z ${ANACONDA_HOME:-} ]]; then
  for __bash_conda in "$HOME/anaconda3" "$HOME/miniconda3" /opt/anaconda3 /opt/miniconda3; do
    [[ -d $__bash_conda ]] || continue
    ANACONDA_HOME=$__bash_conda
    export ANACONDA_HOME
    break
  done
  unset __bash_conda
fi

if [[ -z ${POETRY_HOME:-} && -d $HOME/.poetry ]]; then
  POETRY_HOME=$HOME/.poetry
fi
[[ -n ${POETRY_HOME:-} ]] && export POETRY_HOME

if [[ -z ${PYENV_ROOT:-} && -d $HOME/.pyenv ]]; then
  PYENV_ROOT=$HOME/.pyenv
fi
[[ -n ${PYENV_ROOT:-} ]] && export PYENV_ROOT

if [[ -z ${ASDF_DIR:-} ]]; then
  for __bash_asdf_dir in \
    "$HOME/.asdf" \
    "${HOMEBREW_PREFIX:-}/opt/asdf/libexec" \
    /home/linuxbrew/.linuxbrew/opt/asdf/libexec \
    /opt/homebrew/opt/asdf/libexec \
    /usr/local/opt/asdf/libexec
  do
    [[ -d $__bash_asdf_dir ]] || continue
    ASDF_DIR=$__bash_asdf_dir
    break
  done
  unset __bash_asdf_dir
fi
[[ -n ${ASDF_DIR:-} ]] && export ASDF_DIR

if [[ -z ${ASDF_DATA_DIR:-} && -n ${ASDF_DIR:-} ]]; then
  case $ASDF_DIR in
    "$HOME/.asdf") ASDF_DATA_DIR=$ASDF_DIR ;;
    *) ASDF_DATA_DIR=${XDG_DATA_HOME:-$HOME/.local/share}/asdf ;;
  esac
fi
[[ -n ${ASDF_DATA_DIR:-} ]] && export ASDF_DATA_DIR

__bash_env_roots=(
  "RBENV_ROOT:$HOME/.rbenv"
  "NODENV_ROOT:$HOME/.nodenv"
  "GOENV_ROOT:$HOME/.goenv"
  "JENV_ROOT:$HOME/.jenv"
  "SDKMAN_DIR:$HOME/.sdkman"
)
for __bash_env_root in "${__bash_env_roots[@]}"; do
  __bash_env_name=${__bash_env_root%%:*}
  __bash_env_dir=${__bash_env_root#*:}
  if [[ -n ${!__bash_env_name:-} ]]; then
    export "$__bash_env_name"
  elif [[ -d $__bash_env_dir ]]; then
    export "$__bash_env_name=$__bash_env_dir"
  fi
done
unset __bash_env_roots __bash_env_root __bash_env_name __bash_env_dir

if [[ -z ${JAVA_HOME:-} ]]; then
  if [[ -x /usr/libexec/java_home ]]; then
    __bash_java_home=$(/usr/libexec/java_home 2>/dev/null)
    [[ -n $__bash_java_home ]] && JAVA_HOME=$__bash_java_home
    unset __bash_java_home
  else
    for __bash_jdk in \
      /usr/lib/jvm/default-java \
      /usr/lib/jvm/default \
      /usr/lib/jvm/java-21-openjdk-amd64 \
      /usr/lib/jvm/java-17-openjdk-amd64 \
      /usr/lib/jvm/java-11-openjdk-amd64
    do
      [[ -d $__bash_jdk ]] || continue
      JAVA_HOME=$__bash_jdk
      break
    done
    unset __bash_jdk
  fi
fi
[[ -n ${JAVA_HOME:-} ]] && export JAVA_HOME

_benv_path_prepend() {
  local var=$1 dir=$2 value
  [[ -d $dir ]] || return 0

  value=${!var-}
  case ":$value:" in
    *":$dir:"*) ;;
    *) export "$var=$dir${value:+:$value}" ;;
  esac
}

case ${SHELLS_OS:-unknown} in
  linux|wsl)
    for __bash_libdir in \
      /usr/lib/x86_64-linux-gnu \
      /usr/lib/aarch64-linux-gnu
    do
      [[ -d $__bash_libdir ]] || continue
      _benv_path_prepend LIBRARY_PATH "$__bash_libdir"
      _benv_path_prepend LD_LIBRARY_PATH "$__bash_libdir"
      case " ${RUSTFLAGS:-} " in
        *" -L $__bash_libdir "*) ;;
        *) export RUSTFLAGS="-L $__bash_libdir${RUSTFLAGS:+ $RUSTFLAGS}" ;;
      esac
      break
    done
    unset __bash_libdir
    ;;
esac

: "${DOCKER_BUILDKIT:=1}"
: "${COMPOSE_DOCKER_CLI_BUILD:=1}"
export DOCKER_BUILDKIT COMPOSE_DOCKER_CLI_BUILD

unset -f _benv_path_prepend
