# shellcheck shell=bash
#
# macOS settings (appearance, Desktop & Dock, hot corners, menu bar, keyboard,
# trackpad, Language & Region, screenshots, save and print dialogs, Finder,
# Finder sidebar, login items). Unlike every other step these are always set as
# desired, without checking the current value first. The exception is Finder
# sidebar favorites, which are only ever added, never removed or reordered.
#
# Sourced by install-macos.sh; not meant to be run on its own.

# Make sure an app does not open at login: remove its entry from System
# Settings > General > Login Items > Open at Login (matched by app path).
# Removing an entry that isn't there does nothing.
#
# The first run asks for permission for the terminal to control System Events
# (System Settings > Privacy & Security > Automation).
#
#   remove_login_item LABEL APP_PATH
remove_login_item() {
  local label="$1" app="$2" result

  if ((DRY_RUN)); then
    note "[dry-run] remove login item for $app"
    DONE+=("$label")
    return 0
  fi

  # Prints the number of entries removed.
  if result="$(osascript - "$app" <<'APPLESCRIPT' 2>&1
on run argv
  tell application "System Events"
    set found to every login item whose path is (item 1 of argv)
    repeat with li in found
      delete li
    end repeat
    return count of found
  end tell
end run
APPLESCRIPT
  )"; then
    note "Removed $result login item(s) for $app"
    DONE+=("$label")
  else
    note "Could not change login items: $result"
    note "Allow the terminal to control System Events in System Settings >"
    note "Privacy & Security > Automation, then re-run this script."
    SKIPPED+=("$label (no permission to control System Events)")
  fi
}

# Folders that a dry run would have created (one per line), so the favorites
# step can report them as "would add" instead of "does not exist".
PLANNED_DIRS=""

# Create a folder (and any missing parents) unless it already exists. If a file
# or broken symlink is in the way (at the path or a parent), nothing is created.
#
#   ensure_dir LABEL DIR
ensure_dir() {
  local label="$1" dir="$2" tilde='~' shown d missing=""
  shown="${dir//"$HOME"/$tilde}"

  if [[ -d "$dir" ]]; then
    note "$shown already exists"
    PRESENT+=("$label ($shown)")
    return 0
  fi

  # Walk up to the nearest thing that exists; it has to be a folder (or a
  # symlink to one), or mkdir -p would fail. Remember what would be created.
  d="$dir"
  while [[ ! -e "$d" ]] && [[ ! -L "$d" ]]; do
    missing+="$d"$'\n'
    d="$(dirname "$d")"
  done
  if [[ ! -d "$d" ]]; then
    note "${d//"$HOME"/$tilde} exists but is not a folder; $shown not created."
    SKIPPED+=("$label ($shown: ${d//"$HOME"/$tilde} is not a folder)")
    return 0
  fi

  if run mkdir -p "$dir"; then
    if ((DRY_RUN)); then
      PLANNED_DIRS+="$missing"
    else
      note "Created $shown"
    fi
    DONE+=("$label ($shown)")
  else
    note "Could not create $shown"
    SKIPPED+=("$label ($shown could not be created)")
  fi
}

