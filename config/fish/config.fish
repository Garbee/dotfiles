# Stop fish from dumping some text every time it starts.
set fish_greeting

function fish_prompt
    echo " ⌘ ⡆⡢⣇⠢ "
end

function humanize_duration -d "Make a time interval human readable"
    command awk '
        function hmTime(time,   stamp) {
            split("h:m:s:ms", units, ":")
            for (i = 2; i >= -1; i--) {
                if (t = int( i < 0 ? time % 1000 : time / (60 ^ i * 1000) % 60 )) {
                    stamp = stamp t units[sqrt((i - 2) ^ 2) + 1] " "
                }
            }
            if (stamp ~ /^ *$/) {
                return "0ms"
            }
            return substr(stamp, 1, length(stamp) - 1)
        }
        { 
            print hmTime($0) 
        }
    '
end

function iterm2_print_user_vars
    set -l durationPrefix ""
    if test $CMD_DURATION -gt (math "1000 * 10")
        set durationPrefix "💥"
    end
    if test $CMD_DURATION -gt (math "1000 * 20")
        set durationPrefix "💥$durationPrefix"
    end
    if test $CMD_DURATION -gt (math "1000 * 30")
        set durationPrefix "💥$durationPrefix"
    end
    set -l humanString (echo $CMD_DURATION | humanize_duration)
    iterm2_set_user_var cmdDuration "$durationPrefix $humanString"
end

source $HOME/.iterm2_shell_integration.(basename $SHELL)

# Use bat for pretty quick output in termanal
abbr cat "bat"
# Easy way to get back to cat when needed
abbr ccat "cat"
# Exa is much more beautiful listing output
abbr ls "exa"
# Prettier quick listing access
abbr l "exa -lahF"
# Easy way to get back to normal ls
abbr lls "ls"
# Much better ping view
abbr ping "prettyping --nolegend"
# Shorten getting process tree list
abbr proctree "pstree -g 3"

# Nord color theme
set -U fish_color_normal normal
set -U fish_color_command 81a1c1
set -U fish_color_quote a3be8c
set -U fish_color_redirection b48ead
set -U fish_color_end 88c0d0
set -U fish_color_error ebcb8b
set -U fish_color_param eceff4
set -U fish_color_comment 434c5e
set -U fish_color_match --background=brblue
set -U fish_color_selection white --bold --background=brblack
set -U fish_color_search_match bryellow --background=brblack
set -U fish_color_history_current --bold
set -U fish_color_operator 00a6b2
set -U fish_color_escape 00a6b2
set -U fish_color_cwd green
set -U fish_color_cwd_root red
set -U fish_color_valid_path --underline
set -U fish_color_autosuggestion 4c566a
set -U fish_color_user brgreen
set -U fish_color_host normal
set -U fish_color_cancel -r
set -U fish_pager_color_completion normal
set -U fish_pager_color_description B3A06D yellow
set -U fish_pager_color_prefix white --bold --underline
set -U fish_pager_color_progress brwhite --background=cyan

# PATH
set -x PATH /opt/homebrew/bin $PATH
set PUPPETEER_SKIP_CHROMIUM_DOWNLOAD true

