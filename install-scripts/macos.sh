#!/usr/bin/env zsh

# Make ZSH not care about end of line comments when running the script
setopt interactive_comments

# Path to main dotfile folder. We know the install script is located one directory under. So get script path then get it's dir then parent.
dotfilePath=$0:A:h:h

# Silence any MoTD or "last login" message when starting a shell
if [ ! -f "$HOME/.hushlogin" ]; then
    touch "$HOME/.hushlogin"
fi

ask() {
    # https://djm.me/ask
    local prompt default reply

    if [ "${2:-}" = "Y" ]; then
        prompt="Y/n"
        default=Y
    elif [ "${2:-}" = "N" ]; then
        prompt="y/N"
        default=N
    else
        prompt="y/n"
        default=
    fi

    while true; do

        # Ask the question (not using "read -p" as it uses stderr not stdout)
        echo -n "$1 [$prompt] "

        # Read the answer (use /dev/tty in case stdin is redirected from somewhere else)
        read reply </dev/tty

        # Default?
        if [ -z "$reply" ]; then
            reply=$default
        fi

        # Check if the reply is valid
        case "$reply" in
        Y* | y*) return 0 ;;
        N* | n*) return 1 ;;
        esac

    done
}

# Ask for the administrator password upfront
sudo -v

# Keep-alive: update existing `sudo` time stamp until the install script has finished
while true; do
    sudo -n true
    sleep 60
    kill -0 "$$" || exit
done 2>/dev/null &

if ask "Do you want to install Rosetta 2?" Y; then
    softwareupdate --install-rosetta
fi

# Make temp folder for holding some files
tempDir=$(mktemp -d)

# Configure global settings
echo "Configuring Global Settings"

# Turn off window tinting based on wallpaper
defaults write .GlobalPreferences AppleReduceDesktopTinting -bool true

## Install color schemes for Apple Color Picker
curl -L -o ~/Library/Colors/Nord.clr https://raw.githubusercontent.com/arcticicestudio/nord/develop/src/swatches/Nord.clr

# Show seconds in clock
defaults write com.apple.menuextra.clock ShowSeconds -bool true
defaults write com.apple.menuextra.clock DateFormat "EEE MMM d  h:mm:ss a"

# Disable automatic capitalization as it"s annoying when typing code
defaults write NSGlobalDomain NSAutomaticCapitalizationEnabled -bool false

# Disable smart dashes as they"re annoying when typing code
defaults write NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool false

# Disable automatic period substitution as it"s annoying when typing code
defaults write NSGlobalDomain NSAutomaticPeriodSubstitutionEnabled -bool false

# Disable smart quotes as they"re annoying when typing code
defaults write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false

# Disable auto-correct
defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false

# Enable full keyboard access for all controls
# (e.g. enable Tab in modal dialogs)
defaults write NSGlobalDomain AppleKeyboardUIMode -int 3

# Finder prefs
chflags nohidden ~/Library && xattr -d com.apple.FinderInfo ~/Library
sudo chflags nohidden /Volumes

# Global preference modifications

## Keyboard
defaults write -g NSAutomaticSpellingCorrectionEnabled -bool false
defaults write -g NSAutomaticCapitalizationEnabled -bool false
defaults write -g NSAutomaticPeriodSubstitutionEnabled -bool false

## Misc
mkdir -p "$HOME/Developer"
mkdir -p "$HOME/bin"
mkdir -p "$HOME/.ssh"

# Install Homebrew
if ! command -v brew &>/dev/null; then
    NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

if ! grep -q 'eval $(/opt/homebrew/bin/brew shellenv)' "$HOME/.zprofile"; then
    echo 'eval $(/opt/homebrew/bin/brew shellenv)' >>"$HOME/.zprofile"
fi

eval $(/opt/homebrew/bin/brew shellenv)

brew install mas

if ! ask "Are you logged into the App Store?"; then
    echo "Must be logged into App Store to complete installation."
    exit 1
fi

echo "Installing homebrew software"

