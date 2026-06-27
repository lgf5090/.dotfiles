function proxy --description 'Enable HTTP proxy'
    set -l host
    set -l port

    switch (count $argv)
        case 0
            set host (set -q PROXY_HOST; and echo $PROXY_HOST; or echo 127.0.0.1)
            set port (set -q PROXY_PORT; and echo $PROXY_PORT; or echo 3067)
        case 1
            set host (set -q PROXY_HOST; and echo $PROXY_HOST; or echo 127.0.0.1)
            set port $argv[1]
        case 2
            set host $argv[1]
            set port $argv[2]
        case '*'
            echo 'usage: proxy [[host] port]' >&2
            return 2
    end

    set -l url "http://$host:$port"
    set -gx http_proxy $url
    set -gx https_proxy $url
    set -gx HTTP_PROXY $url
    set -gx HTTPS_PROXY $url
    echo "proxy on ($host:$port)"
end
