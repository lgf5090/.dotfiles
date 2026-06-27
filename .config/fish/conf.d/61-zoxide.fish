if status is-interactive
    set -l zoxide_candidates
    set -q ZOXIDE_EXE; and set -a zoxide_candidates "$ZOXIDE_EXE"
    set -a zoxide_candidates \
        "$HOME/.local/bin/zoxide" \
        /home/linuxbrew/.linuxbrew/bin/zoxide \
        "$HOME/.linuxbrew/bin/zoxide" \
        /opt/homebrew/bin/zoxide \
        /usr/local/bin/zoxide \
        /usr/bin/zoxide

    set -l zoxide
    for candidate in $zoxide_candidates
        test -n "$candidate"; and test -x "$candidate"; or continue
        set zoxide "$candidate"
        break
    end

    set -l zoxide_discovery 0
    set -q FISH_ZOXIDE_DISCOVERY; and set zoxide_discovery "$FISH_ZOXIDE_DISCOVERY"
    if test -z "$zoxide"; and test "$zoxide_discovery" = 1
        set zoxide (command -s zoxide 2>/dev/null)
    end

    if test -n "$zoxide"; and test -x "$zoxide"
        set -l cache_dir "$XDG_CACHE_HOME/fish"
        set -l cache_key (string replace -a / % -- "$zoxide")
        set -l cache_file "$cache_dir/zoxide-init-$cache_key.fish"

        if test -s "$cache_file"; and test "$cache_file" -nt "$zoxide"
            source "$cache_file"
        else
            set -l zoxide_init ("$zoxide" init fish 2>/dev/null)
            if test -n "$zoxide_init"
                string join \n -- $zoxide_init | source
                test -d "$cache_dir"; or mkdir -p "$cache_dir" 2>/dev/null
                if test -d "$cache_dir"; and test -w "$cache_dir"
                    set -l cache_tmp "$cache_file.tmp."(random)
                    printf '%s\n' $zoxide_init > "$cache_tmp"
                    and command mv -f "$cache_tmp" "$cache_file" 2>/dev/null
                    or command rm -f "$cache_tmp" 2>/dev/null
                end
            end
        end
    end
end
