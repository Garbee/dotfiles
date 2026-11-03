# shellcheck shell=bash
#
# Claude Code: install and settings.
#
# Sourced by install-macos.sh; not meant to be run on its own.

install_claude_code() {
  log "Claude Code"

  local claude_bin="$HOME/.local/bin/claude"
  local existing
  if existing="$(command -v claude 2>/dev/null)" || {
    [[ -x "$claude_bin" ]] && existing="$claude_bin"
  }; then
    note "Already installed at $existing"
    PRESENT+=("Claude Code")
    return 0
  fi

  if ((DRY_RUN)); then
    note "[dry-run] run the official Claude Code installer (installs to $claude_bin)"
    DONE+=("Claude Code")
    return 0
  fi

  note "Running the official Claude Code installer."
  /bin/bash -c "$(curl -fsSL https://claude.ai/install.sh)"
  DONE+=("Claude Code")

  case ":$PATH:" in
    *":$HOME/.local/bin:"*) ;;
    *) note "Note: $HOME/.local/bin is not on your PATH; add it to use 'claude'." ;;
  esac
}

configure_claude_code() {
  log "Claude Code settings"

  if pgrep -qx claude 2>/dev/null; then
    note "Warning: Claude Code is running. It rewrites ~/.claude.json and may"
    note "undo the trust setting below; quit it and re-run if that happens."
  fi

  local settings="$HOME/.claude/settings.json"

  # Start every session as if launched with --dangerously-skip-permissions,
  # and don't show the "are you sure" prompt for bypass mode each time.
  json_set "$settings" '["permissions", "defaultMode"]' '"bypassPermissions"'
  json_set "$settings" '["skipDangerousModePermissionPrompt"]' 'true'

  # No attribution in git commits or pull requests: no Co-Authored-By
  # trailer, no "Generated with Claude Code" line, no session link.
  json_set "$settings" '["attribution", "commit"]' '""'
  json_set "$settings" '["attribution", "pr"]' '""'
  json_set "$settings" '["attribution", "sessionUrl"]' 'false'

  # No background auto-updates; `claude update` still works when run by hand.
  json_set "$settings" '["env", "DISABLE_AUTOUPDATER"]' '"1"'

  # Trust the home folder so Claude Code doesn't ask when started there.
  # Claude Code records an untrusted folder as false, so that may be replaced.
  local home_real
  home_real="$(cd "$HOME" && pwd -P)"
  json_set "$HOME/.claude.json" \
    "[\"projects\", \"$home_real\", \"hasTrustDialogAccepted\"]" 'true' '[false]'
}
