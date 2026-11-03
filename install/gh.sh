# shellcheck shell=bash
#
# GitHub CLI extensions.
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

# The GitHub CLI extensions to install.
install_gh_extensions() {
  gh_extension_install github/gh-stack
  gh_extension_install github/gh-actions-lock
}
