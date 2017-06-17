#!/bin/bash - 
# Used2BeTXT.sh
###############


DIRECTORY="$HOME/RetroPie"

readonly SCRIPT_DIR="$(dirname "$0")"
readonly SCRIPT_NAME="$(basename "$0")"
readonly SCRIPT_URL="https://raw.githubusercontent.com/meleu/share/master/Used2BeTXT.sh"

readonly HELP="
NEED TO WRITE THE HELP MESSAGE
"


function update_script() {
    local err_flag=0
    local err_msg

    err_msg=$(wget "$SCRIPT_URL" -O "/tmp/$SCRIPT_NAME" 2>&1) \
    && err_msg=$(cp "/tmp/$SCRIPT_NAME" "$SCRIPT_DIR/$SCRIPT_NAME" 2>&1) \
    || err_flag=1

    if [[ $err_flag -ne 0 ]]; then
        err_msg=$(echo "$err_msg" | tail -1)
        echo "Failed to update \"$SCRIPT_NAME\": $err_msg" >&2
        return 1
    fi
}


function get_data() {
    sed -e "/^$1:/!d ; s/^$1: //" "$2"
}



for file in "$@"; do
    gamelist=$(grep "^Platform: " "$file" | cut -d: -f2 | tr -d ' ' | tr [:upper:] [:lower:])
    [[ -z "$gamelist" ]] && continue
    gamelist+="_gamelist.xml"

    [[ -f "$gamelist" ]] || echo "<gameList />" > "$gamelist"

    # name : the very first line of the txt file
    name="$(head -1 "$file")"
    [[ -z "$name" ]] && continue

    # path : ? TODO
    # image : ? TODO
    # video : ? TODO
    # marquee : ? TODO

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
