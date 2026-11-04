# AGENTS.md

Guidance for AI coding agents working in this repository.

## What this repository is

Personal dotfiles: configuration that is synced between machines. Changes here
end up on every machine where the dotfiles are installed, so treat edits with
care.

## Rule 1: No secrets — this repository is public

Everything committed here is publicly visible. Never commit:

- API keys, tokens, passwords, or passphrases
- Private keys (SSH, GPG, TLS) or certificates containing private material
- Credentials files (e.g. `~/.aws/credentials`, `~/.netrc`, `.npmrc` with auth
  tokens, `gh`/`docker` auth configs)
- Personal or sensitive data such as private hostnames, internal URLs, IP
  addresses, or account IDs

When configuration needs a secret or a machine-specific value:

- Read it at runtime from an environment variable, the OS keychain, or a
  password manager CLI.
- Or source an untracked local override file (for example `~/.zshrc.local` or
  `~/.gitconfig.local`) that the tracked config includes if it exists. Local
  override files must never be committed; add them to `.gitignore`.

Before committing, review the diff for anything that looks like a secret. If a
secret is ever committed, removing it in a later commit is not enough — it is
already public and must be rotated. Tell the user immediately.

## Rule 2: Scripts must be non-destructive

Install/setup scripts must be safe to run on a machine that is already set up
and already has its own configuration. A script should make the changes it
can and leave everything else alone.

Requirements for every script:

- **Never overwrite existing files.** If the target already exists (as a file,
  directory, or symlink pointing somewhere else), skip it and print a message
  explaining what was skipped and why. Do not silently replace, and do not
  "back up then replace" unless the user explicitly asks for that behavior.
- **Never delete** user files or directories.
- **Idempotent.** Running a script twice must produce the same result as
  running it once. A symlink that already points to the correct place is a
  no-op, not an error.
- **Continue past skips.** A conflict on one item should not stop the rest of
  the installation; report a summary of what was created, what was already in
  place, and what was skipped due to conflicts.
- **Append, don't replace,** when a change has to go into an existing file
  (e.g. adding a `source` line to a shell rc file). Check that the line is not
  already present before appending.
- **Don't stop to ask.** `install-macos.sh` asks for the administrator
  password once, at the start, and keeps sudo's credentials fresh for the
  whole run, so privileged and system-wide steps (`sudo`, changing the login
  shell) just run, after checking `have_sudo`. Anything that truly needs the
  user's input (such as the git signing key, asked as soon as Secretive is
  installed) is asked as early as it can be, so the rest of the run is
  unattended. Never add yes/no confirmations.
- **Avoid destructive commands** such as `rm -rf`, `ln -sf`, `cp -f`, `mv`
  over existing paths, or `>` redirection onto existing files. Use `ln -s`
  without `-f`, `cp -n`, and `>>` only after checking for duplicates.
- Shell scripts should use `set -euo pipefail` (or the equivalent) and quote
  all variable expansions.
- Prefer supporting a dry-run mode (e.g. `--dry-run`) that prints what would
  change without changing anything.

**Exception: macOS system settings.** User preferences set with `defaults
write` (Dock, menu bar, etc.) and login items are always set to the desired
state, without checking the current value or asking first. They still go
through the dry-run mode.

## Platform

Every machine is an Apple silicon Mac running a current macOS; Intel Macs
and older macOS versions are not supported. The primary machine runs macOS (zsh). Scripts should work with the
BSD versions of core utilities shipped with macOS, and not assume GNU-only
flags. If Linux support is added, detect the OS rather than assuming one.

## Scripts

- `init.sh` — bootstrap for a new Mac, meant to be piped from curl: installs
  the Xcode Command Line Tools (for git) if needed, clones the repository to
  `~/.dotfiles` unless something is already there (an existing checkout is
  used as is, anything else stops the script), then runs `install-macos.sh`
  with the same options and the terminal as its input. Supports `--dry-run`.
  Bash 3.2 compatible, with everything inside `main` so a partial download
  runs nothing.
