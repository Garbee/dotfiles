#!/bin/zsh

if [[ $(sw_vers -productVersion) == "12.4" ]]; then
    isStable=true
else
    isStable=false
fi

exit

# Make ZSH not care about end of line comments when running the script
setopt interactive_comments

echo "You will be prompted for information up until 1Password is logged into the CLI."

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

__dock_item() {
    printf '%s%s%s%s%s' \
        '<dict><key>tile-data</key><dict><key>file-data</key><dict>' \
        '<key>_CFURLString</key><string>' \
        "$1" \
        '</string><key>_CFURLStringType</key><integer>0</integer>' \
        '</dict></dict></dict>'
}

if ask "Do you want to clear all dock icons?" N; then
    defaults write com.apple.dock persistent-apps -array
    defaults write com.apple.dock persistent-apps -array-add "$(__dock_item /System/Applications/Launchpad.app)"
    defaults write com.apple.dock persistent-apps -array-add "$(__dock_item /Applications/Safari.app)"
    killAll Dock
fi

if ask "Do you want to install Rosetta 2?" Y; then
    softwareupdate --install-rosetta
fi

casksToInstall=(
    "font-iosevka"
    "font-iosevka-slab"
    "font-input"
    "font-victor-mono-nerd-font"
    "font-lexend"
    "font-lexend-exa"
    "font-lexend-giga"
    "font-lexend-mega"
    "font-lexend-peta"
    "font-lexend-tera"
    "font-lexend-zetta"
    "google-chrome"
    "iterm2"
    "raycast"
    "discord"
    "fsmonitor"
    "typora"
    "pitch"
    "deepgit"
    "steam"
    "runescape"
    "ivpn"
    "contexts"
    "fig"
    "docker"
    "secretive"
    "logitech-options"
    "logitech-unifying"
    "logitech-g-hub"
    "audacity"
    "elgato-stream-deck"
    "elgato-wave-link"
    "screenflow"
    "openemu"
    "monitorcontrol"
)

if isStable; then
    casksToInstall+=("soundsource")
    casksToInstall+=("audio-hijack")
    casksToInstall+=("loopback")
    casksToInstall+=("parallels")
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
# Show the path bar
defaults write com.apple.finder ShowPathbar -bool true
# Show the status bar
defaults write com.apple.finder ShowStatusBar -bool true
# Show user library folder
chflags nohidden ~/Library

# Enable developer options in Safari
defaults write com.apple.Safari IncludeInternalDebugMenu -bool true
defaults write com.apple.Safari IncludeDevelopMenu -bool true
defaults write com.apple.Safari WebKitDeveloperExtrasEnabledPreferenceKey -bool true
defaults write com.apple.Safari com.apple.Safari.ContentPageGroupIdentifier.WebKit2DeveloperExtrasEnabled -bool true
defaults write -g WebKitDeveloperExtras -bool true

# Global preference modifications

## Keyboard
defaults write -g NSAutomaticSpellingCorrectionEnabled -bool false
defaults write -g NSAutomaticCapitalizationEnabled -bool false
defaults write -g NSAutomaticPeriodSubstitutionEnabled -bool false

## Misc
mkdir -p "$HOME/Code"
mkdir -p "$HOME/bin"
mkdir -p "$HOME/.ssh"

# Install Homebrew
if ! command -v brew &>/dev/null; then
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
fi

if ! grep -q 'eval $(/opt/homebrew/bin/brew shellenv)' "$HOME/.zprofile"; then
    echo 'eval $(/opt/homebrew/bin/brew shellenv)' >>"$HOME/.zprofile"
fi

eval $(/opt/homebrew/bin/brew shellenv)

# Bootstrapping 1Password

brew install mas

if ! ask "Are you logged into the App Store?"; then
    echo "Must be logged into App Store to complete installation."
    exit 1
fi

brew install --cask "1password"
brew install --cask "1password-cli"

# Install brewed software
echo "Installing homebrew software"

brew tap homebrew/cask
brew tap homebrew/cask-versions
brew tap homebrew/cask-fonts
brew tap homebrew/cask-drivers

formulaeToInstall=(
    "node"
    "coreutils"
    "git"
    "mas"
    "fish"
    "git-flow"
    "git-delta"
    "git-quick-stats"
    "gnupg"
    "httpie"
    "pstree"
    "tldr"
    "bat"
    "exa"
    "jq"
    "neovim"
    "prettyping"
    "the_silver_searcher"
    "fzf"
)

for target in $formulaeToInstall; do
    brew list $target &>/dev/null || brew install $target
done

for target in $casksToInstall; do
    brew list $target &>/dev/null || brew install --cask $target
done

# Install AppStore Content

appStoreApps=()

# Safari Plugins
appStoreApps+=("1365531024") # 1Blocker
appStoreApps+=("1592917505") # Noir
appStoreApps+=("1533805339") # Keepa - Price Tracker
appStoreApps+=("1482490089") # Tampermonkey

# Media
appStoreApps+=("1484348796") # Endel

# Utilities
appStoreApps+=("1508732804") # Soulver 3
appStoreApps+=("1513574319") # Glance
appStoreApps+=("1452453066") # Hidden Bar
appStoreApps+=("441258766")  # Magnet
appStoreApps+=("470158793")  # Keka
appStoreApps+=("1224268771") # Screens
appStoreApps+=("979299240")  # Network Kit X
appStoreApps+=("411643860")  # DaisyDisk
appStoreApps+=("1194883472") # File Peek

# DevTools
appStoreApps+=("1109319285") # SSH Config Editor
appStoreApps+=("429449079")  # Patterns
appStoreApps+=("1512570906") # Flow Chart Designer 3
appStoreApps+=("1559348223") # Power Plist Editor
appStoreApps+=("499768540")  # Power JSON Editor
appStoreApps+=("1195426709") # Sequence Diagram
appStoreApps+=("1006087419") # SnippetsLab

