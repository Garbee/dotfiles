# shellcheck shell=bash
#
# Color palettes for the macOS color picker (the Color Palettes tab, in any
# app's Colors window), stored in ~/Library/Colors.
#
# Sourced by install-macos.sh; not meant to be run on its own.

COLOR_PALETTES_DIR="$HOME/Library/Colors"

# Download a palette (.clr) into ~/Library/Colors unless a file with that name
# is already there. Pin URL to a commit, so the file can't change under us.
#
#   install_color_palette LABEL NAME URL   e.g. ... Nord.clr https://...
install_color_palette() {
  local label="$1" name="$2" url="$3"
  local dest="$COLOR_PALETTES_DIR/$name" tmp

  log "$label"

  if [[ -e "$dest" ]] || [[ -L "$dest" ]]; then
    note "~/Library/Colors/$name already exists; leaving it alone."
    PRESENT+=("$label (~/Library/Colors/$name)")
    return 0
  fi

  if [[ -e "$COLOR_PALETTES_DIR" ]] && [[ ! -d "$COLOR_PALETTES_DIR" ]]; then
    note "~/Library/Colors exists but is not a directory; leaving it alone."
    SKIPPED+=("$label (~/Library/Colors is not a directory)")
    return 0
  fi

  if ((DRY_RUN)); then
    note "[dry-run] download $url to ~/Library/Colors/$name"
    DONE+=("$label")
    return 0
  fi

  [[ -d "$COLOR_PALETTES_DIR" ]] || mkdir -p "$COLOR_PALETTES_DIR"
  # Download next to the destination, check it is a property list (which
  # .clr files are), and only then move it into place. mv -n never replaces
  # a file that appeared in the meantime.
  tmp="$(mktemp "$COLOR_PALETTES_DIR/.tmp-palette.XXXXXX")"
  if curl -fsSL -o "$tmp" "$url" &&
    plutil -lint -s "$tmp" &&
    chmod 644 "$tmp" &&
    mv -n "$tmp" "$dest" &&
    [[ ! -e "$tmp" ]]; then
    note "Installed ~/Library/Colors/$name"
    DONE+=("$label")
  else
    rm -f "$tmp" # our own temp file only
    note "Could not download $name."
    SKIPPED+=("$label (download failed)")
  fi
}

install_color_palettes() {
  install_color_palette "Nord color palette" Nord.clr \
    https://raw.githubusercontent.com/nordtheme/nord/1cef71605416a222e57225b544540ce0fcec18d4/src/swatches/Nord.clr
}
