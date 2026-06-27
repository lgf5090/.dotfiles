function _spm_help
    printf '%s\n' \
        'spm - simple cross-platform package manager helper' \
        '' \
        'USAGE' \
        '  spm [package ...]' \
        '  spm -i | --install package ...' \
        '  spm -u | --upgrade [package ...]' \
        '  spm -s | --search query' \
        '  spm -r | --remove package ...' \
        '  spm --info package' \
        '  spm --list [query]' \
        '  spm --update' \
        '  spm --clean' \
        '  spm --manager NAME action [package ...]' \
        '  spm --dry-run action [package ...]' \
        '  spm -h | --help' \
        '' \
        'DEFAULTS' \
        '  spm git' \
        '      Install git. On Debian/Ubuntu this runs: sudo apt install -y git' \
        '' \
        '  spm -i git' \
        '  spm --install git' \
        '      Install git.' \
        '' \
        '  spm -u git' \
        '  spm --upgrade git' \
        '      Upgrade git.' \
        '' \
        '  spm -u' \
        '  spm --upgrade' \
        '      Upgrade all packages. On Debian/Ubuntu this runs:' \
        '        sudo apt update && sudo apt upgrade -y' \
        '' \
        '  spm -s git' \
        '  spm --search git' \
        '      Search package names/descriptions.' \
        '' \
        'MORE EXAMPLES' \
        '  spm --remove git' \
        '  spm --info git' \
        '  spm --list git' \
        '  spm --update' \
        '  spm --clean' \
        '  spm --which' \
        '  spm --dry-run -u' \
        '  spm -m apt install curl' \
        '  spm --manager brew search ripgrep' \
        '' \
        'PACKAGE MANAGER PRIORITY' \
        '  Unix, Linux, macOS, WSL, WSL2:' \
        '    brew first, then system managers such as apt, dnf, yum, apk, pacman,' \
        '    zypper, xbps-install, emerge, eopkg, swupd, pkg, pkg_add, pkgin,' \
        '    port, nix, guix, and conda.' \
        '' \
        '  Windows shells:' \
        '    winget, then scoop, then choco.' \
        '' \
        'OPTIONS' \
        '  -i, --install       install packages' \
        '  -u, --upgrade       upgrade packages, or all packages when no package is given' \
        '  -s, --search        search packages' \
        '  -r, --remove        remove packages' \
        '      --info          show package details' \
        '  -l, --list          list installed packages, optionally filtered by query' \
        '      --update        refresh package indexes' \
        '      --clean         clean package manager caches when supported' \
        '      --which         print selected package manager' \
        '  -m, --manager NAME  force a package manager for this invocation' \
        '      --dry-run       print commands without running them' \
        '  -h, --help          show this help' \
        '' \
        'ENVIRONMENT' \
        '  SPM_MANAGER         default package manager override, same as --manager' \
        '  SPM_NO_SUDO=1       never prepend sudo'
end

function _spm_has
    command -q -- $argv[1]
end

function _spm_is_windows
    switch "$OSTYPE"
        case 'msys*' 'cygwin*' 'win32*'
            return 0
    end

    set -l kernel (command uname -s 2>/dev/null)
    switch "$kernel"
        case 'MINGW*' 'MSYS*' 'CYGWIN*' Windows_NT
            return 0
    end

    return 1
end

function _spm_detect_manager
    if set -q SPM_MANAGER; and test -n "$SPM_MANAGER"
        echo $SPM_MANAGER
        return 0
    end

    if _spm_is_windows
        for manager in winget scoop choco
            if _spm_has $manager
                echo $manager
                return 0
            end
        end
        return 1
    end

    for manager in brew apt apt-get nala dnf dnf5 yum microdnf apk pacman paru yay zypper xbps-install emerge eopkg swupd pkg pkg_add pkgin port nix-env profile nix guix conda
        switch $manager
            case profile
                if _spm_has nix; and nix profile --help >/dev/null 2>&1
                    echo nix-profile
                    return 0
                end
            case '*'
                if _spm_has $manager
                    echo $manager
                    return 0
                end
        end
    end

    return 1
end

