set -l manager_discovery 0
set -q FISH_ENV_MANAGER_DISCOVERY; and set manager_discovery "$FISH_ENV_MANAGER_DISCOVERY"

for spec in rbenv:RBENV_ROOT nodenv:NODENV_ROOT goenv:GOENV_ROOT
    set -l parts (string split : -- "$spec")
    set -l manager $parts[1]
    set -l root_var $parts[2]
    set -l manager_root $$root_var
    set -l manager_exe

    if test -n "$manager_root"; and test -x "$manager_root/bin/$manager"
        set manager_exe "$manager_root/bin/$manager"
    else if test "$manager_discovery" = 1
        set manager_exe (command -s "$manager" 2>/dev/null)
    end

    if test -n "$manager_exe"
        "$manager_exe" init - fish 2>/dev/null | source
    end
end

set -l jenv
if set -q JENV_ROOT; and test -x "$JENV_ROOT/bin/jenv"
    set jenv "$JENV_ROOT/bin/jenv"
else if test "$manager_discovery" = 1
    set jenv (command -s jenv 2>/dev/null)
end

if test -n "$jenv"
    "$jenv" init - fish 2>/dev/null | source
end
