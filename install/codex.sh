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

CODEX_CONFIG="$HOME/.codex/config.toml"

# Turn off Codex's check for a new version at startup (and its offer to
# update), the same as Claude Code's DISABLE_AUTOUPDATER: update by re-running
# the installer instead. An existing check_for_update_on_startup is left as is.
configure_codex() {
  local key="check_for_update_on_startup" label current dir tmp mode
  local tilde='~'
  label="${CODEX_CONFIG//"$HOME"/$tilde}: $key = false"

  log "Codex settings"

  if [[ -L "$CODEX_CONFIG" ]] || { [[ -e "$CODEX_CONFIG" ]] && [[ ! -f "$CODEX_CONFIG" ]]; }; then
    note "$CODEX_CONFIG is not a regular file; leaving it alone."
    SKIPPED+=("$label (not a regular file)")
    return 0
  fi

  # The key's value, if it is set at the top level (before the first table
  # header), with any trailing comment removed.
  current=""
  if [[ -f "$CODEX_CONFIG" ]]; then
    current="$(awk -v k="$key" '
      /^[[:space:]]*\[/ { exit }
      $0 ~ "^[[:space:]]*" k "[[:space:]]*=" {
        sub(/^[^=]*=[[:space:]]*/, ""); sub(/[[:space:]]*(#.*)?$/, ""); print; exit
      }' "$CODEX_CONFIG")"
  fi

  if [[ "$current" == "false" ]]; then
    note "$label is already set"
    PRESENT+=("$label")
    return 0
  elif [[ -n "$current" ]]; then
    note "$key is $current in $CODEX_CONFIG; left alone."
    SKIPPED+=("$label (is $current)")
    return 0
  fi

  if ((DRY_RUN)); then
    note "[dry-run] add $key = false to the top of $CODEX_CONFIG"
    DONE+=("[dry-run] $label")
    return 0
  fi

  # A top-level key has to come before any [table] in TOML, so it goes at the
  # top of the file rather than the end. The rest of the file is kept as is,
  # written to a copy that then replaces the original in one step.
  dir="$(dirname "$CODEX_CONFIG")"
  [[ -d "$dir" ]] || mkdir -p "$dir"
  mode=600
  [[ -f "$CODEX_CONFIG" ]] && mode="$(stat -f '%Lp' "$CODEX_CONFIG")"
  tmp="$(mktemp "$dir/.tmp-config.XXXXXX")"
  if {
    printf '%s = false\n' "$key"
    if [[ -s "$CODEX_CONFIG" ]]; then
      printf '\n'
      cat "$CODEX_CONFIG"
    fi
  } >>"$tmp" && chmod "$mode" "$tmp" && mv "$tmp" "$CODEX_CONFIG"; then
    note "$label set"
    DONE+=("$label")
  else
    rm -f "$tmp" # our own temp file only
    note "Could not write $CODEX_CONFIG; not changed."
    SKIPPED+=("$label (write failed)")
  fi
}