function _spm_needs_sudo
    set -l manager $argv[1]

    if test "$SPM_NO_SUDO" = 1
        return 1
    end

    if test (id -u 2>/dev/null) = 0
        return 1
    end

    switch $manager
        case apt apt-get nala dnf dnf5 yum microdnf apk pacman zypper xbps-install emerge eopkg swupd pkg pkg_add port
            _spm_has sudo
        case '*'
            return 1
    end
end

function _spm_run
    set -l dry_run $argv[1]
    set -e argv[1]

    if test "$dry_run" = 1
        printf '+'
        for arg in $argv
            printf ' %s' (string escape -- $arg)
        end
        printf '\n'
        return 0
    end

    command $argv
end

function _spm_sudo_run
    set -l dry_run $argv[1]
    set -l manager $argv[2]
    set -e argv[1 2]

    if _spm_needs_sudo $manager
        _spm_run $dry_run sudo $argv
    else
        _spm_run $dry_run $argv
    end
end

function _spm_join
    string join ' ' -- $argv
end

function _spm_unsupported
    echo "spm: $argv[1] does not support action: $argv[2]" >&2
    return 2
end

function _spm_require_packages
    set -l action $argv[1]
    set -e argv[1]

    if test (count $argv) -eq 0
        echo "spm: $action requires at least one package/query" >&2
        return 2
    end
end

