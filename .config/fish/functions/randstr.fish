function _randstr_usage
    printf '%s\n' \
        'usage:' \
        '  randstr [LENGTH] [COUNT]' \
        '  randstr -l LENGTH -n COUNT [options]' \
        '  randstr -h | --help' \
        '' \
        'Generate random strings using fish builtins.' \
        '' \
        'options:' \
        '  -l, --length N        characters per string, default: 16' \
        '  -n, --count N         number of strings, default: 1' \
        '  --lower               use a-z' \
        '  --upper               use A-Z' \
        '  --alpha               use A-Za-z' \
        '  --digits              use 0-9' \
        '  --alnum               use A-Za-z0-9, default' \
        '  --hex                 use 0-9a-f' \
        '  --safe                use A-Za-z0-9_-' \
        '  --symbols             use shell-friendly symbols' \
        '  --alphabet CHARS      use a custom character set' \
        '  --prefix TEXT         prepend TEXT to each string' \
        '  --suffix TEXT         append TEXT to each string'
end

function _randstr_positive_int --argument-names value
    string match -qr '^[1-9][0-9]*$' -- "$value"
end

function _randstr_generate_one --argument-names length alphabet prefix suffix
    set -l alphabet_len (string length -- "$alphabet")
    set -l out
    set -l i 1

    while test $i -le $length
        set -l pos (random 1 $alphabet_len)
        set out "$out"(string sub -s $pos -l 1 -- "$alphabet")
        set i (math "$i + 1")
    end

    printf '%s%s%s\n' "$prefix" "$out" "$suffix"
end

function randstr --description 'Generate random strings'
    set -l length 16
    set -l count 1
    set -l alphabet ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789
    set -l prefix
    set -l suffix
    set -l positional 0
    set -l argv_copy $argv

    while test (count $argv_copy) -gt 0
        switch $argv_copy[1]
            case -h --help
                _randstr_usage
                return 0
            case -l --length
                if test (count $argv_copy) -lt 2; or not _randstr_positive_int "$argv_copy[2]"
                    echo "randstr: $argv_copy[1] requires a positive integer" >&2
                    return 2
                end
                set length $argv_copy[2]
                set -e argv_copy[1..2]
            case -n --count
                if test (count $argv_copy) -lt 2; or not _randstr_positive_int "$argv_copy[2]"
                    echo "randstr: $argv_copy[1] requires a positive integer" >&2
                    return 2
                end
                set count $argv_copy[2]
                set -e argv_copy[1..2]
            case --lower
                set alphabet abcdefghijklmnopqrstuvwxyz
                set -e argv_copy[1]
            case --upper
                set alphabet ABCDEFGHIJKLMNOPQRSTUVWXYZ
                set -e argv_copy[1]
            case --alpha
                set alphabet ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz
                set -e argv_copy[1]
            case --digits
                set alphabet 0123456789
                set -e argv_copy[1]
            case --alnum
                set alphabet ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789
                set -e argv_copy[1]
            case --hex
                set alphabet 0123456789abcdef
                set -e argv_copy[1]
            case --safe
                set alphabet ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_-
                set -e argv_copy[1]
            case --symbols
                set alphabet '!#$%&()*+,-./:;<=>?@[]^_{|}~'
                set -e argv_copy[1]
            case --alphabet
                if test (count $argv_copy) -lt 2; or test -z "$argv_copy[2]"
                    echo 'randstr: --alphabet requires CHARS' >&2
                    return 2
                end
                set alphabet "$argv_copy[2]"
                set -e argv_copy[1..2]
            case --prefix
                if test (count $argv_copy) -lt 2
                    echo 'randstr: --prefix requires TEXT' >&2
                    return 2
                end
                set prefix "$argv_copy[2]"
                set -e argv_copy[1..2]
            case --suffix
                if test (count $argv_copy) -lt 2
                    echo 'randstr: --suffix requires TEXT' >&2
                    return 2
                end
                set suffix "$argv_copy[2]"
                set -e argv_copy[1..2]
            case --
                set -e argv_copy[1]
                while test (count $argv_copy) -gt 0
                    if test $positional -eq 0
                        if not _randstr_positive_int "$argv_copy[1]"
                            echo 'randstr: LENGTH requires a positive integer' >&2
                            return 2
                        end
                        set length $argv_copy[1]
                    else if test $positional -eq 1
                        if not _randstr_positive_int "$argv_copy[1]"
                            echo 'randstr: COUNT requires a positive integer' >&2
                            return 2
                        end
                        set count $argv_copy[1]
                    else
                        echo "randstr: unexpected argument: $argv_copy[1]" >&2
                        return 2
                    end
                    set positional (math "$positional + 1")
                    set -e argv_copy[1]
                end
            case '-*'
                echo "randstr: unknown option: $argv_copy[1]" >&2
                return 2
            case '*'
                if test $positional -eq 0
                    if not _randstr_positive_int "$argv_copy[1]"
                        echo 'randstr: LENGTH requires a positive integer' >&2
                        return 2
                    end
                    set length $argv_copy[1]
                else if test $positional -eq 1
                    if not _randstr_positive_int "$argv_copy[1]"
                        echo 'randstr: COUNT requires a positive integer' >&2
                        return 2
                    end
                    set count $argv_copy[1]
                else
                    echo "randstr: unexpected argument: $argv_copy[1]" >&2
                    return 2
                end
                set positional (math "$positional + 1")
                set -e argv_copy[1]
        end
    end

    if test -z "$alphabet"
        echo 'randstr: alphabet must not be empty' >&2
        return 2
    end

    set -l i 1
    while test $i -le $count
        _randstr_generate_one "$length" "$alphabet" "$prefix" "$suffix"
        set i (math "$i + 1")
    end
end

complete -e randstr 2>/dev/null
complete -c randstr -s h -l help -d 'Show help'
complete -c randstr -s l -l length -x -a '8 12 16 24 32 48 64' -d 'Characters per string'
complete -c randstr -s n -l count -x -a '1 2 3 5 10 20 50 100' -d 'Number of strings'
complete -c randstr -l lower -d 'Use a-z'
complete -c randstr -l upper -d 'Use A-Z'
complete -c randstr -l alpha -d 'Use A-Za-z'
complete -c randstr -l digits -d 'Use 0-9'
complete -c randstr -l alnum -d 'Use A-Za-z0-9'
complete -c randstr -l hex -d 'Use 0-9a-f'
complete -c randstr -l safe -d 'Use A-Za-z0-9_-'
complete -c randstr -l symbols -d 'Use shell-friendly symbols'
complete -c randstr -l alphabet -x -d 'Custom character set'
complete -c randstr -l prefix -x -d 'Prefix each string'
complete -c randstr -l suffix -x -d 'Suffix each string'
