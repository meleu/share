#!/usr/bin/env bash
# custom-system-autoscraper.sh
##############################
#
# This script gets all the symbolic links in a custom ES system directory and
# tries to create a gamelist.xml based on already existent metadata, boxart,
# marquee, and video.
#
# More info here: 
# https://retropie.org.uk/forum/post/84125
#
# meleu - 2017-Jun

CUSTOM_SYSTEM_DIR="$1"
USAGE="Usage:
$0 /path/to/custom/system/directory
"

if [[ -z "$CUSTOM_SYSTEM_DIR" ]]; then
    echo "ERROR: missing argument." >&2
    echo "$USAGE" >&2
    exit 1
fi

if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    echo "This script gets all the symbolic links in a custom ES system directory and"
    echo "tries to create a gamelist.xml based on already existent metadata, boxart,"
    echo "marquee, and video."
    echo
    echo "More info here: https://retropie.org.uk/forum/post/84125"
    echo
    echo "$USAGE"
    exit 0
fi

CUSTOM_GAMELIST="$1/gamelist.xml"
[[ -s "$CUSTOM_GAMELIST" ]] || echo -e "<gameList>\n</gameList>" > "$CUSTOM_GAMELIST"
temp_gamelist=$(mktemp gamelist.XXX)

while read -r symlink; do
    # ignore if it's not a symlink
    symlink_full="$CUSTOM_SYSTEM_DIR/$symlink" 
    [[ -L "$symlink_full" ]] || continue

    # ignore if the symlink points to non-existent/zero-length file
    rom_full="$(readlink "$CUSTOM_SYSTEM_DIR/$symlink")"
    [[ -s "$rom_full" ]] || continue

    rom="$(basename "$rom_full")"
    system_dir="$(echo "$rom_full" | sed 's|\(.*/RetroPie/roms/[^/]*\).*|\1|')"
    system=$(basename "$system_dir")

    # looking for the system's gamelist.xml
    # more details about these files here:
    # https://github.com/retropie/EmulationStation/blob/master/GAMELISTS.md
    system_gamelist="$system_dir/gamelist.xml"
    if [[ ! -s "$system_gamelist" ]]; then
        system_gamelist="$HOME/.emulationstation/gamelists/$system/gamelist.xml"
        if [[ ! -s "$system_gamelist" ]]; then
            system_gamelist="/etc/emulationstation/gamelists/$system/gamelist.xml"
            [[ -s "$system_gamelist" ]] || continue
        fi
    fi

    # getting all game's data in xml format
    metadata="$(xmlstarlet sel -t -c "/gameList/game[contains(path,\"$rom\")]" "$system_gamelist" 2> /dev/null)"
    [[ -z "$metadata" ]] && continue

    # don't do anything if there's an entry for this game already
    xmlstarlet sel -Q -t -c "/gameList/game[contains(path,\"./$symlink\")]" "$CUSTOM_GAMELIST" \
    && continue

    sed -i '/<\/gameList>/d' "$CUSTOM_GAMELIST" \
    && echo "$metadata" >> "$CUSTOM_GAMELIST" \
    && echo "</gameList>" >> "$CUSTOM_GAMELIST"

    # <path> must be the symlink
    xmlstarlet ed -u "/gameList/game[contains(path,\"$rom\")]/path" -v "./$symlink" "$CUSTOM_GAMELIST" > "$temp_gamelist"
    cat "$temp_gamelist" > "$CUSTOM_GAMELIST"

    # using full path for <image>, <marquee>, and <video>
    image=$(xmlstarlet sel -t -v \
        "/gameList/game[contains(path,\"./$symlink\")][starts-with(image,'./')]/image" \
        "$CUSTOM_GAMELIST")
    if [[ -n "$image" ]]; then
        image="$system_dir/$image"
        xmlstarlet ed -u \
            "/gameList/game[contains(path,\"./$symlink\")][starts-with(image,'./')]/image" \
            -v "$image" "$CUSTOM_GAMELIST" > "$temp_gamelist"
        cat "$temp_gamelist" > "$CUSTOM_GAMELIST"
    fi

    marquee=$(xmlstarlet sel -t -v \
        "/gameList/game[contains(path,\"./$symlink\")][starts-with(marquee,'./')]/marquee" \
        "$temp_gamelist")
    if [[ -n "$marquee" ]]; then
        marquee="$system_dir/$marquee"
        xmlstarlet ed -u \
            "/gameList/game[contains(path,\"./$symlink\")][starts-with(marquee,'./')]/marquee" \
            -v "$marquee" "$CUSTOM_GAMELIST" > "$temp_gamelist"
        cat "$temp_gamelist" > "$CUSTOM_GAMELIST"
    fi

    video=$(xmlstarlet sel -t -v \
        "/gameList/game[contains(path,\"./$symlink\")][starts-with(video,'./')]/video" \
        "$temp_gamelist")
    if [[ -n "$video" ]]; then
        video="$system_dir/$video"
        xmlstarlet ed -u \
            "/gameList/game[contains(path,\"./$symlink\")][starts-with(video,'./')]/video" \
            -v "$video" "$CUSTOM_GAMELIST" > "$temp_gamelist"
        cat "$temp_gamelist" > "$CUSTOM_GAMELIST"
    fi

    echo "The entry for \"$symlink\" has been created in \"$CUSTOM_GAMELIST\"."
done < <(ls -1 "$CUSTOM_SYSTEM_DIR")

rm "$temp_gamelist"