function _spm_exec
    set -l manager $argv[1]
    set -l action $argv[2]
    set -l dry_run $argv[3]
    set -e argv[1 2 3]

    switch $manager
        case apt apt-get
            switch $action
                case install
                    _spm_require_packages $action $argv; and _spm_sudo_run $dry_run $manager $manager install -y $argv
                case upgrade
                    if test (count $argv) -eq 0
                        _spm_sudo_run $dry_run $manager $manager update; and _spm_sudo_run $dry_run $manager $manager upgrade -y
                    else
                        _spm_sudo_run $dry_run $manager $manager install --only-upgrade -y $argv
                    end
                case search
                    _spm_require_packages $action $argv; and _spm_run $dry_run $manager search $argv
                case remove
                    _spm_require_packages $action $argv; and _spm_sudo_run $dry_run $manager $manager remove -y $argv
                case info
                    _spm_require_packages $action $argv; and _spm_run $dry_run $manager show $argv
                case list
                    _spm_run $dry_run $manager list --installed $argv
                case update
                    _spm_sudo_run $dry_run $manager $manager update
                case clean
                    _spm_sudo_run $dry_run $manager $manager autoremove -y; and _spm_sudo_run $dry_run $manager $manager autoclean
                case '*'
                    _spm_unsupported $manager $action
            end
        case nala
            switch $action
                case install
                    _spm_require_packages $action $argv; and _spm_sudo_run $dry_run $manager nala install -y $argv
                case upgrade
                    if test (count $argv) -eq 0
                        _spm_sudo_run $dry_run $manager nala update; and _spm_sudo_run $dry_run $manager nala upgrade -y
                    else
                        _spm_sudo_run $dry_run $manager nala install --only-upgrade -y $argv
                    end
                case search
                    _spm_require_packages $action $argv; and _spm_run $dry_run nala search $argv
                case remove
                    _spm_require_packages $action $argv; and _spm_sudo_run $dry_run $manager nala remove -y $argv
                case info
                    _spm_require_packages $action $argv; and _spm_run $dry_run nala show $argv
                case list
                    _spm_run $dry_run apt list --installed $argv
                case update
                    _spm_sudo_run $dry_run $manager nala update
                case clean
                    _spm_sudo_run $dry_run $manager apt autoremove -y; and _spm_sudo_run $dry_run $manager apt autoclean
                case '*'
                    _spm_unsupported $manager $action
            end
        case brew
            switch $action
                case install
                    _spm_require_packages $action $argv; and _spm_run $dry_run brew install $argv
                case upgrade
                    _spm_run $dry_run brew upgrade $argv
                case search
                    _spm_require_packages $action $argv; and _spm_run $dry_run brew search $argv
                case remove
                    _spm_require_packages $action $argv; and _spm_run $dry_run brew uninstall $argv
                case info
                    _spm_require_packages $action $argv; and _spm_run $dry_run brew info $argv
                case list
                    _spm_run $dry_run brew list $argv
                case update
                    _spm_run $dry_run brew update
                case clean
                    _spm_run $dry_run brew cleanup
                case '*'
                    _spm_unsupported $manager $action
            end
        case dnf dnf5 yum microdnf
            switch $action
                case install
                    _spm_require_packages $action $argv; and _spm_sudo_run $dry_run $manager $manager install -y $argv
                case upgrade
                    _spm_sudo_run $dry_run $manager $manager upgrade -y $argv
                case search
                    _spm_require_packages $action $argv; and _spm_run $dry_run $manager search $argv
                case remove
                    _spm_require_packages $action $argv; and _spm_sudo_run $dry_run $manager $manager remove -y $argv
                case info
                    _spm_require_packages $action $argv; and _spm_run $dry_run $manager info $argv
                case list
                    _spm_run $dry_run $manager list installed $argv
                case update
                    _spm_sudo_run $dry_run $manager $manager makecache
                case clean
                    _spm_sudo_run $dry_run $manager $manager clean all
                case '*'
                    _spm_unsupported $manager $action
            end
        case apk
            switch $action
                case install
                    _spm_require_packages $action $argv; and _spm_sudo_run $dry_run $manager apk add $argv
                case upgrade
                    _spm_sudo_run $dry_run $manager apk upgrade $argv
                case search
                    _spm_require_packages $action $argv; and _spm_run $dry_run apk search $argv
                case remove
                    _spm_require_packages $action $argv; and _spm_sudo_run $dry_run $manager apk del $argv
                case info
                    _spm_require_packages $action $argv; and _spm_run $dry_run apk info $argv
                case list
                    _spm_run $dry_run apk info $argv
                case update
                    _spm_sudo_run $dry_run $manager apk update
                case clean
                    _spm_sudo_run $dry_run $manager apk cache clean
                case '*'
                    _spm_unsupported $manager $action
            end
        case pacman
            switch $action
                case install
                    _spm_require_packages $action $argv; and _spm_sudo_run $dry_run $manager pacman -S --needed --noconfirm $argv
                case upgrade
                    if test (count $argv) -eq 0
                        _spm_sudo_run $dry_run $manager pacman -Syu --noconfirm
                    else
                        _spm_sudo_run $dry_run $manager pacman -S --needed --noconfirm $argv
                    end
                case search
                    _spm_require_packages $action $argv; and _spm_run $dry_run pacman -Ss $argv
                case remove
                    _spm_require_packages $action $argv; and _spm_sudo_run $dry_run $manager pacman -Rns --noconfirm $argv
                case info
                    _spm_require_packages $action $argv; and _spm_run $dry_run pacman -Si $argv
                case list
                    _spm_run $dry_run pacman -Qs $argv
                case update
                    _spm_sudo_run $dry_run $manager pacman -Sy
                case clean
                    _spm_sudo_run $dry_run $manager pacman -Sc --noconfirm
                case '*'
                    _spm_unsupported $manager $action
            end
        case paru yay
            switch $action
                case install
                    _spm_require_packages $action $argv; and _spm_run $dry_run $manager -S --needed --noconfirm $argv
                case upgrade
                    if test (count $argv) -eq 0
                        _spm_run $dry_run $manager -Syu --noconfirm
                    else
                        _spm_run $dry_run $manager -S --needed --noconfirm $argv
                    end
                case search
                    _spm_require_packages $action $argv; and _spm_run $dry_run $manager -Ss $argv
                case remove
                    _spm_require_packages $action $argv; and _spm_run $dry_run $manager -Rns --noconfirm $argv
                case info
                    _spm_require_packages $action $argv; and _spm_run $dry_run $manager -Si $argv
                case list
                    _spm_run $dry_run $manager -Qs $argv
                case update
                    _spm_run $dry_run $manager -Sy
                case clean
                    _spm_run $dry_run $manager -Sc --noconfirm
                case '*'
                    _spm_unsupported $manager $action
            end
        case zypper
            switch $action
                case install
                    _spm_require_packages $action $argv; and _spm_sudo_run $dry_run $manager zypper --non-interactive install $argv
                case upgrade
                    _spm_sudo_run $dry_run $manager zypper --non-interactive update $argv
                case search
                    _spm_require_packages $action $argv; and _spm_run $dry_run zypper search $argv
                case remove
                    _spm_require_packages $action $argv; and _spm_sudo_run $dry_run $manager zypper --non-interactive remove $argv
                case info
                    _spm_require_packages $action $argv; and _spm_run $dry_run zypper info $argv
                case list
                    _spm_run $dry_run zypper search --installed-only $argv
                case update
                    _spm_sudo_run $dry_run $manager zypper refresh
                case clean
                    _spm_sudo_run $dry_run $manager zypper clean --all
                case '*'
                    _spm_unsupported $manager $action
            end
        case xbps-install
            switch $action
                case install
                    _spm_require_packages $action $argv; and _spm_sudo_run $dry_run $manager xbps-install -Sy $argv
                case upgrade
                    if test (count $argv) -eq 0
                        _spm_sudo_run $dry_run $manager xbps-install -Syu
                    else
                        _spm_sudo_run $dry_run $manager xbps-install -Su $argv
                    end
                case search
                    _spm_require_packages $action $argv; and _spm_run $dry_run xbps-query -Rs (_spm_join $argv)
                case remove
                    _spm_require_packages $action $argv; and _spm_sudo_run $dry_run $manager xbps-remove -R $argv
                case info
                    _spm_require_packages $action $argv; and _spm_run $dry_run xbps-query -RS $argv
                case list
                    _spm_run $dry_run xbps-query -l $argv
                case update
                    _spm_sudo_run $dry_run $manager xbps-install -S
                case clean
                    _spm_sudo_run $dry_run $manager xbps-remove -O
                case '*'
                    _spm_unsupported $manager $action
            end
        case emerge
            switch $action
                case install
                    _spm_require_packages $action $argv; and _spm_sudo_run $dry_run $manager emerge --ask=n $argv
                case upgrade
                    if test (count $argv) -eq 0
                        _spm_sudo_run $dry_run $manager emerge --ask=n --update --deep --newuse @world
                    else
                        _spm_sudo_run $dry_run $manager emerge --ask=n --update $argv
                    end
                case search
                    _spm_require_packages $action $argv; and _spm_run $dry_run emerge --search (_spm_join $argv)
                case remove
                    _spm_require_packages $action $argv; and _spm_sudo_run $dry_run $manager emerge --ask=n --depclean $argv
                case info
                    _spm_require_packages $action $argv; and _spm_run $dry_run equery meta $argv
                case list
                    _spm_run $dry_run equery list $argv
                case update
                    _spm_sudo_run $dry_run $manager emerge --sync
                case clean
                    _spm_sudo_run $dry_run $manager emerge --ask=n --depclean
                case '*'
                    _spm_unsupported $manager $action
            end
        case eopkg
            switch $action
                case install
                    _spm_require_packages $action $argv; and _spm_sudo_run $dry_run $manager eopkg install -y $argv
                case upgrade
                    _spm_sudo_run $dry_run $manager eopkg upgrade -y $argv
                case search
                    _spm_require_packages $action $argv; and _spm_run $dry_run eopkg search $argv
                case remove
                    _spm_require_packages $action $argv; and _spm_sudo_run $dry_run $manager eopkg remove -y $argv
                case info
                    _spm_require_packages $action $argv; and _spm_run $dry_run eopkg info $argv
                case list
                    _spm_run $dry_run eopkg list-installed $argv
                case update
                    _spm_sudo_run $dry_run $manager eopkg update-repo
                case clean
                    _spm_sudo_run $dry_run $manager eopkg clean
                case '*'
                    _spm_unsupported $manager $action
            end
        case swupd
            switch $action
                case install
                    _spm_require_packages $action $argv; and _spm_sudo_run $dry_run $manager swupd bundle-add $argv
                case upgrade
                    _spm_sudo_run $dry_run $manager swupd update $argv
                case search
                    _spm_require_packages $action $argv; and _spm_run $dry_run swupd search $argv
                case remove
                    _spm_require_packages $action $argv; and _spm_sudo_run $dry_run $manager swupd bundle-remove $argv
                case info
                    _spm_require_packages $action $argv; and _spm_run $dry_run swupd bundle-info $argv
                case list
                    _spm_run $dry_run swupd bundle-list $argv
                case update
                    _spm_sudo_run $dry_run $manager swupd update --download
                case clean
                    _spm_sudo_run $dry_run $manager swupd clean
                case '*'
                    _spm_unsupported $manager $action
            end
        case pkg
            switch $action
                case install
                    _spm_require_packages $action $argv; and _spm_sudo_run $dry_run $manager pkg install -y $argv
                case upgrade
                    _spm_sudo_run $dry_run $manager pkg upgrade -y $argv
                case search
                    _spm_require_packages $action $argv; and _spm_run $dry_run pkg search $argv
                case remove
                    _spm_require_packages $action $argv; and _spm_sudo_run $dry_run $manager pkg delete -y $argv
                case info
                    _spm_require_packages $action $argv; and _spm_run $dry_run pkg info $argv
                case list
                    _spm_run $dry_run pkg info $argv
                case update
                    _spm_sudo_run $dry_run $manager pkg update
                case clean
                    _spm_sudo_run $dry_run $manager pkg clean -y
                case '*'
                    _spm_unsupported $manager $action
            end
        case pkg_add
            switch $action
                case install
                    _spm_require_packages $action $argv; and _spm_sudo_run $dry_run $manager pkg_add $argv
                case upgrade
                    _spm_sudo_run $dry_run $manager pkg_add -u $argv
                case search
                    _spm_require_packages $action $argv; and _spm_run $dry_run pkg_info -Q (_spm_join $argv)
                case remove
                    _spm_require_packages $action $argv; and _spm_sudo_run $dry_run $manager pkg_delete $argv
                case info
                    _spm_require_packages $action $argv; and _spm_run $dry_run pkg_info $argv
                case list
                    _spm_run $dry_run pkg_info $argv
                case update
                    _spm_sudo_run $dry_run $manager pkg_add -u
                case '*'
                    _spm_unsupported $manager $action
            end
        case pkgin
            switch $action
                case install
                    _spm_require_packages $action $argv; and _spm_sudo_run $dry_run $manager pkgin -y install $argv
                case upgrade
                    _spm_sudo_run $dry_run $manager pkgin -y upgrade $argv
                case search
                    _spm_require_packages $action $argv; and _spm_run $dry_run pkgin search $argv
                case remove
                    _spm_require_packages $action $argv; and _spm_sudo_run $dry_run $manager pkgin -y remove $argv
                case info
                    _spm_require_packages $action $argv; and _spm_run $dry_run pkgin show-full-deps $argv
                case list
                    _spm_run $dry_run pkgin list $argv
                case update
                    _spm_sudo_run $dry_run $manager pkgin update
                case clean
                    _spm_sudo_run $dry_run $manager pkgin clean
                case '*'
                    _spm_unsupported $manager $action
            end
        case port
            switch $action
                case install
                    _spm_require_packages $action $argv; and _spm_sudo_run $dry_run $manager port install $argv
                case upgrade
                    if test (count $argv) -eq 0
                        _spm_sudo_run $dry_run $manager port selfupdate; and _spm_sudo_run $dry_run $manager port upgrade outdated
                    else
                        _spm_sudo_run $dry_run $manager port upgrade $argv
                    end
                case search
                    _spm_require_packages $action $argv; and _spm_run $dry_run port search $argv
                case remove
                    _spm_require_packages $action $argv; and _spm_sudo_run $dry_run $manager port uninstall $argv
                case info
                    _spm_require_packages $action $argv; and _spm_run $dry_run port info $argv
                case list
                    _spm_run $dry_run port installed $argv
                case update
                    _spm_sudo_run $dry_run $manager port selfupdate
                case clean
                    _spm_sudo_run $dry_run $manager port clean --all all
                case '*'
                    _spm_unsupported $manager $action
            end
        case winget
            switch $action
                case install
                    _spm_require_packages $action $argv; and _spm_run $dry_run winget install --accept-package-agreements --accept-source-agreements $argv
                case upgrade
                    if test (count $argv) -eq 0
                        _spm_run $dry_run winget upgrade --all --accept-package-agreements --accept-source-agreements
                    else
                        _spm_run $dry_run winget upgrade --accept-package-agreements --accept-source-agreements $argv
                    end
                case search
                    _spm_require_packages $action $argv; and _spm_run $dry_run winget search $argv
                case remove
                    _spm_require_packages $action $argv; and _spm_run $dry_run winget uninstall $argv
                case info
                    _spm_require_packages $action $argv; and _spm_run $dry_run winget show $argv
                case list
                    _spm_run $dry_run winget list $argv
                case update
                    _spm_run $dry_run winget source update
                case '*'
                    _spm_unsupported $manager $action
            end
        case scoop
            switch $action
                case install
                    _spm_require_packages $action $argv; and _spm_run $dry_run scoop install $argv
                case upgrade
                    if test (count $argv) -eq 0
                        _spm_run $dry_run scoop update; and _spm_run $dry_run scoop update '*'
                    else
                        _spm_run $dry_run scoop update $argv
                    end
                case search
                    _spm_require_packages $action $argv; and _spm_run $dry_run scoop search $argv
                case remove
                    _spm_require_packages $action $argv; and _spm_run $dry_run scoop uninstall $argv
                case info
                    _spm_require_packages $action $argv; and _spm_run $dry_run scoop info $argv
                case list
                    _spm_run $dry_run scoop list $argv
                case update
                    _spm_run $dry_run scoop update
                case clean
                    _spm_run $dry_run scoop cleanup '*'
                case '*'
                    _spm_unsupported $manager $action
            end
        case choco
            switch $action
                case install
                    _spm_require_packages $action $argv; and _spm_run $dry_run choco install -y $argv
                case upgrade
                    if test (count $argv) -eq 0
                        _spm_run $dry_run choco upgrade all -y
                    else
                        _spm_run $dry_run choco upgrade -y $argv
                    end
                case search
                    _spm_require_packages $action $argv; and _spm_run $dry_run choco search $argv
                case remove
                    _spm_require_packages $action $argv; and _spm_run $dry_run choco uninstall -y $argv
                case info
                    _spm_require_packages $action $argv; and _spm_run $dry_run choco info $argv
                case list
                    _spm_run $dry_run choco list --local-only $argv
                case update
                    _spm_run $dry_run choco outdated
                case '*'
                    _spm_unsupported $manager $action
            end
        case nix-env
            switch $action
                case install
                    _spm_require_packages $action $argv; and _spm_run $dry_run nix-env -iA $argv
                case upgrade
                    _spm_run $dry_run nix-env -u $argv
                case search
                    _spm_require_packages $action $argv; and _spm_run $dry_run nix-env -qaP $argv
                case remove
                    _spm_require_packages $action $argv; and _spm_run $dry_run nix-env -e $argv
                case info
                    _spm_require_packages $action $argv; and _spm_run $dry_run nix-env -qa --description $argv
                case list
                    _spm_run $dry_run nix-env -q $argv
                case update
                    _spm_run $dry_run nix-channel --update
                case clean
                    _spm_run $dry_run nix-collect-garbage -d
                case '*'
                    _spm_unsupported $manager $action
            end
        case nix-profile
            switch $action
                case install
                    _spm_require_packages $action $argv; and _spm_run $dry_run nix profile install $argv
                case upgrade
                    if test (count $argv) -eq 0
                        _spm_run $dry_run nix profile upgrade --all
                    else
                        _spm_run $dry_run nix profile upgrade $argv
                    end
                case search info
                    _spm_require_packages $action $argv; and _spm_run $dry_run nix search nixpkgs (_spm_join $argv)
                case remove
                    _spm_require_packages $action $argv; and _spm_run $dry_run nix profile remove $argv
                case list
                    _spm_run $dry_run nix profile list $argv
                case clean
                    _spm_run $dry_run nix store gc
                case '*'
                    _spm_unsupported $manager $action
            end
        case nix
            switch $action
                case search info
                    _spm_require_packages $action $argv; and _spm_run $dry_run nix search nixpkgs (_spm_join $argv)
                case list
                    _spm_run $dry_run nix profile list $argv
                case clean
                    _spm_run $dry_run nix store gc
                case '*'
                    _spm_unsupported $manager $action
            end
        case guix
            switch $action
                case install
                    _spm_require_packages $action $argv; and _spm_run $dry_run guix install $argv
                case upgrade
                    _spm_run $dry_run guix upgrade $argv
                case search
                    _spm_require_packages $action $argv; and _spm_run $dry_run guix search $argv
                case remove
                    _spm_require_packages $action $argv; and _spm_run $dry_run guix remove $argv
                case info
                    _spm_require_packages $action $argv; and _spm_run $dry_run guix show $argv
                case list
                    _spm_run $dry_run guix package --list-installed $argv
                case update
                    _spm_run $dry_run guix pull
                case clean
                    _spm_run $dry_run guix gc
                case '*'
                    _spm_unsupported $manager $action
            end
        case conda
            switch $action
                case install
                    _spm_require_packages $action $argv; and _spm_run $dry_run conda install -y $argv
                case upgrade
                    if test (count $argv) -eq 0
                        _spm_run $dry_run conda update -y --all
                    else
                        _spm_run $dry_run conda update -y $argv
                    end
                case search
                    _spm_require_packages $action $argv; and _spm_run $dry_run conda search $argv
                case remove
                    _spm_require_packages $action $argv; and _spm_run $dry_run conda remove -y $argv
                case info
                    _spm_require_packages $action $argv; and _spm_run $dry_run conda search --info $argv
                case list
                    _spm_run $dry_run conda list $argv
                case update
                    _spm_run $dry_run conda update -y conda
                case clean
                    _spm_run $dry_run conda clean -a -y
                case '*'
                    _spm_unsupported $manager $action
            end
        case '*'
            echo "spm: unsupported package manager: $manager" >&2
            return 2
    end
