# OrbStack (installed by install-macos.sh): its init script adds ~/.orbstack/bin
# (docker, kubectl, orb, orbctl) to PATH. OrbStack appended this line to
# ~/.bash_profile when it first started; it lives here instead. It runs before
# 20-path.sh, which drops the PATH entry this repeats in nested login shells.
if [[ -r "$HOME/.orbstack/shell/init.bash" ]]; then
  . "$HOME/.orbstack/shell/init.bash"
fi
