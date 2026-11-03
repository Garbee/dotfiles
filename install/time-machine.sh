# shellcheck shell=bash
#
# Time Machine exclusions for downloaded dependencies (every node_modules
# folder, Go's module cache). time-machine/exclude-dependencies.sh does the
# work; this installs a LaunchAgent that runs it at login and once a day, so
# folders created later are excluded too.
#
# The agent's plist holds this machine's path to the repository, so it is
# written here rather than tracked and symlinked. An existing plist that
# differs is left alone.
#
# Sourced by install-macos.sh; not meant to be run on its own.

TM_AGENT_LABEL="local.dotfiles.time-machine-exclusions"

# Escape text for an XML string.
xml_escape() {
  local s="$1"
  s="${s//&/&amp;}"
  s="${s//</&lt;}"
  s="${s//>/&gt;}"
  printf '%s' "$s"
}

tm_agent_plist() {
  local script log
  script="$(xml_escape "$DOTFILES/time-machine/exclude-dependencies.sh")"
  log="$(xml_escape "$HOME/Library/Logs/time-machine-exclusions.log")"
  cat <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<!-- Written by install-macos.sh in the dotfiles repository. -->
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>$TM_AGENT_LABEL</string>
  <key>ProgramArguments</key>
  <array>
    <string>/bin/bash</string>
    <string>$script</string>
  </array>
  <key>RunAtLoad</key>
  <true/>
  <key>StartInterval</key>
  <integer>86400</integer>
  <key>ProcessType</key>
  <string>Background</string>
  <key>LowPriorityIO</key>
  <true/>
  <key>Nice</key>
  <integer>10</integer>
  <key>StandardOutPath</key>
  <string>$log</string>
  <key>StandardErrorPath</key>
  <string>$log</string>
</dict>
</plist>
EOF
}

install_time_machine_exclusions() {
  local label="Time Machine exclusions agent" tilde='~'
  local agents="$HOME/Library/LaunchAgents" plist content shown domain
  plist="$agents/$TM_AGENT_LABEL.plist"
  shown="${plist//"$HOME"/$tilde}"
  domain="gui/$(id -u)"
  content="$(tm_agent_plist)"

  log "Time Machine exclusions (node_modules, Go module cache)"

  if [[ -L "$plist" ]] || { [[ -e "$plist" ]] && [[ ! -f "$plist" ]]; }; then
    note "$shown is not a regular file; leaving it alone."
    SKIPPED+=("$label ($shown is not a regular file)")
    return 0
  fi

  if [[ -f "$plist" ]]; then
    if [[ "$(cat "$plist")" != "$content" ]]; then
      note "$shown exists with different contents (e.g. the repository moved);"
      note "leaving it alone. To replace it, unload and remove it, then re-run:"
      note "  launchctl bootout $domain/$TM_AGENT_LABEL; rm $shown"
      SKIPPED+=("$label ($shown differs)")
      return 0
    fi
    note "$shown already in place"
    PRESENT+=("$label ($shown)")
  elif ((DRY_RUN)); then
    note "[dry-run] write $shown (runs time-machine/exclude-dependencies.sh"
    note "          at login and daily)"
    DONE+=("$label ($shown)")
  else
    [[ -d "$agents" ]] || mkdir -p "$agents"
    # noclobber: never write over a file that appeared in the meantime.
    if (
      set -o noclobber
      printf '%s\n' "$content" >"$plist"
    ); then
      note "Wrote $shown"
      DONE+=("$label ($shown)")
    else
      note "Could not write $shown"
      SKIPPED+=("$label (could not write $shown)")
      return 0
    fi
  fi

  # Load it now rather than at next login. Loading runs it once right away
  # (RunAtLoad), in the background.
  if launchctl print "$domain/$TM_AGENT_LABEL" >/dev/null 2>&1; then
    note "Agent already loaded"
    PRESENT+=("$label loaded")
  elif run launchctl bootstrap "$domain" "$plist"; then
    ((DRY_RUN)) || note "Agent loaded; the first scan is running in the background."
    DONE+=("$label loaded")
  else
    note "Could not load the agent; it will load at next login."
    SKIPPED+=("$label not loaded (launchctl bootstrap failed)")
  fi
}
