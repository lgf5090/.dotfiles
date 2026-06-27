function _uuid_usage
    printf '%s\n' \
        'usage:' \
        '  uuid' \
        '  uuid -n COUNT' \
        '  uuid -h | --help' \
        '' \
        'Generate RFC 4122 version 4 UUIDs using shell builtins. On Linux, this reads' \
        '/proc/sys/kernel/random/uuid with the shell builtin read; otherwise it falls' \
        "back to fish's random builtin."
end

function _uuid_v4
    if test -r /proc/sys/kernel/random/uuid
        read -l generated_uuid < /proc/sys/kernel/random/uuid
        if string match -qr '^[0-9A-Fa-f]{8}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{12}$' -- "$generated_uuid"
            printf '%s\n' "$generated_uuid"
            return 0
        end
    end

    set -l a (random 0 65535)
    set -l b (random 0 65535)
    set -l c (math "0x4000 + ("(random 0 65535)" % 0x1000)")
    set -l d (math "0x8000 + ("(random 0 65535)" % 0x4000)")
    set -l e (random 0 65535)
    set -l f (random 0 65535)
    set -l g (random 0 65535)
    set -l h (random 0 65535)

    printf '%04x%04x-%04x-%04x-%04x-%04x%04x%04x\n' $a $b $c $d $e $f $g $h
end

function uuid --description 'Generate RFC 4122 version 4 UUIDs'
    set -l count 1
    set -l argv_copy $argv

    while test (count $argv_copy) -gt 0
        switch $argv_copy[1]
            case -h --help
                _uuid_usage
                return 0
            case -n --count
                if test (count $argv_copy) -lt 2; or not string match -qr '^[1-9][0-9]*$' -- "$argv_copy[2]"
                    echo "uuid: $argv_copy[1] requires a positive integer" >&2
                    return 2
                end
                set count $argv_copy[2]
                set -e argv_copy[1..2]
            case --
                set -e argv_copy[1]
                if test (count $argv_copy) -gt 0
                    echo "uuid: unexpected argument: $argv_copy[1]" >&2
                    return 2
                end
            case '-*'
                echo "uuid: unknown option: $argv_copy[1]" >&2
                return 2
            case '*'
                echo "uuid: unexpected argument: $argv_copy[1]" >&2
                return 2
        end
    end

    set -l i 1
    while test $i -le $count
        _uuid_v4
        set i (math "$i + 1")
    end
end

complete -e uuid 2>/dev/null
complete -c uuid -s h -l help -d 'Show help'
complete -c uuid -s n -l count -x -a '1 2 3 5 10 20 50 100' -d 'Number of UUIDs'
