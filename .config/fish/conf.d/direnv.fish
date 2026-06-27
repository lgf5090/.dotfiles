if status is-interactive
    set -l direnv_candidates
    set -q DIRENV_EXE; and set -a direnv_candidates "$DIRENV_EXE"
    set -a direnv_candidates \
        "$HOME/.local/bin/direnv" \
        /home/linuxbrew/.linuxbrew/bin/direnv \
        "$HOME/.linuxbrew/bin/direnv" \
        /opt/homebrew/bin/direnv \
        /usr/local/bin/direnv \
        /usr/bin/direnv

    set -l direnv
    for candidate in $direnv_candidates
        test -n "$candidate"; and test -x "$candidate"; or continue
        set direnv "$candidate"
        break
    end

    set -l direnv_discovery 0
    set -q FISH_DIRENV_DISCOVERY; and set direnv_discovery "$FISH_DIRENV_DISCOVERY"
    if test -z "$direnv"; and test "$direnv_discovery" = 1
        set direnv (command -s direnv 2>/dev/null)
    end

    if test -n "$direnv"; and test -x "$direnv"
        set -l direnv_real (path resolve -- "$direnv" 2>/dev/null)
        test -n "$direnv_real"; or set direnv_real "$direnv"
        set -l cache_dir "$XDG_CACHE_HOME/fish"
        set -l cache_key (string replace -a / % -- "$direnv_real")
        set -l cache_file "$cache_dir/direnv-hook-$cache_key.fish"

        if test -s "$cache_file"; and test "$cache_file" -nt "$direnv_real"
            source "$cache_file"
        else
            set -l direnv_hook ("$direnv" hook fish 2>/dev/null)
            if test -n "$direnv_hook"
                string join \n -- $direnv_hook | source
                test -d "$cache_dir"; or mkdir -p "$cache_dir" 2>/dev/null
                if test -d "$cache_dir"; and test -w "$cache_dir"
                    set -l cache_tmp "$cache_file.tmp."(random)
                    printf '%s\n' $direnv_hook > "$cache_tmp"
                    and command mv -f "$cache_tmp" "$cache_file" 2>/dev/null
                    or command rm -f "$cache_tmp" 2>/dev/null
                end
            end
        end
    end
end
