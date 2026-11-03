# Aliases.

# prettyping (installed by install-macos.sh) wraps ping with a live graph.
if command -v prettyping >/dev/null 2>&1; then
  alias ping='prettyping'
fi
