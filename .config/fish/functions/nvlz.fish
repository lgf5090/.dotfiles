function nvlz --description 'nvim with nvim-lazy config'
    set -lx NVIM_APPNAME nvim-lazy
    command nvim $argv
end
