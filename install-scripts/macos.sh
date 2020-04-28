#!/bin/zsh
# Make ZSH not care about end of line comments when running the script
setopt interactive_comments

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
            Y*|y*) return 0 ;;
            N*|n*) return 1 ;;
        esac

    done
}

casksToInstall=(
    "1password-beta"
    "font-iosevka"
    "font-iosevka-slab"
    "font-input"
    "jetbrains-toolbox"
    "google-chrome"
    "google-chrome-canary"
    "dash"
    "kaleidoscope"
    "dash"
    "fork"
    "iterm2"
    "alfred"
    "discord"
    "paw"
    "airparrot"
    "forklift"
    "mission-control-plus"
    "itsycal"
    "fsmonitor"
    "soundsource"
    "focusatwill"
)

if ask "Do you want to install Parallels? (You will need to be present to provide the password for install)"; then
    casksToInstall+=("parallels")
fi

if ask "Do you want to install Steam?"; then
    casksToInstall+=("steam")
fi

if ask "Do you want to install Open Broadcast Studio?"; then
    casksToInstall+=("obs")
fi

vared -p 'What global name would you like to use for git?: ' -c gitName
vared -p 'What global email would you like to use for git?: ' -c gitEmail

# Make temp folder for holding some files
tempDir=$(mktemp -d)

# Configure global settings
echo "Configuring Global Settings"

## Install color schemes for Apple Color Picker
curl -L -o ~/Library/Colors/Nord.clr https://raw.githubusercontent.com/arcticicestudio/nord/develop/src/swatches/Nord.clr

# Enable AirDrop over Ethernet and on Unsupported Macs
defaults write com.apple.NetworkBrowser BrowseAllInterfaces -bool true

# Show the path bar
defaults write com.apple.finder ShowPathbar -bool true
# Show the status bar
defaults write com.apple.finder ShowStatusBar -bool true
# Show user library folder
chflags nohidden ~/Library

# Enable developer options in Safari
defaults write com.apple.Safari IncludeInternalDebugMenu -bool true && \
defaults write com.apple.Safari IncludeDevelopMenu -bool true && \
defaults write com.apple.Safari WebKitDeveloperExtrasEnabledPreferenceKey -bool true && \
defaults write com.apple.Safari com.apple.Safari.ContentPageGroupIdentifier.WebKit2DeveloperExtrasEnabled -bool true && \
defaults write -g WebKitDeveloperExtras -bool true

# Global preference modifications

## Keyboard
defaults write -g NSAutomaticSpellingCorrectionEnabled -bool false
defaults write -g NSAutomaticCapitalizationEnabled -bool false
defaults write -g NSAutomaticPeriodSubstitutionEnabled -bool false

## Help 1Password Native integration with Canary
mkdir -p $HOME/Library/Application Support/Google/Chrome/

## Misc
mkdir -p $HOME/Code
mkdir -p $HOME/bin

# Install Homebrew
if ! which brew &> /dev/null; then
	/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
fi

# Install brewed software
echo "Installing homebrew software"

brew tap homebrew/cask
brew tap homebrew/cask-versions
brew tap homebrew/cask-fonts

formulaeToInstall=(
	"node"
	"yarn"
	"coreutils"
	"git"
	"mas"
	"fish"
)

for target in $formulaeToInstall; do
	brew list $target &> /dev/null || brew install $target
done

for target in $casksToInstall; do
	brew cask list $target &> /dev/null || brew cask install $target
done

# Install AppStore Content

appStoreApps=()

appStoreApps+=("1024640650") # CotEditor
appStoreApps+=("1157491961") # PLIST Editor
appStoreApps+=("567740330") # JSON Editor
appStoreApps+=("441258766") # Magnet
appStoreApps+=("639968404") # Parcel
appStoreApps+=("1435957248") # Drafts
appStoreApps+=("1195426709") # Sequence Diagram
appStoreApps+=("1399498094") # WebSocket Client
appStoreApps+=("470158793") # Keka
appStoreApps+=("1006087419") # SnippetsLab
appStoreApps+=("918858936") # Airmail
appStoreApps+=("1233861775") # Acorn
appStoreApps+=("1224268771") # Screens
appStoreApps+=("979299240") # Network Kit X
appStoreApps+=("411643860") # DaisyDisk
appStoreApps+=("409203825") # Numbers
appStoreApps+=("409201541") # Pages
appStoreApps+=("409183694") # Keynote

for appId in $appStoreApps; do
    mas install "$appId"
done

## Configurations

### Git
echo "Configuring git"
git config --global user.name "$gitName"
git config --global user.email "$gitEmail"
git config --global core.autocrlf false
git config --global core.filemode false
git config --global color.ui true

### Fish Shell
echo "Configuring Fish Shell"
echo $(which fish) | sudo tee -a /etc/shells
chsh -s $(which fish)

### Itsycal
echo "Configuring Itsycal"
defaults write -app Itsycal HideIcon -bool true
defaults write -app Itsycal SizePreference -bool true
defaults write -app Itsycal ClockFormat "hh:mm:ss a - EEE, MMM dd yyyy"
# attempt to set to auto-launch on login. Doesn"t work. To debug.
# defaults write loginwindow AutoLaunchedApplicationDictionary -array-add "{ "Path" = "/Applications/Itsycal.app"; "Hide" = 0; }"

### iTerm
echo "Configuring iTerm"
defaults write com.googlecode.iterm2.plist PrefsCustomFolder -string "~/.dotfiles/iterm2"
defaults write com.googlecode.iterm2.plist LoadPrefsFromCustomFolder -bool true

### Setup CotEdtior
echo "Configuring CotEditor"
defaults write -app CotEditor fontName "Iosevka"
defaults write -app CotEditor fontSize 14
defaults write -app CotEditor lineHeight 1.5
defaults write -app CotEditor highlightCurrentLine -bool true

### Setup Depot Tools
echo "Installing depot tools"
git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git $HOME/bin/depot_tools


# Cleanup
echo "Cleaning up"
rm -rf $tempDir

# Install XCode
echo "Installing XCode"
mas install 497799835
