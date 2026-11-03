# shellcheck shell=bash
#
# The macOS application firewall (System Settings > Network > Firewall).
# Turning it on needs sudo, so it is confirmed first.
#
# Sourced by install-macos.sh; not meant to be run on its own.

SOCKETFILTERFW="/usr/libexec/ApplicationFirewall/socketfilterfw"

enable_firewall() {
  local label="Firewall" state

  log "$label"

  if [[ ! -x "$SOCKETFILTERFW" ]]; then
    note "$SOCKETFILTERFW not found; firewall not changed."
    SKIPPED+=("$label (socketfilterfw missing)")
    return 0
  fi

  # Reading the state doesn't need sudo. Prints e.g. "Firewall is enabled.
  # (State = 1)"; 2 is on and blocking all incoming connections, also fine.
  state="$("$SOCKETFILTERFW" --getglobalstate 2>/dev/null || true)"
  if [[ "$state" == *"State = 1"* ]] || [[ "$state" == *"State = 2"* ]]; then
    note "Already on"
    PRESENT+=("$label on")
    return 0
  fi

  if ! confirm "Turn on the firewall (requires sudo)?"; then
    SKIPPED+=("$label (declined)")
    return 0
  fi

  if run sudo "$SOCKETFILTERFW" --setglobalstate on; then
    DONE+=("$label on")
  else
    # e.g. when the setting is managed by a configuration profile.
    note "Could not turn on the firewall."
    SKIPPED+=("$label (socketfilterfw failed)")
  fi
}
