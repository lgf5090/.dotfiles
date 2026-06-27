# bash

Fish-style bash configuration.

## Layout

```text
bash/
  config.bash
  conf.d/
  functions/
  completions/
```

- `config.bash`: small entry file.
- `conf.d/*.bash`: startup config, tools, plugins. Loaded by filename order.
- `functions/*.bash`: shell functions. Loaded by filename order.
- `completions/*.bash`: bash completion registrations. Loaded by filename order.

## Use

```bash
source /tmp/bash/config.bash
```

## Use As Native bash Config

```bash
ln -s /tmp/bash ~/.config/bash
```

bash does not read `~/.config/bash` by default. Add this once to `~/.bashrc`:

```bash
source "$HOME/.config/bash/.bashrc"
```

For login shells, also add this to `~/.bash_profile` if needed:

```bash
source "$HOME/.config/bash/.bash_profile"
```

## Add A Tool

Add a file only:

```text
conf.d/60-your-tool.bash
```

Use adjacent numbers inside the same category. Current bash tool ranges:

- `60-69`: interactive CLI integrations such as `fzf`, `zoxide`, `lf`.
- `70-79`: runtime, package, and environment managers such as `mise`, `asdf`,
  `pyenv`, `fnm`, `nvm`, `conda`, `SDKMAN`, `direnv`, and `poetry`.

No change is needed in `config.bash`.

## Local Env And Alias Files

`conf.d/11-local-env.bash` loads `~/.envs` if it exists:

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

`conf.d/45-local-aliases.bash` loads `~/.aliases` if it exists:

```text
gs="git status"
ll="ls -alFh"
```

Aliases load after the default aliases, so local aliases can override them.

## Add A Function

Add a file only:

```text
functions/your-function.bash
```

## Add Completion

Add a file only:

```text
completions/your-command.bash
```
