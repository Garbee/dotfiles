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

# Rosetta is installed if an x86_64 binary can run
if ! arch -x86_64 /usr/bin/true 2>/dev/null; then
    if ask "Do you want to install Rosetta 2?" Y; then
        softwareupdate --install-rosetta
    fi
fi

installUnifiIdentityEndpoint=false
if ask "Do you want to install UniFi Identity Endpoint?" N; then
    installUnifiIdentityEndpoint=true
fi

installOrbstack=false
if ask "Do you want to install OrbStack?" N; then
    installOrbstack=true
fi

installSecretive=false
if ask "Do you want to install Secretive?" Y; then
    installSecretive=true
fi

# Make temp folder for holding some files
tempDir=$(mktemp -d)

# Configure global settings
echo "Configuring Global Settings"

# Turn off window tinting based on wallpaper
defaults write .GlobalPreferences AppleReduceDesktopTinting -bool true

## Install color schemes for Apple Color Picker
if [ ! -f "$HOME/Library/Colors/Nord.clr" ]; then
    mkdir -p "$HOME/Library/Colors"
    curl -fsSL -o "$HOME/Library/Colors/Nord.clr" https://raw.githubusercontent.com/arcticicestudio/nord/develop/src/swatches/Nord.clr
fi

# Menu bar clock: seconds, AM/PM, day of week; date only when space allows
defaults write com.apple.menuextra.clock ShowSeconds -bool true
defaults write com.apple.menuextra.clock ShowAMPM -bool true
defaults write com.apple.menuextra.clock ShowDayOfWeek -bool true
defaults write com.apple.menuextra.clock ShowDate -int 0

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
defaults write NSGlobalDomain AppleKeyboardUIMode -int 2

# Show all file extensions
defaults write NSGlobalDomain AppleShowAllExtensions -bool true

# Dark mode (best-effort via defaults; fully applies after next login)
defaults write NSGlobalDomain AppleInterfaceStyle -string "Dark"
defaults write NSGlobalDomain AppleIconAppearanceTheme -string "RegularDark"

# Dock
defaults write com.apple.dock autohide -bool true
defaults write com.apple.dock magnification -bool true
defaults write com.apple.dock largesize -int 128
defaults write com.apple.dock tilesize -int 36
defaults write com.apple.dock minimize-to-application -bool true
defaults write com.apple.dock show-recents -bool false
# Disable bottom-right Quick Note hot corner
defaults write com.apple.dock wvous-br-corner -int 1

# Trackpad (settings mirrored to built-in and Bluetooth domains;
# fully apply after next login)
defaults write -g com.apple.trackpad.scaling -float 1
defaults write -g com.apple.trackpad.forceClick -bool true
for trackpadDomain in com.apple.AppleMultitouchTrackpad com.apple.driver.AppleBluetoothMultitouch.trackpad; do
    # Tap to click off, medium click firmness, force click on
    defaults write $trackpadDomain Clicking -bool false
    defaults write $trackpadDomain FirstClickThreshold -int 1
    defaults write $trackpadDomain SecondClickThreshold -int 1
    defaults write $trackpadDomain ForceSuppressed -bool false
    # Secondary click with two fingers, not corner click
    defaults write $trackpadDomain TrackpadRightClick -bool true
    defaults write $trackpadDomain TrackpadCornerSecondaryClick -int 0
    # Disable look up on three-finger tap and three-finger drag
    defaults write $trackpadDomain TrackpadThreeFingerTapGesture -int 0
    defaults write $trackpadDomain TrackpadThreeFingerDrag -bool false
    # Scroll and zoom gestures
    defaults write $trackpadDomain TrackpadScroll -bool true
    defaults write $trackpadDomain TrackpadHorizScroll -bool true
    defaults write $trackpadDomain TrackpadMomentumScroll -bool true
    defaults write $trackpadDomain TrackpadPinch -bool true
    defaults write $trackpadDomain TrackpadRotate -bool true
    defaults write $trackpadDomain TrackpadTwoFingerDoubleTapGesture -bool true
    # Mission Control, full-screen swipes, Launchpad, and Notification Center gestures
    defaults write $trackpadDomain TrackpadThreeFingerHorizSwipeGesture -int 2
    defaults write $trackpadDomain TrackpadThreeFingerVertSwipeGesture -int 2
    defaults write $trackpadDomain TrackpadFourFingerHorizSwipeGesture -int 2
    defaults write $trackpadDomain TrackpadFourFingerVertSwipeGesture -int 2
    defaults write $trackpadDomain TrackpadFourFingerPinchGesture -int 2
    defaults write $trackpadDomain TrackpadFiveFingerPinchGesture -int 2
    defaults write $trackpadDomain TrackpadTwoFingerFromRightEdgeSwipeGesture -int 3
