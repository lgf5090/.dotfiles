for dir in \
    "$XDG_DATA_HOME/fish/vendor_completions.d" \
    "$HOME/.config/fish/completions" \
    /home/linuxbrew/.linuxbrew/share/fish/vendor_completions.d \
    /opt/homebrew/share/fish/vendor_completions.d \
    /usr/local/share/fish/vendor_completions.d
    test -r "$dir/poetry.fish"; or continue
    contains -- "$dir" $fish_complete_path
    or set -g fish_complete_path "$dir" $fish_complete_path
    break
end
