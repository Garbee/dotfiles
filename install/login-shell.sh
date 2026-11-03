# shellcheck shell=bash
#
# Login shell (Homebrew bash).
#
# Sourced by install-macos.sh; not meant to be run on its own.

set_login_shell() {
  log "Login shell"

  if ((!DRY_RUN)) && [[ ! -x "$BREW_BASH" ]]; then
    note "$BREW_BASH not found; cannot set it as the login shell."
    SKIPPED+=("Login shell: $BREW_BASH missing")
    return 0
  fi

  # chsh only allows shells listed in /etc/shells.
  if grep -qxF "$BREW_BASH" /etc/shells; then
    note "$BREW_BASH is already listed in /etc/shells"
  elif have_sudo "Add $BREW_BASH to /etc/shells"; then
    if ((DRY_RUN)); then
      note "[dry-run] append $BREW_BASH to /etc/shells"
    else
      printf '%s\n' "$BREW_BASH" | sudo tee -a /etc/shells >/dev/null
    fi
    DONE+=("Added $BREW_BASH to /etc/shells")
  else
    note "Not added; cannot change the login shell without it."
    SKIPPED+=("Change login shell")
    return 0
  fi

  local user current
  user="$(id -un)"
  current="$(dscl . -read "/Users/$user" UserShell | awk '{print $2}')"

  if [[ "$current" == "$BREW_BASH" ]]; then
    note "Login shell is already $BREW_BASH"
    PRESENT+=("Login shell set to $BREW_BASH")
    return 0
  fi

  # Through sudo, so chsh doesn't ask for the password again.
  have_sudo "Change login shell (still $current)" || return 0
  if run sudo chsh -s "$BREW_BASH" "$user"; then
    DONE+=("Login shell changed from $current to $BREW_BASH")
  else
    note "chsh failed; the login shell is still $current."
    SKIPPED+=("Change login shell (still $current)")
  fi
}
