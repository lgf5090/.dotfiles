if test -f "$XDG_CONFIG_HOME/lf/icons"
    set -gx LF_ICONS (string join : -- (cat "$XDG_CONFIG_HOME/lf/icons"))
end

if command -q lf
    function lf
        set -l tmp_dir /tmp
        set -q TMPDIR; and test -n "$TMPDIR"; and set tmp_dir "$TMPDIR"
        set -l tmp (mktemp "$tmp_dir/lf-cwd.XXXXXX")
        or return

        command lf -last-dir-path="$tmp" $argv
        set -l rc $status

        if test -s "$tmp"
            set -l dir (cat "$tmp")
            if test -d "$dir"; and test "$dir" != "$PWD"
                builtin cd -- "$dir"
            end
        end

        rm -f -- "$tmp"
        return $rc
    end
end
