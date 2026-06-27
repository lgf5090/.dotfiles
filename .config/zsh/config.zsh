# Fish-style zsh entrypoint.

: "${ZSH_CONFIG_DIR:=${${(%):-%x}:A:h}}"
typeset -g ZSH_CONFIG_DIR

fpath=("$ZSH_CONFIG_DIR/functions" "$ZSH_CONFIG_DIR/completions" "${fpath[@]}")

_zsource_dir() {
  local dir=$1 file
  [[ -d $dir ]] || return 0

  for file in "$dir"/*.zsh(N-.); do
    [[ -r $file ]] && source "$file"
  done
}

_zsource_dir "$ZSH_CONFIG_DIR/functions"
_zsource_dir "$ZSH_CONFIG_DIR/conf.d"

unfunction _zsource_dir
