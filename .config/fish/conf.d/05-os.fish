if set -q SHELLS_OS; and contains -- "$SHELLS_OS" linux wsl macos freebsd cygwin windows unknown
    return 0
end

set -l __fish_uname (command uname -s)
set __fish_uname (string lower -- "$__fish_uname")

switch $__fish_uname
    case 'linux*'
        set -gx SHELLS_OS linux
    case 'darwin*'
        set -gx SHELLS_OS macos
    case 'freebsd*'
        set -gx SHELLS_OS freebsd
    case 'cygwin*'
        set -gx SHELLS_OS cygwin
    case 'msys*' 'mingw*'
        set -gx SHELLS_OS windows
    case '*'
        set -gx SHELLS_OS unknown
end

if test "$SHELLS_OS" = linux; and test -r /proc/version
    read -l proc_version < /proc/version
    string match -qir 'microsoft|wsl' -- "$proc_version"; and set -gx SHELLS_OS wsl
end
