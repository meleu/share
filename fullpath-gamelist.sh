#!/usr/bin/env bash
# fullpath-gamelist.sh
######################
#
# This script gets an ES gamelist.xml and tries to update the 
# <path> entries using the full path.
#
# meleu - 2017/Jun

DIRECTORY="$HOME/RetroPie"

readonly SCRIPT_DIR="$(dirname "$0")"
readonly SCRIPT_NAME="$(basename "$0")"
readonly SCRIPT_URL="https://raw.githubusercontent.com/meleu/share/master/fullpath-gamelist.sh"

readonly HELP="
Usage:
$0 [OPTIONS] gamelist.xml

The OPTIONS are:

-h|--help                       print this message and exit.

-u|--update                     update the script and exit.

-d|--directory  DIRECTORY       look for files in DIRECTORY.

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


function fullpath() {
    [[ -z "$1" ]] && return 1

    local element="$1"
    local rom
    local rom_full

    while read -r file; do
        rom="$(basename "$file")"
        find "$DIRECTORY"
        echo "$rom"
    done < <(xmlstarlet sel -t -v "/gameList/game/$element" "$GAMELIST"; echo)
}


case "$1" in
    -h|--help)
        echo "$HELP" >&2
        exit 0
        ;;
    -u|--update)
        if update_script; then
            echo "The script has been successfully updated. You can run it again."
            exit 0
        fi
        exit 1
        ;;
    -d|--directory)
        shift
        DIRECTORY="$1"
        if [[ ! -d "$DIRECTORY" ]]; then
            echo "ERROR: \"$DIRECTORY\": invalid directory." >&2
            exit 1
        fi
        shift
        ;;
    '')
        echo "ERROR: missing gamelist.xml" >&2
        echo "$HELP" >&2
        exit 1
        ;;
    -*)
        echo "ERROR: \"$1\": invalid option" >&2
        echo "$HELP" >&2
        exit 1
        ;;
esac

readonly GAMELIST="$1"

if [[ ! -f "$GAMELIST" ]]; then
    echo "ERROR: \"$GAMELIST\": file not found." >&2
    exit 1
fi

fullpath path
