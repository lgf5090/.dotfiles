set -q FNM_DIR; and _fpath_prepend "$FNM_DIR"

set -q FISH_FNM_ACTIVATE; or set -gx FISH_FNM_ACTIVATE default

switch (string lower -- "$FISH_FNM_ACTIVATE")
    case full use-on-cd 1 yes true
        if command -q fnm
            fnm env --use-on-cd --shell fish 2>/dev/null | source
        end
    case env
        if command -q fnm
            fnm env --shell fish 2>/dev/null | source
        end
    case none 0 no false
    case '*'
        set -q FNM_DIR; and _fpath_prepend "$FNM_DIR/aliases/default/bin"
end
