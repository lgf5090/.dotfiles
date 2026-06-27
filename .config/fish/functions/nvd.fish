function nvd --description 'nvim with nvim-dev config'
    set -lx NVIM_APPNAME nvim-dev
    command nvim $argv
end
