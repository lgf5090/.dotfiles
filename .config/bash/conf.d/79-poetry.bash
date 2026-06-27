if [[ $- == *i* ]]; then
  for __bash_poetry_completion in \
    "${XDG_DATA_HOME:-$HOME/.local/share}/bash-completion/completions/poetry" \
    "$HOME/.local/share/bash-completion/completions/poetry" \
    "${HOMEBREW_PREFIX:+$HOMEBREW_PREFIX/etc/bash_completion.d/poetry}" \
    /etc/bash_completion.d/poetry
  do
    [[ -r $__bash_poetry_completion ]] || continue
    source "$__bash_poetry_completion"
    break
  done
  unset __bash_poetry_completion
fi
