_spm_help() {
  cat <<'EOF'
spm - simple cross-platform package manager helper

USAGE
  spm [package ...]
  spm -i | --install package ...
  spm -u | --upgrade [package ...]
  spm -s | --search query
  spm -r | --remove package ...
  spm --info package
  spm --list [query]
  spm --update
  spm --clean
  spm --manager NAME action [package ...]
  spm --dry-run action [package ...]
  spm -h | --help

DEFAULTS
  spm git
      Install git. On Debian/Ubuntu this runs: sudo apt install -y git

  spm -i git
  spm --install git
      Install git.

  spm -u git
  spm --upgrade git
      Upgrade git.

  spm -u
  spm --upgrade
      Upgrade all packages. On Debian/Ubuntu this runs:
        sudo apt update && sudo apt upgrade -y

  spm -s git
  spm --search git
      Search package names/descriptions.

MORE EXAMPLES
  spm --remove git
  spm --info git
  spm --list git
  spm --update
  spm --clean
  spm --which
  spm --dry-run -u
  spm -m apt install curl
  spm --manager brew search ripgrep

PACKAGE MANAGER PRIORITY
  Unix, Linux, macOS, WSL, WSL2:
    brew first, then system managers such as apt, dnf, yum, apk, pacman,
    zypper, xbps-install, emerge, eopkg, swupd, pkg, pkg_add, pkgin,
    port, nix, guix, and conda.

  Windows shells:
    winget, then scoop, then choco.

OPTIONS
  -i, --install       install packages
  -u, --upgrade       upgrade packages, or all packages when no package is given
  -s, --search        search packages
  -r, --remove        remove packages
      --info          show package details
  -l, --list          list installed packages, optionally filtered by query
      --update        refresh package indexes
      --clean         clean package manager caches when supported
      --which         print selected package manager
  -m, --manager NAME  force a package manager for this invocation
      --dry-run       print commands without running them
  -h, --help          show this help

ENVIRONMENT
  SPM_MANAGER         default package manager override, same as --manager
  SPM_NO_SUDO=1       never prepend sudo
EOF
}

_spm_has() {
  command -v "$1" >/dev/null 2>&1
}

_spm_is_windows() {
  case ${OSTYPE:-} in
    msys* | cygwin* | win32*) return 0 ;;
  esac

  case "$(uname -s 2>/dev/null)" in
    MINGW* | MSYS* | CYGWIN* | Windows_NT) return 0 ;;
  esac

  return 1
}

_spm_detect_manager() {
  local manager

  if [[ -n ${SPM_MANAGER:-} ]]; then
    printf '%s\n' "$SPM_MANAGER"
    return 0
  fi

  if _spm_is_windows; then
    for manager in winget scoop choco; do
      if _spm_has "$manager"; then
        printf '%s\n' "$manager"
        return 0
      fi
    done
    return 1
  fi

  for manager in \
    brew \
    apt apt-get nala \
    dnf dnf5 yum microdnf \
    apk pacman paru yay zypper \
    xbps-install emerge eopkg swupd \
    pkg pkg_add pkgin port \
    nix-env profile nix guix conda; do
    case $manager in
      profile)
        _spm_has nix && nix profile --help >/dev/null 2>&1 && printf '%s\n' nix-profile && return 0
        ;;
      *)
        _spm_has "$manager" && printf '%s\n' "$manager" && return 0
        ;;
    esac
  done

  return 1
}

_spm_needs_sudo() {
  local manager=$1

  [[ ${SPM_NO_SUDO:-0} == 1 ]] && return 1
  [[ $(id -u 2>/dev/null) == 0 ]] && return 1

  case $manager in
    apt | apt-get | nala | dnf | dnf5 | yum | microdnf | apk | pacman | zypper | \
      xbps-install | emerge | eopkg | swupd | pkg | pkg_add | port)
      _spm_has sudo
      ;;
    *)
      return 1
      ;;
  esac
}

