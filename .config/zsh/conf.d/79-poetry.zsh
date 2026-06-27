for __zsh_poetry_completion_dir in \
  "${XDG_DATA_HOME:-$HOME/.local/share}/zsh/site-functions" \
  "$HOME/.zfunc" \
  "${HOMEBREW_PREFIX:+$HOMEBREW_PREFIX/share/zsh/site-functions}" \
  /home/linuxbrew/.linuxbrew/share/zsh/site-functions \
  /opt/homebrew/share/zsh/site-functions \
  /usr/local/share/zsh/site-functions
do
  [[ -r $__zsh_poetry_completion_dir/_poetry ]] || continue
  fpath=("$__zsh_poetry_completion_dir" "${fpath[@]:#$__zsh_poetry_completion_dir}")
  if (( $+functions[compdef] )); then
    autoload -Uz _poetry
    compdef _poetry poetry
  fi
  break
done
unset __zsh_poetry_completion_dir
