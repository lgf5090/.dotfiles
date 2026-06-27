set -q XDG_CONFIG_HOME; or set -gx XDG_CONFIG_HOME $HOME/.config
set -q XDG_DATA_HOME; or set -gx XDG_DATA_HOME $HOME/.local/share
set -q XDG_STATE_HOME; or set -gx XDG_STATE_HOME $HOME/.local/state
set -q XDG_CACHE_HOME; or set -gx XDG_CACHE_HOME $HOME/.cache

for dir in "$XDG_STATE_HOME/fish" "$XDG_CACHE_HOME/fish"
    test -d "$dir"; or mkdir -p "$dir" 2>/dev/null
end
