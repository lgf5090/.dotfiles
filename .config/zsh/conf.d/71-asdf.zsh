if [[ -n ${ASDF_DIR:-} ]]; then
  _zpath_prepend "$ASDF_DIR/bin"
fi

if [[ -n ${ASDF_DATA_DIR:-} ]]; then
  _zpath_prepend "$ASDF_DATA_DIR/shims"
fi

for __zsh_asdf_script in \
  "${ASDF_DIR:+$ASDF_DIR/asdf.sh}" \
  "${ASDF_DIR:+$ASDF_DIR/libexec/asdf.sh}" \
  "${HOMEBREW_PREFIX:+$HOMEBREW_PREFIX/opt/asdf/libexec/asdf.sh}" \
  /home/linuxbrew/.linuxbrew/opt/asdf/libexec/asdf.sh \
  /opt/homebrew/opt/asdf/libexec/asdf.sh \
  /usr/local/opt/asdf/libexec/asdf.sh \
  "$HOME/.asdf/asdf.sh"
do
  [[ -r $__zsh_asdf_script ]] || continue
  source "$__zsh_asdf_script"
  break
done
unset __zsh_asdf_script

for __zsh_asdf_completion_dir in \
  "${ASDF_DIR:+$ASDF_DIR/completions}" \
  "${ASDF_DIR:+$ASDF_DIR/libexec/completions}" \
  "${HOMEBREW_PREFIX:+$HOMEBREW_PREFIX/opt/asdf/libexec/completions}" \
  /home/linuxbrew/.linuxbrew/opt/asdf/libexec/completions \
  /opt/homebrew/opt/asdf/libexec/completions \
  /usr/local/opt/asdf/libexec/completions \
  "$HOME/.asdf/completions"
do
  [[ -d $__zsh_asdf_completion_dir ]] || continue
  fpath=("$__zsh_asdf_completion_dir" "${fpath[@]:#$__zsh_asdf_completion_dir}")
  if (( $+functions[compdef] )); then
    autoload -Uz _asdf
    compdef _asdf asdf
  fi
  break
done
unset __zsh_asdf_completion_dir
