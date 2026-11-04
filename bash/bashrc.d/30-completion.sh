# Tab completion. Homebrew's bash-completion@2 (`brew install
# bash-completion@2`) completes brew, gh, git and every other Homebrew
# package that ships a completion. Skipped quietly if it isn't installed.
if [[ -n "${HOMEBREW_PREFIX:-}" ]] &&
  [[ -r "$HOMEBREW_PREFIX/etc/profile.d/bash_completion.sh" ]]; then
  # Load completions lazily, the first time a command is completed, instead
  # of sourcing all of Homebrew's etc/bash_completion.d at startup (about
  # 15 ms per new shell). bash-completion looks in
  # BASH_COMPLETION_USER_DIR/completions/<command>, and
  # completion/homebrew/completions in this repo is a symlink to
  # /opt/homebrew/etc/bash_completion.d. The default user directory stays
  # first, so completions put there still win.
  BASH_COMPLETION_USER_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/bash-completion:$DOTFILES_BASH/completion/homebrew"
  # Nothing to source eagerly: /var/empty is an empty directory on macOS.
  BASH_COMPLETION_COMPAT_DIR=/var/empty
  . "$HOMEBREW_PREFIX/etc/profile.d/bash_completion.sh"

  # Lazy loading finds a file by the command's name, so a file that also
  # completes another command needs a loader for that one. OrbStack's orbctl
  # file completes orb too. Returning 124 makes bash retry the completion
  # with what the file registered.
  _dotfiles_complete_orb() {
    . "$HOMEBREW_PREFIX/etc/bash_completion.d/orbctl" 2>/dev/null && return 124
  }
  complete -F _dotfiles_complete_orb orb
fi
