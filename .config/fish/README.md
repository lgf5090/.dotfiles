# fish

Fish configuration with the same project layout as `/tmp/zsh`.

## Layout

```text
fish/
  config.fish
  conf.d/
  functions/
  completions/
```

- `config.fish`: small entry file.
- `conf.d/*.fish`: startup config, tools, plugins. Loaded by fish by filename order.
- `functions/*.fish`: shell functions. Autoloaded by fish.
- `completions/*.fish`: fish completions. Discovered by fish.

## Use As Native Fish Config

```sh
ln -s /tmp/fish ~/.config/fish
```

If `~/.config/fish` already exists, move or merge it first.

```fish
exec fish
```

Fish will load `conf.d/`, `functions/`, and `completions/` through its native
startup conventions.

## Use From Another Config

```fish
source /tmp/fish/config.fish
```

In this mode, `config.fish` adds this project's `functions/` and `completions/`
paths, then sources this project's `conf.d/*.fish`.

## Add A Tool

Add a file only:

```text
conf.d/60-your-tool.fish
```

Use adjacent numbers inside the same category. Current fish tool ranges:

- `60-69`: interactive CLI integrations such as `fzf`, `zoxide`, `lf`.
- `70-79`: runtime, package, and environment managers such as `mise`, `asdf`,
  `pyenv`, `fnm`, `nvm`, `conda`, `SDKMAN`, `direnv`, and `poetry`.

## Local Env And Alias Files

`conf.d/11-local-env.fish` loads `~/.envs` if it exists:

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

`conf.d/45-local-aliases.fish` loads `~/.aliases` if it exists:

```text
gs="git status"
ll="ls -alFh"
```

Aliases load after the default aliases, so local aliases can override them.
Fish aliases are implemented as functions, so repeated loads are skipped while
the file mtime is unchanged.

## Add A Function

Add a file only:

```text
functions/your-function.fish
```

## Add Completion

Add a file only:

```text
completions/your-command.fish
```
