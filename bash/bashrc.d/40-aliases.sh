# Aliases.

# prettyping (installed by install-macos.sh) wraps ping with a live graph.
if command -v prettyping >/dev/null 2>&1; then
  alias ping='prettyping'
fi

# Go up two or three directories. (`..` alone already works through autocd
# in 10-options.sh.)
alias ...='cd ../..'
alias ....='cd ../../..'