done

# Finder prefs
chflags nohidden ~/Library
# The xattr may already be gone, which xattr -d treats as an error
xattr -d com.apple.FinderInfo ~/Library 2>/dev/null || true
sudo chflags nohidden /Volumes

# Show hidden files
defaults write com.apple.finder AppleShowAllFiles -bool true
defaults write com.apple.finder ShowPathbar -bool true
defaults write com.apple.finder ShowStatusBar -bool true
# Default to column view
defaults write com.apple.finder FXPreferredViewStyle -string "clmv"
# Auto-empty trash after 30 days
defaults write com.apple.finder FXRemoveOldTrashItems -bool true
# New windows open in Home
defaults write com.apple.finder NewWindowTarget -string "PfHm"
defaults write com.apple.finder ShowExternalHardDrivesOnDesktop -bool false
# Disable floating/Liquid Glass sidebar appearance
defaults write -g NSSplitViewItemSidebarDefaultsToFloatingAppearance -bool false
defaults write -g NSConvolutionOverride1 -float 10
# Keep folders on top when sorting by name
defaults write com.apple.finder _FXSortFoldersFirst -bool true
# Disable extension change warning
defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false
# Disable emoji picker from keyboard
defaults write com.apple.HIToolbox AppleFnUsageType -int "0"

# Save screenshots to ~/Pictures/Screenshots
mkdir -p "$HOME/Pictures/Screenshots"
defaults write com.apple.screencapture location -string "$HOME/Pictures/Screenshots"

# Restart affected apps so settings take effect
killall Dock 2>/dev/null || true
killall Finder 2>/dev/null || true
killall ControlCenter 2>/dev/null || true
killall SystemUIServer 2>/dev/null || true

## Misc
if [[ ! -d "$HOME/Developer" ]]; then
    mkdir -p "$HOME/Developer"
fi

if [[ ! -d "$HOME/bin" ]]; then
    mkdir -p "$HOME/bin"
fi

if [[ ! -d "$HOME/.ssh" ]]; then
    mkdir -p "$HOME/.ssh"
fi

# Install Homebrew
if ! command -v brew &>/dev/null; then
    NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

if ! grep -qsF 'eval $(/opt/homebrew/bin/brew shellenv)' "$HOME/.zprofile"; then
    echo 'eval $(/opt/homebrew/bin/brew shellenv)' >>"$HOME/.zprofile"
fi

eval $(/opt/homebrew/bin/brew shellenv)

if ! brew list mas &>/dev/null; then
    brew install mas
fi

if ! ask "Are you logged into the App Store?"; then
    echo "Must be logged into App Store to complete installation."
    exit 1
fi

echo "Installing homebrew software"

source "$dotfilePath/install-scripts/formulae.sh"

formulaeToInstall=("${crossPlatformFormulae[@]}" "${macosOnlyFormulae[@]}")

if [ "$installSecretive" = true ]; then
    formulaeToInstall+=("secretive") # SSH keys in Secure Enclave
fi

if [ "$installUnifiIdentityEndpoint" = true ]; then
    formulaeToInstall+=("unifi-identity-endpoint")
fi

if [ "$installOrbstack" = true ]; then
    formulaeToInstall+=("orbstack")
fi

for target in $formulaeToInstall; do
    if ! brew list $target &>/dev/null; then
        echo "Installing $target"
        brew install --quiet $target
    fi
done

curl -fsSL https://claude.ai/install.sh | bash

echo "Configuring Claude Code"
"$dotfilePath/install-scripts/claude.sh"

# Wins window manager (settings pane lives in System Settings > Wins,
# stored in the cools.wins.main defaults domain). Written before first
# launch so the app picks them up. launchOnLogin still requires one
# manual launch for the app to register its login item.
echo "Configuring Wins"
defaults write cools.wins.main launchOnLogin -bool true
defaults write cools.wins.main respectStageManager -bool true
# Snapping
defaults write cools.wins.main edgeSnap -bool true
defaults write cools.wins.main showSplitWindow -bool true
defaults write cools.wins.main snapMarginEnable -bool false
defaults write cools.wins.main gapSize -int 0
defaults write cools.wins.main centerStatus -bool true
# Dock previews and flick gestures
defaults write cools.wins.main enableDockPreview -bool true
defaults write cools.wins.main enableFlickDock -bool true
# Window hiding
defaults write cools.wins.main enableShakeHiddenWindows -bool true
defaults write cools.wins.main hiddenAllWindowStatus -bool true
defaults write cools.wins.main hiddenOtherWindowsStatus -bool true
# Command-Tab Plus and Mission Control Pro
defaults write cools.wins.main commandTabPlus -bool true
defaults write cools.wins.main missionControlProStatus -bool true
defaults write cools.wins.main missionControlProClosesWindowStatus -bool false
defaults write cools.wins.main missionControlProQuitAppStatus -bool false
# Move window between displays
defaults write cools.wins.main nextDisplayStatus -bool true
defaults write cools.wins.main prevDisplayStatus -bool true