# Add folders to the Finder sidebar's Favorites, at the end. Favorites that are
# already there (in any position) and any others are left alone; folders that
# don't exist are skipped. Uses install/finder-favorites.swift, because the
# sidebar can't be set with `defaults`.
#
#   add_finder_favorites PATH...
add_finder_favorites() {
  local helper="$DOTFILES/install/finder-favorites.swift" tilde='~'
  local output status path shown dry=""

  if ! xcrun --find swift >/dev/null 2>&1; then
    note "swift not found (Xcode Command Line Tools); Finder favorites not changed."
    SKIPPED+=("Finder sidebar favorites (swift missing)")
    return 0
  fi

  # The helper only reads the sidebar in dry-run mode. The compiler's
  # deprecation warnings go to stderr.
  ((DRY_RUN)) && dry=--dry-run
  if ! output="$(xcrun swift "$helper" ${dry:+"$dry"} "$@" 2>/dev/null)"; then
    note "Could not open the Finder sidebar favorites; not changed."
    SKIPPED+=("Finder sidebar favorites (could not open the list)")
    return 0
  fi

  while IFS=$'\t' read -r status path; do
    [[ -n "$status" ]] || continue
    shown="${path//"$HOME"/$tilde}"
    case "$status" in
      added)
        note "Added $shown"
        DONE+=("Finder favorite: $shown")
        ;;
      would-add)
        note "[dry-run] add $shown"
        DONE+=("[dry-run] Finder favorite: $shown")
        ;;
      present)
        note "$shown is already a favorite"
        PRESENT+=("Finder favorite: $shown")
        ;;
      missing)
        if ((DRY_RUN)) && [[ $'\n'"$PLANNED_DIRS" == *$'\n'"$path"$'\n'* ]]; then
          note "[dry-run] add $shown (once created)"
          DONE+=("[dry-run] Finder favorite: $shown")
          continue
        fi
        note "$shown does not exist; not added."
        SKIPPED+=("Finder favorite: $shown (folder does not exist)")
        ;;
      *)
        note "Could not add $shown"
        SKIPPED+=("Finder favorite: $shown (failed)")
        ;;
    esac
  done <<<"$output"
}

