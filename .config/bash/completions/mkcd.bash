_mkcd_complete() {
  local cur=${COMP_WORDS[COMP_CWORD]}
  COMPREPLY=($(compgen -d -- "$cur"))
}

complete -F _mkcd_complete mkcd
