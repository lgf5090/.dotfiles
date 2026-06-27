: "${SDKMAN_DIR:=$HOME/.sdkman}"
export SDKMAN_DIR

if [[ -s $SDKMAN_DIR/bin/sdkman-init.sh ]]; then
  source "$SDKMAN_DIR/bin/sdkman-init.sh"
fi
