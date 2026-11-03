# shellcheck shell=bash
#
# Bash startup files (see bash/README.md).
#
# Sourced by install-macos.sh; not meant to be run on its own.

# Link the bash startup files (see bash/README.md). Runs before the Claude
# Code and Codex installers so nothing they append lands in a file that would
# then block the link.
link_bash_files() {
  local name
  for name in bash_profile bashrc bash_logout; do
    log "Bash: ~/.$name"
    if ! link_file "Bash ~/.$name" "$DOTFILES/bash/$name" "$HOME/.$name"; then
      note "Machine-specific settings can go in ~/.$name.local, which the"
      note "tracked file sources (see bash/README.md)."
    fi
  done
}

# An empty ~/.hushlogin stops login shells from printing the "Last login"
# line (and any message of the day). An existing one is left as is.
create_hushlogin() {
  local label="~/.hushlogin"

  log "Hush login"

  if [[ -e "$HOME/.hushlogin" ]] || [[ -L "$HOME/.hushlogin" ]]; then
    note "$label already exists"
    PRESENT+=("$label")
    return 0
  fi

  run touch "$HOME/.hushlogin"
  DONE+=("$label (no \"Last login\" message)")
}
