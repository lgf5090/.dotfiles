set -q MISE_DATA_DIR; or set -gx MISE_DATA_DIR "$XDG_DATA_HOME/mise"
set -q FISH_MISE_ACTIVATE; or set -gx FISH_MISE_ACTIVATE shims

if not set -q MISE_CACHE_DIR
    set -l mise_cache "$XDG_CACHE_HOME/mise"
    if not test -d "$mise_cache"
        mkdir -p "$mise_cache" 2>/dev/null
    end
    if not test -w "$mise_cache"
        set -l cache_base /tmp
        set -q TMPDIR; and set cache_base (string trim --right --chars=/ -- "$TMPDIR")
        set mise_cache "$cache_base/mise-$USER"
        test -d "$mise_cache"; or mkdir -p "$mise_cache" 2>/dev/null
    end
    set -gx MISE_CACHE_DIR "$mise_cache"
end

set -l mise
for candidate in \
    "$MISE_EXE" \
    "$HOME/.local/bin/mise" \
    /home/linuxbrew/.linuxbrew/bin/mise \
    "$HOME/.linuxbrew/bin/mise" \
    /opt/homebrew/bin/mise \
    /usr/local/bin/mise \
    /opt/mise/bin/mise
    test -n "$candidate"; and test -x "$candidate"; or continue
    set mise "$candidate"
    break
end

if test -z "$mise"; and test "$SHELLS_OS" = windows
    for candidate in \
        "$HOME/scoop/shims/mise.exe" \
        "$PROGRAMDATA/scoop/shims/mise.exe" \
        "$LOCALAPPDATA/Microsoft/WinGet/Links/mise.exe"
        test -n "$candidate"; and test -x "$candidate"; or continue
        set mise "$candidate"
        break
    end
end

set -l mise_discovery 0
set -q FISH_MISE_DISCOVERY; and set mise_discovery "$FISH_MISE_DISCOVERY"
if test -z "$mise"; and test "$mise_discovery" = 1
    set mise (command -s mise 2>/dev/null)
end

switch (string lower -- "$FISH_MISE_ACTIVATE")
    case full 1 yes true
        if test -n "$mise"; and test -x "$mise"
            "$mise" activate fish | source
        end
end

switch (string lower -- "$FISH_MISE_ACTIVATE")
    case none 0 no false
    case '*'
        _fpath_prepend "$HOME/.mise/shims" "$MISE_DATA_DIR/shims"
end
