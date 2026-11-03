# shellcheck shell=bash
#
# Touch ID for sudo, via /etc/pam.d/sudo_local. macOS keeps that file across
# updates (unlike /etc/pam.d/sudo, which includes it).
#
# pam_reattach (Homebrew's pam-reattach, installed in homebrew.sh) makes the
# Touch ID prompt work inside tmux and screen. It has to come before
# pam_tid.so in the file.
#
# Sourced by install-macos.sh; not meant to be run on its own.

SUDO_LOCAL="/etc/pam.d/sudo_local"
PAM_REATTACH="$BREW_PREFIX/lib/pam/pam_reattach.so"
SUDO_LOCAL_REATTACH="auth       optional       $PAM_REATTACH"
SUDO_LOCAL_TID='auth       sufficient     pam_tid.so'

# Does FILE have an uncommented "auth <control> <module>" line (any spacing)?
#
#   pam_has FILE CONTROL MODULE_REGEX
pam_has() {
  [[ -f "$1" ]] &&
    grep -Eq "^[[:space:]]*auth[[:space:]]+$2[[:space:]]+$3([[:space:]]|\$)" "$1"
}

enable_touch_id_sudo() {
  local label="Touch ID for sudo" has_reattach=0 has_tid=0
  local add=()

  log "$label"

  # Not a symlink or anything else we would write through.
  if [[ -L "$SUDO_LOCAL" ]] || { [[ -e "$SUDO_LOCAL" ]] && [[ ! -f "$SUDO_LOCAL" ]]; }; then
    note "$SUDO_LOCAL is not a regular file; leaving it alone."
    SKIPPED+=("$label ($SUDO_LOCAL is not a regular file)")
    return 0
  fi

  pam_has "$SUDO_LOCAL" optional '([^[:space:]]*/)?pam_reattach\.so' && has_reattach=1
  pam_has "$SUDO_LOCAL" sufficient 'pam_tid\.so' && has_tid=1

  if ((has_reattach && has_tid)); then
    note "Already enabled in $SUDO_LOCAL (with pam_reattach)"
    PRESENT+=("$label (with pam_reattach)")
    return 0
  fi

  # pam_reattach must come before pam_tid.so, and adding it there would mean
  # rewriting the file rather than appending to it.
  if ((has_tid)); then
    note "$SUDO_LOCAL already enables Touch ID, but without pam_reattach"
    note "(needed inside tmux and screen). To add it, put this line above the"
    note "pam_tid.so line:"
    note "  $SUDO_LOCAL_REATTACH"
    PRESENT+=("$label")
    SKIPPED+=("pam_reattach in $SUDO_LOCAL (must go above the existing pam_tid.so line)")
    return 0
  fi

  if ((!has_reattach)); then
    # A missing module would be logged as an error on every sudo.
    if ((!DRY_RUN)) && [[ ! -f "$PAM_REATTACH" ]]; then
      note "$PAM_REATTACH not found; enabling Touch ID without it"
      note "(it won't work inside tmux or screen until it is added)."
      SKIPPED+=("pam_reattach in $SUDO_LOCAL ($PAM_REATTACH missing)")
    else
      add+=("$SUDO_LOCAL_REATTACH")
    fi
  fi
  add+=("$SUDO_LOCAL_TID")

  note "Lines to add to $SUDO_LOCAL:"
  printf '      %s\n' "${add[@]}"
  if ! confirm "Enable Touch ID for sudo (requires sudo)?"; then
    SKIPPED+=("$label (declined)")
    return 0
  fi

  if ((DRY_RUN)); then
    note "[dry-run] append the lines above to $SUDO_LOCAL"
  else
    sudo_keepalive
    # Appends to an existing file (keeping its other lines) or creates it.
    {
      [[ -e "$SUDO_LOCAL" ]] ||
        printf '# sudo_local: local config file which survives system update and is included for sudo\n'
      printf '%s\n' "${add[@]}"
    } | sudo tee -a "$SUDO_LOCAL" >/dev/null
  fi
  if ((${#add[@]} > 1)); then
    DONE+=("$label (with pam_reattach)")
  else
    DONE+=("$label")
  fi
}
