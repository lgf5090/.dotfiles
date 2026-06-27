# Language and toolchain environment variables used by 15-path.fish.
# Existing values are respected so ~/.envs or parent shells can override.

set -q NPM_CONFIG_PREFIX; or set -gx NPM_CONFIG_PREFIX "$HOME/.npm-global"
set -q PNPM_HOME; or set -gx PNPM_HOME "$HOME/.pnpm-global"

if not set -q FNM_DIR
    for dir in "$XDG_DATA_HOME/fnm" "$HOME/.fnm"
        test -d "$dir"; or continue
        set -gx FNM_DIR "$dir"
        break
    end
end

test -d "$HOME/.volta"; and set -gx VOLTA_HOME "$HOME/.volta"
test -d "$HOME/.bun"; and set -gx BUN_INSTALL "$HOME/.bun"
test -d "$HOME/.deno"; and set -gx DENO_INSTALL "$HOME/.deno"

set -q GOPATH; or set -gx GOPATH "$HOME/go"

if not set -q GOROOT
    for dir in \
        /home/linuxbrew/.linuxbrew/opt/go/libexec \
        /opt/homebrew/opt/go/libexec \
        /usr/local/go \
        "$HOME/.local/go"
        test -d "$dir"; or continue
        set -gx GOROOT "$dir"
        break
    end
end

if not set -q ANACONDA_HOME
    for dir in "$HOME/anaconda3" "$HOME/miniconda3" /opt/anaconda3 /opt/miniconda3
        test -d "$dir"; or continue
        set -gx ANACONDA_HOME "$dir"
        break
    end
end

if not set -q POETRY_HOME
    test -d "$HOME/.poetry"; and set -gx POETRY_HOME "$HOME/.poetry"
end

if not set -q PYENV_ROOT
    test -d "$HOME/.pyenv"; and set -gx PYENV_ROOT "$HOME/.pyenv"
end

if not set -q ASDF_DIR
    for dir in \
        "$HOME/.asdf" \
        /home/linuxbrew/.linuxbrew/opt/asdf/libexec \
        /opt/homebrew/opt/asdf/libexec \
        /usr/local/opt/asdf/libexec
        test -d "$dir"; or continue
        set -gx ASDF_DIR "$dir"
        break
    end
end

if not set -q ASDF_DATA_DIR
    if set -q ASDF_DIR
        if test "$ASDF_DIR" = "$HOME/.asdf"
            set -gx ASDF_DATA_DIR "$ASDF_DIR"
        else
            set -gx ASDF_DATA_DIR "$XDG_DATA_HOME/asdf"
        end
    end
end

for pair in \
    "RBENV_ROOT:$HOME/.rbenv" \
    "NODENV_ROOT:$HOME/.nodenv" \
    "GOENV_ROOT:$HOME/.goenv" \
    "JENV_ROOT:$HOME/.jenv" \
    "SDKMAN_DIR:$HOME/.sdkman"
    set -l parts (string split -m1 : -- "$pair")
    set -l name $parts[1]
    set -l dir $parts[2]
    set -q $name; and continue
    test -d "$dir"; and set -gx $name "$dir"
end

if not set -q JAVA_HOME
    if test -x /usr/libexec/java_home
        set -l java_home (/usr/libexec/java_home 2>/dev/null)
        test -n "$java_home"; and set -gx JAVA_HOME "$java_home"
    else
        for dir in \
            /usr/lib/jvm/default-java \
            /usr/lib/jvm/default \
            /usr/lib/jvm/java-21-openjdk-amd64 \
            /usr/lib/jvm/java-17-openjdk-amd64 \
            /usr/lib/jvm/java-11-openjdk-amd64
            test -d "$dir"; or continue
            set -gx JAVA_HOME "$dir"
            break
        end
    end
end

switch "$SHELLS_OS"
    case linux wsl
        for dir in \
            /usr/lib/x86_64-linux-gnu \
            /usr/lib/aarch64-linux-gnu
            test -d "$dir"; or continue
            contains -- "$dir" $LIBRARY_PATH; or set -gx LIBRARY_PATH "$dir" $LIBRARY_PATH
            contains -- "$dir" $LD_LIBRARY_PATH; or set -gx LD_LIBRARY_PATH "$dir" $LD_LIBRARY_PATH

            set -l rustflags ''
            set -q RUSTFLAGS; and set rustflags "$RUSTFLAGS"
            string match -q -- "* -L $dir *" " $rustflags "
            or begin
                if test -n "$rustflags"
                    set -gx RUSTFLAGS "-L $dir $rustflags"
                else
                    set -gx RUSTFLAGS "-L $dir"
                end
            end
            break
        end
end

set -q DOCKER_BUILDKIT; or set -gx DOCKER_BUILDKIT 1
set -q COMPOSE_DOCKER_CLI_BUILD; or set -gx COMPOSE_DOCKER_CLI_BUILD 1
