# Tab completion. Homebrew's bash-completion@2 (`brew install
# bash-completion@2`) loads completions for brew, gh, git and every other
# Homebrew package that ships one. Skipped quietly if it isn't installed.
if [[ -n "${HOMEBREW_PREFIX:-}" ]] &&
  [[ -r "$HOMEBREW_PREFIX/etc/profile.d/bash_completion.sh" ]]; then
  . "$HOMEBREW_PREFIX/etc/profile.d/bash_completion.sh"
fi
