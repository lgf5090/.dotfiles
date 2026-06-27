_zpath_append \
  "$HOME/.lmstudio/bin" \
  "$HOME/.mimocode/bin" \
  "$HOME/.turso" \
  "$HOME/.local/bin" \
  "$HOME/bin" \
  "$HOME/Applications" \
  "$HOME/.local/Applications"

_zpath_prepend \
  "${ASDF_DIR:+$ASDF_DIR/bin}" \
  "${RBENV_ROOT:+$RBENV_ROOT/bin}" \
  "${NODENV_ROOT:+$NODENV_ROOT/bin}" \
  "${GOENV_ROOT:+$GOENV_ROOT/bin}" \
  "${JENV_ROOT:+$JENV_ROOT/bin}" \
  "${CARGO_HOME:-$HOME/.cargo}/bin" \
  "$HOME/.rd/bin" \
  "$HOME/.opencode/bin"

[[ -r $HOME/.cargo/env ]] && source "$HOME/.cargo/env"

[[ -r $HOME/.turso/env ]] && source "$HOME/.turso/env"

_zpath_prepend \
  "${BUN_INSTALL:+$BUN_INSTALL/bin}" \
  "${DENO_INSTALL:+$DENO_INSTALL/bin}" \
  "${NPM_CONFIG_PREFIX:+$NPM_CONFIG_PREFIX/bin}" \
  "${PNPM_HOME:+$PNPM_HOME}" \
  "$HOME/.yarn/bin" \
  "$HOME/.config/yarn/global/node_modules/.bin" \
  "${VOLTA_HOME:+$VOLTA_HOME/bin}" \
  "$HOME/.volta/bin" \
  "${FNM_DIR:+$FNM_DIR}" \
  "$HOME/.local/share/npm/bin"

_zpath_prepend \
  "${PYENV_ROOT:+$PYENV_ROOT/bin}" \
  "${ANACONDA_HOME:+$ANACONDA_HOME/bin}" \
  "${POETRY_HOME:+$POETRY_HOME/bin}" \
  "$HOME/.poetry/bin" \
  "$HOME/.local/pipx/bin"

_zpath_prepend \
  "${GOPATH:+$GOPATH/bin}" \
  "${GOROOT:+$GOROOT/bin}"

case ${SHELLS_OS:-unknown} in
  linux|wsl)
    _zpath_append \
      /snap/bin \
      /var/lib/snapd/snap/bin \
      /var/lib/flatpak/exports/bin \
      "$HOME/.local/share/flatpak/exports/bin" \
      /opt/bin
    ;;
esac

case ${SHELLS_OS:-unknown} in
  wsl)
    _zpath_append \
      "/mnt/c/Program Files/Microsoft VS Code/bin" \
      "/mnt/c/Users/$USER/AppData/Local/Programs/Microsoft VS Code/bin"
    ;;
  cygwin)
    _zpath_prepend /mingw64/bin
    _zpath_append \
      "/cygdrive/c/Program Files/Microsoft VS Code/bin" \
      "/cygdrive/c/Users/$USER/AppData/Local/Programs/Microsoft VS Code/bin"
    ;;
  windows)
    _zpath_prepend /mingw64/bin
    _zpath_append \
      "/c/Program Files/Microsoft VS Code/bin" \
      "/c/Users/$USER/AppData/Local/Programs/Microsoft VS Code/bin"
    ;;
esac

_zpath_prepend \
  "$HOME/.nix-profile/bin" \
  /run/current-system/sw/bin \
  /nix/var/nix/profiles/default/bin

for __zsh_brew in \
  /home/linuxbrew/.linuxbrew/bin/brew \
  "$HOME/.linuxbrew/bin/brew" \
  /opt/homebrew/bin/brew \
  /usr/local/bin/brew
do
  if [[ -x $__zsh_brew ]]; then
    __zsh_brew_bin=${__zsh_brew:h}
    __zsh_brew_prefix=${__zsh_brew_bin:h}

    _zpath_prepend "$__zsh_brew_prefix/bin" "$__zsh_brew_prefix/sbin"
    export HOMEBREW_PREFIX=$__zsh_brew_prefix
    export HOMEBREW_CELLAR="$__zsh_brew_prefix/Cellar"
    case $__zsh_brew_prefix in
      /opt/homebrew|*/Homebrew) export HOMEBREW_REPOSITORY=$__zsh_brew_prefix ;;
      *) export HOMEBREW_REPOSITORY="$__zsh_brew_prefix/Homebrew" ;;
    esac
    [[ -z ${MANPATH+x} ]] || export MANPATH=":${MANPATH#:}"
    export INFOPATH="$__zsh_brew_prefix/share/info:${INFOPATH:-}"
    break
  fi
done
unset __zsh_brew __zsh_brew_bin __zsh_brew_prefix

export PATH
