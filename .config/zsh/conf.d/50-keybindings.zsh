[[ -o interactive ]] || return 0

setopt NO_FLOW_CONTROL

ZVM_INSERT_MODE_CURSOR=$ZVM_CURSOR_BEAM
ZVM_NORMAL_MODE_CURSOR=$ZVM_CURSOR_BLOCK
ZVM_VISUAL_MODE_CURSOR=$ZVM_CURSOR_BLOCK

ZVM_VI_HIGHLIGHT_BACKGROUND=none
ZVM_VI_HIGHLIGHT_FOREGROUND=none
ZVM_VI_HIGHLIGHT_EXTRASTYLE=none

autoload -Uz edit-command-line
zle -N edit-command-line

# Ctrl+F/Ctrl+R/Ctrl+T/Alt+C are reserved for fzf in 60-fzf.zsh.

_zbind_widget() {
  local keymap=$1 key=$2 widget=$3
  (( $+widgets[$widget] )) || return 0

  if (( $+functions[zvm_bindkey] )); then
    zvm_bindkey "$keymap" "$key" "$widget"
  else
    bindkey -M "$keymap" "$key" "$widget"
  fi
}

_zbind_viins() {
  # Basic movement and editing.
  _zbind_widget viins '^A' beginning-of-line
  _zbind_widget viins '^E' end-of-line
  _zbind_widget viins '^X^F' forward-char
  _zbind_widget viins '^B' backward-char
  _zbind_widget viins '^D' delete-char
  _zbind_widget viins '^H' backward-delete-char
  _zbind_widget viins '^K' kill-line
  _zbind_widget viins '^U' backward-kill-line
  _zbind_widget viins '^W' backward-kill-word
  _zbind_widget viins '^Y' yank

  # History.
  _zbind_widget viins '^X^R' history-incremental-search-backward
  _zbind_widget viins '^S' history-incremental-search-forward
  _zbind_widget viins '^P' up-history
  _zbind_widget viins '^N' down-history

  # Meta key bindings.
  _zbind_widget viins '\ef' forward-word
  _zbind_widget viins '\eb' backward-word
  _zbind_widget viins '\ed' kill-word
  _zbind_widget viins '\e^?' backward-kill-word
  _zbind_widget viins '\e.' insert-last-word

  # Completion and special editing.
  _zbind_widget viins '^I' expand-or-complete
  _zbind_widget viins '^X^T' transpose-chars
  _zbind_widget viins '\et' transpose-words
  _zbind_widget viins '\eu' up-case-word
  _zbind_widget viins '\el' down-case-word
  _zbind_widget viins '^Xc' capitalize-word
  _zbind_widget viins '^V' quoted-insert

  # Navigation keys.
  _zbind_widget viins '\e[A' history-beginning-search-backward
  _zbind_widget viins '\e[B' history-beginning-search-forward
  _zbind_widget viins '\e[H' beginning-of-line
  _zbind_widget viins '\e[F' end-of-line
  _zbind_widget viins '^[[1;5C' forward-word
  _zbind_widget viins '^[[1;5D' backward-word
  _zbind_widget viins '\e[5~' history-beginning-search-backward
  _zbind_widget viins '\e[6~' history-beginning-search-forward
  _zbind_widget viins '\e[3~' delete-char
}

_zbind_vicmd() {
  # Basic movement and editing.
  _zbind_widget vicmd '^A' beginning-of-line
  _zbind_widget vicmd '^E' end-of-line
  _zbind_widget vicmd '^X^F' forward-char
  _zbind_widget vicmd '^B' backward-char
  _zbind_widget vicmd '^D' delete-char
  _zbind_widget vicmd '^K' kill-line
  _zbind_widget vicmd '^U' backward-kill-line
  _zbind_widget vicmd '^W' backward-kill-word
  _zbind_widget vicmd '^Y' yank

  # History.
  _zbind_widget vicmd '^X^R' history-incremental-search-backward
  _zbind_widget vicmd '^S' history-incremental-search-forward
  _zbind_widget vicmd '^P' up-history
  _zbind_widget vicmd '^N' down-history

  # Vi-style additions.
  _zbind_widget vicmd 'gg' beginning-of-buffer-or-history
  _zbind_widget vicmd 'G' end-of-buffer-or-history

  # This intentionally overrides zsh-vi-mode's default "v enters visual mode".
  _zbind_widget vicmd 'v' edit-command-line

  # Meta key bindings.
  _zbind_widget vicmd '\ef' forward-word
  _zbind_widget vicmd '\eb' backward-word

  # Navigation keys.
  _zbind_widget vicmd '\e[A' up-history
  _zbind_widget vicmd '\e[B' down-history
  _zbind_widget vicmd '\e[H' beginning-of-line
  _zbind_widget vicmd '\e[F' end-of-line
  _zbind_widget vicmd '^[[1;5C' forward-word
  _zbind_widget vicmd '^[[1;5D' backward-word
  _zbind_widget vicmd '\e[3~' delete-char
}

_zbind_optional_widgets() {
  if (( $+widgets[autosuggest-toggle] )); then
    bindkey -M viins '^\' autosuggest-toggle
    bindkey -M vicmd '^\' autosuggest-toggle
  fi
}

_zbind_fzf_widgets() {
  if (( $+widgets[_fzf_file_no_hidden] )); then
    _zbind_widget viins '^F' _fzf_file_no_hidden
    _zbind_widget vicmd '^F' _fzf_file_no_hidden
  fi

  if (( $+widgets[fzf-history-widget] )); then
    _zbind_widget viins '^R' fzf-history-widget
    _zbind_widget vicmd '^R' fzf-history-widget
  fi

  if (( $+widgets[fzf-file-widget] )); then
    _zbind_widget viins '^T' fzf-file-widget
    _zbind_widget vicmd '^T' fzf-file-widget
  fi

  if (( $+widgets[fzf-cd-widget] )); then
    _zbind_widget viins '\ec' fzf-cd-widget
    _zbind_widget vicmd '\ec' fzf-cd-widget
  fi
}

zvm_after_init() {
  _zbind_viins
  _zbind_optional_widgets
  _zbind_fzf_widgets
}

zvm_after_lazy_keybindings() {
  _zbind_vicmd
  _zbind_optional_widgets
  _zbind_fzf_widgets
}
