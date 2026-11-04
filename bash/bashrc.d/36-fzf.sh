# fzf (installed by install-macos.sh) key bindings and completion: Ctrl-R
# fuzzy-searches history, Ctrl-T inserts a file path, Alt-C cd's into a
# directory, and `**<Tab>` fuzzy-completes paths. Loaded after
# 30-completion.sh, since fzf's `**` completion wraps the existing ones.
# What they list is set in profile.d/40-fzf.sh.
if command -v fzf >/dev/null 2>&1; then
  # `fzf --bash` prints these two files; sourcing them from Homebrew's copy
  # skips running fzf at every startup.
  __fzf_shell="${HOMEBREW_PREFIX:-/opt/homebrew}/opt/fzf/shell"
  if [[ -r "$__fzf_shell/key-bindings.bash" ]] &&
    [[ -r "$__fzf_shell/completion.bash" ]]; then
    . "$__fzf_shell/key-bindings.bash"
    . "$__fzf_shell/completion.bash"
  else
    eval "$(fzf --bash)"
  fi
  unset __fzf_shell

  # `**<Tab>` lists paths with fd too (fzf calls these if they exist).
  if command -v fd >/dev/null 2>&1; then
    _fzf_compgen_path() { fd --hidden --exclude .git . "$1"; }
    _fzf_compgen_dir() { fd --type d --hidden --exclude .git . "$1"; }
  fi
fi
