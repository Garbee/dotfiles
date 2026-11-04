# Homebrew: PATH, MANPATH, INFOPATH and HOMEBREW_* variables.
#
# This is what `brew shellenv bash` prints, written out: running brew costs
# about 15 ms in every new tab, and on Apple silicon the prefix is always
# /opt/homebrew. If brew ever changes what it sets, compare with
# `brew shellenv bash`.
if [[ -x /opt/homebrew/bin/brew ]]; then
  export HOMEBREW_PREFIX="/opt/homebrew"
  export HOMEBREW_CELLAR="/opt/homebrew/Cellar"
  export HOMEBREW_REPOSITORY="/opt/homebrew"
  export PATH="/opt/homebrew/bin:/opt/homebrew/sbin${PATH+:$PATH}"
  # An empty entry in MANPATH (here a leading :) makes man search its default
  # paths too, which include Homebrew's man pages once /opt/homebrew/bin is
  # on PATH.
  if [[ -n "${MANPATH-}" ]]; then
    export MANPATH="${MANPATH%"${MANPATH##*[!:]}"}"
    export MANPATH=":${MANPATH#"${MANPATH%%[!:]*}"}"
  fi
  export INFOPATH="/opt/homebrew/share/info:${INFOPATH:-}"
fi

# Homebrew behavior (see `man brew`, ENVIRONMENT).
export HOMEBREW_NO_AUTO_UPDATE=1      # no `brew update` before every install
export HOMEBREW_NO_ANALYTICS=1        # no usage analytics
export HOMEBREW_NO_ENV_HINTS=1        # no hints about these variables
export HOMEBREW_NO_AUTOREMOVE=1       # keep dependencies nothing needs anymore
export HOMEBREW_NO_INSTALL_CLEANUP=1  # no cleanup after every install
# `brew upgrade` leaves casks that update themselves (auto_updates) alone,
# as it did before Homebrew 6.
export HOMEBREW_NO_UPGRADE_AUTO_UPDATES_CASKS=1
# Third-party taps must be trusted (`brew trust --tap`) before their
# formulae and casks load. install-macos.sh trusts the ones it uses.
export HOMEBREW_REQUIRE_TAP_TRUST=1
export HOMEBREW_CLEANUP_MAX_AGE_DAYS=45     # cached downloads kept 45 days
export HOMEBREW_CLEANUP_PERIODIC_FULL_DAYS=0 # no periodic full cleanup
