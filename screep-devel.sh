#!/bin/bash
# This script is intended to be the RetroPie's runcommand-onend.sh
# please, rename it to /opt/retropie/configs/all/runcommand-onend.sh
#
# What does it do?
##################
# If the user takes screenshots during a game, the most recent screenshot
# will be the emulationstation image for this game.
#
# Conditions to make it work:
#############################
# You must have these settings in your retroarch.cfg (system specific or
# global; note: system specific takes precedence):
#
# auto_screenshot_filename = "false"
# screenshot_directory = "/path/to/screenshots/folder"
#
# The screenshot directory must exist, otherwise the RetroArch won't be able
# to save the screenshots.
#
# TODO: 
# 1. if the game is an arcade game and has no entry in gamelist.xml, create
#    an entry with no <game> field. It'll make the ES use the game name rather
#    than rom name.
# 2. find another way to detect an existing game in gamelist.xml, instead of
#    looking for <image> field. The gamelist.xml can have entries with no
#    <image> field.
# 3. deal with an "empty" gamelist.xml. In other words: <gameList />

echo "--- start of $(basename $0) ---" >&2

# variables ##################################################################
readonly system="$1"
readonly full_path_rom="$3"
readonly retroarch_cfg="/opt/retropie/configs/all/retroarch.cfg"
readonly system_ra_cfg="/opt/retropie/configs/$system/retroarch.cfg"
readonly gamelist="$HOME/RetroPie/roms/$system/gamelist.xml"
readonly gamelist_user="$HOME/.emulationstation/gamelists/$system/gamelist.xml"
readonly gamelist_global="/etc/emulationstation/gamelists/$system/gamelist.xml"

rom_file="${full_path_rom##*/}"
rom="${rom_file%.*}"
image="$rom.png"

source "/opt/retropie/lib/inifuncs.sh"


# functions ##################################################################

function get_configs() {
    iniConfig ' = ' '"'
    
    # only go on if the auto_screenshot_filename is false
    iniGet "auto_screenshot_filename" "$system_ra_cfg"
    if ! [[ "$ini_value" =~ ^(false|0)$ ]]; then
        # if true, the user explicitly wanna turn it off for this specific system
        if [[ "$ini_value" =~ ^(true|1)$ ]]; then
            echo "Auto scraper is off for $system. Exiting..." >&2
            exit 0
        fi
        # if it's neither true nor false (absent), try the global config
        iniGet "auto_screenshot_filename" "$retroarch_cfg"
        if ! [[ "$ini_value" =~ ^(false|0)$ ]]; then
            echo "Auto scraper is off. Exiting..." >&2
            exit 0
        fi
    fi
    
    # getting the screenshots directory
    # try system specific, if not found try the global one
    iniGet "screenshot_directory" "$system_ra_cfg"
    screenshot_dir="$ini_value"
    if [[ -z "$screenshot_dir" ]]; then
        iniGet "screenshot_directory" "$retroarch_cfg"
        screenshot_dir="$ini_value"
        if [[ -z "$screenshot_dir" ]]; then
            echo "You must set a path for 'screenshot_directory' in \"retroarch.cfg\"." >&2
            echo "Aborting..." >&2
            exit 1
        fi
    fi
    # dealing with the tilde '~'
    screenshot_dir="${screenshot_dir/#~/$HOME}"

    # if there is no "customized gamelist.xml", copy the user specific,
    # if it fails, copy the global one
    if ! [[ -f "$gamelist" ]]; then
        echo "Copying \"$gamelist_user\" to \"$gamelist\"." >&2
    
        if ! cp "$gamelist_user" "$gamelist" 2>/dev/null; then
            echo "Failed to copy \"$gamelist_user\"." >&2
            echo "Copying \"$gamelist_global\" to \"$gamelist\"." >&2
    
            if ! cp "$gamelist_global" "$gamelist" 2>/dev/null; then
                echo "Failed to copy \"$gamelist_global\"." >&2
                echo "Aborting..." >&2
                exit 1
            fi
        fi
    fi
}

# sometimes we need to convert strings to a XML-friendly entries
function echo_xml_safe() {
    output="$(sed 's#\&#\&amp;#g' <<< "$@")"
    output="$(
        sed "
            s#\"#\&quot;#g
            s#'#\&apos;#g
            s#<#\&lt;#g
            s#>#\&gt;#g" <<< "$output"
    )"
    echo "$output"
}

# sometimes we need to escape characters to make them to NOT be considered a REGEX
function echo_regex_safe() {
    echo "$(sed 's#[][&\^]#\\&#g' <<< "$@")"
}


# starting point #############################################################

get_configs

# if there is no screenshot named "ROM Name.png", we have nothing to do here
if ! [[ -f "$screenshot_dir/$image" ]]; then
    echo "There is no screenshot for \"$rom\" in the \"$screenshot_dir\" folder." >&2
    echo "\"$screenshot_dir/$image\" not found!" >&2
    echo "Exiting..." >&2
    exit 0
fi

# now we must the XML-safe versions of some variables
xfull_path_rom="$(echo_xml_safe "$full_path_rom")"
xrom_file="$(echo_xml_safe "$rom_file")"
xrom="$(echo_xml_safe "$rom")"
ximage="$(echo_xml_safe "$image")"
xscreenshot_dir="$(echo_xml_safe $screenshot_dir)"

# regex to detect if the gamelist.xml has an entry for this rom:
rom_regex="<path>.*$(echo_regex_safe "$xrom_file")<\/path>"

# new <image> field
new_img_regex="<image>$xscreenshot_dir/$ximage</image>"

# if this rom present in gamelist.xml
if grep -q "$rom_regex" "$gamelist"; then
    new_img_regex="$(echo_regex_safe "$new_img_regex")"

    # check if this rom entry has an <image> field
    if sed "/$rom_regex/,/<\/game>/!d" "$gamelist" | grep -q "<image>" ; then
        # the <image> entry MUST be on a single line and match the pattern:
        # anything followed by rom name followed or not by "-image" followed
        # by dot followed by 3 chars
        old_img_regex="<image>.*$(echo_regex_safe "$xrom")\(-image\)\?\....</image>"
        sed -i "s|$old_img_regex|$new_img_regex|" "$gamelist"

    # this rom is present in gamelist.xml but has no <image> field
    else
        sed -i "/$rom_regex/ s|.*|&\n\t\t${new_img_regex}|" "$gamelist"
    fi

# this rom is not present in gamelist.xml
else
    # No <name> field when system is arcade, fba, mame-*, neogeo. It'll
    # make the ES get the real game name from its own code (MameNameMap.cpp).
    if [[ "$system" =~ ^(mame-.*|fba|arcade|neogeo)$ ]]; then
        game_name=
    else
        game_name="<name>$xrom</name>"
    fi

    # there is no entry for this game yet, let's create it
    gamelist_entry="
    <game>
        <path>$xfull_path_rom</path>
        $game_name
        <desc></desc>
        $new_img_regex
        <releasedate></releasedate>
        <developer></developer>
        <publisher></publisher>
        <genre></genre>
    </game>"

    # escaping it for a safe sed use
    gamelist_entry="$(echo_regex_safe "$gamelist_entry")"

    # putting backslash at the end of the lines
    gamelist_entry="$(sed 's#$#\\#' <<< "$gamelist_entry")"

    # in the substitution below the trailing "n&" takes advantage of the
    # backslash in the end of gamelist_entry (OK, this is inelegant, but works)
    sed -i "/<\/gameList>/ s|.*|${gamelist_entry}n&|" "$gamelist"
fi

echo "--- end of $(basename $0) ---" >&2
