# fzf (installed by install-macos.sh) key bindings and completion: Ctrl-R
# fuzzy-searches history, Ctrl-T inserts a file path, Alt-C cd's into a
# directory, and `**<Tab>` fuzzy-completes paths. Loaded after
# 30-completion.sh, since fzf's `**` completion wraps the existing ones.
if command -v fzf >/dev/null 2>&1; then
  eval "$(fzf --bash)"
fi
