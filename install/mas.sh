# shellcheck shell=bash
#
# Mac App Store apps, installed with mas (installed by install_brew_packages).
#
# mas needs root to install; it uses the sudo cached at the start of the run.
# You must be signed in to the App Store app. Apps already on this Apple
# Account are installed with `mas install`; free apps that aren't yet are
# "gotten" with `mas get`. Paid apps that haven't been bought are skipped: buy
# them in the App Store and re-run.
#
# Sourced by install-macos.sh; not meant to be run on its own.

MAS="$BREW_PREFIX/bin/mas"

# The apps to install, one per line, in the format docs/mas-list.md prints from
# `mas list`, so its output can be pasted in here as is. The lines are read as
# data (the ID and, after the #, the name), not run. Xcode is left out on
# purpose: drop its line from pasted output.
MAS_APPS='
appStoreApps+=("1365531024") # 1Blocker
appStoreApps+=("1622835804") # Kagi for Safari
appStoreApps+=("1346247457") # Endel
appStoreApps+=("1436994560") # Portal
appStoreApps+=("1508732804") # Soulver
appStoreApps+=("1452453066") # Hidden Bar
appStoreApps+=("470158793") # Keka
appStoreApps+=("411643860") # DaisyDisk
appStoreApps+=("403504866") # PCalc
appStoreApps+=("937984704") # Amphetamine
appStoreApps+=("1596706466") # Speediness
appStoreApps+=("1559348223") # Power Plist Editor
appStoreApps+=("499768540") # Power JSON Editor
appStoreApps+=("1565766176") # Power YAML Editor
appStoreApps+=("1569680330") # Rsyncinator
appStoreApps+=("6446933691") # Postico 2
appStoreApps+=("6747497179") # Marked 3
appStoreApps+=("1663047912") # Screens 5
appStoreApps+=("1569813296") # 1Password for Safari
appStoreApps+=("6738342400") # Tampermonkey
appStoreApps+=("361285480") # Keynote
appStoreApps+=("361304891") # Numbers
appStoreApps+=("361309726") # Pages
appStoreApps+=("408981434") # iMovie
appStoreApps+=("1631624924") # Final Cut Pro
appStoreApps+=("6746516157") # Compressor
'

# Print MAS_APPS as "ID Name" lines.
mas_app_list() {
  local line pattern='^appStoreApps\+=\("([0-9]+)"\)[[:space:]]*#[[:space:]]*(.*)$'
  while IFS= read -r line; do
    if [[ "$line" =~ $pattern ]]; then
      printf '%s %s\n' "${BASH_REMATCH[1]}" "${BASH_REMATCH[2]}"
    elif [[ "$line" =~ [^[:space:]] ]]; then
      note "install/mas.sh: ignoring unrecognized line: $line" >&2
    fi
  done <<<"$MAS_APPS"
}

# Succeeds if the App Store lists app ID as free.
mas_app_is_free() {
  [[ -x "$JQ" ]] &&
    "$MAS" lookup --json "$1" 2>/dev/null |
    "$JQ" -e '(if type == "array" then .[0] else . end).price == 0' >/dev/null 2>&1
}

install_mas_apps() {
  local installed id name missing=""

  log "Mac App Store apps"

  if [[ ! -x "$MAS" ]]; then
    if ((DRY_RUN)); then
      note "[dry-run] install the App Store apps with mas (once it is installed)"
      DONE+=("[dry-run] Mac App Store apps")
    else
      note "$MAS not found; App Store apps not installed."
      SKIPPED+=("Mac App Store apps (mas missing)")
    fi
    return 0
  fi

  # `mas list` prints "<id>  <name>  (<version>)", the ID right-aligned.
  installed="$("$MAS" list 2>/dev/null | awk '{ print $1 }')"

  while read -r id name; do
    [[ -n "$id" ]] || continue
    if printf '%s\n' "$installed" | grep -qxF "$id"; then
      note "$name is already installed"
      PRESENT+=("App Store: $name")
    else
      missing+="$id $name"$'\n'
    fi
  done <<<"$(mas_app_list)"

  [[ -n "$missing" ]] || return 0

  note "Not installed yet:"
  while read -r id name; do
    [[ -n "$id" ]] && note "  $name"
  done <<<"$missing"
  have_sudo "Mac App Store apps" || return 0
  # mas reads from stdin; keep it away from the list being read.
  while read -r id name <&3; do
    [[ -n "$id" ]] || continue
    if ((DRY_RUN)); then
      note "[dry-run] sudo $MAS install $id ($name), or mas get if it is free"
      DONE+=("[dry-run] App Store: $name")
    elif sudo "$MAS" install "$id"; then
      DONE+=("App Store: $name")
    elif mas_app_is_free "$id"; then
      # Free, but not yet on this Apple Account.
      if sudo "$MAS" get "$id"; then
        DONE+=("App Store: $name")
      else
        note "Could not get $name."
        SKIPPED+=("App Store: $name (mas get failed)")
      fi
    else
      note "Could not install $name: not bought on this Apple Account, or not"
      note "signed in to the App Store. Buy it there and re-run this script."
      SKIPPED+=("App Store: $name (not bought, or not signed in)")
    fi
  done 3<<<"$missing"
}
