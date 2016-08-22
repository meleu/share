#!/bin/bash
# this script is intended to be the RetroPie's runcommand-onend.sh
# please, rename it to /opt/retropie/configs/all/runcommand-onend.sh

function echo_xml_safe() {
    output=$(sed 's#\&#\&amp;#g' <<< "$@")
    output=$(
        sed "
            s#\"#\&quot;#g
            s#'#\&apos;#g
            s#<#\&lt;#g
            s#>#\&gt;#g" <<< "$@"
    )
    echo "$output"
}

function echo_regex_safe() {
    echo "$(
        sed '
            s#[][&\]#\\&#g
            s#\^#\\^#g' <<< "$@"
    )"
}

echo "--- start of $(basename $0) ---" >&2

system="$1"
full_path_rom="$3"
retroarch_cfg="/opt/retropie/configs/all/retroarch.cfg"
system_ra_cfg="/opt/retropie/configs/$system/retroarch.cfg"
gamelist="$HOME/RetroPie/roms/$system/gamelist.xml"
gamelist_user="$HOME/.emulationstation/gamelists/$system/gamelist.xml"
gamelist_global="/etc/emulationstation/gamelists/$system/gamelist.xml"

rom="${full_path_rom##*/}"
rom="${rom%.*}"
image="$rom.png"

# XML-safe equivalent
xfull_path_rom="$(echo_xml_safe "$full_path_rom")"
xrom="$(echo_xml_safe "$rom")"
ximage="$(echo_xml_safe "$image")"

source "/opt/retropie/lib/inifuncs.sh"

iniConfig ' = ' '"'

# only go on if the auto_screenshot_filename is false
iniGet "auto_screenshot_filename" "$system_ra_cfg"
if ! [[ "$ini_value" =~ ^(false|0)$ ]]; then
    # if true, the user explicitly wants to turn off for this specific system
    if [[ "$ini_value" =~ ^(true|1)$ ]]; then
        echo "Auto scraper is off for this system. Exiting..." >&2
        exit 0
    fi
    # if it's neither true nor false (eg: absent), try the global config
    iniGet "auto_screenshot_filename" "$retroarch_cfg"
    if ! [[ "$ini_value" =~ ^(false|0)$ ]]; then
        echo "Auto scraper is off. Exiting..." >&2
        exit 0
    fi
fi

# getting the screenshots directory
# try system specific retroarch.cfg, if not found try the global one
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
# XML-safe equivalent
xscreenshot_dir="$(echo_xml_safe $screenshot_dir)"

# if there is no screenshot named "ROM Name.png", we have nothing to do here
if ! [[ -f "$screenshot_dir/$image" ]]; then
    echo "There is no screenshot for \"$rom\". Exiting..." >&2
    exit 0
fi

# if there is no "customized gamelist.xml", try the user specific,
# if it fails, get the global one
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

# the <image> entry MUST be on a single line and match the pattern:
# anything followed by rom name followed or not by "-image" followed by dot followed by 3 chars
old_img_regex="<image>.*$(echo_regex_safe "$xrom")\(-image\)\?\....</image>"
new_img_regex="<image>$xscreenshot_dir/$ximage</image>"

# if there is an entry, update the <image> entry
if grep -q "$old_img_regex" "$gamelist"; then
    new_img_regex="$(echo_regex_safe "$new_img_regex")"
    sed -i "s|$old_img_regex|$new_img_regex|" "$gamelist"

else
    # there is no entry for this game yet, let's create it
    gamelist_entry="
    <game id=\"\" source=\"\">
        <path>$xfull_path_rom</path>
        <name>$xrom</name>
        <desc></desc>
        $new_img_regex
        <releasedate></releasedate>
        <developer></developer>
        <publisher></publisher>
        <genre></genre>
    </game>"
    # escaping it for a safe sed use
    gamelist_entry=$(echo_regex_safe "$gamelist_entry")
    gamelist_entry=$(sed 's#$#\\#' <<< "$gamelist_entry")
    # in the substitution below the trailing n& takes advantage of the
    # backslash in the end of gamelist_entry (OK, this is inelegant, but works)
    sed -i "/<\/gameList>/ s|.*|${gamelist_entry}n&|" "$gamelist"
fi

echo "--- end of $(basename $0) ---" >&2
