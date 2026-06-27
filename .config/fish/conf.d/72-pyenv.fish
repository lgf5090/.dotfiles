set -q PYENV_ROOT; and _fpath_prepend "$PYENV_ROOT/bin"

set -l pyenv
if set -q PYENV_ROOT; and test -x "$PYENV_ROOT/bin/pyenv"
    set pyenv "$PYENV_ROOT/bin/pyenv"
else
    set -l pyenv_discovery 0
    set -q FISH_PYENV_DISCOVERY; and set pyenv_discovery "$FISH_PYENV_DISCOVERY"
    if test "$pyenv_discovery" = 1
        set pyenv (command -s pyenv 2>/dev/null)
    end
end

if test -n "$pyenv"
    "$pyenv" init - fish 2>/dev/null | source
    "$pyenv" virtualenv-init - fish 2>/dev/null | source
end
