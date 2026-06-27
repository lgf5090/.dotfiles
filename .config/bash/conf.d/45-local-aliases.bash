if [[ ${_BLOCAL_LOADER_VERSION:-0} != 2 ]]; then
  _bash_local_conf_dir=${BASH_SOURCE[0]%/*}
  source "$_bash_local_conf_dir/01-helpers.bash"
  unset _bash_local_conf_dir
fi

_bload_aliases "${BASH_LOCAL_ALIASES_FILE:-$HOME/.aliases}"
