#!/usr/bin/env bash
# Used2BeTXT.sh
###############
#
# This script converts synopsis text files to gamelist.xml files.
#
# More info in this forum thread: https://retropie.org.uk/forum/post/79022
#
# meleu - 2017/Jun

readonly SCRIPT_DIR="$(dirname "$0")"
readonly SCRIPT_NAME="$(basename "$0")"
readonly SCRIPT_FULL="$SCRIPT_DIR/$SCRIPT_NAME"
readonly SCRIPT_URL="https://raw.githubusercontent.com/meleu/share/master/Used2BeTXT.sh"

readonly HELP="
Usage:
$0 [OPTIONS] synopsis1.txt [synopsisN.txt ...]

The OPTIONS are:

-h|--help       print this message and exit.

-u|--update     update the script and exit.
"


function update_script() {
    local err_flag=0
    local err_msg

    if err_msg=$(wget "$SCRIPT_URL" -O "/tmp/$SCRIPT_NAME" 2>&1); then
        if diff -q "$SCRIPT_FULL" "/tmp/$SCRIPT_NAME" >/dev/null; then
            echo "You already have the latest version. Nothing changed."
            rm -f "/tmp/$SCRIPT_NAME"
            exit 0
        fi
        err_msg=$(mv "/tmp/$SCRIPT_NAME" "$SCRIPT_DIR/$SCRIPT_NAME" 2>&1) \
        || err_flag=1
    else
        err_flag=1
    fi

    if [[ $err_flag -ne 0 ]]; then
        err_msg=$(echo "$err_msg" | tail -1)
        echo "Failed to update \"$SCRIPT_NAME\": $err_msg" >&2
        exit 1
    fi
    
    echo "The script has been successfully updated. You can run it again."
    exit 0
}


function get_data() {
    sed -e "/^$1:/!d ; s/^$1: //" "$2"
}


# START HERE #################################################################

case "$1" in
    -h|--help)
        echo "$HELP" >&2
        exit 0
        ;;
    -u|--update)
        update_script
        ;;
    '')
        echo "ERROR: missing synopsis text file." >&2
        echo "$HELP" >&2
        exit 1
        ;;
    -*)
        echo "ERROR: \"$1\": invalid option" >&2
        echo "$HELP" >&2
        exit 1
        ;;
esac


for file in "$@"; do
    gamelist=$(grep "^Platform: " "$file" | cut -d: -f2 | tr -d ' ' | tr [:upper:] [:lower:])
    [[ -z "$gamelist" ]] && continue
    gamelist+="_gamelist.xml"

    [[ -f "$gamelist" ]] || echo "<gameList />" > "$gamelist"

    # name : the very first line of the txt file
    name="$(head -1 "$file")"
    [[ -z "$name" ]] && continue

    # path : TODO
    # image : TODO
    # video : TODO
    # marquee : TODO

    # releasedate : "Release Year"
    releasedate="$(get_data "Release Year" "$file")"
    # Note: releasedate must be a date/time in the format %Y%m%dT%H%M%S or empty
    releasedate="$(date -d ${releasedate}-1-1 +%Y%m%dT%H%M%S)" || realeasedate=""

    # developer : "Developer"
    developer="$(get_data "Developer" "$file")"

    # publisher : "Publisher"
    publisher="$(get_data "Publisher" "$file")"

    # genre : "Genre"
    genre="$(get_data "Genre" "$file")"

    # players : "Players"
    players="$(get_data "Players" "$file")"
    # Note: players must be an integer
    players=$(echo $players | sed 's/[^0-9 ]//g' | tr -s ' ' '\n' | sort -nr | head -1)

    # desc : the content below "______" to the end of file
    desc="$(sed '/^__________/,$!d' "$file" | tail -n +2)"

    if [[ $(xmlstarlet sel -t -v "count(/gameList/game[name='$name'])" "$gamelist") -eq 0 ]]; then
        xmlstarlet ed -L -s "/gameList" -t elem -n "game" -v "" \
            -s "/gameList/game[last()]" -t elem -n "name" -v "$name" \
            -s "/gameList/game[last()]" -t elem -n "path" -v "$path" \
            -s "/gameList/game[last()]" -t elem -n "image" -v "$image" \
            -s "/gameList/game[last()]" -t elem -n "video" -v "$video" \
            -s "/gameList/game[last()]" -t elem -n "marquee" -v "$marquee" \
            -s "/gameList/game[last()]" -t elem -n "desc" -v "$desc" \
            -s "/gameList/game[last()]" -t elem -n "releasedate" -v "$releasedate" \
            -s "/gameList/game[last()]" -t elem -n "developer" -v "$developer" \
            -s "/gameList/game[last()]" -t elem -n "publisher" -v "$publisher" \
            -s "/gameList/game[last()]" -t elem -n "genre" -v "$genre" \
            -s "/gameList/game[last()]" -t elem -n "players" -v "$players" \
            "$gamelist"
    else
        xmlstarlet ed -L \
            -u "/gameList/game[name='$name']/path" -v "$path" \
            -u "/gameList/game[name='$name']/image" -v "$image" \
            -u "/gameList/game[name='$name']/video" -v "$video" \
            -u "/gameList/game[name='$name']/marquee" -v "$marquee" \
            -u "/gameList/game[name='$name']/desc" -v "$desc" \
            -u "/gameList/game[name='$name']/releasedate" -v "$releasedate" \
            -u "/gameList/game[name='$name']/developer" -v "$developer" \
            -u "/gameList/game[name='$name']/publisher" -v "$publisher" \
            -u "/gameList/game[name='$name']/genre" -v "$genre" \
            -u "/gameList/game[name='$name']/players" -v "$players" \
            "$gamelist"
    fi

    echo "\"$file\" data has been added to \"$gamelist\"."
done
