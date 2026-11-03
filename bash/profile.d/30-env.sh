# General environment variables.

export LANG="${LANG:-en_US.UTF-8}"

# Editor for git commits, crontab, `fc`, etc. Neovim (installed by
# install-macos.sh); fall back to vi if it's missing.
if command -v nvim >/dev/null 2>&1; then
  export EDITOR="nvim"
else
  export EDITOR="vi"
fi
export VISUAL="$EDITOR"

# Silence the "default interactive shell is now zsh" notice if the system
# /bin/bash is ever started.
export BASH_SILENCE_DEPRECATION_WARNING=1

# Use Secretive's agent (keys in the Secure Enclave) for everything that talks
# to an SSH agent directly, such as git's SSH commit signing. ssh itself
# already uses it via IdentityAgent in ssh/config.
if [[ -d /Applications/Secretive.app ]]; then
  export SSH_AUTH_SOCK="$HOME/Library/Containers/com.maxgoedjen.Secretive.SecretAgent/Data/socket.ssh"
fi
