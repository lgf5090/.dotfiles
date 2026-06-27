if status is-interactive; and not set -q SHELLS_NO_PROMPT
    if command -q starship
        starship init fish | source
    else
        command -q git; and set -g __fish_prompt_has_git 1

        function fish_prompt
            set -l rc $status
            set -l now (date +%H:%M:%S)
            set -l cwd (string replace -r "^$HOME" '~' -- "$PWD")

            set -l extra
            if set -q VIRTUAL_ENV
                set extra $extra (set_color cyan)"("(basename "$VIRTUAL_ENV")")"(set_color normal)
            else if set -q CONDA_DEFAULT_ENV; and test "$CONDA_DEFAULT_ENV" != base
                set extra $extra (set_color cyan)"($CONDA_DEFAULT_ENV)"(set_color normal)
            end

            if set -q __fish_prompt_has_git
                set -l dir "$PWD"
                while test -n "$dir"; and test "$dir" != /
                    if test -e "$dir/.git"
                        set -l branch (git symbolic-ref --short HEAD 2>/dev/null; or git rev-parse --short HEAD 2>/dev/null)
                        if test -n "$branch"
                            set -l dirty
                            git diff-index --quiet HEAD -- 2>/dev/null; or set dirty '*'
                            set extra $extra (set_color magenta)"$branch$dirty"(set_color normal)
                        end
                        break
                    end
                    set dir (string replace -r '/[^/]*$' '' -- "$dir")
                end
            end

            printf '%s[%s]%s %s%s%s@%s %s[%s]%s' \
                (set_color brblack) $now (set_color normal) \
                (set_color green) $USER (set_color brwhite) $hostname \
                (set_color blue) $cwd (set_color normal)

            for item in $extra
                printf ' %s' "$item"
            end

            test $rc -ne 0; and printf ' %s[%s]%s' (set_color red) $rc (set_color normal)
            printf '\n%s$ %s' (set_color cyan) (set_color normal)
        end
    end
end
