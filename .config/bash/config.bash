# Fish-style bash entrypoint.

_bash_config_file=${BASH_SOURCE[0]}
case $_bash_config_file in
  /*) ;;
  *) _bash_config_file=$PWD/$_bash_config_file ;;
esac

: "${BASH_CONFIG_DIR:=$(cd -- "${_bash_config_file%/*}" && pwd -P)}"

_bsource_dir() {
  local dir=$1 file nullglob_was_set
  [[ -d $dir ]] || return 0

  shopt -q nullglob
  nullglob_was_set=$?
  shopt -s nullglob

  for file in "$dir"/*.bash; do
    [[ -r $file ]] && source "$file"
  done

  (( nullglob_was_set == 0 )) || shopt -u nullglob
}

_bsource_dir "$BASH_CONFIG_DIR/functions"
_bsource_dir "$BASH_CONFIG_DIR/conf.d"
_bsource_dir "$BASH_CONFIG_DIR/completions"

unset _bash_config_file
unset -f _bsource_dir
