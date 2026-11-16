# shellcheck shell=bash
#
# Herdr settings (the app is installed by install_brew_packages).
#
# Sourced by install-macos.sh; not meant to be run on its own.

HERDR_SETTINGS="$HOME/.config/herdr-app/settings.json"

# No telemetry and no sounds. Herdr writes its settings file with the
# defaults (true for both) once it has run, so true is replaced; anything
# else is left alone.
configure_herdr() {
  log "Herdr settings"

  json_set "$HERDR_SETTINGS" '["telemetry"]' 'false' '[true]'
  json_set "$HERDR_SETTINGS" '["sounds", "enabled"]' 'false' '[true]'
}
