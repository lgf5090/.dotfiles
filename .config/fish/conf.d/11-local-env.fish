set -q _FLOCAL_LOADER_VERSION; or set -g _FLOCAL_LOADER_VERSION 0
if test "$_FLOCAL_LOADER_VERSION" != 1
    set -l _fish_local_conf_dir (string replace -r '/[^/]*$' '' -- (status filename))
    source "$_fish_local_conf_dir/01-helpers.fish"
end

set -l _fish_local_envs_file "$HOME/.envs"
set -q FISH_LOCAL_ENVS_FILE; and set _fish_local_envs_file "$FISH_LOCAL_ENVS_FILE"
_fload_envs "$_fish_local_envs_file"
