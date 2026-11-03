# Prompt: Starship (installed by install-macos.sh, configured in
# starship/starship.toml). Keeps bash's default prompt if it isn't installed.
# Starship keeps whatever is already in PROMPT_COMMAND (20-history.sh's
# `history -a`).
if command -v starship >/dev/null 2>&1; then
  eval "$(starship init bash)"
fi
