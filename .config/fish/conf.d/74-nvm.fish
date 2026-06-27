set -q NVM_DIR; or set -gx NVM_DIR "$HOME/.nvm"

if not functions -q nvm
    for plugin_dir in \
        "$XDG_DATA_HOME/fish/plugins/nvm.fish" \
        "$HOME/.config/fish/plugins/nvm.fish" \
        "$HOME/.local/share/fisherman/nvm.fish"
        test -d "$plugin_dir"; or continue

        if test -d "$plugin_dir/functions"
            contains -- "$plugin_dir/functions" $fish_function_path
            or set -g fish_function_path "$plugin_dir/functions" $fish_function_path
        end

        if test -d "$plugin_dir/completions"
            contains -- "$plugin_dir/completions" $fish_complete_path
            or set -g fish_complete_path "$plugin_dir/completions" $fish_complete_path
        end

        for file in "$plugin_dir"/conf.d/*.fish "$plugin_dir"/init.fish
            test -r "$file"; and source "$file"
        end
        break
    end
end
