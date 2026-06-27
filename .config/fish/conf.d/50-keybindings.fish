status is-interactive; or return 0

fish_vi_key_bindings

isatty stdin; and command stty -ixon 2>/dev/null

# Ctrl+R/Ctrl+T/Alt+C are reserved for fzf in 60-fzf.fish.

# Insert mode: movement and editing.
bind -M insert ctrl-a beginning-of-line
bind -M insert ctrl-e end-of-line
bind -M insert ctrl-f forward-char
bind -M insert ctrl-b backward-char
bind -M insert ctrl-d delete-char
bind -M insert ctrl-h backward-delete-char
bind -M insert ctrl-k kill-line
bind -M insert ctrl-u backward-kill-line
bind -M insert ctrl-w backward-kill-word
bind -M insert ctrl-y yank

# Insert mode: history.
bind -M insert ctrl-x,ctrl-r history-search-backward
bind -M insert ctrl-s history-search-forward
bind -M insert ctrl-p up-or-search
bind -M insert ctrl-n down-or-search

# Insert mode: meta key bindings.
bind -M insert alt-f forward-word
bind -M insert alt-b backward-word
bind -M insert alt-d kill-word
bind -M insert alt-delete backward-kill-word
bind -M insert alt-. history-token-search-backward

# Insert mode: completion and special editing.
bind -M insert tab complete
bind -M insert alt-\* complete-and-search
bind -M insert ctrl-x,ctrl-t transpose-chars
bind -M insert alt-t transpose-words
bind -M insert alt-u upcase-word
bind -M insert alt-l downcase-word
bind -M insert ctrl-x,c capitalize-word
bind -M insert ctrl-v fish_clipboard_paste

# Command mode: movement and editing.
bind -M default ctrl-a beginning-of-line
bind -M default ctrl-e end-of-line
bind -M default ctrl-f forward-char
bind -M default ctrl-b backward-char
bind -M default ctrl-d delete-char
bind -M default ctrl-k kill-line
bind -M default ctrl-u backward-kill-line
bind -M default ctrl-w backward-kill-word
bind -M default ctrl-y yank

# Command mode: history.
bind -M default ctrl-x,ctrl-r history-search-backward
bind -M default ctrl-s history-search-forward
bind -M default ctrl-p up-or-search
bind -M default ctrl-n down-or-search

# Command mode: vi-style additions.
bind -M default g,g beginning-of-history
bind -M default G end-of-history
bind -M default v edit_command_buffer

# Command mode: meta key bindings.
bind -M default alt-f forward-word
bind -M default alt-b backward-word

# Command mode: case conversion.
bind -M default \~ togglecase-char

# Navigation keys.
bind -M insert up history-search-backward
bind -M insert down history-search-forward
bind -M default up history-search-backward
bind -M default down history-search-forward

bind -M insert home beginning-of-line
bind -M insert end end-of-line
bind -M default home beginning-of-line
bind -M default end end-of-line

bind -M insert ctrl-right forward-word
bind -M insert ctrl-left backward-word
bind -M default ctrl-right forward-word
bind -M default ctrl-left backward-word

bind -M insert pageup history-search-backward
bind -M insert pagedown history-search-forward

bind -M insert delete delete-char
bind -M default delete delete-char