- `install-macos.sh` — macOS bootstrap (Xcode CLT, Homebrew, Homebrew bash, Git, jq, ripgrep, fd, fzf, bat, coreutils, prettyping, Node.js, mas, pam-reattach, Zed, Herdr,
  Neovim with its config symlinked to ~/.config/nvim/init.lua (`nvim/init.lua`) and tree-sitter-cli for its parsers, 1Password + CLI, Secretive, IVPN, OrbStack, OBS Studio, BetterMouse, Display Pilot 2, Elgato Stream Deck + Wave Link, IINA, Nativ,
  UniFi Identity Endpoint, Wins, Mac App Store apps (`install/mas.sh`: 1Blocker, Kagi, Endel, Portal, Soulver, Hidden Bar, Keka, DaisyDisk, PCalc, Amphetamine, Speediness, Power Plist/JSON/YAML Editor, Postico 2, Marked 3, Screens 5, 1Password for Safari, Tampermonkey, Keynote, Numbers, Pages, iMovie, Final Cut Pro, Compressor, in the `mas list` format that `docs/mas-list.md` prints, so its output can be pasted in), Docker Sandboxes (`sbx`, from the trusted `docker/tap` tap), GitHub CLI + gh-stack and gh-actions-lock extensions,
  Codex CLI (with its startup update check off: `check_for_update_on_startup = false` in ~/.codex/config.toml), pnpm (standalone installer, without letting it edit shell files; PATH is set in `bash/profile.d/20-path.sh`), bash-completion, bash startup files (`bash/`, see `bash/README.md`; `ping` is aliased to prettyping, Up/Down search history by prefix, fzf's Ctrl-R/Ctrl-T/Alt-C bindings listing with fd and previewing with bat, man pages in Neovim, coloured `ls`, `mkcd`/`up`/`fcd`/`fe` functions, OrbStack's PATH setup), an empty ~/.hushlogin, Starship prompt with its config symlinked to ~/.config/starship.toml (`starship/starship.toml`), ~/.ssh/config symlink (`ssh/config`, which includes untracked `~/.ssh/config.local`; keepalives and connection sharing via `~/.ssh/sockets`, which the script creates), the dotfiles remote switched from HTTPS to SSH,
  ~/.config/git/config symlink (`git/config`: name, email, SSH commit/tag signing, push/pull/fetch/diff/merge/rebase defaults, fsmonitor; includes `git/frz.config`, symlinked to ~/.config/git/frz.config, for repositories under ~/Developer/frz, setting the Frithuz email; includes untracked
  `~/.config/git/config.local`, where the script puts the Secretive signing key it prompts
  for, or a placeholder, and trusts that key for both emails in untracked `~/.config/git/allowed_signers`),
  ~/.sbxenv.yaml, the Docker Sandboxes defaults for `sbx env run`/`sbx env create` (`install/sbx.sh`; generated rather than symlinked, since it needs absolute paths, and left alone if it already exists: the frithuz claude-kit agent plus the `sbx/claude-sandbox` mixin, which writes /etc/claude-code/CLAUDE.md telling Claude Code the sandbox is disposable so it doesn't stop to confirm destructive commands, and the `sbx/git-identity` mixin, given the name and emails from `git/config` and `git/frz.config` and ~/Developer/frz, so sandboxes commit with the same identities as the host; and, as the last step since sbx settings need a Docker sign-in, `quay.io/frithuz/claude-kit` and `quay.io/frithuz/codex-kit` appended to sbx's `kit.allowedSources`, running `sbx login` first when interactive and not signed in),
  Claude Code and its settings (including no git attribution, `DISABLE_AUTOUPDATER`, and no built-in MCP servers: claude.ai connectors, claude-artifacts or plugin-bundled servers), macOS settings (dark mode, green accent color, dark icons,
  no wallpaper tinting in windows, no floating Liquid Glass sidebars; Dock size 36px, auto-hide, magnification, recent apps,
  minimize into app icon and open app indicators; click wallpaper to show
  desktop only in Stage Manager; no hot corners; no Mission Control Space rearranging; menu bar clock with seconds, AM/PM, day of the week and the date when space allows, no battery, no Wi-Fi and no recent items; fastest key repeat, no press-and-hold, keyboard navigation, no smart quotes/dashes, autocorrect, auto-capitalize or double-space period; trackpad: tap to click, medium click and Force Click, two-finger secondary click, no three-finger tap or drag, all scroll, zoom and swipe gestures on; Monday as first day of the week; screenshots as PNG without shadows in ~/Pictures/Screenshots; save and print dialogs expanded, new documents saved locally rather than iCloud; Finder: all extensions, no extension-change warning, folders first, search current folder, path and status bars, column view, new windows at home, hidden files, ~/Library and /Volumes shown (/Volumes needs sudo), full path in titles, Trash emptied after 30 days without a warning, no disks, removable media or servers on the Desktop, no recent tags, no .DS_Store on network/USB volumes; Finder sidebar favorites ~, Desktop, Documents, Downloads, ~/Developer and ~/Developer/frz (created if missing), added via `install/finder-favorites.swift`, never removed; UniFi Endpoint removed from login items), the Nord palette for the macOS color picker (`install/color-palettes.sh`, downloaded from a pinned commit into ~/Library/Colors unless already there), Wins settings (`install/wins.sh`: open at login, edge snapping without gaps, Dock previews and flick gestures, window hiding, Command-Tab Plus, Mission Control Pro, moving windows between displays), Time Machine exclusions for every `node_modules` and the Go module cache (`time-machine/exclude-dependencies.sh`, run at login and daily by a generated LaunchAgent), the firewall, Touch ID for sudo, with pam_reattach so it
  works in tmux/screen (`/etc/pam.d/sudo_local`), login shell). Asks for the administrator password at the start, the git signing key right after the Homebrew packages (once Secretive is installed), and, if sbx isn't signed in, a Docker sign-in at the very end (with 1Password installed to sign in with); keeps sudo's credentials fresh until it exits, and otherwise runs without prompting. Supports `--dry-run`. It runs under the system `/bin/bash`
  (3.2) before Homebrew's bash exists, so it must stay bash 3.2 compatible.
