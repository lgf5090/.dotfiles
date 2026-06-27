__bash_path_append=(
  "$HOME/.lmstudio/bin" \
  "$HOME/.mimocode/bin" \
  "$HOME/.turso" \
  "$HOME/.local/bin" \
  "$HOME/bin" \
  "$HOME/Applications" \
  "$HOME/.local/Applications"
)

_bpath_prepend \
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

__bash_path_prepend=(
  "${BUN_INSTALL:+$BUN_INSTALL/bin}" \
  "${DENO_INSTALL:+$DENO_INSTALL/bin}" \
  "${NPM_CONFIG_PREFIX:+$NPM_CONFIG_PREFIX/bin}" \
  "${PNPM_HOME:+$PNPM_HOME}" \
  "$HOME/.yarn/bin" \
  "$HOME/.config/yarn/global/node_modules/.bin" \
  "${VOLTA_HOME:+$VOLTA_HOME/bin}" \
  "$HOME/.volta/bin" \
  "${FNM_DIR:+$FNM_DIR}" \
  "$HOME/.local/share/npm/bin" \
  "${PYENV_ROOT:+$PYENV_ROOT/bin}" \
  "${ANACONDA_HOME:+$ANACONDA_HOME/bin}" \
  "${POETRY_HOME:+$POETRY_HOME/bin}" \
  "$HOME/.poetry/bin" \
  "$HOME/.local/pipx/bin" \
  "${GOPATH:+$GOPATH/bin}" \
  "${GOROOT:+$GOROOT/bin}"
)

case ${SHELLS_OS:-unknown} in
  linux|wsl)
    __bash_path_append+=( \
      /snap/bin \
      /var/lib/snapd/snap/bin \
      /var/lib/flatpak/exports/bin \
      "$HOME/.local/share/flatpak/exports/bin" \
      /opt/bin
    )
    ;;
esac

case ${SHELLS_OS:-unknown} in
  wsl)
    __bash_path_append+=( \
      "/mnt/c/Program Files/Microsoft VS Code/bin" \
      "/mnt/c/Users/$USER/AppData/Local/Programs/Microsoft VS Code/bin"
    )
    ;;
  cygwin)
    __bash_path_prepend+=(/mingw64/bin)
    __bash_path_append+=( \
      "/cygdrive/c/Program Files/Microsoft VS Code/bin" \
      "/cygdrive/c/Users/$USER/AppData/Local/Programs/Microsoft VS Code/bin"
    )
    ;;
  windows)
    __bash_path_prepend+=(/mingw64/bin)
    __bash_path_append+=( \
      "/c/Program Files/Microsoft VS Code/bin" \
      "/c/Users/$USER/AppData/Local/Programs/Microsoft VS Code/bin"
    )
    ;;
esac

__bash_path_prepend+=( \
  "$HOME/.nix-profile/bin" \
  /run/current-system/sw/bin \
  /nix/var/nix/profiles/default/bin
)

for __bash_brew in \
  /home/linuxbrew/.linuxbrew/bin/brew \
  "$HOME/.linuxbrew/bin/brew" \
  /opt/homebrew/bin/brew \
  /usr/local/bin/brew
do
  if [[ -x $__bash_brew ]]; then
    __bash_brew_bin=${__bash_brew%/*}
    __bash_brew_prefix=${__bash_brew_bin%/*}

    __bash_path_prepend+=("$__bash_brew_prefix/sbin" "$__bash_brew_prefix/bin")
    export HOMEBREW_PREFIX=$__bash_brew_prefix
    export HOMEBREW_CELLAR="$__bash_brew_prefix/Cellar"
    case $__bash_brew_prefix in
      /opt/homebrew|*/Homebrew) export HOMEBREW_REPOSITORY=$__bash_brew_prefix ;;
      *) export HOMEBREW_REPOSITORY="$__bash_brew_prefix/Homebrew" ;;
    esac
    [[ -z ${MANPATH+x} ]] || export MANPATH=":${MANPATH#:}"
    export INFOPATH="$__bash_brew_prefix/share/info:${INFOPATH:-}"
    break
  fi
done

_bpath_append "${__bash_path_append[@]}"
_bpath_prepend "${__bash_path_prepend[@]}"

unset __bash_path_append __bash_path_prepend
unset __bash_brew __bash_brew_bin __bash_brew_prefix
export PATH
