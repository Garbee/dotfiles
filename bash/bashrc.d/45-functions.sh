# Small helper functions.

# mkcd DIR: create DIR (and any missing parents) and cd into it.
mkcd() {
  if [[ $# -ne 1 ]]; then
    echo "usage: mkcd DIR" >&2
    return 2
  fi
  mkdir -p -- "$1" && cd -- "$1"
}

# up [N]: go up N directories (default 1).
up() {
  local n="${1:-1}" dir=""
  if [[ ! "$n" =~ ^[1-9][0-9]*$ ]]; then
    echo "usage: up [N]" >&2
    return 2
  fi
  while ((n > 0)); do
    dir="../$dir"
    n=$((n - 1))
  done
  cd -- "$dir"
}

# fcd [DIR] and fe [DIR] need fzf. They list with fd when it's installed
# (skipping .gitignored paths, like Ctrl-T and Alt-C) and find otherwise.
if command -v fzf >/dev/null 2>&1; then
  # fcd [DIR]: pick a directory under DIR (default .) and cd into it.
  fcd() {
    local dir
    if command -v fd >/dev/null 2>&1; then
      dir="$(fd --type d --hidden --exclude .git . "${1:-.}" | fzf --scheme=path)"
    else
      dir="$(find "${1:-.}" -type d -not -path '*/.git/*' | fzf --scheme=path)"
    fi
    if [[ -n "$dir" ]]; then
      cd -- "$dir"
    fi
  }

  # fe [DIR]: pick one or more files under DIR (Tab to select several) and
  # open them in $EDITOR.
  fe() {
    local file preview="cat {}"
    local -a files=()
    if command -v bat >/dev/null 2>&1; then
      preview="bat --color=always --style=numbers --line-range=:500 {}"
    fi
    while IFS= read -r file; do
      files+=("$file")
    done < <(
      if command -v fd >/dev/null 2>&1; then
        fd --type f --hidden --exclude .git . "${1:-.}"
      else
        find "${1:-.}" -type f -not -path '*/.git/*'
      fi | fzf --multi --scheme=path --preview "$preview"
    )
    if ((${#files[@]} > 0)); then
      "${EDITOR:-vi}" -- "${files[@]}"
    fi
  }
fi
