_zplugins_load() {
  (( ${+__zsh_plugins_loaded} )) && return 0
  typeset -g __zsh_plugins_loaded=1

  _zplugin zsh-users zsh-autosuggestions
  _zplugin zsh-users zsh-history-substring-search
  _zplugin jeffreytse zsh-vi-mode
  _zplugin zdharma-continuum fast-syntax-highlighting
}

case ${ZSH_PLUGIN_LOAD:-sync} in
  none|0|no|false) ;;
  defer|lazy)
    if [[ -o interactive ]]; then
      autoload -Uz add-zle-hook-widget
      _zplugins_load_deferred() {
        add-zle-hook-widget -d zle-line-init _zplugins_load_deferred 2>/dev/null
        _zplugins_load
        zle reset-prompt 2>/dev/null || true
      }
      add-zle-hook-widget zle-line-init _zplugins_load_deferred 2>/dev/null \
        || _zplugins_load
    else
      _zplugins_load
    fi
    ;;
  *)
    _zplugins_load
    ;;
esac
