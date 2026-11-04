# Line editing. These are readline settings, set with `bind` here instead of
# in ~/.inputrc so they only apply to bash and need no extra symlink.

# Up/Down search history for lines starting with what's already typed (plain
# Up/Down when the line is empty). Terminals send either form of the arrow
# keys depending on their mode, so bind both.
bind '"\e[A": history-search-backward'
bind '"\e[B": history-search-forward'
bind '"\eOA": history-search-backward'
bind '"\eOB": history-search-forward'

# Tab completion: list all matches on the first Tab when there's more than
# one, ignore case, and colour the part already typed.
bind 'set show-all-if-ambiguous on'
bind 'set completion-ignore-case on'
bind 'set menu-complete-display-prefix on'
bind 'set colored-completion-prefix on'
