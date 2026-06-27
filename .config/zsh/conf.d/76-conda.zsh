__ZSH_CONDA_EXE=
if [[ -n ${ANACONDA_HOME:-} && -x $ANACONDA_HOME/bin/conda ]]; then
  __ZSH_CONDA_EXE=$ANACONDA_HOME/bin/conda
elif [[ ${ZSH_CONDA_DISCOVERY:-0} == 1 ]] && (( $+commands[conda] )); then
  __ZSH_CONDA_EXE=${commands[conda]}
fi

if [[ -n ${__ZSH_CONDA_EXE:-} && -x $__ZSH_CONDA_EXE ]]; then
  _zconda_load() {
    local __zsh_conda_setup
    unfunction conda mamba _zconda_load 2>/dev/null

    __zsh_conda_setup=$("$__ZSH_CONDA_EXE" shell.zsh hook 2>/dev/null || :)
    if [[ -n $__zsh_conda_setup ]]; then
      eval "$__zsh_conda_setup"
    elif [[ -n ${ANACONDA_HOME:-} && -r $ANACONDA_HOME/etc/profile.d/conda.sh ]]; then
      source "$ANACONDA_HOME/etc/profile.d/conda.sh"
    else
      _zpath_prepend "${__ZSH_CONDA_EXE:h}"
    fi
  }

  conda() {
    _zconda_load
    conda "$@"
  }

  __ZSH_MAMBA_EXE=
  if [[ -n ${ANACONDA_HOME:-} && -x $ANACONDA_HOME/bin/mamba ]]; then
    __ZSH_MAMBA_EXE=$ANACONDA_HOME/bin/mamba
  elif [[ ${ZSH_CONDA_DISCOVERY:-0} == 1 ]] && (( $+commands[mamba] )); then
    __ZSH_MAMBA_EXE=${commands[mamba]}
  fi

  if [[ -n $__ZSH_MAMBA_EXE ]]; then
    mamba() {
      _zconda_load
      mamba "$@"
    }
  fi
  unset __ZSH_MAMBA_EXE
fi

__ZSH_MICROMAMBA_EXE=
if [[ -n ${MICROMAMBA_EXE:-} && -x $MICROMAMBA_EXE ]]; then
  __ZSH_MICROMAMBA_EXE=$MICROMAMBA_EXE
elif [[ ${ZSH_CONDA_DISCOVERY:-0} == 1 ]] && (( $+commands[micromamba] )); then
  __ZSH_MICROMAMBA_EXE=${commands[micromamba]}
fi

if [[ -n ${__ZSH_MICROMAMBA_EXE:-} && -x $__ZSH_MICROMAMBA_EXE ]]; then
  micromamba() {
    local __zsh_micromamba_setup
    unfunction micromamba 2>/dev/null

    __zsh_micromamba_setup=$("$__ZSH_MICROMAMBA_EXE" shell hook --shell zsh 2>/dev/null || :)
    [[ -n $__zsh_micromamba_setup ]] && eval "$__zsh_micromamba_setup"
    micromamba "$@"
  }
fi
