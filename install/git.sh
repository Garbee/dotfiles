# shellcheck shell=bash
#
# Global git config: symlink git/config to ~/.config/git/config, put this
# machine's SSH signing key (a Secretive public key) in the untracked
# ~/.config/git/config.local, and trust it in ~/.config/git/allowed_signers.
#
# Sourced by install-macos.sh; not meant to be run on its own.

GIT_CONFIG_DIR="$HOME/.config/git"
GIT_CONFIG_LOCAL="$GIT_CONFIG_DIR/config.local"
# Written when no key is given yet. Signing fails until it is replaced, and
# re-running this script asks for the key again.
GIT_SIGNINGKEY_PLACEHOLDER="key::REPLACE-WITH-SECRETIVE-PUBLIC-KEY"
# Keys trusted when verifying signatures (gpg.ssh.allowedSignersFile in
# git/config). Untracked; this script adds this machine's signing key to it.
GIT_ALLOWED_SIGNERS="$GIT_CONFIG_DIR/allowed_signers"
SECRETIVE_APP="/Applications/Secretive.app"

link_git_config() {
  log "Git config"

  if [[ ! -e "$GIT_CONFIG_DIR" ]]; then
    if ((DRY_RUN)); then
      note "[dry-run] mkdir -p ~/.config/git"
    else
      mkdir -p "$GIT_CONFIG_DIR"
    fi
  elif [[ ! -d "$GIT_CONFIG_DIR" ]]; then
    note "~/.config/git exists but is not a directory; leaving it alone."
    SKIPPED+=("Git config (~/.config/git is not a directory)")
    return 0
  fi

  if ! link_file "Git config" "$DOTFILES/git/config" "$GIT_CONFIG_DIR/config"; then
    note "Its settings can move to ~/.config/git/config.local, which the"
    note "tracked config includes last (so they still take precedence)."
  fi
}

