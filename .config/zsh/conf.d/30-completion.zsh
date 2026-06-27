autoload -Uz compinit

_zcompdump_dir="${XDG_CACHE_HOME:-$HOME/.cache}/zsh"
if ! { [[ -d $_zcompdump_dir ]] || mkdir -p "$_zcompdump_dir" 2>/dev/null; } || [[ ! -w $_zcompdump_dir ]]; then
  _zcompdump_dir="${TMPDIR:-/tmp}/zsh-${UID:-$USER}"
  mkdir -p "$_zcompdump_dir" 2>/dev/null
fi

_zcompdump="$_zcompdump_dir/zcompdump-${ZSH_VERSION}"
if [[ ! -s $_zcompdump || $_zcompdump -ot "$ZSH_CONFIG_DIR/config.zsh" ]]; then
  compinit -d "$_zcompdump"
else
  compinit -C -d "$_zcompdump"
fi
unset _zcompdump _zcompdump_dir

(( $+functions[_mcc_register_completion] )) && _mcc_register_completion

LISTMAX=999999
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
