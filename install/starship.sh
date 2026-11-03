# shellcheck shell=bash
#
# Starship prompt: symlink starship/starship.toml to ~/.config/starship.toml.
# Starship itself is installed by install_brew_packages, and started by
# bash/bashrc.d/50-prompt.sh.
#
# Sourced by install-macos.sh; not meant to be run on its own.

link_starship_config() {
  local config_dir="$HOME/.config"

  log "Starship config"

  if [[ ! -e "$config_dir" ]]; then
    if ((DRY_RUN)); then
      note "[dry-run] mkdir -p ~/.config"
    else
      mkdir -p "$config_dir"
    fi
  elif [[ ! -d "$config_dir" ]]; then
    note "~/.config exists but is not a directory; leaving it alone."
    SKIPPED+=("Starship config (~/.config is not a directory)")
    return 0
  fi

  if ! link_file "Starship config" "$DOTFILES/starship/starship.toml" \
    "$config_dir/starship.toml"; then
    note "Starship reads STARSHIP_CONFIG instead, if set (e.g. in"
    note "~/.bash_profile.local)."
  fi
}
