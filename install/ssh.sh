# shellcheck shell=bash
#
# ~/.ssh/config symlink, and ~/.ssh/sockets for its connection sharing
# (ControlPath).
#
# Sourced by install-macos.sh; not meant to be run on its own.

link_ssh_config() {
  local ssh_dir="$HOME/.ssh"

  log "SSH config"

  # ssh refuses a ~/.ssh that others can write to, so create it private.
  if [[ ! -e "$ssh_dir" ]]; then
    if ((DRY_RUN)); then
      note "[dry-run] mkdir -m 700 ~/.ssh"
    else
      mkdir -m 700 "$ssh_dir"
    fi
  elif [[ ! -d "$ssh_dir" ]]; then
    note "~/.ssh exists but is not a directory; leaving it alone."
    SKIPPED+=("SSH config (~/.ssh is not a directory)")
    return 0
  fi

  # Connection sharing sockets. Private: anyone who can reach a socket can use
  # the connection behind it.
  if [[ -d "$ssh_dir/sockets" ]]; then
    note "~/.ssh/sockets already exists"
    PRESENT+=("SSH sockets folder (~/.ssh/sockets)")
  elif [[ -e "$ssh_dir/sockets" ]] || [[ -L "$ssh_dir/sockets" ]]; then
    note "~/.ssh/sockets exists but is not a directory; leaving it alone."
    note "ssh will work, just without connection sharing."
    SKIPPED+=("SSH sockets folder (~/.ssh/sockets is not a directory)")
  else
    run mkdir -m 700 "$ssh_dir/sockets"
    DONE+=("SSH sockets folder (~/.ssh/sockets)")
  fi

  if ! link_file "SSH config" "$DOTFILES/ssh/config" "$ssh_dir/config"; then
    note "Its settings can move to ~/.ssh/config.local, which the tracked"
    note "config includes first (so they still take precedence)."
  fi
}
