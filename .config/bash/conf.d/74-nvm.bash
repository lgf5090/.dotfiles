: "${NVM_DIR:=$HOME/.nvm}"
export NVM_DIR

if [[ -s "$NVM_DIR/nvm.sh" ]]; then
  _nvm_load() {
    unset -f _nvm_load nvm node npm npx 2>/dev/null
    source "$NVM_DIR/nvm.sh"
    [[ -s "$NVM_DIR/bash_completion" ]] && source "$NVM_DIR/bash_completion"
  }

  nvm() { _nvm_load; nvm "$@"; }
  node() { _nvm_load; node "$@"; }
  npm() { _nvm_load; npm "$@"; }
  npx() { _nvm_load; npx "$@"; }
fi
