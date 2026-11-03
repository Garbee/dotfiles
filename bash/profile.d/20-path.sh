# Per-user bin directories ahead of everything else, then drop duplicates.

# Move DIR to the front of PATH (adding it if missing, ignoring it if it
# doesn't exist). Moving rather than skipping matters on macOS: the
# /etc/profile path_helper puts system directories first again in every
# nested login shell.
__path_prepend() {
  [[ -d "$1" ]] || return 0
  local p=":$PATH:"
  p="${p//:"$1":/:}"
  p="${p#:}"
  PATH="$1${p:+:${p%:}}"
}

# pnpm's standalone installer (install-macos.sh) puts pnpm in $PNPM_HOME/bin,
# and `pnpm add -g` puts global packages' commands there too. pnpm reads
# PNPM_HOME to find its home, so export it.
export PNPM_HOME="${PNPM_HOME:-$HOME/Library/pnpm}"
__path_prepend "$PNPM_HOME/bin"

# Native installers (Claude Code, Codex) put their binaries here.
__path_prepend "$HOME/.local/bin"

# Keep the first occurrence of each directory. path_helper re-appends the
# inherited PATH in nested login shells, which leaves repeats at the end.
__path_dedupe() {
  local dir out=":"
  local -a dirs
  IFS=: read -r -a dirs <<<"$PATH"
  for dir in ${dirs[@]+"${dirs[@]}"}; do
    [[ -n "$dir" ]] && [[ "$out" != *":$dir:"* ]] && out="$out$dir:"
  done
  out="${out#:}"
  PATH="${out%:}"
}
__path_dedupe

unset -f __path_prepend __path_dedupe
export PATH
