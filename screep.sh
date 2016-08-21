#!/bin/bash
# this script is intended to be the RetroPie's runcommand-onend.sh
# please, rename it to /opt/retropie/configs/all/runcommand-onend.sh
echo "--- start of $(basename $0) ---" >&2

readonly system="$1"
readonly full_path_rom="$3"
readonly retroarch_cfg="/opt/retropie/configs/all/retroarch.cfg"
readonly system_ra_cfg="/opt/retropie/configs/$system/retroarch.cfg"
readonly gamelist="$HOME/RetroPie/roms/$system/gamelist.xml"
readonly gamelist1="$HOME/.emulationstation/gamelists/$system/gamelist.xml"
readonly gamelist2="/etc/emulationstation/gamelists/$system/gamelist.xml"

rom="${full_path_rom##*/}"
rom="${rom%.*}"
scrap_img="$rom.png"

source "/opt/retropie/lib/inifuncs.sh"

iniConfig ' = ' '"'

# only go on if the auto_screenshot_filename is false
iniGet "auto_screenshot_filename" "$retroarch_cfg"
if ! [[ "$ini_value" =~ ^(false|0)$ ]]; then
    exit 0
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

# if there is no screenshot named "ROM Name.png", we have nothing to do here
if ! [[ -f "$screenshot_dir/$scrap_img" ]]; then
    echo "There is no screenshot for \"$rom\". Exiting..." >&2
    exit 0
fi

# if there is no "customized gamelist.xml", try the user specific,
# if it fails, get the global one
if ! [[ -f "$gamelist" ]]; then
    echo "Copying \"$gamelist1\" to \"$gamelist\"." >&2

    if ! cp "$gamelist1" "$gamelist" 2>/dev/null; then
        echo "Failed to copy \"$gamelist1\"." >&2
        echo "Copying \"$gamelist2\" to \"$gamelist\"." >&2

        if ! cp "$gamelist2" "$gamelist" 2>/dev/null; then
            echo "Failed to copy \"$gamelist2\"." >&2
            echo "Aborting..." >&2
            exit 1
        fi
    fi
fi

# the <image> entry MUST be on a single line and match the pattern:
# anything followed by rom name followed or not by "-image" followed by dot followed by 3 chars
old_img_regex="<image>.*$rom\(-image\)\?\....</image>"
new_img_regex="<image>$screenshot_dir/$scrap_img</image>"

if grep -q "$old_img_regex" "$gamelist"; then
    sed -i "s|$old_img_regex|$new_img_regex|" "$gamelist"

else # oh! there is no entry for this game yet!
    gamelist_entry="\\
    <game id=\"\" source=\"\">\\
        <path>$full_path_rom</path> \\
        <name>$rom</name> \\
        <desc></desc> \\
        $new_img_regex \\
        <releasedate></releasedate> \\
        <developer></developer> \\
        <publisher></publisher> \\
        <genre></genre> \\
    </game>"

    sed -i "/<\/gameList>/ s|.*|${gamelist_entry}\n&|" "$gamelist"
fi

echo "--- end of $(basename $0) ---" >&2
