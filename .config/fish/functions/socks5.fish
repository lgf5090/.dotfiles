function socks5 --description 'Enable SOCKS5 proxy'
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
            echo 'usage: socks5 [[host] port]' >&2
            return 2
    end

    set -l url "socks5://$host:$port"
    set -gx all_proxy $url
    set -gx ALL_PROXY $url
    echo "socks5 on ($host:$port)"
end