# Reference
appStoreApps+=("403504866") # PCalc

# Productivity
appStoreApps+=("409203825")  # Numbers
appStoreApps+=("409201541")  # Pages
appStoreApps+=("409183694")  # Keynote
appStoreApps+=("408981434")  # iMovie
appStoreApps+=("824171161")  # Affinity Designer
appStoreApps+=("881418622")  # Affinity Publisher
appStoreApps+=("824183456")  # Affinity Photo
appStoreApps+=("1444383602") # Good Notes

# Education
appStoreApps+=("1476088902") # Rosetta Stone

for appId in $appStoreApps; do
    mas install "$appId"
done

hostsPrefPath=/Library/PreferencePanes/Hosts.prefPane

if [ ! -d $hostsPrefPath ]; then
    curl -O https://www.dirk-froehling.de/resources/Software/Hosts-PrefPane-1.4.5.pkg
    sudo installer -pkg Hosts-PrefPane-1.4.5.pkg -target /
    rm Hosts-PrefPane-1.4.5.pkg
fi

## Configurations

if [ ! -f "$HOME/.gitconfig" ]; then
    ### Git
    echo "Configuring git"
    ln -s "$HOME/.dotfiles/git/gitconfig" "$HOME/.gitconfig"
fi

if [ ! -f "$HOME/.ssh/config" ]; then
    echo "Linking SSH Config"
    ln -s "$HOME/.dotfiles/ssh/config" "$HOME/.ssh/config"
fi

### Fish Shell
echo "Configuring Fish Shell"
fishShellLocation="$(which fish)"
echo "$fishShellLocation" | sudo tee -a /etc/shells
sudo chsh -s "$fishShellLocation" "$USER"

### iTerm
echo "Configuring iTerm"
defaults write com.googlecode.iterm2.plist PrefsCustomFolder -string "~/.dotfiles/iterm"
defaults write com.googlecode.iterm2.plist LoadPrefsFromCustomFolder -bool true

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

# Finder: show hidden files by default
defaults write com.apple.finder AppleShowAllFiles -bool true

# Avoid creating .DS_Store files on network or USB volumes
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true

# Enable AirDrop over Ethernet and on unsupported Macs running Lion
defaults write com.apple.NetworkBrowser BrowseAllInterfaces -bool true

# Show the ~/Library folder
chflags nohidden ~/Library && xattr -d com.apple.FinderInfo ~/Library

# Show the /Volumes folder
sudo chflags nohidden /Volumes

# Minimize windows into their application"s icon
defaults write com.apple.dock minimize-to-application -bool true

# Set the icon size of Dock items to 36 pixels
defaults write com.apple.dock tilesize -int 36

# Don"t automatically rearrange Spaces based on most recent use
defaults write com.apple.dock mru-spaces -bool false

# Automatically hide and show the Dock
defaults write com.apple.dock autohide -bool true

# Don"t show recent applications in Dock
defaults write com.apple.dock show-recents -bool false

# Minimize apps to app icon
defaults write com.apple.dock minimize-to-application -bool true

# Magnify apps on hover
defaults write com.apple.dock magnification -bool true

# Enable Safari's debug menu
defaults write .GlobalPreferences WebkitDeveloperExtras -bool true

# Enable the Develop menu and the Web Inspector in Safari
defaults write com.apple.Safari IncludeDevelopMenu -bool true
defaults write com.apple.Safari WebKitDeveloperExtrasEnabledPreferenceKey -bool true
defaults write com.apple.Safari com.apple.Safari.ContentPageGroupIdentifier.WebKit2DeveloperExtrasEnabled -bool true

# Prevent Time Machine from prompting to use new hard drives as backup volume
defaults write com.apple.TimeMachine DoNotOfferNewDisksForBackup -bool true

# Check for software updates daily, not just once per week
defaults write com.apple.SoftwareUpdate ScheduleFrequency -int 1

# Download newly available updates in background
defaults write com.apple.SoftwareUpdate AutomaticDownload -int 1

# Turn on app auto-update
defaults write com.apple.commerce AutoUpdate -bool true

if [ ! -d "$HOME/bin/depot_tools" ]; then
    ### Setup Depot Tools
    echo "Installing depot tools"
    git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git "$HOME/bin/depot_tools"
fi

if [ ! -f "$HOME/.iterm2_shell_integration.fish" ]; then
    http --output "$HOME/.iterm2_shell_integration.fish" https://iterm2.com/shell_integration/fish
fi

COMPLETION_DIR="$HOME/.config/fish/completions"
mkdir -p "$COMPLETION_DIR"

if [ ! -f "$COMPLETION_DIR/git-flow.fish" ]; then
    http --output "$COMPLETION_DIR/git-flow.fish" https://raw.githubusercontent.com/bobthecow/git-flow-completion/master/git.fish
fi

FISH_CONFIG_FILE="$HOME/.config/fish/config.fish"

if [ ! -f "$FISH_CONFIG_FILE" ]; then
    ln -s "$dotfilePath/config/fish/config.fish" "$FISH_CONFIG_FILE"
fi

NVIM_CONFIG_FILE="$HOME/.config/nvim/init.vim"

if [ ! -f "$NVIM_CONFIG_FILE" ]; then
    mkdir -p dirname $NVIM_CONFIG_FILE
    ln -s "$dotfilePath/config/nvim/init.vim" "$NVIM_CONFIG_FILE"
fi

echo "Installing pynvim for neovim plugins"
python3 -m pip install --user --upgrade pynvim

# Cleanup
echo "Cleaning up"
rm -rf "$tempDir"
