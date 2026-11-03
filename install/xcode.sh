# shellcheck shell=bash
#
# Xcode Command Line Tools.
#
# Sourced by install-macos.sh; not meant to be run on its own.

install_xcode_clt() {
  log "Xcode Command Line Tools"

  local clt_path
  if clt_path="$(xcode-select -p 2>/dev/null)"; then
    note "Already installed at $clt_path"
    PRESENT+=("Xcode Command Line Tools")
    return 0
  fi

  if ((DRY_RUN)); then
    note "[dry-run] xcode-select --install"
    DONE+=("Xcode Command Line Tools")
    return 0
  fi

  xcode-select --install
  note "Finish the installation in the dialog that just opened."
  note "Waiting for it to complete (Ctrl+C to abort, then re-run this script)..."
  until xcode-select -p >/dev/null 2>&1; do
    sleep 5
  done
  note "Installed."
  DONE+=("Xcode Command Line Tools")
}
