# shellcheck shell=bash
#
# pnpm, from its standalone installer (no Node.js needed). It installs to
# $PNPM_HOME, by default ~/Library/pnpm, with the executable in its bin/.
#
# Sourced by install-macos.sh; not meant to be run on its own.

install_pnpm() {
  log "pnpm"

  local pnpm_home="${PNPM_HOME:-$HOME/Library/pnpm}"
  local existing
  if existing="$(command -v pnpm 2>/dev/null)" || {
    [[ -x "$pnpm_home/bin/pnpm" ]] && existing="$pnpm_home/bin/pnpm"
  }; then
    note "Already installed at $existing"
    PRESENT+=("pnpm")
    return 0
  fi

  if ((DRY_RUN)); then
    note "[dry-run] run the official pnpm installer (installs to $pnpm_home)"
    DONE+=("pnpm")
    return 0
  fi

  # The installer's `pnpm setup` appends PATH lines to the shell rc file,
  # which here is a symlink into this repository. PNPM_NO_MODIFY_PATH stops
  # that; bash/profile.d/20-path.sh puts pnpm on PATH instead.
  note "Running the official pnpm installer."
  if curl -fsSL https://get.pnpm.io/install.sh |
    PNPM_HOME="$pnpm_home" PNPM_NO_MODIFY_PATH=1 /bin/sh -; then
    note "No need to add the lines above: bash/profile.d/20-path.sh already"
    note "does the same (in new shells)."
    DONE+=("pnpm")
  else
    note "The pnpm installer failed; continuing."
    SKIPPED+=("pnpm (installer failed)")
  fi
}
