# Bash startup files

`install-macos.sh` symlinks these into your home folder:

| Repo file           | Linked as          | Read by                        |
| ------------------- | ------------------ | ------------------------------ |
| `bash/bash_profile` | `~/.bash_profile`  | login shells                   |
| `bash/bashrc`       | `~/.bashrc`        | interactive shells             |
| `bash/bash_logout`  | `~/.bash_logout`   | login shells, on exit          |

The symlinks point at the repo, so editing a file here changes every new
shell straight away. Nothing needs to be re-installed.

## Kinds of shell

Bash picks its startup files based on two questions:

- **Login shell?** This is the first shell of a session. On macOS, every new
  Terminal, Ghostty, iTerm, Zed or Herdr tab or window starts a login shell,
  and so does `ssh` into this Mac. `bash -l` starts one too.
- **Interactive?** That means a person is typing at a prompt. Scripts,
  `bash -c '...'` and commands run over `ssh host cmd` are not interactive.

| Shell                                 | Login | Interactive | Example                      |
| ------------------------------------- | ----- | ----------- | ---------------------------- |
| New terminal tab                      | yes   | yes         | opening Terminal             |
| Nested shell                          | no    | yes         | typing `bash` in a tab       |
| Script or command                     | no    | no          | `./install-macos.sh`, `bash -c` |

## Loading order

### Login shell (a new terminal tab)

1. **`/etc/profile`** (system, macOS). This runs `path_helper`, which builds
   `PATH` from `/etc/paths` and `/etc/paths.d/`, putting system directories
   first. Then it sources **`/etc/bashrc`**. That sets a default `PS1` and,
   in Apple's Terminal, sources `/etc/bashrc_Apple_Terminal`, which saves and
   restores each tab's history in `~/.bash_sessions/`.
2. **`~/.bash_profile`** → `bash/bash_profile`. Bash reads only the first of
   `~/.bash_profile`, `~/.bash_login` and `~/.profile` that it finds, so the
   other two are ignored while this file exists. It:
   1. Follows its own symlink to find this repo, and exports the path as
      `DOTFILES_BASH`.
   2. Sources **`bash/profile.d/*.sh`** in name order. These set up the
      environment:
      - `10-homebrew.sh`: `brew shellenv` (Homebrew's `PATH`, `MANPATH`,
        `HOMEBREW_*`), plus `HOMEBREW_*` settings: no auto-update,
        analytics, hints or automatic cleanup, and taps must be trusted.
      - `20-path.sh`: puts `~/.local/bin` (Claude Code, Codex) first in `PATH`.
      - `30-env.sh`: `EDITOR` (Neovim), `LANG`, `SSH_AUTH_SOCK` (Secretive's
        agent, used for git commit signing), `DO_NOT_TRACK` and the like.
   3. Sources **`~/.bash_profile.local`** if it exists, for machine-specific
      environment settings.
   4. Sources **`~/.bashrc`**. Bash never does this by itself in a login
      shell.
3. **`~/.bashrc`** → `bash/bashrc`. It:
   1. Returns straight away unless the shell is interactive.
   2. Sources **`bash/bashrc.d/*.sh`** in name order. These are interactive
      settings:
      - `10-options.sh`: `shopt` options.
      - `20-history.sh`: history size, sharing between tabs, de-duplication.
      - `30-completion.sh`: Homebrew's `bash-completion@2`, if installed.
      - `40-aliases.sh`: aliases.
      - `50-prompt.sh`: the Starship prompt, if installed. Its config is
        `starship/starship.toml`, linked as `~/.config/starship.toml`.
   3. Sources **`~/.bashrc.local`** if it exists, for machine-specific
      interactive settings.
4. You get a prompt.
5. On exit: **`~/.bash_logout`** → `bash/bash_logout`, which sources
   `~/.bash_logout.local` if it exists.

### Interactive non-login shell (`bash` typed in a tab)

Only **`~/.bashrc`** is read. `/etc/profile` and `~/.bash_profile` are
skipped, so the environment (`PATH`, exported variables) is inherited from
the parent shell. That is why environment settings go in `profile.d/` and not
`bashrc.d/`: they're set once at login and passed down, instead of being
redone, and possibly stacked up, in every nested shell.

### Non-interactive shell (scripts, `bash -c`)

Bash reads none of these files. If `BASH_ENV` is set, it reads the file that
names, but these dotfiles don't set it. Scripts inherit the exported
environment of whatever started them and should not depend on aliases or
other interactive settings.

## Where does a setting go?

| Setting                                          | Put it in               |
| ------------------------------------------------ | ----------------------- |
| `PATH`, exported variables (`export FOO=...`)    | `profile.d/`            |
| Aliases, functions, `shopt`, prompt, completion, key bindings | `bashrc.d/` |
| Anything secret or specific to one machine       | a `.local` file (below) |

Fragments must be `*.sh` files. They are sourced, not executed, so they need
no shebang or execute bit. They load in name order, so the numeric prefix sets
the order: `10-` runs before `20-`. To add a fragment, create a new file. It
is picked up by the next new shell.

Clean up temporary variables and helper functions, using `unset` and
`unset -f`. Everything a fragment defines stays in your shell otherwise.

## Local overrides (untracked)

This repository is public, so tokens, work hostnames and per-machine tweaks
belong in these files in your home folder. They are never committed: the
repo's `.gitignore` ignores `*.local`.

| File                    | Sourced                                 | Use for                   |
| ----------------------- | --------------------------------------- | ------------------------- |
| `~/.bash_profile.local` | at login, after `profile.d/`            | environment, secrets      |
| `~/.bashrc.local`       | in interactive shells, after `bashrc.d/` | aliases, prompt tweaks    |
| `~/.bash_logout.local`  | when a login shell exits                | cleanup                   |

Each one loads after the tracked fragments, so anything it sets wins.

## Installer notes

- If `~/.bash_profile`, `~/.bashrc` or `~/.bash_logout` already exists,
  `install-macos.sh` leaves it alone and reports it as skipped. To switch
  over, move the file's useful contents into the matching `.local` file, move
  the original aside, and re-run the script.
- Some installers append to your startup files, for example the Codex
  installer adds a `PATH` block. `install-macos.sh` links these files first,
  and runs such installers with `~/.local/bin` already on `PATH` so they have
  nothing to add. If one still writes to a linked file, the change shows up as
  a diff in this repo. Move it to a `.local` file instead of committing it.
