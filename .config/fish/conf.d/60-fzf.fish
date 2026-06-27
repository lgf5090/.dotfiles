if command -q fd
    set -gx FZF_DEFAULT_COMMAND 'fd --type f --hidden --strip-cwd-prefix'
else
    set -gx FZF_DEFAULT_COMMAND 'find . -type f'
end

set -q FISH_FZF_COMPLETION; or set -gx FISH_FZF_COMPLETION 0
set -gx FZF_CTRL_T_COMMAND "$FZF_DEFAULT_COMMAND"
set -gx FZF_DEFAULT_OPTS '--height=60% --layout=reverse --border=rounded --preview-window=right:65%:wrap:border-left'

if command -q bat
    set -gx _FZF_PREVIEW_CMD 'bat --color=always --style=plain,numbers --line-range=:500 {}'
else
    set -gx _FZF_PREVIEW_CMD 'sed -n "1,200p" {} 2>/dev/null'
end
set -gx FZF_CTRL_T_OPTS "--preview '$_FZF_PREVIEW_CMD'"

if status is-interactive; and command -q fzf
    set -l fzf_dirs
    set -q HOMEBREW_PREFIX; and set -a fzf_dirs "$HOMEBREW_PREFIX/opt/fzf/shell"
    set -a fzf_dirs \
        /home/linuxbrew/.linuxbrew/opt/fzf/shell \
        /opt/homebrew/opt/fzf/shell \
        /usr/local/opt/fzf/shell \
        /usr/share/fzf \
        /usr/share/doc/fzf/examples

    set -l fzf_loaded 0
    for dir in $fzf_dirs
        test -r "$dir/key-bindings.fish"; or test -r "$dir/completion.fish"; or continue
        test -r "$dir/key-bindings.fish"; and source "$dir/key-bindings.fish"
        switch (string lower -- "$FISH_FZF_COMPLETION")
            case 1 yes true on
                test -r "$dir/completion.fish"; and source "$dir/completion.fish"
        end
        set fzf_loaded 1
        break
    end

    if test "$fzf_loaded" != 1
        set -l fzf_ver (fzf --version 2>/dev/null)
        set -l fzf_ver_parts (string split ' ' -- $fzf_ver)
        set fzf_ver $fzf_ver_parts[1]

        if _fver_ge "$fzf_ver" 0.48.0
            fzf --fish | source
        end
    end
end
