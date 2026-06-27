set -q EDITOR; or set -gx EDITOR vim
set -q VISUAL; or set -gx VISUAL $EDITOR
set -q PAGER; or set -gx PAGER less
set -q LESS; or set -gx LESS '-R -F -X'
set -q CLICOLOR; or set -gx CLICOLOR 1