end

function spm --description 'Simple cross-platform package manager helper'
    set -l action install
    set -l manager
    set -l dry_run 0
    set -l args $argv

    if set -q SPM_MANAGER; and test -n "$SPM_MANAGER"
        set manager $SPM_MANAGER
    end

    while test (count $args) -gt 0
        set -l arg $args[1]
        switch $arg
            case -h --help
                _spm_help
                return 0
            case --which
                if test -z "$manager"
                    set manager (_spm_detect_manager)
                    or begin
                        echo 'spm: no supported package manager found' >&2
                        return 1
                    end
                end
                echo $manager
                return 0
            case --dry-run
                set dry_run 1
                set -e args[1]
            case -m --manager
                if test (count $args) -lt 2
                    echo "spm: $arg requires a package manager name" >&2
                    return 2
                end
                set manager $args[2]
                set -e args[1 2]
            case '--manager=*'
                set manager (string replace -- '--manager=' '' $arg)
                set -e args[1]
            case -i --install install add
                set action install
                set -e args[1]
            case -u --upgrade upgrade update-all
                set action upgrade
                set -e args[1]
            case -s --search search
                set action search
                set -e args[1]
            case -r --remove remove rm uninstall
                set action remove
                set -e args[1]
            case --info info show
                set action info
                set -e args[1]
            case -l --list list ls
                set action list
                set -e args[1]
            case --update refresh
                set action update
                set -e args[1]
            case --clean clean
                set action clean
                set -e args[1]
            case --
                set -e args[1]
                break
            case '-*'
                echo "spm: unknown option: $arg" >&2
                echo 'Run `spm --help` for usage.' >&2
                return 2
            case '*'
                break
        end
    end

    if test -z "$manager"
        set manager (_spm_detect_manager)
        or begin
            echo 'spm: no supported package manager found' >&2
            return 1
        end
    end

    _spm_exec $manager $action $dry_run $args
end
