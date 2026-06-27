HISTFILE="$XDG_STATE_HOME/bash/history"
HISTSIZE=100000
HISTFILESIZE=100000
HISTCONTROL=ignoreboth:erasedups
HISTTIMEFORMAT='%F %T '

export HISTFILE HISTSIZE HISTFILESIZE HISTCONTROL HISTTIMEFORMAT

shopt -s histappend
shopt -s cmdhist

_bhistory_sync() {
  history -a
  history -n
}

case $- in
  *i*) _bprompt_add _bhistory_sync ;;
esac
