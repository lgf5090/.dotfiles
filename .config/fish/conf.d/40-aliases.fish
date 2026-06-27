set -g __fish_ls_color_opt
switch $SHELLS_OS
    case linux wsl cygwin windows
        set -g __fish_ls_color_opt --color=auto
    case macos freebsd
        set -g __fish_ls_color_opt -G
end

function ls --wraps ls --description 'list directory contents'
    command ls $__fish_ls_color_opt $argv
end

function ll --wraps ls --description 'list all files, long format'
    command ls $__fish_ls_color_opt -alFh $argv
end

function la --wraps ls --description 'list non-hidden and hidden files'
    command ls $__fish_ls_color_opt -A $argv
end

function l --wraps ls --description 'list files in columns'
    command ls $__fish_ls_color_opt -CF $argv
end

function lt --wraps ls --description 'list all files by time'
    command ls $__fish_ls_color_opt -alFht $argv
end

function grep --wraps grep --description 'grep with color'
    command grep --color=auto $argv
end

function fgrep --wraps fgrep --description 'fgrep with color'
    command fgrep --color=auto $argv
end

function egrep --wraps egrep --description 'egrep with color'
    command egrep --color=auto $argv
end

function .. --description 'cd ..'
    cd ..
end

function ... --description 'cd ../..'
    cd ../..
end

function .... --description 'cd ../../..'
    cd ../../..
end

function md --wraps mkdir --description 'mkdir -p'
    command mkdir -p $argv
end

function now --wraps date --description 'current timestamp'
    command date +%Y-%m-%dT%H:%M:%S%z $argv
end

function cls --wraps clear --description clear
    command clear $argv
end

function reload --description 'reload fish config'
    set -l config_dir "$__fish_config_dir"
    set -q FISH_CONFIG_DIR; and set config_dir "$FISH_CONFIG_DIR"
    source "$config_dir/config.fish" $argv
end

# alias dotfiles='/usr/bin/git --git-dir="$HOME/.dotfiles/" --work-tree="$HOME"'
alias dotfiles='git --git-dir="$HOME/.dotfiles/" --work-tree="$HOME"'