formulaeToInstall=(
    "node"
    "coreutils"
    "git"
    "git-delta"
    "git-quick-stats"
    "gnupg"
    "gh"
    "go"
    "httpie"
    "pstree"
    "tlrc"
    "bat"
    "exa"
    "jq"
    "neovim"
    "prettyping"
    "the_silver_searcher"
    "fzf"
    "harper"
    "discord"
    "visual-studio-code"
    "iterm2"
    "latest"
    "secretive"
    "osaurus"
    "obsidian"
    "zed"
    "juxtacode"
    "orbstack"
    "unifi-identity-endpoint"
    "emclient"
    "antigravity"
    "bruno"
)

for target in $formulaeToInstall; do
    if ! brew list $target &>/dev/null; then
        echo "Installing $target"
        brew install --quiet $target
    fi
done

# Install AppStore Content

appStoreApps=()

# Safari Plugins
appStoreApps+=("1365531024") # 1Blocker
appStoreApps+=("1592917505") # Noir
appStoreApps+=("1533805339") # Keepa - Price Tracker
appStoreApps+=("6738342400") # Tampermonkey
appStoreApps+=("1622835804") # Kagi
appStoreApps+=("1615431236") # Bonjourr Startpage

# Media
appStoreApps+=("1346247457") # Endel
appStoreApps+=("1436994560") # Portal

# Utilities
appStoreApps+=("1508732804") # Soulver 3
appStoreApps+=("1452453066") # Hidden Bar
appStoreApps+=("470158793")  # Keka
appStoreApps+=("411643860")  # DaisyDisk
appStoreApps+=("1588708173") # Elsewhen
appStoreApps+=("403504866")  # PCalc
appStoreApps+=("937984704") # Amphetamine
appStoreApps+=("1596706466") # Speediness

# DevTools
appStoreApps+=("1559348223") # Power Plist Editor
appStoreApps+=("499768540")  # Power JSON Editor
appStoreApps+=("1565766176") # Power YAML Editor
appStoreApps+=("1569680330") # Rsyncinator
appStoreApps+=("6446933691") # Postico 2

# Productivity
# Update with Creator Studio IDs.
# appStoreApps+=("409203825")  # Numbers
# appStoreApps+=("409201541")  # Pages
# appStoreApps+=("409183694")  # Keynote
appStoreApps+=("890031187")  # Marked 2
appStoreApps+=("1663047912") # Screens 5
appStoreApps+=("1522267256") # Shareful

for appId in $appStoreApps; do
    mas install "$appId"
done

## Configurations

if [ ! -f "$HOME/.gitconfig" ]; then
    ### Git
    echo "Configuring git"
    ln -s "$HOME/.dotfiles/git/gitconfig" "$HOME/.gitconfig"
fi

if [ ! -f "$HOME/.ssh/config" ]; then
    echo "Linking SSH Config"
    mkdir -p "$HOME/.ssh"
    ln -s "$HOME/.dotfiles/ssh/config" "$HOME/.ssh/config"
fi

if [ ! -f "$HOME/.zshrc" ]; then
    echo "Linking ZSH Config"
    ln -s "$HOME/.dotfiles/config/zshrc" "$HOME/.zshrc"
fi

if [ ! -f "$HOME/.zshenv" ]; then
    echo "Linking ZSH Env"
    ln -s "$HOME/.dotfiles/config/zshenv" "$HOME/.zshenv"
fi

sh -c 'curl -fLo "${XDG_DATA_HOME:-$HOME/.local/share}"/nvim/site/autoload/plug.vim --create-dirs \
       https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'

cd $HOME/.dotfiles
git remote set-url origin git@github.com:Garbee/dotfiles.git
cd $HOME

# Cleanup
echo "Cleaning up"
rm -rf "$tempDir"

# Manual Tasks
cat <<'EOF'
Setup is now complete.
There are a few manual tasks to finish so things are fully functional.

First, go into the Privacy and Security system preferences.
The following should be granted permissions:

* Full Disk access
   * Iterm2
   * Terminal
   * Visual Studio Code
   * Zed
* App Management
   * Iterm2
   * Terminal
   * Latest
* Screen & System Audio Recording
   * MacWhisper
   * Zoom
   * Slack
EOF

if ask "Do you want to open the Privacy and Security system preferences now?"; then
    open "x-apple.systempreferences:com.apple.preference.security?Privacy_All"
fi