- `install/` — the steps `install-macos.sh` runs, one file per area. They are
  sourced by `install-macos.sh` (not run on their own) and follow the same bash
  3.2 rule. `lib.sh` has the shared helpers (`run`, `have_sudo`, `link_file`,
  `json_set`, `set_default`, `sudo_keepalive`, and the `DONE`/`PRESENT`/`SKIPPED` summary lists). Add Homebrew
  packages to `install_brew_packages` in `homebrew.sh` and gh extensions to
  `install_gh_extensions` in `gh.sh`. A new area gets its own file, which must
  be added to the module list and the step order in `install-macos.sh`.
  The step order lives in its `main` function, so that bash reads it all
  before running: never move commands back to the top level of the script.

## Working in this repo as an agent

- Do not run install/setup scripts against the user's real home directory
  to test them unless asked. Test against a temporary directory by
  overriding `HOME` or the script's target directory.
- Keep configuration portable: avoid hard-coding the username or absolute home
  paths; use `$HOME` / `~` instead.
- Only commit or push when the user asks.

## Commit messages

Use Go-style commit messages:

```
install/ssh: create ~/.ssh/sockets for connection sharing

ssh/config now sets ControlPath to ~/.ssh/sockets/%C, and ssh only
warns (and skips sharing) when that directory is missing, so create it,
private, alongside the config symlink.
```

- **Subject:** `<area>: <what the change does>`. The area is the file or
  directory mainly affected, without its extension: `install/homebrew`,
  `bash`, `ssh`, `git`, `AGENTS.md`. Name more than one with commas
  (`ssh, install/ssh: ...`); use `all:` for changes that touch everything.
- After the colon, write a lowercase phrase that completes the sentence
  "This change modifies the dotfiles to ___", so it starts with a verb
  (`add`, `fix`, `install`), not past tense. No trailing period. Keep the whole line to about 72
  characters.
- **Body:** after a blank line, explain why the change is needed and anything
  non-obvious about it, in full sentences, wrapped at about 72 characters.
  Skip it only when the subject says everything.
- No Markdown in the message, no `Co-Authored-By` or other attribution lines.
