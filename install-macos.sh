#!/bin/bash
#
# macOS bootstrap.
#
# Safe to re-run: every step checks the current state first and skips anything
# already done. Nothing is overwritten or deleted. Privileged or system-wide
# changes (Touch ID for sudo, the firewall, editing /etc/shells, changing the
# login shell) are confirmed first. The exception is macOS settings
# (appearance, Dock, keyboard, menu bar, login items, etc.), which are always
# set to the desired values.
#
# The steps live in install/ (one file per area, sourced below); this file
# parses options, loads them and runs them in order.
#
# NOTE: This runs under the macOS system bash (3.2) before Homebrew's bash is
# installed, so it must stay bash 3.2 compatible (no associative arrays,
# no ${var,,}, guard empty-array expansions under `set -u`, etc).

set -euo pipefail

DRY_RUN=0

usage() {
  cat <<EOF
Usage: $(basename "$0") [--dry-run]

  -n, --dry-run   Show what would be done without changing anything.
  -h, --help      Show this help.
EOF
}

for arg in "$@"; do
  case "$arg" in
    -n | --dry-run) DRY_RUN=1 ;;
    -h | --help)
      usage
      exit 0
      ;;
    *)
      printf 'Unknown option: %s\n\n' "$arg" >&2
      usage >&2
      exit 2
      ;;
  esac
done

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "This script is for macOS only." >&2
  exit 1
fi

# hw.optional.arm64 is 1 on Apple silicon, even under Rosetta.
if [[ "$(sysctl -n hw.optional.arm64 2>/dev/null || echo 0)" != "1" ]]; then
  echo "This script is for Apple silicon Macs only." >&2
  exit 1
fi

# The repository this script lives in (symlink targets point into it).
DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"

for module in lib xcode homebrew gh bash starship neovim claude codex pnpm ssh git macos-settings time-machine firewall touch-id-sudo login-shell; do
  # shellcheck source=/dev/null
  source "$DOTFILES/install/$module.sh"
done

# Everything runs from inside main, which bash reads in full before running
# any of it. Otherwise bash reads the script as it goes, and if the file
# changes during a run (say, a git pull while a prompt waits), it carries on
# from the same byte offset in the new contents, in the middle of some line.
main() {
  ((DRY_RUN)) && printf 'Dry run: no changes will be made.\n'

  install_xcode_clt
  install_homebrew
  install_brew_packages
  install_gh_extensions
  link_bash_files
  link_starship_config
  link_neovim_config
  install_claude_code
  configure_claude_code
  install_codex
  install_pnpm
  link_ssh_config
  link_git_config
  configure_git_signing_key
  configure_macos
  install_time_machine_exclusions
  enable_firewall
  enable_touch_id_sudo
  set_login_shell

  log "Summary"
  # ${arr[@]+...} avoids "unbound variable" for empty arrays in bash 3.2.
  print_list "$( ((DRY_RUN)) && echo "Would do:" || echo "Done:")" ${DONE[@]+"${DONE[@]}"}
  print_list "Already in place:" ${PRESENT[@]+"${PRESENT[@]}"}
  print_list "Skipped:" ${SKIPPED[@]+"${SKIPPED[@]}"}
  printf '\n'
}

# On one line with main, so nothing after it is read from the file either.
main "$@"; exit
