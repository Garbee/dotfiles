# shellcheck shell=bash
#
# Shared helpers: logging, dry-run, prompts, the run summary, symlinks and
# JSON edits. Bash 3.2 compatible, like everything in this directory.
#
# Sourced by install-macos.sh; not meant to be run on its own.

DONE=()    # changes made by this run
PRESENT=() # already in place
SKIPPED=() # not done (declined, conflict, or non-interactive)

log() { printf '\n==> %s\n' "$*"; }
note() { printf '    %s\n' "$*"; }

# Run a command, or just print it in dry-run mode.
run() {
  if ((DRY_RUN)); then
    note "[dry-run] $*"
  else
    "$@"
  fi
}

# Ask a yes/no question; defaults to no. Non-interactive runs answer no.
confirm() {
  if ((DRY_RUN)); then
    note "[dry-run] would ask: $1"
    return 0
  fi
  if [[ ! -t 0 ]]; then
    note "Not running interactively; skipping: $1"
    return 1
  fi
  local reply
  read -r -p "    $1 [y/N] " reply
  [[ "$reply" =~ ^[Yy]([Ee][Ss])?$ ]]
}

# Ask for the administrator password (unless sudo already has it), then keep
# sudo's cached credentials fresh in the background until this script exits,
# so later steps and long installers don't ask again. Call it after the user
# has agreed to a privileged step, right before its first sudo. Does nothing
# in dry-run mode, or if the keepalive is already running.
SUDO_KEEPALIVE_PID=""
sudo_keepalive() {
  ((DRY_RUN)) && return 0
  if [[ -n "$SUDO_KEEPALIVE_PID" ]] && kill -0 "$SUDO_KEEPALIVE_PID" 2>/dev/null; then
    return 0
  fi

  if ! sudo -v; then
    # The step's own sudo will ask again, and report if that fails too.
    note "Could not authenticate with sudo."
    return 0
  fi

  # Refresh the timestamp every minute (sudo's default timeout is 5), and
  # stop when this script is gone or sudo stops accepting the refresh.
  local parent=$$
  (
    while kill -0 "$parent" 2>/dev/null; do
      sleep 60
      sudo -n -v 2>/dev/null || exit 0
    done
  ) </dev/null >/dev/null 2>&1 &
  SUDO_KEEPALIVE_PID=$!
  trap 'kill "$SUDO_KEEPALIVE_PID" 2>/dev/null || true' EXIT
}

