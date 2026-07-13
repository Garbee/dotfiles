#!/usr/bin/env zsh

# Homebrew packages shared between install scripts.
# crossPlatformFormulae install on both macOS and Linux.
# macosOnlyFormulae are casks or otherwise unavailable on Linux.

crossPlatformFormulae=()

# Languages & Runtimes
crossPlatformFormulae+=("node" "go")

# Version Control & Signing
crossPlatformFormulae+=("git" "gh" "gnupg")

# CLI Utilities
crossPlatformFormulae+=(
    "coreutils"
    "bat"                 # cat with syntax highlighting
    "betterleaks"         # Secret/leak scanner
    "bitwarden-cli"       # Bitwarden password manager CLI
    "eza"                 # Modern ls replacement
    "fzf"                 # Fuzzy finder
    "httpie"              # Friendly HTTP client
    "jq"                  # JSON processor
    "prettyping"          # Prettier ping output
    "pstree"              # Process tree viewer
    "the_silver_searcher" # Code search (ag)
    "tmux"                # Terminal multiplexer
)

# Editors
crossPlatformFormulae+=("neovim")

macosOnlyFormulae=()

# Editors & Writing
macosOnlyFormulae+=("zed" "obsidian")

# Desktop Applications
macosOnlyFormulae+=(
    "discord"
    "ghostty" # Terminal emulator
    "wins"    # Window manager (settings live in System Settings > Wins)
)
