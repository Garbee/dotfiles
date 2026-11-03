# shellcheck shell=bash
#
# Codex CLI.
#
# Sourced by install-macos.sh; not meant to be run on its own.

install_codex() {
  log "Codex CLI"

  local codex_bin="$HOME/.local/bin/codex"
  local existing
  if existing="$(command -v codex 2>/dev/null)" || {
    [[ -x "$codex_bin" ]] && existing="$codex_bin"
  }; then
    note "Already installed at $existing"
    PRESENT+=("Codex CLI")
    return 0
  fi

  if ((DRY_RUN)); then
    note "[dry-run] run the official Codex installer (installs to $codex_bin)"
    DONE+=("Codex CLI")
    return 0
  fi

  # The installer appends a PATH block to your shell profile unless
  # ~/.local/bin is already on PATH. bash/profile.d/20-path.sh handles that,
  # so put it on PATH for the installer too. CODEX_NON_INTERACTIVE stops it
  # from prompting to launch Codex at the end.
  note "Running the official Codex installer."
  if curl -fsSL https://chatgpt.com/codex/install.sh |
    PATH="$HOME/.local/bin:$PATH" CODEX_NON_INTERACTIVE=1 /bin/sh; then
    DONE+=("Codex CLI")
  else
    note "The Codex installer failed; continuing."
    SKIPPED+=("Codex CLI (installer failed)")
  fi
}
