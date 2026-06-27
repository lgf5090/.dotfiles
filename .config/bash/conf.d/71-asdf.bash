if [[ -n ${ASDF_DIR:-} ]]; then
  _bpath_prepend "$ASDF_DIR/bin"
fi

if [[ -n ${ASDF_DATA_DIR:-} ]]; then
  _bpath_prepend "$ASDF_DATA_DIR/shims"
fi

for __bash_asdf_script in \
  "${ASDF_DIR:+$ASDF_DIR/asdf.sh}" \
  "${ASDF_DIR:+$ASDF_DIR/libexec/asdf.sh}" \
  "${HOMEBREW_PREFIX:+$HOMEBREW_PREFIX/opt/asdf/libexec/asdf.sh}" \
  /home/linuxbrew/.linuxbrew/opt/asdf/libexec/asdf.sh \
  /opt/homebrew/opt/asdf/libexec/asdf.sh \
  /usr/local/opt/asdf/libexec/asdf.sh \
  "$HOME/.asdf/asdf.sh"
do
  [[ -r $__bash_asdf_script ]] || continue
  source "$__bash_asdf_script"
  break
done
unset __bash_asdf_script

if [[ $- == *i* ]]; then
  for __bash_asdf_completion in \
    "${ASDF_DIR:+$ASDF_DIR/completions/asdf.bash}" \
    "${ASDF_DIR:+$ASDF_DIR/libexec/completions/asdf.bash}" \
    "${HOMEBREW_PREFIX:+$HOMEBREW_PREFIX/opt/asdf/libexec/completions/asdf.bash}" \
    /home/linuxbrew/.linuxbrew/opt/asdf/libexec/completions/asdf.bash \
    /opt/homebrew/opt/asdf/libexec/completions/asdf.bash \
    /usr/local/opt/asdf/libexec/completions/asdf.bash \
    "$HOME/.asdf/completions/asdf.bash"
  do
    [[ -r $__bash_asdf_completion ]] || continue
    source "$__bash_asdf_completion"
    break
  done
  unset __bash_asdf_completion
fi
