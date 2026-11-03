#!/bin/bash
#
# Bootstrap a new Mac. Meant to be downloaded and run directly:
#
#   curl -fsSL https://raw.githubusercontent.com/Garbee/dotfiles/main/init.sh | bash
#
# or, to see what it would do first:
#
#   curl -fsSL https://raw.githubusercontent.com/Garbee/dotfiles/main/init.sh | bash -s -- --dry-run
#
# Installs the Xcode Command Line Tools (for git) if needed, clones the
# dotfiles to ~/.dotfiles unless something is already there, then runs
# install-macos.sh with the same options. Safe to re-run.
#
# Runs under the macOS system bash (3.2), like install-macos.sh.

set -euo pipefail

DOTFILES_DIR="$HOME/.dotfiles"
DOTFILES_URL="https://github.com/Garbee/dotfiles.git"

# Everything runs from inside main, called on the last line, so a download cut
# off partway through runs nothing at all.
main() {
  local dry_run=0 arg

  for arg in "$@"; do
    case "$arg" in
      -n | --dry-run) dry_run=1 ;;
      -h | --help)
        printf 'Usage: init.sh [--dry-run]\n\n'
        printf 'Clones %s to %s and runs install-macos.sh.\n' "$DOTFILES_URL" "$DOTFILES_DIR"
        printf 'Options are passed on to install-macos.sh (see its --help).\n'
        return 0
        ;;
    esac
  done
  ((dry_run)) && printf 'Dry run: no changes will be made.\n'

  if [[ "$(uname -s)" != "Darwin" ]]; then
    echo "This script is for macOS only." >&2
    return 1
  fi
  # hw.optional.arm64 is 1 on Apple silicon, even under Rosetta.
  if [[ "$(sysctl -n hw.optional.arm64 2>/dev/null || echo 0)" != "1" ]]; then
    echo "This script is for Apple silicon Macs only." >&2
    return 1
  fi

  # git comes with the Command Line Tools. /usr/bin/git exists without them,
  # but only to offer installing them.
  printf '\n==> Xcode Command Line Tools\n'
  if xcode-select -p >/dev/null 2>&1; then
    printf '    Already installed\n'
  elif ((dry_run)); then
    printf '    [dry-run] xcode-select --install\n'
  else
    xcode-select --install
    printf '    Finish the installation in the dialog that just opened.\n'
    printf '    Waiting for it to complete (Ctrl+C to abort, then re-run)...\n'
    until xcode-select -p >/dev/null 2>&1; do
      sleep 5
    done
  fi

  printf '\n==> Dotfiles\n'
  if [[ -f "$DOTFILES_DIR/install-macos.sh" ]]; then
    printf '    %s already exists; using it as is (not updated).\n' "$DOTFILES_DIR"
  elif [[ -e "$DOTFILES_DIR" ]] || [[ -L "$DOTFILES_DIR" ]]; then
    printf '    %s exists but is not these dotfiles; leaving it alone.\n' "$DOTFILES_DIR" >&2
    printf '    Move it aside and re-run, or clone %s yourself.\n' "$DOTFILES_URL" >&2
    return 1
  elif ((dry_run)); then
    printf '    [dry-run] git clone %s %s\n' "$DOTFILES_URL" "$DOTFILES_DIR"
    printf '    [dry-run] then run install-macos.sh --dry-run from it\n'
    return 0
  else
    git clone "$DOTFILES_URL" "$DOTFILES_DIR"
  fi

  # When piped into bash, stdin is the script itself, and install-macos.sh
  # would treat the run as non-interactive and couldn't ask for the password
  # or the git signing key. Give it the terminal instead, if there is one.
  if { : </dev/tty; } 2>/dev/null; then
    /bin/bash "$DOTFILES_DIR/install-macos.sh" "$@" </dev/tty
  else
    /bin/bash "$DOTFILES_DIR/install-macos.sh" "$@"
  fi
}

main "$@"; exit
