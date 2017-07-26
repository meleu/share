#!/bin/bash
# cheevoscraper.sh
##################
#
# Check if a rom has cheevos.


if ! source /opt/retropie/lib/inifuncs.sh ; then
    echo "ERROR: \"inifuncs.sh\" file not found! Aborting..." >&2
    exit 1
fi

# TODO: verificar dependencias: xmlstarlet e jq


readonly CONFIG_DIR="/opt/retropie/configs"
SYSTEM=
USER=
TOKEN=

RP_USER="$SUDO_USER"
[[ -z "$RP_USER" ]] && RP_USER="$(id -un)"


# Getting cheevos account info (needed to retrieve achievements list).
function get_cheevos_token() {
    iniConfig ' = ' '"'

    local global_retroarchcfg="$CONFIG_DIR/all/retroarch.cfg"
    local retroarchcfg="$CONFIG_DIR/$SYSTEM/retroarch.cfg"
    local cfgfile
    local password

    if [[ -n "$SYSTEM" && -f "$retroarchcfg" ]]; then
        included_cfgs="$(sed '/^#include/!d; s/^#include \+"\([^"]*\)"/\1/' "$retroarchcfg")"
        for cfgfile in "$retroarchcfg" $included_cfgs ; do
            iniGet cheevos_username "$cfgfile"
            USER="$ini_value"
            [[ -z "$USER" ]] && continue

            iniGet cheevos_password "$cfgfile"
            password="$ini_value"
            break
        done
    else
        iniGet cheevos_username "$global_retroarchcfg"
        USER="$ini_value"
        [[ -z "$USER" ]] && continue

        iniGet cheevos_password "$global_retroarchcfg"
        password="$ini_value"
    fi

    if [[ -z "$USER" || -z "$password" ]]; then
        echo "ERROR: failed to get cheevos account info. Aborting..."
        exit 1
    fi

    TOKEN="$(curl -s "http://retroachievements.org/dorequest.php?r=login&u=${USER}&p=${password}" | jq -r .Token)"
    if [[ "$TOKEN" == null || -z "$TOKEN" ]]; then
        echo "ERROR: cheevos authentication failed. Aborting..."
        exit 1
    fi
}


# Get the valid extensions for ROMs of a specific system
function get_extensions() {
    [[ -z "$SYSTEM" ]] && return 1

    for es_systems in "/home/$RP_USER/.emulationstation/es_systems.cfg" "/etc/emulationstation/es_systems.cfg"; do
        extensions=$(xmlstarlet sel -t -v "/systemList/system[name=\"$SYSTEM\"]/extension" "$es_systems")
        [[ -n "$extensions" ]] && break
    done
    [[ -z "$extensions" ]] && return 1
    echo "$extensions" | sed 's/\./\*\./g'
}


# Check if a game has cheevos.
# returns 0 if yes; 1 if not.
function game_has_cheevos() {
    local hash="$1"
    [[ -n "$hash" && -n "$TOKEN" ]] || return 1

    local gameid="$(curl -s "http://retroachievements.org/dorequest.php?r=gameid&m=$hash" | jq .GameID)"
    [[ -z "$gameid" || "$gameid" -lt 1 ]] && return 1

    local number_of_cheevos="$(curl -s "http://retroachievements.org/dorequest.php?r=patch&u=${USER}&g=${gameid}&f=3&l=1&t=${TOKEN}" | jq '.PatchData.Achievements | length')"
    [[ -z "$number_of_cheevos" || "$number_of_cheevos" -lt 1 ]] && return 1

    return 0
}


function scrape_cheevos() {
    local rom
    local hash
    local dir="/home/$RP_USER/RetroPie/roms/$SYSTEM/"
    [[ -n "$1" ]] && dir="$1"
    [[ -d "$dir" ]] || return 1

    local find_regex="$(get_extensions)"
    [[ -z "$find_regex" ]] && return 1
    find_regex="$(echo "$find_regex" | sed 's/\*//g; s/\./\\\./g; s/ \+/\\|/g; s/^/\.\*\\(/; s/$/\\)/')"

    get_cheevos_token

    while read -r rom; do
        [[ -f "$rom" ]] || continue
        echo -n "\nChecking \"$rom\"..."
        case "$rom" in
            *.zip|*.ZIP)
                hash="$(zcat "$rom" | md5sum | cut -d' ' -f1)"
                ;;
            *.7z|*.7Z)
                hash="$(7z e -so -bd "$rom" 2>/dev/null | md5sum | cut -d' ' -f1)"
                ;;
            *)
                hash="$(md5sum "$rom" | cut -d' ' -f1)"
                ;;
        esac
        [[ -z "$hash" ]] && continue

        game_has_cheevos "$hash" && echo " HAS CHEEVOS!"
    done < <(find "$dir" -regex "$find_regex" | sort)
}


# marcar o jogo como tendo achievements.

# START HERE ##################################################################

SYSTEM="$1"
scrape_cheevos
