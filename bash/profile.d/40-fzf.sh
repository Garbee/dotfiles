# fzf settings, read by fzf and its key bindings (bashrc.d/36-fzf.sh).

# List files with fd: faster than fzf's own walker, and it skips whatever
# .gitignore ignores. Hidden files are included, except .git itself. Used by
# plain `fzf` and Ctrl-T; Alt-C lists directories the same way.
if command -v fd >/dev/null 2>&1; then
  export FZF_DEFAULT_COMMAND='fd --type f --hidden --exclude .git'
  export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
  export FZF_ALT_C_COMMAND='fd --type d --hidden --exclude .git'
fi

# Ctrl-T previews the highlighted file with bat.
if command -v bat >/dev/null 2>&1; then
  export FZF_CTRL_T_OPTS="--preview 'bat --color=always --style=numbers --line-range=:500 {}'"
fi
