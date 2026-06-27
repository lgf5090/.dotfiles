case $- in
  *i*) ;;
  *) return 0 ;;
esac

set -o vi

if [[ -t 0 ]]; then
  stty -ixon 2>/dev/null || true
fi

# Ctrl+F/Ctrl+R/Ctrl+T/Alt+C are reserved for fzf in 60-fzf.bash.

# Insert mode: movement and editing.
bind -m vi-insert '"\C-a": beginning-of-line'
bind -m vi-insert '"\C-e": end-of-line'
bind -m vi-insert '"\C-x\C-f": forward-char'
bind -m vi-insert '"\C-b": backward-char'
bind -m vi-insert '"\C-d": delete-char'
bind -m vi-insert '"\C-h": backward-delete-char'
bind -m vi-insert '"\C-k": kill-line'
bind -m vi-insert '"\C-u": unix-line-discard'
bind -m vi-insert '"\C-w": backward-kill-word'
bind -m vi-insert '"\C-y": yank'

# Insert mode: history.
bind -m vi-insert '"\C-x\C-r": reverse-search-history'
bind -m vi-insert '"\C-s": forward-search-history'
bind -m vi-insert '"\C-p": previous-history'
bind -m vi-insert '"\C-n": next-history'

# Insert mode: meta key bindings.
bind -m vi-insert '"\ef": forward-word'
bind -m vi-insert '"\eb": backward-word'
bind -m vi-insert '"\ed": kill-word'
bind -m vi-insert '"\e\C-?": backward-kill-word'
bind -m vi-insert '"\e.": yank-last-arg'

# Insert mode: completion and special editing.
bind -m vi-insert '"\t": complete'
bind -m vi-insert '"\C-x\C-t": transpose-chars'
bind -m vi-insert '"\et": transpose-words'
bind -m vi-insert '"\eu": upcase-word'
bind -m vi-insert '"\el": downcase-word'
bind -m vi-insert '"\C-xc": capitalize-word'
bind -m vi-insert '"\C-v": quoted-insert'

# Command mode: movement and editing.
bind -m vi-command '"\C-a": beginning-of-line'
bind -m vi-command '"\C-e": end-of-line'
bind -m vi-command '"\C-x\C-f": forward-char'
bind -m vi-command '"\C-b": backward-char'
bind -m vi-command '"\C-d": delete-char'
bind -m vi-command '"\C-k": kill-line'
bind -m vi-command '"\C-u": unix-line-discard'
bind -m vi-command '"\C-w": backward-kill-word'
bind -m vi-command '"\C-y": yank'

# Command mode: history.
bind -m vi-command '"\C-x\C-r": reverse-search-history'
bind -m vi-command '"\C-s": forward-search-history'
bind -m vi-command '"\C-p": previous-history'
bind -m vi-command '"\C-n": next-history'

# Command mode: vi-style additions.
bind -m vi-command '"gg": beginning-of-history'
bind -m vi-command '"G": end-of-history'
bind -m vi-command '"v": edit-and-execute-command'

# Command mode: meta key bindings.
bind -m vi-command '"\ef": forward-word'
bind -m vi-command '"\eb": backward-word'

# Navigation keys.
bind -m vi-insert '"\e[A": history-search-backward'
bind -m vi-insert '"\e[B": history-search-forward'
bind -m vi-command '"\e[A": previous-history'
bind -m vi-command '"\e[B": next-history'

bind -m vi-insert '"\e[H": beginning-of-line'
bind -m vi-insert '"\e[F": end-of-line'
bind -m vi-command '"\e[H": beginning-of-line'
bind -m vi-command '"\e[F": end-of-line'

bind -m vi-insert '"\e[1;5C": forward-word'
bind -m vi-insert '"\e[1;5D": backward-word'
bind -m vi-command '"\e[1;5C": forward-word'
bind -m vi-command '"\e[1;5D": backward-word'

bind -m vi-insert '"\e[5~": history-search-backward'
bind -m vi-insert '"\e[6~": history-search-forward'

bind -m vi-insert '"\e[3~": delete-char'
bind -m vi-command '"\e[3~": delete-char'
