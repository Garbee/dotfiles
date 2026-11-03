#!/bin/bash
#
# Exclude downloaded dependencies from Time Machine backups: every
# node_modules folder in the home folder, and Go's module cache. They can be
# downloaded again, and are often large and full of small files.
#
# An exclusion is stored on the folder itself, so it lasts until the folder is
# deleted; folders created since the last run are picked up by the next one.
# install-macos.sh installs a LaunchAgent that runs this at login and daily.
# Safe to run by hand at any time. Prints each folder it newly excludes.
#
# Runs under the system bash (3.2).

set -euo pipefail

# Exclude DIR unless it already is.
exclude() {
  local dir="$1"
  # Prints "[Excluded]    /path" or "[Included]    /path".
  if tmutil isexcluded "$dir" 2>/dev/null | grep -q '^\[Excluded\]'; then
    return 0
  fi
  if tmutil addexclusion "$dir"; then
    printf 'Excluded %s\n' "$dir"
  fi
}

# node_modules folders. -x stays on the home folder's volume (no network
# shares, external drives or OrbStack's Linux machines); ~/Library and the
# Trash are skipped. Once a node_modules is found, nothing inside it is
# searched: excluding it covers any nested ones. Folders that can't be read
# are skipped quietly.
while IFS= read -r -d '' dir; do
  exclude "$dir"
done < <(find -x "$HOME" \
  \( -path "$HOME/Library" -o -path "$HOME/.Trash" \) -prune -o \
  -type d -name node_modules -prune -print0 2>/dev/null || true)

# Go's module cache (downloaded modules): ask go where it is, since it can be
# moved with GOPATH, GOMODCACHE or `go env -w`; otherwise go's default. A
# LaunchAgent has a minimal PATH, so look for Homebrew's go directly.
gomodcache=""
for go in /opt/homebrew/bin/go "$(command -v go 2>/dev/null || true)"; do
  if [[ -n "$go" ]] && [[ -x "$go" ]]; then
    gomodcache="$("$go" env GOMODCACHE 2>/dev/null || true)"
    break
  fi
done
gomodcache="${gomodcache:-$HOME/go/pkg/mod}"
if [[ -d "$gomodcache" ]]; then
  exclude "$gomodcache"
fi
