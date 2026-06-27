set -l conda_discovery 0
set -q FISH_CONDA_DISCOVERY; and set conda_discovery "$FISH_CONDA_DISCOVERY"

if set -q ANACONDA_HOME; and test -x "$ANACONDA_HOME/bin/conda"
    set -g __FISH_CONDA_EXE "$ANACONDA_HOME/bin/conda"
else if test "$conda_discovery" = 1
    set -g __FISH_CONDA_EXE (command -s conda 2>/dev/null)
end

if set -q __FISH_CONDA_EXE; and test -x "$__FISH_CONDA_EXE"
    function _fconda_load
        functions -e conda mamba _fconda_load 2>/dev/null

        set -l conda_setup ("$__FISH_CONDA_EXE" shell.fish hook 2>/dev/null)
        if test -n "$conda_setup"
            string join \n -- $conda_setup | source
        else if set -q ANACONDA_HOME; and test -r "$ANACONDA_HOME/etc/fish/conf.d/conda.fish"
            source "$ANACONDA_HOME/etc/fish/conf.d/conda.fish"
        else
            _fpath_prepend (path dirname "$__FISH_CONDA_EXE")
        end
    end

    function conda
        _fconda_load
        conda $argv
    end

    set -l mamba
    if set -q ANACONDA_HOME; and test -x "$ANACONDA_HOME/bin/mamba"
        set mamba "$ANACONDA_HOME/bin/mamba"
    else if test "$conda_discovery" = 1
        set mamba (command -s mamba 2>/dev/null)
    end

    if test -n "$mamba"
        function mamba
            _fconda_load
            mamba $argv
        end
    end
end

if set -q MICROMAMBA_EXE; and test -x "$MICROMAMBA_EXE"
    set -g __FISH_MICROMAMBA_EXE "$MICROMAMBA_EXE"
else if test "$conda_discovery" = 1
    set -g __FISH_MICROMAMBA_EXE (command -s micromamba 2>/dev/null)
end

if set -q __FISH_MICROMAMBA_EXE; and test -x "$__FISH_MICROMAMBA_EXE"
    function micromamba
        functions -e micromamba 2>/dev/null

        set -l micromamba_setup ("$__FISH_MICROMAMBA_EXE" shell hook --shell fish 2>/dev/null)
        test -n "$micromamba_setup"; and string join \n -- $micromamba_setup | source
        micromamba $argv
    end
end
