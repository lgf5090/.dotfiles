if [[ ${_ZLOCAL_LOADER_VERSION:-0} != 1 ]]; then
  _zsh_local_conf_dir=${${(%):-%x}:A:h}
  source "$_zsh_local_conf_dir/01-helpers.zsh"
  unset _zsh_local_conf_dir
fi

_zload_envs "${ZSH_LOCAL_ENVS_FILE:-$HOME/.envs}"