# Install AppStore Content

appStoreApps=()

# Safari Plugins
appStoreApps+=("1365531024") # 1Blocker
appStoreApps+=("1622835804") # Kagi

# Media
appStoreApps+=("1346247457") # Endel
appStoreApps+=("1436994560") # Portal

# Utilities
appStoreApps+=("1352778147") # Bitwarden
appStoreApps+=("1508732804") # Soulver
appStoreApps+=("1452453066") # Hidden Bar
appStoreApps+=("470158793")  # Keka
appStoreApps+=("411643860")  # DaisyDisk
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
appStoreApps+=("890031187")  # Marked 2
appStoreApps+=("1663047912") # Screens 5
appStoreApps+=("1522267256") # Shareful

installedAppIds=$(mas list | awk '{print $1}')

for appId in $appStoreApps; do
    if ! echo "$installedAppIds" | grep -qx "$appId"; then
        mas install "$appId"
    fi
done

## Configurations

# Test -L along with -e so a broken symlink is not treated as missing
if [ ! -e "$HOME/.gitconfig" ] && [ ! -L "$HOME/.gitconfig" ]; then
    ### Git
    echo "Configuring git"
    ln -s "$HOME/.dotfiles/git/gitconfig" "$HOME/.gitconfig"
fi

if [ ! -e "$HOME/.ssh/config" ] && [ ! -L "$HOME/.ssh/config" ]; then
    echo "Linking SSH Config"
    mkdir -p "$HOME/.ssh"
    ln -s "$HOME/.dotfiles/ssh/config" "$HOME/.ssh/config"
fi

if [ ! -e "$HOME/.zshrc" ] && [ ! -L "$HOME/.zshrc" ]; then
    echo "Linking ZSH Config"
    ln -s "$HOME/.dotfiles/config/zshrc" "$HOME/.zshrc"
fi

if [ ! -e "$HOME/.zshenv" ] && [ ! -L "$HOME/.zshenv" ]; then
    echo "Linking ZSH Env"
    ln -s "$HOME/.dotfiles/config/zshenv" "$HOME/.zshenv"
fi

if [ ! -e "$HOME/.tmux.conf" ] && [ ! -L "$HOME/.tmux.conf" ]; then
    echo "Linking tmux Config"
    ln -s "$HOME/.dotfiles/config/tmux.conf" "$HOME/.tmux.conf"
fi

if [ ! -e "$HOME/.config/nvim/init.lua" ] && [ ! -L "$HOME/.config/nvim/init.lua" ]; then
    echo "Linking Neovim Config"
    mkdir -p "$HOME/.config/nvim"
    ln -s "$HOME/.dotfiles/config/nvim/init.lua" "$HOME/.config/nvim/init.lua"
fi

if [ ! -e "$HOME/.config/ghostty/config" ] && [ ! -L "$HOME/.config/ghostty/config" ]; then
    echo "Linking Ghostty Config"
    mkdir -p "$HOME/.config/ghostty"
    ln -s "$HOME/.dotfiles/config/ghostty/config" "$HOME/.config/ghostty/config"
fi

if [ ! -e "$HOME/.config/hunk/config.toml" ] && [ ! -L "$HOME/.config/hunk/config.toml" ]; then
    echo "Linking Hunk Config"
    mkdir -p "$HOME/.config/hunk"
    ln -s "$HOME/.dotfiles/config/hunk/config.toml" "$HOME/.config/hunk/config.toml"
fi

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
   * Terminal
   * Ghostty
   * Zed
* App Management
   * Terminal
   * Ghostty
* Accessibility
   * Wins
* Screen & System Audio Recording
   * Wins (needed for Dock previews)

Then launch Wins once so it registers its login item.
EOF

if ask "Do you want to open the Privacy and Security system preferences now?"; then
    open "x-apple.systempreferences:com.apple.preference.security?Privacy_All"
fi