# Read a Secretive public key from the user. Prints the key, or nothing if
# they pressed Enter without one. Messages go to stderr, since the output is
# captured.
read_signing_key() {
  local key
  # "<type> <base64> [comment]". In a variable: quoting inside [[ =~ ]]
  # differs between bash versions.
  local pattern='^(ssh-[a-z0-9-]+|ecdsa-sha2-nistp[0-9]+|sk-[a-z0-9@.-]+) [A-Za-z0-9+/]+=*( .*)?$'
  note "Create a signing key in Secretive (e.g. named \"git signing\"), then copy" >&2
  note "its public key (it starts with ecdsa-sha2-nistp256) and paste it here." >&2
  while :; do
    read -r -p "    Public key (Enter to skip): " key
    # Trim surrounding whitespace.
    key="${key#"${key%%[![:space:]]*}"}"
    key="${key%"${key##*[![:space:]]}"}"
    key="${key#key::}"
    if [[ -z "$key" ]]; then
      return 0
    fi
    if [[ "$key" =~ $pattern ]]; then
      printf '%s\n' "$key"
      return 0
    fi
    note "That doesn't look like an SSH public key; try again." >&2
  done
}

# Trust KEY (a public key: "<type> <base64> [comment]") for the user.email in
# git/config, so git can verify this machine's own signatures. Appends a line
# to the allowed signers file unless one with the same key is already there.
#
#   add_allowed_signer KEY
add_allowed_signer() {
  local label="Git allowed signer" key_type key_data email line
  read -r key_type key_data _ <<<"$1"
  email="$(git config --file "$DOTFILES/git/config" --get user.email)"
  line="$email namespaces=\"git\" $key_type $key_data"

  if [[ -L "$GIT_ALLOWED_SIGNERS" ]] ||
    { [[ -e "$GIT_ALLOWED_SIGNERS" ]] && [[ ! -f "$GIT_ALLOWED_SIGNERS" ]]; }; then
    note "~/.config/git/allowed_signers is not a regular file; leaving it alone."
    SKIPPED+=("$label (~/.config/git/allowed_signers is not a regular file)")
    return 0
  fi

  # Any uncommented line with this key, whatever its principals.
  if [[ -f "$GIT_ALLOWED_SIGNERS" ]] &&
    grep -v '^[[:space:]]*#' "$GIT_ALLOWED_SIGNERS" | grep -qF -- "$key_type $key_data"; then
    note "Signing key already trusted in ~/.config/git/allowed_signers"
    PRESENT+=("$label")
    return 0
  fi

  if ((DRY_RUN)); then
    note "[dry-run] append to ~/.config/git/allowed_signers: $line"
  else
    printf '%s\n' "$line" >>"$GIT_ALLOWED_SIGNERS"
    note "Trusted the signing key for $email in ~/.config/git/allowed_signers"
  fi
  DONE+=("$label ($email)")
}

# The user.signingkey currently in ~/.config/git/config.local (empty if none).
# Fails if config.local is not a regular file.
git_signing_key_current() {
  if [[ -L "$GIT_CONFIG_LOCAL" ]] || { [[ -e "$GIT_CONFIG_LOCAL" ]] && [[ ! -f "$GIT_CONFIG_LOCAL" ]]; }; then
    return 1
  fi
  if [[ -f "$GIT_CONFIG_LOCAL" ]]; then
    git config --file "$GIT_CONFIG_LOCAL" --get user.signingkey || true
  fi
}

# The key pasted by ask_git_signing_key, and whether it asked at all.
GIT_SIGNING_KEY_INPUT=""
GIT_SIGNING_KEY_ASKED=0

# Ask for the Secretive public key, if one is still needed, early in the run
# (right after the Homebrew packages, which include Secretive), so the rest of
# the run doesn't stop to wait for it. Opens Secretive to create the key in.
# configure_git_signing_key uses the answer.
ask_git_signing_key() {
  local current

  current="$(git_signing_key_current)" || return 0
  if [[ -n "$current" ]] && [[ "$current" != "$GIT_SIGNINGKEY_PLACEHOLDER" ]]; then
    return 0
  fi
  ((DRY_RUN)) && return 0
  [[ -t 0 ]] || return 0

  log "Git signing key"
  if [[ -d "$SECRETIVE_APP" ]]; then
    open "$SECRETIVE_APP" || true
  else
    note "$SECRETIVE_APP not found; paste a key from another source, or press"
    note "Enter to skip and re-run this script later."
  fi
  GIT_SIGNING_KEY_INPUT="$(read_signing_key)"
  GIT_SIGNING_KEY_ASKED=1
}

configure_git_signing_key() {
  local label="Git signing key" current key

  log "$label"

  if ! current="$(git_signing_key_current)"; then
    note "~/.config/git/config.local is not a regular file; leaving it alone."
    SKIPPED+=("$label (~/.config/git/config.local is not a regular file)")
    return 0
  fi
  if [[ -n "$current" ]] && [[ "$current" != "$GIT_SIGNINGKEY_PLACEHOLDER" ]]; then
    note "Already set in ~/.config/git/config.local"
    PRESENT+=("$label")
    if [[ "$current" == key::* ]]; then
      add_allowed_signer "${current#key::}"
    else
      # A path to a key file rather than the key itself.
      note "user.signingkey is not an inline key; add it to"
      note "~/.config/git/allowed_signers yourself to verify your own signatures."
      SKIPPED+=("Git allowed signer (user.signingkey is not an inline key)")
    fi
    return 0
  fi
  [[ -n "$current" ]] && note "~/.config/git/config.local still has the placeholder key."

  if ((DRY_RUN)); then
    note "[dry-run] would ask for a Secretive public key (after the Homebrew packages)"
    note "[dry-run] and set user.signingkey in ~/.config/git/config.local (or a"
    note "[dry-run] placeholder if none is given), and trust it in"
    note "[dry-run] ~/.config/git/allowed_signers"
    DONE+=("$label")
    return 0
  fi

  key="$GIT_SIGNING_KEY_INPUT"
  if [[ -n "$key" ]]; then
    git config --file "$GIT_CONFIG_LOCAL" user.signingkey "key::$key"
    note "Set user.signingkey in ~/.config/git/config.local"
    DONE+=("$label")
    add_allowed_signer "$key"
    return 0
  fi

  ((GIT_SIGNING_KEY_ASKED)) || note "Not running interactively; couldn't ask for the key."
  if [[ -n "$current" ]]; then
    note "Leaving the placeholder; re-run this script to add the key."
  else
    git config --file "$GIT_CONFIG_LOCAL" user.signingkey "$GIT_SIGNINGKEY_PLACEHOLDER"
    note "Left a placeholder in ~/.config/git/config.local. Commits and tags will"
    note "fail to sign until user.signingkey is set to \"key::<public key>\""
    note "there (or this script is re-run)."
  fi
  SKIPPED+=("$label (placeholder in ~/.config/git/config.local)")
}
