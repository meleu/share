#!/bin/bash - 
# gamelist-cleaner.sh
#####################
#
# This script gets a gamelist.xml as input and check if the path for the games
# leads to an existing file. If the file doesn't exist, the <game> entry will
# be deleted from the resulting gamelist.xml.
#
# Run the script with '--help' to get more info.
# 
# meleu - 2017/Jun

ROMS_DIR="$HOME/RetroPie/roms"

readonly SCRIPT_DIR="$(dirname "$0")"
readonly SCRIPT_NAME="$(basename "$0")"
readonly SCRIPT_FULL="$SCRIPT_DIR/$SCRIPT_NAME"
readonly SCRIPT_URL="https://raw.githubusercontent.com/meleu/share/master/gamelist-cleaner.sh"

readonly USAGE="Usage:
$0 [OPTIONS] [gamelist.xml]...
"

readonly HELP="
This script gets a gamelist.xml as input and check if the path for the games
leads to an existing file. If the file doesn't exist, the <game> entry will
be deleted and a cleaner gamelist.xml file will be generated.

The resulting file will be named \"gamelist.xml-clean\" and will be in the
same folder as the original file. Nothing changes in the original gamelist.xml.

$USAGE
The OPTIONS are:

-h|--help           print this message and exit.

-u|--update         update the script and exit.

-s|--system SYSTEM  specifies to which system the gamelist.xml file belongs,
                    e.g.: nes, megadrive. Default: name of the directory where
                    the file is located.

-d|--directory DIR  specifies the ROMs directory. Default:
                    $ROMS_DIR
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
        err_msg=$(mv "/tmp/$SCRIPT_NAME" "$SCRIPT_FULL" 2>&1) \
        || err_flag=1
    else
        err_flag=1
    fi

    if [[ $err_flag -ne 0 ]]; then
        err_msg=$(echo "$err_msg" | tail -1)
        echo "Failed to update \"$SCRIPT_NAME\": $err_msg" >&2
        exit 1
    fi
    
    chmod a+x "$SCRIPT_FULL"
    echo "The script has been successfully updated. You can run it again."
    exit 0
}


while [[ -n "$1" ]]; do
    case "$1" in
        -h|--help)
            echo "$HELP" >&2
            exit 0
            ;;
        -u|--update)
            update_script
            ;;
        -s|--system)
            shift
            CUSTOM_SYSTEM="$1"
            shift
            ;;
        -d|--directory)
            shift
            ROMS_DIR="$1"
            shift
            ;;
        '')
            echo "ERROR: missing gamelist.xml" >&2
            echo "$HELP" >&2
            exit 1
            ;;
        -*) # yes, files starting with '-' don't work in this script
            echo "ERROR: \"$1\": invalid option" >&2
            echo "$HELP" >&2
            exit 1
            ;;
        *)
            break
            ;;
    esac
done

for file in "$@"; do
    original_gamelist="$(readlink -e "$file")"
    clean_gamelist="${original_gamelist}-clean"
    gamelist_dir="$(dirname "$original_gamelist")"

    if [[ ! -s "$original_gamelist" ]]; then
        echo "\"$original_gamelist\": file not found or is zero-length. Ignoring..."
        continue
    fi

    system="$CUSTOM_SYSTEM"
    [[ -z "$system" ]] && system=$(basename "$gamelist_dir")
    if [[ ! -d "$ROMS_DIR/$system" ]]; then
        echo "WARNING: \"$ROMS_DIR/$system\": directory not found." >&2
        echo "You don't have a ROMs folder for a system named \"$system\"." >&2
        echo "Ignoring \"$original_gamelist\"..." >&2
        continue
    fi

    cat "$original_gamelist" > "$clean_gamelist"
    while read -r path; do
        full_path="$path"
        [[ "$path" == ./* ]] && full_path="$ROMS_DIR/$system/$path"
        [[ -f "$full_path" ]] && continue

        xmlstarlet ed -L -d "/gameList/game[path=\"$path\"]" "$clean_gamelist"
        echo "The game with <path> = \"$path\" has been removed from xml."
    done < <(xmlstarlet sel -t -v "/gameList/game/path" "$original_gamelist"; echo)
    echo
    echo "The \"$clean_gamelist\" is ready!"
    echo
    echo "See the difference between file sizes:"
    du -bh "$original_gamelist" "$clean_gamelist"
done