_spm_run() {
  local dry_run=$1
  shift

  if (( dry_run )); then
    printf '+'
    printf ' %q' "$@"
    printf '\n'
    return 0
  fi

  "$@"
}

_spm_sudo_run() {
  local dry_run=$1 manager=$2
  shift 2

  if _spm_needs_sudo "$manager"; then
    _spm_run "$dry_run" sudo "$@"
  else
    _spm_run "$dry_run" "$@"
  fi
}

_spm_join() {
  local IFS=' '
  printf '%s' "$*"
}

_spm_unsupported() {
  printf 'spm: %s does not support action: %s\n' "$1" "$2" >&2
  return 2
}

_spm_require_packages() {
  local action=$1
  shift

  if (( $# == 0 )); then
    printf 'spm: %s requires at least one package/query\n' "$action" >&2
    return 2
  fi
}

_spm_exec() {
  local manager=$1 action=$2 dry_run=$3
  shift 3

  case $manager in
    apt | apt-get)
      case $action in
        install) _spm_require_packages "$action" "$@" && _spm_sudo_run "$dry_run" "$manager" "$manager" install -y "$@" ;;
        upgrade)
          if (( $# == 0 )); then
            _spm_sudo_run "$dry_run" "$manager" "$manager" update && _spm_sudo_run "$dry_run" "$manager" "$manager" upgrade -y
          else
            _spm_sudo_run "$dry_run" "$manager" "$manager" install --only-upgrade -y "$@"
          fi
          ;;
        search) _spm_require_packages "$action" "$@" && _spm_run "$dry_run" "$manager" search "$@" ;;
        remove) _spm_require_packages "$action" "$@" && _spm_sudo_run "$dry_run" "$manager" "$manager" remove -y "$@" ;;
        info) _spm_require_packages "$action" "$@" && _spm_run "$dry_run" "$manager" show "$@" ;;
        list) _spm_run "$dry_run" "$manager" list --installed "$@" ;;
        update) _spm_sudo_run "$dry_run" "$manager" "$manager" update ;;
        clean) _spm_sudo_run "$dry_run" "$manager" "$manager" autoremove -y && _spm_sudo_run "$dry_run" "$manager" "$manager" autoclean ;;
        *) _spm_unsupported "$manager" "$action" ;;
      esac
      ;;
    nala)
      case $action in
        install) _spm_require_packages "$action" "$@" && _spm_sudo_run "$dry_run" "$manager" nala install -y "$@" ;;
        upgrade)
          if (( $# == 0 )); then
            _spm_sudo_run "$dry_run" "$manager" nala update && _spm_sudo_run "$dry_run" "$manager" nala upgrade -y
          else
            _spm_sudo_run "$dry_run" "$manager" nala install --only-upgrade -y "$@"
          fi
          ;;
        search) _spm_require_packages "$action" "$@" && _spm_run "$dry_run" nala search "$@" ;;
        remove) _spm_require_packages "$action" "$@" && _spm_sudo_run "$dry_run" "$manager" nala remove -y "$@" ;;
        info) _spm_require_packages "$action" "$@" && _spm_run "$dry_run" nala show "$@" ;;
        list) _spm_run "$dry_run" apt list --installed "$@" ;;
        update) _spm_sudo_run "$dry_run" "$manager" nala update ;;
        clean) _spm_sudo_run "$dry_run" "$manager" apt autoremove -y && _spm_sudo_run "$dry_run" "$manager" apt autoclean ;;
        *) _spm_unsupported "$manager" "$action" ;;
      esac
      ;;
    brew)
      case $action in
        install) _spm_require_packages "$action" "$@" && _spm_run "$dry_run" brew install "$@" ;;
        upgrade) _spm_run "$dry_run" brew upgrade "$@" ;;
        search) _spm_require_packages "$action" "$@" && _spm_run "$dry_run" brew search "$@" ;;
        remove) _spm_require_packages "$action" "$@" && _spm_run "$dry_run" brew uninstall "$@" ;;
        info) _spm_require_packages "$action" "$@" && _spm_run "$dry_run" brew info "$@" ;;
        list) _spm_run "$dry_run" brew list "$@" ;;
        update) _spm_run "$dry_run" brew update ;;
        clean) _spm_run "$dry_run" brew cleanup ;;
        *) _spm_unsupported "$manager" "$action" ;;
      esac
      ;;
    dnf | dnf5 | yum | microdnf)
      case $action in
        install) _spm_require_packages "$action" "$@" && _spm_sudo_run "$dry_run" "$manager" "$manager" install -y "$@" ;;
        upgrade) _spm_sudo_run "$dry_run" "$manager" "$manager" upgrade -y "$@" ;;
        search) _spm_require_packages "$action" "$@" && _spm_run "$dry_run" "$manager" search "$@" ;;
        remove) _spm_require_packages "$action" "$@" && _spm_sudo_run "$dry_run" "$manager" "$manager" remove -y "$@" ;;
        info) _spm_require_packages "$action" "$@" && _spm_run "$dry_run" "$manager" info "$@" ;;
        list) _spm_run "$dry_run" "$manager" list installed "$@" ;;
        update) _spm_sudo_run "$dry_run" "$manager" "$manager" makecache ;;
        clean) _spm_sudo_run "$dry_run" "$manager" "$manager" clean all ;;
        *) _spm_unsupported "$manager" "$action" ;;
      esac
      ;;
    apk)
      case $action in
        install) _spm_require_packages "$action" "$@" && _spm_sudo_run "$dry_run" "$manager" apk add "$@" ;;
        upgrade) _spm_sudo_run "$dry_run" "$manager" apk upgrade "$@" ;;
        search) _spm_require_packages "$action" "$@" && _spm_run "$dry_run" apk search "$@" ;;
        remove) _spm_require_packages "$action" "$@" && _spm_sudo_run "$dry_run" "$manager" apk del "$@" ;;
        info) _spm_require_packages "$action" "$@" && _spm_run "$dry_run" apk info "$@" ;;
        list) _spm_run "$dry_run" apk info "$@" ;;
        update) _spm_sudo_run "$dry_run" "$manager" apk update ;;
        clean) _spm_sudo_run "$dry_run" "$manager" apk cache clean ;;
        *) _spm_unsupported "$manager" "$action" ;;
      esac
      ;;
    pacman)
      case $action in
        install) _spm_require_packages "$action" "$@" && _spm_sudo_run "$dry_run" "$manager" pacman -S --needed --noconfirm "$@" ;;
        upgrade)
          if (( $# == 0 )); then
            _spm_sudo_run "$dry_run" "$manager" pacman -Syu --noconfirm
          else
            _spm_sudo_run "$dry_run" "$manager" pacman -S --needed --noconfirm "$@"
          fi
          ;;
        search) _spm_require_packages "$action" "$@" && _spm_run "$dry_run" pacman -Ss "$@" ;;
        remove) _spm_require_packages "$action" "$@" && _spm_sudo_run "$dry_run" "$manager" pacman -Rns --noconfirm "$@" ;;
        info) _spm_require_packages "$action" "$@" && _spm_run "$dry_run" pacman -Si "$@" ;;
        list) _spm_run "$dry_run" pacman -Qs "$@" ;;
        update) _spm_sudo_run "$dry_run" "$manager" pacman -Sy ;;
        clean) _spm_sudo_run "$dry_run" "$manager" pacman -Sc --noconfirm ;;
        *) _spm_unsupported "$manager" "$action" ;;
      esac
      ;;
    paru | yay)
      case $action in
        install) _spm_require_packages "$action" "$@" && _spm_run "$dry_run" "$manager" -S --needed --noconfirm "$@" ;;
        upgrade)
          if (( $# == 0 )); then
            _spm_run "$dry_run" "$manager" -Syu --noconfirm
          else
            _spm_run "$dry_run" "$manager" -S --needed --noconfirm "$@"
          fi
          ;;
        search) _spm_require_packages "$action" "$@" && _spm_run "$dry_run" "$manager" -Ss "$@" ;;
        remove) _spm_require_packages "$action" "$@" && _spm_run "$dry_run" "$manager" -Rns --noconfirm "$@" ;;
        info) _spm_require_packages "$action" "$@" && _spm_run "$dry_run" "$manager" -Si "$@" ;;
        list) _spm_run "$dry_run" "$manager" -Qs "$@" ;;
        update) _spm_run "$dry_run" "$manager" -Sy ;;
        clean) _spm_run "$dry_run" "$manager" -Sc --noconfirm ;;
        *) _spm_unsupported "$manager" "$action" ;;
      esac
      ;;
    zypper)
      case $action in
        install) _spm_require_packages "$action" "$@" && _spm_sudo_run "$dry_run" "$manager" zypper --non-interactive install "$@" ;;
        upgrade) _spm_sudo_run "$dry_run" "$manager" zypper --non-interactive update "$@" ;;
        search) _spm_require_packages "$action" "$@" && _spm_run "$dry_run" zypper search "$@" ;;
        remove) _spm_require_packages "$action" "$@" && _spm_sudo_run "$dry_run" "$manager" zypper --non-interactive remove "$@" ;;
        info) _spm_require_packages "$action" "$@" && _spm_run "$dry_run" zypper info "$@" ;;
        list) _spm_run "$dry_run" zypper search --installed-only "$@" ;;
        update) _spm_sudo_run "$dry_run" "$manager" zypper refresh ;;
        clean) _spm_sudo_run "$dry_run" "$manager" zypper clean --all ;;
        *) _spm_unsupported "$manager" "$action" ;;
      esac
      ;;
    xbps-install)
      case $action in
        install) _spm_require_packages "$action" "$@" && _spm_sudo_run "$dry_run" "$manager" xbps-install -Sy "$@" ;;
        upgrade)
          if (( $# == 0 )); then
            _spm_sudo_run "$dry_run" "$manager" xbps-install -Syu
          else
            _spm_sudo_run "$dry_run" "$manager" xbps-install -Su "$@"
          fi
          ;;
        search) _spm_require_packages "$action" "$@" && _spm_run "$dry_run" xbps-query -Rs "$(_spm_join "$@")" ;;
        remove) _spm_require_packages "$action" "$@" && _spm_sudo_run "$dry_run" "$manager" xbps-remove -R "$@" ;;
        info) _spm_require_packages "$action" "$@" && _spm_run "$dry_run" xbps-query -RS "$@" ;;
        list) _spm_run "$dry_run" xbps-query -l "$@" ;;
        update) _spm_sudo_run "$dry_run" "$manager" xbps-install -S ;;
        clean) _spm_sudo_run "$dry_run" "$manager" xbps-remove -O ;;
        *) _spm_unsupported "$manager" "$action" ;;
      esac
      ;;
    emerge)
      case $action in
        install) _spm_require_packages "$action" "$@" && _spm_sudo_run "$dry_run" "$manager" emerge --ask=n "$@" ;;
        upgrade)
          if (( $# == 0 )); then
            _spm_sudo_run "$dry_run" "$manager" emerge --ask=n --update --deep --newuse @world
          else
            _spm_sudo_run "$dry_run" "$manager" emerge --ask=n --update "$@"
          fi
          ;;
        search) _spm_require_packages "$action" "$@" && _spm_run "$dry_run" emerge --search "$(_spm_join "$@")" ;;
        remove) _spm_require_packages "$action" "$@" && _spm_sudo_run "$dry_run" "$manager" emerge --ask=n --depclean "$@" ;;
        info) _spm_require_packages "$action" "$@" && _spm_run "$dry_run" equery meta "$@" ;;
        list) _spm_run "$dry_run" equery list "$@" ;;
        update) _spm_sudo_run "$dry_run" "$manager" emerge --sync ;;
        clean) _spm_sudo_run "$dry_run" "$manager" emerge --ask=n --depclean ;;
        *) _spm_unsupported "$manager" "$action" ;;
      esac
      ;;
    eopkg)
      case $action in
        install) _spm_require_packages "$action" "$@" && _spm_sudo_run "$dry_run" "$manager" eopkg install -y "$@" ;;
        upgrade) _spm_sudo_run "$dry_run" "$manager" eopkg upgrade -y "$@" ;;
        search) _spm_require_packages "$action" "$@" && _spm_run "$dry_run" eopkg search "$@" ;;
        remove) _spm_require_packages "$action" "$@" && _spm_sudo_run "$dry_run" "$manager" eopkg remove -y "$@" ;;
        info) _spm_require_packages "$action" "$@" && _spm_run "$dry_run" eopkg info "$@" ;;
        list) _spm_run "$dry_run" eopkg list-installed "$@" ;;
        update) _spm_sudo_run "$dry_run" "$manager" eopkg update-repo ;;
        clean) _spm_sudo_run "$dry_run" "$manager" eopkg clean ;;
        *) _spm_unsupported "$manager" "$action" ;;
      esac
      ;;
    swupd)
      case $action in
        install) _spm_require_packages "$action" "$@" && _spm_sudo_run "$dry_run" "$manager" swupd bundle-add "$@" ;;
        upgrade) _spm_sudo_run "$dry_run" "$manager" swupd update "$@" ;;
        search) _spm_require_packages "$action" "$@" && _spm_run "$dry_run" swupd search "$@" ;;
        remove) _spm_require_packages "$action" "$@" && _spm_sudo_run "$dry_run" "$manager" swupd bundle-remove "$@" ;;
        info) _spm_require_packages "$action" "$@" && _spm_run "$dry_run" swupd bundle-info "$@" ;;
        list) _spm_run "$dry_run" swupd bundle-list "$@" ;;
        update) _spm_sudo_run "$dry_run" "$manager" swupd update --download ;;
        clean) _spm_sudo_run "$dry_run" "$manager" swupd clean ;;
        *) _spm_unsupported "$manager" "$action" ;;
      esac
      ;;
    pkg)
      case $action in
        install) _spm_require_packages "$action" "$@" && _spm_sudo_run "$dry_run" "$manager" pkg install -y "$@" ;;
        upgrade) _spm_sudo_run "$dry_run" "$manager" pkg upgrade -y "$@" ;;
        search) _spm_require_packages "$action" "$@" && _spm_run "$dry_run" pkg search "$@" ;;
        remove) _spm_require_packages "$action" "$@" && _spm_sudo_run "$dry_run" "$manager" pkg delete -y "$@" ;;
        info) _spm_require_packages "$action" "$@" && _spm_run "$dry_run" pkg info "$@" ;;
        list) _spm_run "$dry_run" pkg info "$@" ;;
        update) _spm_sudo_run "$dry_run" "$manager" pkg update ;;
        clean) _spm_sudo_run "$dry_run" "$manager" pkg clean -y ;;
        *) _spm_unsupported "$manager" "$action" ;;
      esac
      ;;
    pkg_add)
      case $action in
        install) _spm_require_packages "$action" "$@" && _spm_sudo_run "$dry_run" "$manager" pkg_add "$@" ;;
        upgrade) _spm_sudo_run "$dry_run" "$manager" pkg_add -u "$@" ;;
        search) _spm_require_packages "$action" "$@" && _spm_run "$dry_run" pkg_info -Q "$(_spm_join "$@")" ;;
        remove) _spm_require_packages "$action" "$@" && _spm_sudo_run "$dry_run" "$manager" pkg_delete "$@" ;;
        info) _spm_require_packages "$action" "$@" && _spm_run "$dry_run" pkg_info "$@" ;;
        list) _spm_run "$dry_run" pkg_info "$@" ;;
        update) _spm_sudo_run "$dry_run" "$manager" pkg_add -u ;;
        clean) _spm_unsupported "$manager" "$action" ;;
        *) _spm_unsupported "$manager" "$action" ;;
      esac
      ;;
    pkgin)
      case $action in
        install) _spm_require_packages "$action" "$@" && _spm_sudo_run "$dry_run" "$manager" pkgin -y install "$@" ;;
        upgrade) _spm_sudo_run "$dry_run" "$manager" pkgin -y upgrade "$@" ;;
        search) _spm_require_packages "$action" "$@" && _spm_run "$dry_run" pkgin search "$@" ;;
        remove) _spm_require_packages "$action" "$@" && _spm_sudo_run "$dry_run" "$manager" pkgin -y remove "$@" ;;
        info) _spm_require_packages "$action" "$@" && _spm_run "$dry_run" pkgin show-full-deps "$@" ;;
        list) _spm_run "$dry_run" pkgin list "$@" ;;
        update) _spm_sudo_run "$dry_run" "$manager" pkgin update ;;
        clean) _spm_sudo_run "$dry_run" "$manager" pkgin clean ;;
        *) _spm_unsupported "$manager" "$action" ;;
      esac
      ;;
    port)
      case $action in
        install) _spm_require_packages "$action" "$@" && _spm_sudo_run "$dry_run" "$manager" port install "$@" ;;
        upgrade)
          if (( $# == 0 )); then
            _spm_sudo_run "$dry_run" "$manager" port selfupdate && _spm_sudo_run "$dry_run" "$manager" port upgrade outdated
          else
            _spm_sudo_run "$dry_run" "$manager" port upgrade "$@"
          fi
          ;;
        search) _spm_require_packages "$action" "$@" && _spm_run "$dry_run" port search "$@" ;;
        remove) _spm_require_packages "$action" "$@" && _spm_sudo_run "$dry_run" "$manager" port uninstall "$@" ;;
        info) _spm_require_packages "$action" "$@" && _spm_run "$dry_run" port info "$@" ;;
        list) _spm_run "$dry_run" port installed "$@" ;;
        update) _spm_sudo_run "$dry_run" "$manager" port selfupdate ;;
        clean) _spm_sudo_run "$dry_run" "$manager" port clean --all all ;;
        *) _spm_unsupported "$manager" "$action" ;;
      esac
      ;;
    winget)
      case $action in
        install) _spm_require_packages "$action" "$@" && _spm_run "$dry_run" winget install --accept-package-agreements --accept-source-agreements "$@" ;;
        upgrade)
          if (( $# == 0 )); then
            _spm_run "$dry_run" winget upgrade --all --accept-package-agreements --accept-source-agreements
          else
            _spm_run "$dry_run" winget upgrade --accept-package-agreements --accept-source-agreements "$@"
          fi
          ;;
        search) _spm_require_packages "$action" "$@" && _spm_run "$dry_run" winget search "$@" ;;
        remove) _spm_require_packages "$action" "$@" && _spm_run "$dry_run" winget uninstall "$@" ;;
        info) _spm_require_packages "$action" "$@" && _spm_run "$dry_run" winget show "$@" ;;
        list) _spm_run "$dry_run" winget list "$@" ;;
        update) _spm_run "$dry_run" winget source update ;;
        clean) _spm_unsupported "$manager" "$action" ;;
        *) _spm_unsupported "$manager" "$action" ;;
      esac
      ;;
    scoop)
      case $action in
        install) _spm_require_packages "$action" "$@" && _spm_run "$dry_run" scoop install "$@" ;;
        upgrade)
          if (( $# == 0 )); then
            _spm_run "$dry_run" scoop update && _spm_run "$dry_run" scoop update '*'
          else
            _spm_run "$dry_run" scoop update "$@"
          fi
          ;;
        search) _spm_require_packages "$action" "$@" && _spm_run "$dry_run" scoop search "$@" ;;
        remove) _spm_require_packages "$action" "$@" && _spm_run "$dry_run" scoop uninstall "$@" ;;
        info) _spm_require_packages "$action" "$@" && _spm_run "$dry_run" scoop info "$@" ;;
        list) _spm_run "$dry_run" scoop list "$@" ;;
        update) _spm_run "$dry_run" scoop update ;;
        clean) _spm_run "$dry_run" scoop cleanup '*' ;;
        *) _spm_unsupported "$manager" "$action" ;;
      esac
      ;;
    choco)
      case $action in
        install) _spm_require_packages "$action" "$@" && _spm_sudo_run "$dry_run" "$manager" choco install -y "$@" ;;
        upgrade)
          if (( $# == 0 )); then
            _spm_sudo_run "$dry_run" "$manager" choco upgrade all -y
          else
            _spm_sudo_run "$dry_run" "$manager" choco upgrade -y "$@"
          fi
          ;;
        search) _spm_require_packages "$action" "$@" && _spm_run "$dry_run" choco search "$@" ;;
        remove) _spm_require_packages "$action" "$@" && _spm_sudo_run "$dry_run" "$manager" choco uninstall -y "$@" ;;
        info) _spm_require_packages "$action" "$@" && _spm_run "$dry_run" choco info "$@" ;;
        list) _spm_run "$dry_run" choco list --local-only "$@" ;;
        update) _spm_run "$dry_run" choco outdated ;;
        clean) _spm_unsupported "$manager" "$action" ;;
        *) _spm_unsupported "$manager" "$action" ;;
      esac
      ;;
    nix-env)
      case $action in
        install) _spm_require_packages "$action" "$@" && _spm_run "$dry_run" nix-env -iA "$@" ;;
        upgrade) _spm_run "$dry_run" nix-env -u "$@" ;;
        search) _spm_require_packages "$action" "$@" && _spm_run "$dry_run" nix-env -qaP "$@" ;;
        remove) _spm_require_packages "$action" "$@" && _spm_run "$dry_run" nix-env -e "$@" ;;
        info) _spm_require_packages "$action" "$@" && _spm_run "$dry_run" nix-env -qa --description "$@" ;;
        list) _spm_run "$dry_run" nix-env -q "$@" ;;
        update) _spm_run "$dry_run" nix-channel --update ;;
        clean) _spm_run "$dry_run" nix-collect-garbage -d ;;
        *) _spm_unsupported "$manager" "$action" ;;
      esac
      ;;
    nix-profile)
      case $action in
        install) _spm_require_packages "$action" "$@" && _spm_run "$dry_run" nix profile install "$@" ;;
        upgrade)
          if (( $# == 0 )); then
            _spm_run "$dry_run" nix profile upgrade --all
          else
            _spm_run "$dry_run" nix profile upgrade "$@"
          fi
          ;;
        search) _spm_require_packages "$action" "$@" && _spm_run "$dry_run" nix search nixpkgs "$(_spm_join "$@")" ;;
        remove) _spm_require_packages "$action" "$@" && _spm_run "$dry_run" nix profile remove "$@" ;;
        info) _spm_require_packages "$action" "$@" && _spm_run "$dry_run" nix search nixpkgs "$(_spm_join "$@")" ;;
        list) _spm_run "$dry_run" nix profile list "$@" ;;
        update) _spm_unsupported "$manager" "$action" ;;
        clean) _spm_run "$dry_run" nix store gc ;;
        *) _spm_unsupported "$manager" "$action" ;;
      esac
      ;;
    nix)
      case $action in
        search) _spm_require_packages "$action" "$@" && _spm_run "$dry_run" nix search nixpkgs "$(_spm_join "$@")" ;;
        info) _spm_require_packages "$action" "$@" && _spm_run "$dry_run" nix search nixpkgs "$(_spm_join "$@")" ;;
        list) _spm_run "$dry_run" nix profile list "$@" ;;
        clean) _spm_run "$dry_run" nix store gc ;;
        install | upgrade | remove | update) _spm_unsupported "$manager" "$action" ;;
        *) _spm_unsupported "$manager" "$action" ;;
      esac
      ;;
    guix)
      case $action in
        install) _spm_require_packages "$action" "$@" && _spm_run "$dry_run" guix install "$@" ;;
        upgrade) _spm_run "$dry_run" guix upgrade "$@" ;;
        search) _spm_require_packages "$action" "$@" && _spm_run "$dry_run" guix search "$@" ;;
        remove) _spm_require_packages "$action" "$@" && _spm_run "$dry_run" guix remove "$@" ;;
        info) _spm_require_packages "$action" "$@" && _spm_run "$dry_run" guix show "$@" ;;
        list) _spm_run "$dry_run" guix package --list-installed "$@" ;;
        update) _spm_run "$dry_run" guix pull ;;
        clean) _spm_run "$dry_run" guix gc ;;
        *) _spm_unsupported "$manager" "$action" ;;
      esac
      ;;
    conda)
      case $action in
        install) _spm_require_packages "$action" "$@" && _spm_run "$dry_run" conda install -y "$@" ;;
        upgrade)
          if (( $# == 0 )); then
            _spm_run "$dry_run" conda update -y --all
          else
            _spm_run "$dry_run" conda update -y "$@"
          fi
          ;;
        search) _spm_require_packages "$action" "$@" && _spm_run "$dry_run" conda search "$@" ;;
        remove) _spm_require_packages "$action" "$@" && _spm_run "$dry_run" conda remove -y "$@" ;;
        info) _spm_require_packages "$action" "$@" && _spm_run "$dry_run" conda search --info "$@" ;;
        list) _spm_run "$dry_run" conda list "$@" ;;
        update) _spm_run "$dry_run" conda update -y conda ;;
        clean) _spm_run "$dry_run" conda clean -a -y ;;
        *) _spm_unsupported "$manager" "$action" ;;
      esac
      ;;
    *)
      printf 'spm: unsupported package manager: %s\n' "$manager" >&2
      return 2
      ;;
  esac
}