configure_macos() {
  # System Settings > Appearance. Running apps pick these up when they next
  # start; the Dock restart below applies the icon style to the Dock.
  log "Appearance"
  # Accent colors: -1 graphite, 0 red, 1 orange, 2 yellow, 3 green, 4 blue,
  # 5 purple, 6 pink. The highlight color follows it unless set separately.
  # Dark mode. Choosing Dark in System Settings also turns off Auto, which would
  # otherwise switch back to light during the day. Fully applies after logging
  # out and back in.
  set_default "Dark mode" -g AppleInterfaceStyle -string Dark
  set_default "Dark mode: don't switch automatically" \
    -g AppleInterfaceStyleSwitchesAutomatically -bool false
  set_default "Accent color green" -g AppleAccentColor -int 3
  # Icon & widget style: Regular, Clear or Tinted, then Light, Dark or Automatic.
  set_default "Icon style dark" -g AppleIconAppearanceTheme -string RegularDark
  # "Allow wallpaper tinting in windows" off.
  set_default "Wallpaper tinting in windows off" \
    -g AppleReduceDesktopTinting -bool true
  # Sidebars (Finder, Mail, etc.) attached to the window edge instead of the
  # floating Liquid Glass panel. Hidden settings, no System Settings switch;
  # NSConvolutionOverride1 goes with the first. Apps pick them up when they
  # next start.
  set_default "Sidebars not floating (Liquid Glass)" \
    -g NSSplitViewItemSidebarDefaultsToFloatingAppearance -bool false
  set_default "Sidebars not floating (Liquid Glass): convolution override" \
    -g NSConvolutionOverride1 -float 10

  # System Settings > Desktop & Dock.
  log "Desktop & Dock"
  set_default "Dock icon size 36px" com.apple.dock tilesize -int 36
  set_default "Dock: hide automatically" com.apple.dock autohide -bool true
  set_default "Dock: hide recent apps" com.apple.dock show-recents -bool false
  set_default "Dock magnification on" com.apple.dock magnification -bool true
  # 128 is the largest size the System Settings slider allows.
  set_default "Dock magnification size maximum (128px)" \
    com.apple.dock largesize -int 128
  set_default "Minimize windows into their app icon" \
    com.apple.dock minimize-to-application -bool true
  set_default "Dock: no open app indicators" \
    com.apple.dock show-process-indicators -bool false
  # Mission Control is part of the Dock process.
  set_default "Mission Control: don't rearrange Spaces by recent use" \
    com.apple.dock mru-spaces -bool false
  # false is "Only in Stage Manager"; true is "Always".
  set_default "Click wallpaper to show desktop: only in Stage Manager" \
    com.apple.WindowManager EnableStandardClickToShowDesktop -bool false
  # Desktop & Dock > Hot Corners: 1 is "-" (no action), and no modifier keys.
  local corner
  for corner in tl tr bl br; do
    set_default "Hot corner $corner: no action" \
      com.apple.dock "wvous-$corner-corner" -int 1
    set_default "Hot corner $corner: no modifier" \
      com.apple.dock "wvous-$corner-modifier" -int 0
  done
  # These read their settings at launch; launchd restarts them.
  run killall Dock || true
  run killall WindowManager || true

  # System Settings > Menu Bar.
  log "Menu bar"
  set_default "Menu bar clock shows seconds" \
    com.apple.menuextra.clock ShowSeconds -bool true
  set_default "Menu bar clock shows AM/PM" \
    com.apple.menuextra.clock ShowAMPM -bool true
  set_default "Menu bar clock shows the day of the week" \
    com.apple.menuextra.clock ShowDayOfWeek -bool true
  # Show date: 0 "When space allows", 1 Always, 2 Never.
  set_default "Menu bar clock shows the date when space allows" \
    com.apple.menuextra.clock ShowDate -int 0
  set_default "Menu bar: no battery" \
    com.apple.controlcenter "NSStatusItem VisibleCC Battery" -bool false
  set_default "Menu bar: no Wi-Fi" \
    com.apple.controlcenter "NSStatusItem VisibleCC WiFi" -bool false
  # "Recent documents, applications, and servers": 0 is None.
  set_default "Menu bar: no recent documents, applications, or servers" \
    com.apple.controlcenter NumberOfRecents -int 0
  # These live in Control Center; launchd restarts it.
  run killall ControlCenter || true

  # System Settings > Keyboard. Key repeat and keyboard navigation take effect
  # after logging out and back in; the text settings when apps next start.
  log "Keyboard"
  # The fastest values the System Settings sliders allow (in 15 ms units).
  set_default "Key repeat rate fastest" -g KeyRepeat -int 2
  set_default "Delay until key repeat shortest" -g InitialKeyRepeat -int 15
  # Holding a key repeats it instead of showing the accented-letter picker.
  set_default "Holding a key repeats it (no accent picker)" \
    -g ApplePressAndHoldEnabled -bool false
  # Keyboard > Keyboard navigation: Tab moves between all controls.
  set_default "Keyboard navigation on" -g AppleKeyboardUIMode -int 2
  # Keyboard > Text Input > Edit.
  set_default "No smart quotes" \
    -g NSAutomaticQuoteSubstitutionEnabled -bool false
  set_default "No smart dashes" \
    -g NSAutomaticDashSubstitutionEnabled -bool false
  set_default "No automatic spelling correction" \
    -g NSAutomaticSpellingCorrectionEnabled -bool false
  set_default "No automatic capitalization" \
    -g NSAutomaticCapitalizationEnabled -bool false
  set_default "No period with double-space" \
    -g NSAutomaticPeriodSubstitutionEnabled -bool false

  # System Settings > Trackpad. Takes effect after logging out and back in.
  log "Trackpad"
  set_default "Tap to click (built-in trackpad)" \
    com.apple.AppleMultitouchTrackpad Clicking -bool true
  set_default "Tap to click (Bluetooth trackpad)" \
    com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true
  # Also needed for tap to click, both globally and for this Mac (-currentHost,
  # which set_default doesn't take).
  set_default "Tap to click (this user)" -g com.apple.mouse.tapBehavior -int 1
  run defaults -currentHost write -g com.apple.mouse.tapBehavior -int 1
  DONE+=("Tap to click (this Mac)")
  # Tracking speed (0 to 3) and Force Click.
  set_default "Trackpad tracking speed 1" -g com.apple.trackpad.scaling -float 1
  set_default "Force Click on" -g com.apple.trackpad.forceClick -bool true
  # The rest are set for both the built-in and Bluetooth trackpads.
  local trackpad
  for trackpad in com.apple.AppleMultitouchTrackpad \
    com.apple.driver.AppleBluetoothMultitouch.trackpad; do
    # Click firmness medium (0 light, 1 medium, 2 firm), Force Click on.
    set_default "Trackpad: medium click ($trackpad)" \
      $trackpad FirstClickThreshold -int 1
    set_default "Trackpad: medium Force Click ($trackpad)" \
      $trackpad SecondClickThreshold -int 1
    set_default "Trackpad: Force Click on ($trackpad)" \
      $trackpad ForceSuppressed -bool false
    # Secondary click with two fingers, not in a corner.
    set_default "Trackpad: two-finger secondary click ($trackpad)" \
      $trackpad TrackpadRightClick -bool true
    set_default "Trackpad: no corner secondary click ($trackpad)" \
      $trackpad TrackpadCornerSecondaryClick -int 0
    # No Look Up on three-finger tap, no three-finger drag.
    set_default "Trackpad: no three-finger tap ($trackpad)" \
      $trackpad TrackpadThreeFingerTapGesture -int 0
    set_default "Trackpad: no three-finger drag ($trackpad)" \
      $trackpad TrackpadThreeFingerDrag -bool false
    # Scroll & Zoom: scrolling, momentum, pinch, rotate, smart zoom.
    set_default "Trackpad: scrolling ($trackpad)" \
      $trackpad TrackpadScroll -bool true
    set_default "Trackpad: horizontal scrolling ($trackpad)" \
      $trackpad TrackpadHorizScroll -bool true
    set_default "Trackpad: momentum scrolling ($trackpad)" \
      $trackpad TrackpadMomentumScroll -bool true
    set_default "Trackpad: pinch to zoom ($trackpad)" \
      $trackpad TrackpadPinch -bool true
    set_default "Trackpad: rotate ($trackpad)" \
      $trackpad TrackpadRotate -bool true
    set_default "Trackpad: smart zoom ($trackpad)" \
      $trackpad TrackpadTwoFingerDoubleTapGesture -bool true
    # More Gestures (2 is on): swipe between full-screen apps, Mission
    # Control, App Expose, Launchpad, show Desktop; Notification Center
    # from the right edge (3).
    set_default "Trackpad: three-finger horizontal swipe ($trackpad)" \
      $trackpad TrackpadThreeFingerHorizSwipeGesture -int 2
    set_default "Trackpad: three-finger vertical swipe ($trackpad)" \
      $trackpad TrackpadThreeFingerVertSwipeGesture -int 2
    set_default "Trackpad: four-finger horizontal swipe ($trackpad)" \
      $trackpad TrackpadFourFingerHorizSwipeGesture -int 2
    set_default "Trackpad: four-finger vertical swipe ($trackpad)" \
      $trackpad TrackpadFourFingerVertSwipeGesture -int 2
    set_default "Trackpad: four-finger pinch ($trackpad)" \
      $trackpad TrackpadFourFingerPinchGesture -int 2
    set_default "Trackpad: five-finger pinch ($trackpad)" \
      $trackpad TrackpadFiveFingerPinchGesture -int 2
    set_default "Trackpad: Notification Center from the right edge ($trackpad)" \
      $trackpad TrackpadTwoFingerFromRightEdgeSwipeGesture -int 3
  done

  log "Language & Region"
  # Days are numbered from Sunday = 1. -dict-add keeps entries for any other
  # calendars. Apps pick it up when they next start.
  set_default "First day of the week is Monday" \
    -g AppleFirstWeekday -dict-add gregorian -int 2

  # Screenshot app (Shift-Command-5) > Options.
  log "Screenshots"
  ensure_dir "Screenshots folder" "$HOME/Pictures/Screenshots"
  set_default "Screenshots saved to ~/Pictures/Screenshots" \
    com.apple.screencapture location -string "$HOME/Pictures/Screenshots"
  set_default "Screenshots saved as PNG" com.apple.screencapture type -string png
  set_default "Screenshots of windows without a shadow" \
    com.apple.screencapture disable-shadow -bool true
  run killall SystemUIServer || true

  # Save and print dialogs in every app. Apps pick these up when they next start.
  log "Save and print dialogs"
  set_default "Save dialogs open expanded" \
    -g NSNavPanelExpandedStateForSaveMode -bool true
  set_default "Save dialogs open expanded (newer apps)" \
    -g NSNavPanelExpandedStateForSaveMode2 -bool true
  set_default "Print dialogs open expanded" \
    -g PMPrintingExpandedStateForPrint -bool true
  set_default "Print dialogs open expanded (newer apps)" \
    -g PMPrintingExpandedStateForPrint2 -bool true
  set_default "New documents save to this Mac, not iCloud" \
    -g NSDocumentSaveNewDocumentsToCloud -bool false

  # Finder > Settings, and the View menu.
  log "Finder"
  set_default "Show all filename extensions" \
    -g AppleShowAllExtensions -bool true
  set_default "Finder: no warning when changing an extension" \
    com.apple.finder FXEnableExtensionChangeWarning -bool false
  set_default "Finder: folders on top in windows" \
    com.apple.finder _FXSortFoldersFirst -bool true
  set_default "Finder: folders on top on the Desktop" \
    com.apple.finder _FXSortFoldersFirstOnDesktop -bool true
  # SCcf is "Search the Current Folder"; SCev is This Mac, SCsp the previous scope.
  set_default "Finder: search the current folder by default" \
    com.apple.finder FXDefaultSearchScope -string SCcf
  set_default "Finder: show path bar" com.apple.finder ShowPathbar -bool true
  set_default "Finder: show status bar" com.apple.finder ShowStatusBar -bool true
  # Nlsv list, clmv column, icnv icon, glyv gallery. Folders that already have
  # their own saved view keep it.
  set_default "Finder: list view by default" \
    com.apple.finder FXPreferredViewStyle -string Nlsv
  # PfHm is the home folder (PfDe Desktop, PfDo Documents, PfAF Recents).
  set_default "Finder: new windows open the home folder" \
    com.apple.finder NewWindowTarget -string PfHm
  set_default "Finder: show hidden files" \
    com.apple.finder AppleShowAllFiles -bool true
  set_default "Finder: full path in window titles" \
    com.apple.finder _FXShowPosixPathInTitle -bool true
  set_default "Finder: remove items from the Trash after 30 days" \
    com.apple.finder FXRemoveOldTrashItems -bool true
  set_default "Finder: no warning before emptying the Trash" \
    com.apple.finder WarnOnEmptyTrash -bool false
  set_default "Desktop: hide external disks" \
    com.apple.finder ShowExternalHardDrivesOnDesktop -bool false
  set_default "Desktop: hide removable media" \
    com.apple.finder ShowRemovableMediaOnDesktop -bool false
  set_default "Desktop: hide connected servers" \
    com.apple.finder ShowMountedServersOnDesktop -bool false
  set_default "Desktop: hide internal disks" \
    com.apple.finder ShowHardDrivesOnDesktop -bool false
  set_default "Finder sidebar: no recent tags" \
    com.apple.finder ShowRecentTags -bool false
  # .DS_Store files on shares and USB drives clutter them for other systems.
  set_default "No .DS_Store files on network shares" \
    com.apple.desktopservices DSDontWriteNetworkStores -bool true
  set_default "No .DS_Store files on USB drives" \
    com.apple.desktopservices DSDontWriteUSBStores -bool true
  # Not a default: clears the folder's hidden flag. Setting it again is harmless.
  run chflags nohidden "$HOME/Library"
  DONE+=("Show the ~/Library folder")
  # Finder reads these at launch; launchd restarts it.
  run killall Finder || true

  # Finder > Settings > Sidebar. Finder picks the changes up immediately.
  log "Finder sidebar"
  # Creates ~/Developer too, if needed.
  ensure_dir "Folder for Finder favorites" "$HOME/Developer/frz"
  add_finder_favorites "$HOME" "$HOME/Desktop" "$HOME/Documents" \
    "$HOME/Downloads" "$HOME/Developer" "$HOME/Developer/frz"

  log "Login items"
  remove_login_item "UniFi Endpoint does not open at login" \
    "/Applications/UniFi Endpoint.app"
}
