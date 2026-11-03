# History: big, shared between tabs, without duplicates.

HISTSIZE=100000
HISTFILESIZE=100000
HISTCONTROL=ignoreboth:erasedups # skip lines starting with a space, and dupes
HISTTIMEFORMAT='%F %T '
shopt -s histappend # append to the history file instead of overwriting it
shopt -s cmdhist    # save multi-line commands as one entry

# Write each command to the history file as soon as it runs, so other tabs
# (and a crashed terminal) don't lose it.
case ";${PROMPT_COMMAND:-};" in
  *";history -a;"*) ;;
  *) PROMPT_COMMAND="history -a${PROMPT_COMMAND:+;$PROMPT_COMMAND}" ;;
esac
