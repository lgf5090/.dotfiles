paths() {
  local old_ifs=$IFS part
  IFS=:
  for part in $PATH; do
    printf '%s\n' "$part"
  done
  IFS=$old_ifs
}
