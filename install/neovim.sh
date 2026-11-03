# shellcheck shell=bash
#
# Neovim config: symlink nvim/init.lua to ~/.config/nvim/init.lua. Neovim
# itself (and tree-sitter-cli, which the config uses to build parsers) is
# installed by install_brew_packages.
#
# Only the file is linked, not the folder, so what Neovim writes next to it
# (such as vim.pack's nvim-pack-lock.json) stays out of the repository.
#
# Sourced by install-macos.sh; not meant to be run on its own.

link_neovim_config() {
  local config_dir="$HOME/.config/nvim"

  log "Neovim config"

  if [[ ! -e "$config_dir" ]]; then
    if ((DRY_RUN)); then
      note "[dry-run] mkdir -p ~/.config/nvim"
    else
      mkdir -p "$config_dir"
    fi
  elif [[ ! -d "$config_dir" ]]; then
    note "~/.config/nvim exists but is not a directory; leaving it alone."
    SKIPPED+=("Neovim config (~/.config/nvim is not a directory)")
    return 0
  fi

  link_file "Neovim config" "$DOTFILES/nvim/init.lua" "$config_dir/init.lua" || true
}
