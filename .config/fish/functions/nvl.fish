function nvl --description 'nvim with nvim-lite config'
    set -lx NVIM_APPNAME nvim-lite
    command nvim $argv
end
