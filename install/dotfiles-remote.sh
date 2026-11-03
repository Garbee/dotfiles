# shellcheck shell=bash
#
# The dotfiles checkout's own remote. init.sh clones over HTTPS, since there
# is no SSH key on a new Mac yet; switch origin to SSH so pushes use the
# Secretive key (see ssh/config) instead of asking for a password or token.
#
# Sourced by install-macos.sh; not meant to be run on its own.

use_ssh_dotfiles_remote() {
  local label="Dotfiles remote over SSH" url path ssh_url

  log "$label"

  if ! url="$(git -C "$DOTFILES" remote get-url origin 2>/dev/null)"; then
    note "$DOTFILES has no origin remote; nothing to change."
    PRESENT+=("$label (no origin remote)")
    return 0
  fi

  case "$url" in
    https://github.com/*)
      path="${url#https://github.com/}"
      path="${path%/}"
      path="${path%.git}"
      ssh_url="git@github.com:$path.git"
      ;;
    *)
      note "origin is $url; not an HTTPS GitHub URL, so left as is."
      PRESENT+=("$label ($url)")
      return 0
      ;;
  esac

  run git -C "$DOTFILES" remote set-url origin "$ssh_url"
  note "origin: $url -> $ssh_url"
  DONE+=("$label ($ssh_url)")
}
