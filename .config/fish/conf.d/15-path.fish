_fpath_append \
    "$HOME/.lmstudio/bin" \
    "$HOME/.mimocode/bin" \
    "$HOME/.turso" \
    "$HOME/.local/bin" \
    "$HOME/bin" \
    "$HOME/Applications" \
    "$HOME/.local/Applications"

set -q ASDF_DIR; and _fpath_prepend "$ASDF_DIR/bin"
set -q RBENV_ROOT; and _fpath_prepend "$RBENV_ROOT/bin"
set -q NODENV_ROOT; and _fpath_prepend "$NODENV_ROOT/bin"
set -q GOENV_ROOT; and _fpath_prepend "$GOENV_ROOT/bin"
set -q JENV_ROOT; and _fpath_prepend "$JENV_ROOT/bin"

set -l cargo_home "$HOME/.cargo"
set -q CARGO_HOME; and set cargo_home "$CARGO_HOME"
_fpath_prepend \
    "$cargo_home/bin" \
    "$HOME/.rd/bin" \
    "$HOME/.opencode/bin"

test -r "$HOME/.cargo/env.fish"; and source "$HOME/.cargo/env.fish"
test -r "$HOME/.turso/env.fish"; and source "$HOME/.turso/env.fish"

set -q BUN_INSTALL; and _fpath_prepend "$BUN_INSTALL/bin"
set -q DENO_INSTALL; and _fpath_prepend "$DENO_INSTALL/bin"
set -q NPM_CONFIG_PREFIX; and _fpath_prepend "$NPM_CONFIG_PREFIX/bin"
set -q PNPM_HOME; and _fpath_prepend "$PNPM_HOME"
_fpath_prepend \
    "$HOME/.yarn/bin" \
    "$HOME/.config/yarn/global/node_modules/.bin"
set -q VOLTA_HOME; and _fpath_prepend "$VOLTA_HOME/bin"
_fpath_prepend "$HOME/.volta/bin"
set -q FNM_DIR; and _fpath_prepend "$FNM_DIR"
_fpath_prepend "$HOME/.local/share/npm/bin"

set -q PYENV_ROOT; and _fpath_prepend "$PYENV_ROOT/bin"
set -q ANACONDA_HOME; and _fpath_prepend "$ANACONDA_HOME/bin"
set -q POETRY_HOME; and _fpath_prepend "$POETRY_HOME/bin"
_fpath_prepend \
    "$HOME/.poetry/bin" \
    "$HOME/.local/pipx/bin"

set -q GOPATH; and _fpath_prepend "$GOPATH/bin"
set -q GOROOT; and _fpath_prepend "$GOROOT/bin"

switch "$SHELLS_OS"
    case linux wsl
        _fpath_append \
            /snap/bin \
            /var/lib/snapd/snap/bin \
            /var/lib/flatpak/exports/bin \
            "$HOME/.local/share/flatpak/exports/bin" \
            /opt/bin
end

switch "$SHELLS_OS"
    case wsl
        _fpath_append \
            "/mnt/c/Program Files/Microsoft VS Code/bin" \
            "/mnt/c/Users/$USER/AppData/Local/Programs/Microsoft VS Code/bin"
    case cygwin
        _fpath_prepend /mingw64/bin
        _fpath_append \
            "/cygdrive/c/Program Files/Microsoft VS Code/bin" \
            "/cygdrive/c/Users/$USER/AppData/Local/Programs/Microsoft VS Code/bin"
    case windows
        _fpath_prepend /mingw64/bin
        _fpath_append \
            "/c/Program Files/Microsoft VS Code/bin" \
            "/c/Users/$USER/AppData/Local/Programs/Microsoft VS Code/bin"
end

_fpath_prepend \
    "$HOME/.nix-profile/bin" \
    /run/current-system/sw/bin \
    /nix/var/nix/profiles/default/bin

for brew in \
    /home/linuxbrew/.linuxbrew/bin/brew \
    "$HOME/.linuxbrew/bin/brew" \
    /opt/homebrew/bin/brew \
    /usr/local/bin/brew
    if test -x "$brew"
        set -l brew_bin (path dirname "$brew")
        set -l brew_prefix (path dirname "$brew_bin")

        _fpath_prepend "$brew_prefix/sbin" "$brew_prefix/bin"
        set -gx HOMEBREW_PREFIX "$brew_prefix"
        set -gx HOMEBREW_CELLAR "$brew_prefix/Cellar"
        switch "$brew_prefix"
            case /opt/homebrew '*/Homebrew'
                set -gx HOMEBREW_REPOSITORY "$brew_prefix"
            case '*'
                set -gx HOMEBREW_REPOSITORY "$brew_prefix/Homebrew"
        end
        if set -q MANPATH[1]; and test -n "$MANPATH[1]"
            set -gx MANPATH '' $MANPATH
        end
        contains -- "$brew_prefix/share/info" $INFOPATH
        or set -gx INFOPATH "$brew_prefix/share/info" $INFOPATH
        break
    end
end
