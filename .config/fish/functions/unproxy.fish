function unproxy --description 'Disable all proxies'
    set -e http_proxy https_proxy HTTP_PROXY HTTPS_PROXY all_proxy ALL_PROXY
    echo 'proxy off'
end