spm() {
  local action=install manager=${SPM_MANAGER:-} dry_run=0
  local arg

  while (( $# > 0 )); do
    arg=$1
    case $arg in
      -h | --help)
        _spm_help
        return 0
        ;;
      --which)
        if [[ -z $manager ]]; then
          manager=$(_spm_detect_manager) || {
            printf 'spm: no supported package manager found\n' >&2
            return 1
          }
        fi
        printf '%s\n' "$manager"
        return 0
        ;;
      --dry-run)
        dry_run=1
        shift
        ;;
      -m | --manager)
        if (( $# < 2 )); then
          printf 'spm: %s requires a package manager name\n' "$arg" >&2
          return 2
        fi
        manager=$2
        shift 2
        ;;
      --manager=*)
        manager=${arg#*=}
        shift
        ;;
      -i | --install | install | add)
        action=install
        shift
        ;;
      -u | --upgrade | upgrade | update-all)
        action=upgrade
        shift
        ;;
      -s | --search | search)
        action=search
        shift
        ;;
      -r | --remove | remove | rm | uninstall)
        action=remove
        shift
        ;;
      --info | info | show)
        action=info
        shift
        ;;
      -l | --list | list | ls)
        action=list
        shift
        ;;
      --update | refresh)
        action=update
        shift
        ;;
      --clean | clean)
        action=clean
        shift
        ;;
      --)
        shift
        break
        ;;
      -*)
        printf 'spm: unknown option: %s\n' "$arg" >&2
        printf 'Run `spm --help` for usage.\n' >&2
        return 2
        ;;
      *)
        break
        ;;
    esac
  done

  if [[ -z $manager ]]; then
    manager=$(_spm_detect_manager) || {
      printf 'spm: no supported package manager found\n' >&2
      return 1
    }
  fi

  _spm_exec "$manager" "$action" "$dry_run" "$@"
}
