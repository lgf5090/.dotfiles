function proxyinfo --description 'Show current proxy state'
    set -l h unset
    set -l hs unset
    set -l s unset
    set -q http_proxy; and set h $http_proxy
    set -q https_proxy; and set hs $https_proxy
    set -q all_proxy; and set s $all_proxy

    printf "http : %s\nhttps: %s\nsocks: %s\n" $h $hs $s
end
