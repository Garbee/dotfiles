# shellcheck shell=bash
#
# Rust: the stable toolchain as rustup's default, the rust-analyzer component
# (the language server Claude Code's rust-analyzer-lsp plugin and editors
# use), and cargo subcommands installed with `cargo install`.
#
# rustup itself comes from Homebrew (install_brew_packages). It's keg-only, so
# its commands are run from its keg here; bash/profile.d/20-path.sh puts them
# on PATH for shells.
#
# Sourced by install-macos.sh; not meant to be run on its own.

RUSTUP_BIN="$BREW_PREFIX/opt/rustup/bin"

# Make stable the default toolchain, unless a default is already set (to
# stable or anything else).
configure_rust_toolchain() {
  local label="Rust default toolchain (stable)" current

  log "$label"

  if [[ ! -x "$RUSTUP_BIN/rustup" ]]; then
    if ((DRY_RUN)); then
      note "[dry-run] rustup default stable (once rustup is installed)"
      DONE+=("[dry-run] $label")
    else
      note "$RUSTUP_BIN/rustup not found; no toolchain installed."
      SKIPPED+=("$label (rustup missing)")
    fi
    return 0
  fi

  # Prints e.g. "stable-aarch64-apple-darwin (default)"; fails if none is set.
  if current="$("$RUSTUP_BIN/rustup" default 2>/dev/null)" && [[ -n "$current" ]]; then
    note "Already set: $current"
    PRESENT+=("Rust default toolchain (${current%% *})")
    return 0
  fi

  if ((DRY_RUN)); then
    note "[dry-run] $RUSTUP_BIN/rustup default stable"
    DONE+=("$label")
  elif "$RUSTUP_BIN/rustup" default stable; then
    DONE+=("$label")
  else
    note "Could not install the stable toolchain; continuing."
    SKIPPED+=("$label (rustup failed)")
  fi
}

# Add a rustup component to the default toolchain unless it's already there.
#
#   rustup_component_add COMPONENT   e.g. rust-analyzer
rustup_component_add() {
  local component="$1" label="Rust component $1"

  log "$label"

  if ! "$RUSTUP_BIN/rustup" default >/dev/null 2>&1; then
    if ((DRY_RUN)); then
      note "[dry-run] $RUSTUP_BIN/rustup component add $component"
      DONE+=("[dry-run] $label")
    else
      note "No default Rust toolchain; $component not added."
      SKIPPED+=("$label (no default toolchain)")
    fi
    return 0
  fi

  # Installed components are listed as "<name>-<target triple>".
  if "$RUSTUP_BIN/rustup" component list --installed 2>/dev/null |
    grep -q "^$component-"; then
    note "Already installed"
    PRESENT+=("$label")
    return 0
  fi

  if ((DRY_RUN)); then
    note "[dry-run] $RUSTUP_BIN/rustup component add $component"
    DONE+=("$label")
  elif "$RUSTUP_BIN/rustup" component add "$component"; then
    DONE+=("$label")
  else
    note "Could not add $component; continuing."
    SKIPPED+=("$label (rustup failed)")
  fi
}

# Install a crate's commands with `cargo install --locked` (into
# ${CARGO_HOME:-~/.cargo}/bin) unless COMMAND is already there or on PATH.
# Builds from source, so it takes a minute or two each.
#
#   cargo_install CRATE [COMMAND]   COMMAND defaults to CRATE
cargo_install() {
  local crate="$1" command="${2:-$1}" label="cargo install $1" existing
  local cargo_bin="${CARGO_HOME:-$HOME/.cargo}/bin"

  log "$label"

  if existing="$(command -v "$command" 2>/dev/null)" || {
    [[ -x "$cargo_bin/$command" ]] && existing="$cargo_bin/$command"
  }; then
    note "Already installed at $existing"
    PRESENT+=("$label")
    return 0
  fi

  if ! "$RUSTUP_BIN/rustup" default >/dev/null 2>&1; then
    if ((DRY_RUN)); then
      note "[dry-run] $RUSTUP_BIN/cargo install --locked $crate"
      DONE+=("[dry-run] $label")
    else
      note "No default Rust toolchain; $crate not installed."
      SKIPPED+=("$label (no default toolchain)")
    fi
    return 0
  fi

  if ((DRY_RUN)); then
    note "[dry-run] $RUSTUP_BIN/cargo install --locked $crate"
    DONE+=("$label")
  # cargo runs rustc by name, so rustup's proxies must be on PATH: they're
  # only on it in shells set up by bash/profile.d/20-path.sh.
  elif PATH="$RUSTUP_BIN:$PATH" "$RUSTUP_BIN/cargo" install --locked "$crate"; then
    DONE+=("$label")
  else
    note "Could not install $crate; continuing."
    SKIPPED+=("$label (cargo install failed)")
  fi
}

install_rust() {
  configure_rust_toolchain
  rustup_component_add rust-analyzer
  # Checks dependencies' licenses, advisories and sources.
  cargo_install cargo-deny
  # Mutation testing: checks that the tests notice when the code changes.
  cargo_install cargo-mutants
}
