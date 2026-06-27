# zsh

Fish-style zsh configuration.

## Layout

```text
zsh/
  config.zsh
  conf.d/
  functions/
  completions/
```

- `config.zsh`: small entry file.
- `conf.d/*.zsh`: startup config, tools, plugins. Loaded by filename order.
- `functions/*.zsh`: shell functions. Loaded by filename order.
- `completions/_cmd`: zsh completion definitions. Added to `fpath`.

## Use

```zsh
source /tmp/zsh/config.zsh
```

## Use As Native zsh Config

```zsh
ln -s /tmp/zsh ~/.config/zsh
```

zsh does not read `~/.config/zsh` by default. Add this once to `~/.zshenv`:

```zsh
export ZDOTDIR="$HOME/.config/zsh"
```

Then start a new zsh. The wrapper `.zshrc` in this directory sources
`config.zsh`.

## Add A Tool

Add a file only:

```text
conf.d/60-your-tool.zsh
```

Use adjacent numbers inside the same category. Current zsh tool ranges:

- `60-69`: interactive CLI integrations such as `fzf`, `zoxide`, `lf`.
- `70-79`: runtime, package, and environment managers such as `mise`, `asdf`,
  `pyenv`, `fnm`, `nvm`, `conda`, `SDKMAN`, `direnv`, and `poetry`.

No change is needed in `config.zsh`.

## Local Env And Alias Files

`conf.d/11-local-env.zsh` loads `~/.envs` if it exists:

```text
FOO=bar
EDITOR=nvim
PATH={HOME}/.local/custom/bin:{PATH}
```

- Lines must be `KEY=VALUE`.
- Full-line comments and invalid variable names are ignored.
- Matching outer single or double quotes are stripped.
- `{HOME}` and `{PATH}` are expanded without using `eval`.
- `PATH` is split on `:` and prepended in the written order.

`conf.d/45-local-aliases.zsh` loads `~/.aliases` if it exists:

```text
gs="git status"
ll="ls -alFh"
```

Aliases load after the default aliases, so local aliases can override them.

## Add A Plugin

Add a file only:

```zsh
_zplugin owner repo
```

Example:

```zsh
_zplugin zsh-users zsh-completions
```
