#!/usr/bin/env bash
# add-game-to-custom-system.sh
##############################
#
# This script creates symbolic links for a custom ES system and tries to create
# a gamelist.xml based on already existent metadata, boxart, marquee, and video.
#
# More info here: 
# https://retropie.org.uk/forum/post/84125
#
# meleu - 2017-Jun

CUSTOM_SYSTEM_DIR="$2"
CUSTOM_GAMELIST="$CUSTOM_SYSTEM_DIR/gamelist.xml"
USAGE="
Usage:
$0 -d /path/to/custom/system/directory rom1 [rom2 [romN...]]"

if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    echo "This script creates symbolic links for a custom ES system and tries to create"
    echo "a gamelist.xml based on already existent metadata, boxart, marquee, and video."
    echo
    echo "More info here: https://retropie.org.uk/forum/post/84125"
    echo "$USAGE"
    exit 0
fi

if [[ "$1" != '-d' ]]; then
    echo "ERROR: missing '-d /path/to/custom/system/directory' argument" >&2
    echo "$USAGE" >&2
    exit 1
fi

if [[ ! -d "$CUSTOM_SYSTEM_DIR" ]]; then
    echo "ERROR: \"$CUSTOM_SYSTEM_DIR\" is NOT a directory." >&2
    echo "$USAGE" >&2
    exit 1
fi

shift 2

if [[ "$#" -eq 0 ]]; then
    echo "ERROR: missing rom file(s) as argument." >&2
    echo "$USAGE" >&2
    exit 1
fi

[[ -s "$CUSTOM_GAMELIST" ]] || echo -e "<gameList>\n</gameList>" > "$CUSTOM_GAMELIST"
temp_gamelist=$(mktemp gamelist.XXX)

for file in "$@"; do
    [[ "$file" == gamelist.xml ]] && continue

    rom_full="$(readlink -e "$file")"
    if [[ ! -s "$rom_full" ]]; then
        echo "WARNING: ignoring \"$file\": file not found or is zero-length."
        continue
    fi

    rom="$(basename "$rom_full")"
    system_dir="$(echo "$rom_full" | sed 's|\(.*/RetroPie/roms/[^/]*\).*|\1|')"
    system=$(basename "$system_dir")
    symlink="${rom%.*}-${system}.${rom##*.}"
    symlink_full="$CUSTOM_SYSTEM_DIR/$symlink"

    ln -s "$rom_full" "$symlink_full"
    if [[ "$?" -ne 0 ]]; then
        echo "WARNING: ignoring \"$file\": failed to create symbolic link."
        continue
    fi
    echo "\"$rom\": the link has been created: $symlink_full"

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
done

rm "$temp_gamelist"
