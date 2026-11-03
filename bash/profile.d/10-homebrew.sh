# Homebrew: PATH, MANPATH, INFOPATH and HOMEBREW_* variables.
if [[ -x /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv bash)"
fi
