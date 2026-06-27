function _fpath_remove -a dir
    set -l idx (contains -i -- "$dir" $PATH)
    while test -n "$idx"
        set -e PATH[$idx]
        set idx (contains -i -- "$dir" $PATH)
    end
end

function _fpath_prepend
    for dir in $argv
        test -d "$dir"; or continue
        _fpath_remove "$dir"
        set -gx PATH "$dir" $PATH
    end
end

function _fpath_append
    for dir in $argv
        test -d "$dir"; or continue
        _fpath_remove "$dir"
        set -gx PATH $PATH "$dir"
    end
end

set -g _FLOCAL_LOADER_VERSION 1

function _fpath_prepend_value -a value
    set -l new_path
    for dir in (string split : -- "$value") $PATH
        test -n "$dir"; or continue
        test -d "$dir"; or continue
        contains -- "$dir" $new_path; and continue
        set -a new_path "$dir"
    end
    set -gx PATH $new_path
end

function _fload_envs -a file
    test -r "$file"; or return 0

    while read -l line
        set -l parts (string match -r '^\s*(?:export\s+)?([A-Za-z_][A-Za-z0-9_]*)\s*=\s*(.*?)\s*$' -- "$line")
        test (count $parts) -eq 3; or continue

        set -l key $parts[2]
        set -l val $parts[3]

        if test (string length -- "$val") -ge 2
            switch $val
                case '"*"' "'*'"
                    set val (string sub -s 2 -e -1 -- "$val")
            end
        end

        set val (string replace -a '{HOME}' "$HOME" -- "$val")
        set val (string replace -a '{PATH}' (string join : -- $PATH) -- "$val")

        if test "$key" = PATH
            _fpath_prepend_value "$val"
        else
            set -gx $key "$val"
        end
    end < "$file"
end

function _fload_aliases -a file
    test -r "$file"; or return 0

    set -l load_key "$file:"(path mtime -- "$file")
    if set -q _FLOCAL_ALIASES_LOADED_KEY
        test "$_FLOCAL_ALIASES_LOADED_KEY" = "$load_key"; and return 0
    end

    set -l cache_root "$XDG_CACHE_HOME/fish"
    if not test -d "$cache_root"
        mkdir -p "$cache_root" 2>/dev/null
    end
    if not test -w "$cache_root"
        set -l cache_base /tmp
        set -q TMPDIR; and set cache_base (string trim --right --chars=/ -- "$TMPDIR")
        set cache_root "$cache_base/fish-$USER"
        test -d "$cache_root"; or mkdir -p "$cache_root" 2>/dev/null
    end

    set -l resolved_file (path resolve -- "$file" 2>/dev/null)
    test -n "$resolved_file"; or set resolved_file "$file"
    set -l cache_id (string escape --style=var -- "$resolved_file")
    set -l cache_file "$cache_root/local-aliases-$cache_id.fish"
    set -l cache_header "# _FLOCAL_ALIASES_LOADED_KEY=$load_key"

    if test -r "$cache_file"
        read -l existing_header < "$cache_file"
        if test "$existing_header" = "$cache_header"
            source "$cache_file"
            set -g _FLOCAL_ALIASES_LOADED_KEY "$load_key"
            return 0
        end
    end

    set -l cache_tmp "$cache_file.tmp."(random)
    begin
        printf '%s\n' "$cache_header"
        while read -l line
            set -l parts (string match -r '^\s*([A-Za-z_][A-Za-z0-9_-]*)\s*=\s*(.*?)\s*$' -- "$line")
            test (count $parts) -eq 3; or continue

            set -l name $parts[2]
            set -l body $parts[3]

            if test (string length -- "$body") -ge 2
                switch $body
                    case '"*"' "'*'"
                        set body (string sub -s 2 -e -1 -- "$body")
                end
            end

            printf '%s\n' "$body" | read -l --list words
            set -l wraps
            if test (count $words) -gt 0
                set wraps "--wraps "(string escape -- "$words[1]")
            end
            set -l description (string escape -- "alias $name=$body")

            printf 'function %s %s --description %s\n' "$name" "$wraps" "$description"
            printf '    %s $argv\n' "$body"
            printf 'end\n'
        end < "$file"
    end > "$cache_tmp"

    if test -s "$cache_tmp"
        command mv -f "$cache_tmp" "$cache_file" 2>/dev/null
        if test -r "$cache_file"
            source "$cache_file"
            set -g _FLOCAL_ALIASES_LOADED_KEY "$load_key"
            return 0
        end
    end
    command rm -f "$cache_tmp" 2>/dev/null

    while read -l line
        set -l parts (string match -r '^\s*([A-Za-z_][A-Za-z0-9_-]*)\s*=\s*(.*?)\s*$' -- "$line")
        test (count $parts) -eq 3; or continue

        set -l name $parts[2]
        set -l body $parts[3]

        if test (string length -- "$body") -ge 2
            switch $body
                case '"*"' "'*'"
                    set body (string sub -s 2 -e -1 -- "$body")
            end
        end

        alias "$name" "$body"
    end < "$file"

    set -g _FLOCAL_ALIASES_LOADED_KEY "$load_key"
end

function _fver_ge -a left right
    set -l v1 (string split . -- "$left")
    set -l v2 (string split . -- "$right")

    for i in 1 2 3
        set -l n1 0
        set -l n2 0
        test (count $v1) -ge $i; and set n1 $v1[$i]
        test (count $v2) -ge $i; and set n2 $v2[$i]

        set n1 (string replace -r '[^0-9].*$' '' -- "$n1")
        set n2 (string replace -r '[^0-9].*$' '' -- "$n2")
        test -n "$n1"; or set n1 0
        test -n "$n2"; or set n2 0

        test $n1 -gt $n2; and return 0
        test $n1 -lt $n2; and return 1
    end

    return 0
end

set -q FISH_PLUGIN_DIR; or set -g FISH_PLUGIN_DIR "$XDG_DATA_HOME/fish/plugins"
set -q FISH_PLUGIN_AUTO_INSTALL; or set -g FISH_PLUGIN_AUTO_INSTALL 1
set -q _FPLUGIN_LOADED; or set -g _FPLUGIN_LOADED

function _fplugin -a owner repo
    if test -z "$owner" -o -z "$repo"
        echo "usage: _fplugin <owner> <repo>" >&2
        return 2
    end

    contains -- "$repo" $_FPLUGIN_LOADED; and return 0

    set -l plugin_dir "$FISH_PLUGIN_DIR/$repo"
    if not test -d "$plugin_dir"
        if test "$FISH_PLUGIN_AUTO_INSTALL" != 1
            echo "fish: plugin missing, skip $repo" >&2
            return 0
        end
        command -q git
        or begin
            echo "fish: git not found, skip $repo" >&2
            return 1
        end
        mkdir -p "$FISH_PLUGIN_DIR"; or return
        git clone --depth=1 "https://github.com/$owner/$repo" "$plugin_dir"
        or begin
            echo "fish: failed to install $repo" >&2
            return 1
        end
    end

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

    set -ga _FPLUGIN_LOADED "$repo"
end

function fplugin-update
    command -q git
    or begin
        echo "fish: git not found" >&2
        return 1
    end

    for dir in "$FISH_PLUGIN_DIR"/*
        test -d "$dir/.git"; or continue
        echo "Updating "(basename "$dir")"..."
        git -C "$dir" pull --ff-only
    end
end
