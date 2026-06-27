set -q ASDF_DIR; and _fpath_prepend "$ASDF_DIR/bin"
set -q ASDF_DATA_DIR; and _fpath_prepend "$ASDF_DATA_DIR/shims"

for script in \
    "$ASDF_DIR/asdf.fish" \
    "$ASDF_DIR/libexec/asdf.fish" \
    /home/linuxbrew/.linuxbrew/opt/asdf/libexec/asdf.fish \
    /opt/homebrew/opt/asdf/libexec/asdf.fish \
    /usr/local/opt/asdf/libexec/asdf.fish \
    "$HOME/.asdf/asdf.fish"
    test -r "$script"; or continue
    source "$script"
    break
end

for dir in \
    "$ASDF_DIR/completions" \
    "$ASDF_DIR/libexec/completions" \
    /home/linuxbrew/.linuxbrew/opt/asdf/libexec/completions \
    /opt/homebrew/opt/asdf/libexec/completions \
    /usr/local/opt/asdf/libexec/completions \
    "$HOME/.asdf/completions"
    test -d "$dir"; or continue
    contains -- "$dir" $fish_complete_path
    or set -g fish_complete_path "$dir" $fish_complete_path
    break
end
