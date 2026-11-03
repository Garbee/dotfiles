# shellcheck shell=bash
#
# Homebrew itself, and helpers to install packages and trust taps.
#
# Sourced by install-macos.sh; not meant to be run on its own.

install_homebrew() {
  log "Homebrew"

  if [[ -x "$BREW" ]]; then
    note "Already installed at $BREW"
    PRESENT+=("Homebrew")
  elif ((DRY_RUN)); then
    note "[dry-run] run the official Homebrew installer (installs to $BREW_PREFIX)"
    DONE+=("Homebrew")
    return 0
  else
    note "Running the official Homebrew installer (it will ask for your password)."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    DONE+=("Homebrew")
  fi

  # Make brew available for the rest of this script only.
  eval "$("$BREW" shellenv)"
}

# Install a Homebrew formula or cask (brew works out which) unless present.
#
#   brew_install LABEL PACKAGE [--app PATH] [--sudo]
#
#   PACKAGE        A name, or tap/name (e.g. docker/tap/sbx) for a tap package.
#   --app PATH     The package installs an app at PATH. If PATH already exists
#                  but wasn't installed by Homebrew, leave it alone: the install
#                  would fail on it (or need --force, which would replace it).
#   --sudo         The installer needs an administrator password (e.g. a .pkg
#                  installer); ask before running it.
brew_install() {
  local label="$1" package="$2" app="" needs_sudo=0
  local versions name
  shift 2
  while (($#)); do
    case "$1" in
      --app)
        app="$2"
        shift
        ;;
      --sudo) needs_sudo=1 ;;
      *)
        printf 'brew_install: unknown option: %s\n' "$1" >&2
        return 1
        ;;
    esac
    shift
  done

  log "$label"

  # Prints e.g. "jq 1.8.2"; fails if the package isn't installed. Without
  # --cask, `brew list --versions` only looks at formulae, so check both.
  # It wants the bare name, not tap/name.
  name="${package##*/}"
  if [[ -x "$BREW" ]] && {
    versions="$("$BREW" list --formula --versions "$name" 2>/dev/null)" ||
      versions="$("$BREW" list --cask --versions "$name" 2>/dev/null)"
  } && [[ -n "$versions" ]]; then
    note "Already installed via Homebrew ($versions)"
    PRESENT+=("$label")
    return 0
  fi

  if [[ -n "$app" ]] && [[ -e "$app" ]]; then
    note "$app exists but was not installed by Homebrew; leaving it alone."
    SKIPPED+=("$label (existing $app not managed by Homebrew)")
    return 0
  fi

  if ((needs_sudo)) &&
    ! confirm "Install $label? Its installer needs your administrator password."; then
    SKIPPED+=("$label (declined: needs administrator password)")
    return 0
  fi

  run "$BREW" install -y "$package"
  DONE+=("$label")
}

# Trust a third-party tap so Homebrew will load its formulae and casks.
# Trust is per user (stored in ~/.homebrew/trust.json, or under
# $XDG_CONFIG_HOME/homebrew).
#
#   brew_trust_tap TAP   e.g. docker/tap
brew_trust_tap() {
  local tap="$1" label="Trust Homebrew tap $1"

  log "$label"

  if [[ -x "$BREW" ]] && "$BREW" trust --json=v1 2>/dev/null |
    "$JQ" -e --arg t "$tap" '.taps | index($t) != null' >/dev/null 2>&1; then
    note "Already trusted"
    PRESENT+=("$label")
    return 0
  fi

  run "$BREW" trust --tap "$tap"
  DONE+=("$label")
}

# The Homebrew packages to install, in order.
install_brew_packages() {
  brew_install "Homebrew bash" bash
  # Newer than the Xcode Command Line Tools git; first on PATH after shellenv.
  brew_install "Git" git
  brew_install "bash-completion" bash-completion@2
  brew_install "Neovim" neovim
  brew_install "jq" jq
  brew_install "ripgrep" ripgrep
  brew_install "fd" fd
  brew_install "fzf" fzf
  brew_install "bat" bat
  brew_install "Node.js" node
  # Command-line installs from the Mac App Store.
  brew_install "mas" mas
  # Lets Touch ID for sudo work inside tmux and screen (see touch-id-sudo.sh).
  brew_install "pam-reattach" pam-reattach
  brew_install "Zed" zed --app /Applications/Zed.app
  brew_install "Herdr" herdr-app --app /Applications/Herdr.app
  brew_install "1Password" 1password --app /Applications/1Password.app
  brew_install "1Password CLI" 1password-cli
  brew_install "Secretive" secretive --app /Applications/Secretive.app
  brew_install "IVPN" ivpn --app /Applications/IVPN.app
  brew_install "OrbStack" orbstack --app /Applications/OrbStack.app
  brew_install "OBS Studio" obs --app /Applications/OBS.app
  brew_install "BetterMouse" bettermouse --app /Applications/BetterMouse.app
  brew_install "Display Pilot 2" display-pilot --app "/Applications/Display Pilot 2.app"
  brew_install "Elgato Stream Deck" elgato-stream-deck \
    --app "/Applications/Elgato Stream Deck.app" --sudo
  brew_install "Elgato Wave Link" elgato-wave-link --app "/Applications/Elgato Wave Link.app"
  brew_install "IINA" iina --app /Applications/IINA.app
  brew_install "Nativ" nativ --app /Applications/Nativ.app
  brew_install "UniFi Identity Endpoint" unifi-identity-endpoint \
    --app "/Applications/UniFi Endpoint.app" --sudo
  brew_install "Wins" wins --app /Applications/Wins.app
  brew_trust_tap docker/tap
  brew_install "Docker Sandboxes (sbx)" docker/tap/sbx
  brew_install "GitHub CLI" gh
}
