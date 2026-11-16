# shellcheck shell=bash
#
# GitHub CLI: its git protocol and extensions.
#
# Sourced by install-macos.sh; not meant to be run on its own.

# Install a GitHub CLI extension unless it's already installed.
#
#   gh_extension_install REPO   e.g. github/gh-stack
gh_extension_install() {
  local repo="$1" label="gh extension $1"

  log "$label"

  if [[ ! -x "$GH" ]]; then
    if ((DRY_RUN)); then
      note "[dry-run] $GH extension install $repo"
      DONE+=("$label")
    else
      note "$GH not found; cannot install $repo."
      SKIPPED+=("$label (gh missing)")
    fi
    return 0
  fi

  # `gh extension list` prints "gh <name><TAB><owner/repo><TAB><version>".
  if "$GH" extension list 2>/dev/null | awk -F '\t' -v r="$repo" '$2 == r { found = 1 } END { exit !found }'; then
    note "Already installed"
    PRESENT+=("$label")
    return 0
  fi

  if ((DRY_RUN)); then
    note "[dry-run] $GH extension install $repo"
    DONE+=("$label")
    return 0
  fi

  # Fails (without changing anything) if another extension already provides
  # the same command name.
  if "$GH" extension install "$repo"; then
    DONE+=("$label")
  else
    note "Could not install $repo (another extension with the same name, or"
    note "not logged in: run 'gh auth login' and re-run this script)."
    SKIPPED+=("$label (install failed)")
  fi
}

GH_CONFIG="${GH_CONFIG_DIR:-${XDG_CONFIG_HOME:-$HOME/.config}/gh}/config.yml"

# Have gh clone and push over SSH (with the Secretive keys ssh/config sets up)
# rather than HTTPS. Only set if config.yml doesn't choose a protocol yet, as
# on a new machine: one chosen already (for example at the `gh auth login`
# prompt) is left alone. Runs before anything else uses gh, since gh writes
# its whole default config, git_protocol: https included, the first time it
# saves one.
configure_gh_protocol() {
  local label="gh git_protocol ssh" current

  log "$label"

  if [[ -L "$GH_CONFIG" ]] || { [[ -e "$GH_CONFIG" ]] && [[ ! -f "$GH_CONFIG" ]]; }; then
    note "$GH_CONFIG is not a regular file; leaving it alone."
    SKIPPED+=("$label (config.yml is not a regular file)")
    return 0
  fi

  # The top-level setting (not a per-host one in hosts.yml), without quotes
  # or a trailing comment.
  current=""
  if [[ -f "$GH_CONFIG" ]]; then
    current="$(awk '
      /^git_protocol:/ {
        sub(/^git_protocol:[[:space:]]*/, ""); sub(/[[:space:]]*(#.*)?$/, "")
        gsub(/["\047]/, ""); print; exit
      }' "$GH_CONFIG")"
  fi

  if [[ "$current" == "ssh" ]]; then
    note "Already set"
    PRESENT+=("$label")
    return 0
  elif [[ -n "$current" ]]; then
    note "git_protocol is $current in $GH_CONFIG; left alone."
    note "Run 'gh config set git_protocol ssh' to switch."
    SKIPPED+=("$label (is $current)")
    return 0
  fi

  if [[ ! -x "$GH" ]]; then
    if ((DRY_RUN)); then
      note "[dry-run] $GH config set git_protocol ssh"
      DONE+=("[dry-run] $label")
    else
      note "$GH not found; git_protocol not set."
      SKIPPED+=("$label (gh missing)")
    fi
    return 0
  fi

  if ((DRY_RUN)); then
    note "[dry-run] $GH config set git_protocol ssh"
    DONE+=("$label")
  elif "$GH" config set git_protocol ssh; then
    note "Set. When 'gh auth login' asks for a protocol, choose SSH too."
    DONE+=("$label")
  else
    note "Could not set git_protocol."
    SKIPPED+=("$label (gh config set failed)")
  fi
}

# The GitHub CLI extensions to install.
install_gh_extensions() {
  gh_extension_install github/gh-stack
  gh_extension_install github/gh-actions-lock
}
