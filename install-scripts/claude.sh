#!/usr/bin/env zsh

# Configure Claude Code global settings. Safe to re-run; merges into
# any existing ~/.claude/settings.json rather than overwriting it.
#
# In a Linux container, this should be written to `/etc/claude-code/
# so it is system-wide rather than user-specific.

if ! command -v jq &>/dev/null; then
    echo "jq is required to configure Claude Code settings" >&2
    exit 1
fi

settingsDir="$HOME/.claude"
settingsFile="$settingsDir/settings.json"

mkdir -p "$settingsDir"

if [ ! -s "$settingsFile" ]; then
    echo '{}' >"$settingsFile"
fi

# Empty attribution strings remove the Co-Authored-By commit trailer and
# the "Generated with Claude Code" line in PR bodies.
#
# DISABLE_AUTOUPDATER stops background update checks; `claude update`
# still works when run manually.
#
# permissions.allow pre-approves read-only commands so they stop
# prompting. Entries here are unioned with any the user has already
# saved via "don't ask again".
desired=$(cat <<'EOF'
{
  "$schema": "https://json.schemastore.org/claude-code-settings.json",
  "attribution": { "commit": "", "pr": "" },
  "env": { "DISABLE_AUTOUPDATER": "1" },
  "permissions": {
    "allow": [
      "Bash(git status:*)",
      "Bash(git log:*)",
      "Bash(git diff:*)",
      "Bash(git show:*)",
      "Bash(git blame:*)",
      "Bash(git branch:*)",
      "Bash(git remote -v)",
      "Bash(ls:*)",
      "Bash(cat:*)",
      "Bash(head:*)",
      "Bash(tail:*)",
      "Bash(grep:*)",
      "Bash(rg:*)",
      "Bash(ag:*)",
      "Bash(bat:*)",
      "Bash(eza:*)",
      "Bash(fzf:*)",
      "Bash(prettyping:*)",
      "Bash(pstree:*)",
      "Bash(sort:*)",
      "Bash(uniq:*)",
      "Bash(cut:*)",
      "Bash(tr:*)",
      "Bash(nl:*)",
      "Bash(seq:*)",
      "Bash(stat:*)",
      "Bash(file:*)",
      "Bash(du:*)",
      "Bash(df:*)",
      "Bash(date:*)",
      "Bash(realpath:*)",
      "Bash(readlink:*)",
      "Bash(basename:*)",
      "Bash(dirname:*)",
      "Bash(wc:*)",
      "Bash(which:*)",
      "Bash(jq:*)",
      "Bash(brew list:*)",
      "Bash(brew info:*)",
      "Bash(brew search:*)"
    ]
  }
}
EOF
)

updatedSettings=$(jq --argjson desired "$desired" '
    (($desired.permissions.allow + (.permissions.allow // [])) | unique) as $allow
    | . * $desired
    | .permissions.allow = $allow
' "$settingsFile")
printf '%s\n' "$updatedSettings" >"$settingsFile"
