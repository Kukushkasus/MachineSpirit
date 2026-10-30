# [ PURITY SEAL ] Keep the signal clear. Preserve the entrusted work.
# MachineSpirit: greeting and prompt. Source this LAST from config.fish (after any distro greeting).
# the full emblem needs a wide window; narrower ones get the readout alone, tiny ones nothing
function fish_greeting
    command -q fastfetch; or return
    # ask the terminal itself: on a resize $COLUMNS may not be updated yet
    set -l cols (tput cols 2>/dev/null; or echo $COLUMNS)
    set -l rows (tput lines 2>/dev/null; or echo $LINES)
    if test $cols -ge 100 -a $rows -ge 18
        fastfetch
    else if test $cols -ge 58 -a $rows -ge 14
        fastfetch --logo none
    end
end

# Tiling resizes a fresh terminal as more windows open, which would tear the greeting apart. Until the
# first command is run, a resize clears the screen (and the emblem image) and draws the greeting again
# for the new size; after that the terminal's contents are left alone.
set -g __ms_fresh 1
function __ms_regreet --on-signal WINCH
    set -q __ms_fresh; or return
    test -z (commandline); or return
    printf '\e_Ga=d\e\\'   # drop kitty images
    clear
    fish_greeting
    commandline -f repaint
end
function __ms_used --on-event fish_preexec
    set -e __ms_fresh
end

function fish_prompt
    set -l s $status
    set -l ms_config "$HOME/.config"
    set -q XDG_CONFIG_HOME; and set ms_config "$XDG_CONFIG_HOME"
    test -f "$ms_config/fish/ms-colors.fish"; and source "$ms_config/fish/ms-colors.fish"
    set -q ms_primary; or set -g ms_primary b08d3c
    set -q ms_text; or set -g ms_text c6d5b8
    set -q ms_error; or set -g ms_error c2331f
    set_color $ms_primary; echo -n "["
    set_color $ms_text; echo -n (prompt_pwd)
    set_color $ms_primary; echo -n "]"
    if test $s -ne 0
        set_color $ms_error; echo -n " !$s"
    end
    set_color $ms_primary; echo -n " ⚙ "
    set_color normal
end
