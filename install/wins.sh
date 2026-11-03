# shellcheck shell=bash
#
# Wins (window manager) settings. Wins itself is installed by
# install_brew_packages; its settings pane is in System Settings > Wins, and
# they are stored in the cools.wins.main defaults domain. Like macOS settings,
# they are always set as desired.
#
# Sourced by install-macos.sh; not meant to be run on its own.

configure_wins() {
  local d=cools.wins.main

  log "Wins"
  # Registering the login item needs Wins to be opened once.
  set_default "Wins: open at login" $d launchOnLogin -bool true
  set_default "Wins: respect Stage Manager" $d respectStageManager -bool true

  # Snapping.
  set_default "Wins: snap windows at screen edges" $d edgeSnap -bool true
  set_default "Wins: split window" $d showSplitWindow -bool true
  set_default "Wins: no margin around snapped windows" \
    $d snapMarginEnable -bool false
  set_default "Wins: no gap between snapped windows" $d gapSize -int 0
  set_default "Wins: center window" $d centerStatus -bool true

  # Dock.
  set_default "Wins: window previews in the Dock" \
    $d enableDockPreview -bool true
  set_default "Wins: flick gestures on Dock icons" $d enableFlickDock -bool true

  # Hiding windows.
  set_default "Wins: shake to hide other windows" \
    $d enableShakeHiddenWindows -bool true
  set_default "Wins: hide all windows" $d hiddenAllWindowStatus -bool true
  set_default "Wins: hide other windows" $d hiddenOtherWindowsStatus -bool true

  # Command-Tab Plus and Mission Control Pro.
  set_default "Wins: Command-Tab Plus" $d commandTabPlus -bool true
  set_default "Wins: Mission Control Pro" $d missionControlProStatus -bool true
  set_default "Wins: Mission Control Pro doesn't close windows" \
    $d missionControlProClosesWindowStatus -bool false
  set_default "Wins: Mission Control Pro doesn't quit apps" \
    $d missionControlProQuitAppStatus -bool false

  # Moving windows between displays.
  set_default "Wins: move window to next display" \
    $d nextDisplayStatus -bool true
  set_default "Wins: move window to previous display" \
    $d prevDisplayStatus -bool true

  if pgrep -qx Wins 2>/dev/null; then
    note "Wins is running: quit and reopen it to pick these up."
  fi
  note "Wins needs Accessibility, and Screen & System Audio Recording for Dock"
  note "previews (System Settings > Privacy & Security). Open it once so it"
  note "can register its login item."
}