print_list() {
  local title="$1"
  shift
  (($# == 0)) && return 0
  printf '\n%s\n' "$title"
  printf '  - %s\n' "$@"
}

BREW_PREFIX="/opt/homebrew"
BREW="$BREW_PREFIX/bin/brew"
BREW_BASH="$BREW_PREFIX/bin/bash"
JQ="$BREW_PREFIX/bin/jq"
GH="$BREW_PREFIX/bin/gh"

# Symlink DEST to SRC (a file in this repository) unless something is already
# at DEST. A link that already points to SRC is left as is. Returns 1 if
# skipped because of a conflict (so call it in a condition under set -e).
#
#   link_file LABEL SRC DEST
link_file() {
  local label="$1" src="$2" dest="$3" tilde='~' shown
  shown="${dest//"$HOME"/$tilde}"

  if [[ -L "$dest" ]] && [[ "$(readlink "$dest")" == "$src" ]]; then
    note "$shown already links to $src"
    PRESENT+=("$label ($shown)")
    return 0
  fi

  # -L as well as -e: a broken symlink doesn't "exist" but is still in the way.
  if [[ -e "$dest" ]] || [[ -L "$dest" ]]; then
    note "$shown already exists; leaving it alone."
    note "To use the tracked one, move it aside and re-run this script."
    SKIPPED+=("$label ($shown exists)")
    return 1
  fi

  run ln -s "$src" "$dest"
  DONE+=("$label ($shown -> $src)")
}

# Set a key in a JSON file without touching anything else in it.
#
#   json_set FILE KEY_PATH VALUE [REPLACEABLE]
#
# KEY_PATH is a JSON array of keys, VALUE is JSON. If the key is missing it is
# added; if it already equals VALUE nothing happens. If it holds a different
# value it is left alone and reported as a conflict, unless that value is
# listed in REPLACEABLE (a JSON array), e.g. a default the program wrote itself.
# A missing FILE is created. Other keys (and their order) are preserved.
json_set() {
  local file="$1" key_path="$2" value="$3" replaceable="${4:-[]}"
  local tilde='~' label data state current action dir tmp mode

  label="$file: $(printf '%s' "$key_path" | tr -d '[]"' | sed 's/, */ > /g')"
  label="${label//"$HOME"/$tilde}"

  if [[ ! -x "$JQ" ]]; then
    if ((DRY_RUN)); then
      note "[dry-run] $label would be set to $value (if not already)"
      DONE+=("[dry-run] $label")
    else
      note "$JQ not found; $label not changed."
      SKIPPED+=("$label (jq missing)")
    fi
    return 0
  fi

  # Writing through a symlink would change whatever it points at (possibly a
  # tracked file somewhere else), and replacing it would break the link.
  if [[ -L "$file" ]] || { [[ -e "$file" ]] && [[ ! -f "$file" ]]; }; then
    note "$label: not a regular file (symlink or other); not changed."
    SKIPPED+=("$label (not a regular file)")
    return 0
  fi

  data='{}'
  if [[ -f "$file" ]] && grep -q '[^[:space:]]' "$file"; then
    if ! "$JQ" -e -s 'length == 1 and (.[0] | type == "object")' "$file" >/dev/null 2>&1; then
      note "$label: file is not a JSON object; not changed."
      SKIPPED+=("$label (file is not a valid JSON object)")
      return 0
    fi
    data="$(cat "$file")"
  fi

  # Prints "<state><TAB><current value as JSON>".
  state="$(printf '%s' "$data" | "$JQ" -r \
    --argjson p "$key_path" --argjson v "$value" --argjson r "$replaceable" '
      if any(range(1; $p | length) as $i | getpath($p[:$i]);
             . != null and type != "object") then "blocked\tnull"
      elif (getpath($p[:-1]) | . != null and has($p[-1])) | not then "absent\tnull"
      else getpath($p) as $cur
        | (if $cur == $v then "equal"
           elif any($r[]; . == $cur) then "replace"
           else "conflict" end) + "\t" + ($cur | tojson)
      end')"
  current="${state#*$'\t'}"
  state="${state%%$'\t'*}"

  case "$state" in
    equal)
      note "$label is already $value"
      PRESENT+=("$label = $value")
      return 0
      ;;
    blocked | conflict)
      [[ "$state" == blocked ]] && current="a parent key that is not an object"
      note "$label: found $current (wanted $value); left alone."
      SKIPPED+=("$label is $current, not $value")
      return 0
      ;;
    replace) action="changed $current -> $value" ;;
    *) action="set to $value" ;;
  esac

  if ((DRY_RUN)); then
    note "[dry-run] $label would be $action"
    DONE+=("[dry-run] $label $action")
    return 0
  fi

  # Write a complete copy next to the original, then swap it in atomically so
  # the file is never left half-written. Keeps the original's permissions.
  dir="$(dirname "$file")"
  [[ -d "$dir" ]] || mkdir -p "$dir"
  mode=600
  [[ -f "$file" ]] && mode="$(stat -f '%Lp' "$file")"
  tmp="$(mktemp "$dir/.tmp-json-set.XXXXXX")"
  if printf '%s' "$data" |
    "$JQ" --argjson p "$key_path" --argjson v "$value" 'setpath($p; $v)' >>"$tmp" &&
    chmod "$mode" "$tmp" &&
    mv "$tmp" "$file"; then
    note "$label $action"
    DONE+=("$label $action")
  else
    rm -f "$tmp" # our own temp file only
    note "$label: failed to write; not changed."
    SKIPPED+=("$label (write failed)")
  fi
}
