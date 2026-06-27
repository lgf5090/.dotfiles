set -q _FLOCAL_LOADER_VERSION; or set -g _FLOCAL_LOADER_VERSION 0
if test "$_FLOCAL_LOADER_VERSION" != 1
    set -l _fish_local_conf_dir (string replace -r '/[^/]*$' '' -- (status filename))
    source "$_fish_local_conf_dir/01-helpers.fish"
end

set -l _fish_local_aliases_file "$HOME/.aliases"
set -q FISH_LOCAL_ALIASES_FILE; and set _fish_local_aliases_file "$FISH_LOCAL_ALIASES_FILE"
_fload_aliases "$_fish_local_aliases_file"
