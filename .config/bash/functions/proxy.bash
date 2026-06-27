proxy() {
  local host=${1:-${PROXY_HOST:-127.0.0.1}}
  local port=${2:-${PROXY_PORT:-3067}}

  if (( $# > 2 )); then
    printf 'usage: proxy [host] [port]\n' >&2
    return 2
  fi

  local url="http://$host:$port"
  export http_proxy="$url" https_proxy="$url" HTTP_PROXY="$url" HTTPS_PROXY="$url"
  printf 'proxy on (%s:%s)\n' "$host" "$port"
}

socks5() {
  local host=${1:-${PROXY_HOST:-127.0.0.1}}
  local port=${2:-${PROXY_PORT:-3067}}

  if (( $# > 2 )); then
    printf 'usage: socks5 [host] [port]\n' >&2
    return 2
  fi

  local url="socks5://$host:$port"
  export all_proxy="$url" ALL_PROXY="$url"
  printf 'socks5 on (%s:%s)\n' "$host" "$port"
}

unproxy() {
  unset http_proxy https_proxy HTTP_PROXY HTTPS_PROXY all_proxy ALL_PROXY
  printf 'proxy off\n'
}

proxyinfo() {
  printf 'http : %s\n' "${http_proxy:-unset}"
  printf 'https: %s\n' "${https_proxy:-unset}"
  printf 'socks: %s\n' "${all_proxy:-unset}"
}
