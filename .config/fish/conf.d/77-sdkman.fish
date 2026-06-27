set -q SDKMAN_DIR; or set -gx SDKMAN_DIR "$HOME/.sdkman"

if test -s "$SDKMAN_DIR/bin/sdkman-init.fish"
    source "$SDKMAN_DIR/bin/sdkman-init.fish"
end
