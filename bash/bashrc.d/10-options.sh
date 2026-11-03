# Shell options. Errors are silenced because some options don't exist in
# older bash (e.g. macOS's /bin/bash 3.2 has no globstar or autocd).

shopt -s checkwinsize           # update LINES/COLUMNS after each command
shopt -s cdspell                # fix small typos in `cd` arguments
shopt -s globstar 2>/dev/null   # ** matches across directories (bash 4+)
shopt -s autocd 2>/dev/null     # type a directory name to cd into it (bash 4+)
