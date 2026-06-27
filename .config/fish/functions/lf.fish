function lf --description 'lf with directory follow'
    command -q lf
    or begin
        echo 'lf: command not found' >&2
        return 127
    end

    set -l tmp (mktemp "$TMPDIR/lf-cwd.XXXXXX" 2>/dev/null; or mktemp "/tmp/lf-cwd.XXXXXX")
    command lf -last-dir-path="$tmp" $argv
    set -l rc $status

    if test -s "$tmp"
        set -l dir (cat "$tmp")
        test -d "$dir"; and test "$dir" != "$PWD"; and cd -- "$dir"
    end

    rm -f -- "$tmp"
    return $rc
end
