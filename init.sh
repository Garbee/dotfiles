#!/usr/bin/env bash

# Bootstrap a new machine. Intended to be downloaded and run directly:
#
#   curl -fsSL https://raw.githubusercontent.com/Garbee/dotfiles/main/init.sh | bash
#
# Installs the tooling needed to clone the dotfiles, clones them to
# ~/.dotfiles, then hands off to the platform install script.

set -euo pipefail

DOTFILES_DIR="$HOME/.dotfiles"
DOTFILES_URL="https://github.com/Garbee/dotfiles.git"

os="$(uname -s)"

clt_installed() {
    [ -e /Library/Developer/CommandLineTools/usr/bin/git ]
}

if [ "$os" = "Darwin" ]; then
    # Command Line Tools provide git. Try a headless install first (same
    # technique as the Homebrew installer) so no GUI prompt is needed.
    if ! clt_installed; then
        echo "Searching online for the Command Line Tools"

        # This temporary file prompts the 'softwareupdate' utility to list the Command Line Tools
        clt_placeholder="/tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress"
        sudo touch "$clt_placeholder"

        clt_label="$(softwareupdate -l |
            grep -B 1 -E 'Command Line Tools' |
            awk -F'*' '/^ *\*/ {print $2}' |
            sed -e 's/^ *Label: //' -e 's/^ *//' |
            sort -V |
            tail -n1)"

        if [ -n "$clt_label" ]; then
            echo "Installing $clt_label"
            sudo softwareupdate -i "$clt_label"
            sudo xcode-select --switch /Library/Developer/CommandLineTools
        fi

        sudo rm -f "$clt_placeholder"
    fi

    # Headless install may have failed, so fall back to the GUI installer.
    if ! clt_installed; then
        echo "Installing the Command Line Tools (expect a GUI popup)"
        xcode-select --install

        echo "Waiting for Command Line Tools installation to finish..."
        until clt_installed; do
            sleep 5
        done
        sudo xcode-select --switch /Library/Developer/CommandLineTools
    fi
elif [ "$os" = "Linux" ]; then
    if [ -r /etc/os-release ] && grep -q '^ID=ubuntu$' /etc/os-release; then
        if ! command -v git &>/dev/null; then
            echo "Installing git"
            sudo apt-get update
            sudo apt-get install -y git
        fi
    else
        echo "Unsupported Linux distribution. Install git manually, then clone $DOTFILES_URL to $DOTFILES_DIR." >&2
        exit 1
    fi
else
    echo "Unsupported operating system: $os" >&2
    exit 1
fi

if [ ! -d "$DOTFILES_DIR" ]; then
    echo "Cloning dotfiles to $DOTFILES_DIR"
    git clone "$DOTFILES_URL" "$DOTFILES_DIR"
else
    echo "$DOTFILES_DIR already exists, skipping clone"
fi

if [ "$os" = "Darwin" ]; then
    "$DOTFILES_DIR/install-scripts/macos.sh"
fi
