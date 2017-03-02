#!/usr/bin/env bash
# IT'S A WORK IN PROGRESS! CURRENTLY USELESS!
#
# TODO:
# - use _ovl.png in overlay filenames
# - install the overlay for a different core (maybe lr-fba)
# - dealing with "options", such as the "Burning Force/Option 1"

# TODO: romdir should be /home/$USER/RetroPie/roms/mame-libretro
readonly romdir="zzdir/roms_mame-libretro"

# TODO: inifuncs should be /opt/retropie/lib/inifuncs.sh
readonly inifuncs="zzdir/inifuncs.sh"
source "$inifuncs"

function games_menu() {
    local cmd=( dialog --checklist "Select the games you want to install the overlay." 18 70 60 )
    local options=()
    local choice
    local i=1

    find -maxdepth 1 -type d | sed 's|^\./\?||; /^$/d' > "$tmpfile"
    
    while IFS='' read -r game || [[ -n "$game" ]]; do
        options+=( "$i" "$game" off )
        ((i++))
    done < "$tmpfile"
    echo -n > "$tmpfile"

    choice=$("${cmd[@]}" "${options[@]}" 2>&1 >/dev/tty)
    for i in $choice; do
        echo "${options[3*i-2]}" >> "$tmpfile"
    done
}

function install_overlays() {
    local rom_zip_cfg
    local rom
    local ovl_dir
    local ovl_cfg
    local ovl_img=()
    local choice

    iniConfig ' = ' '"'

    games_menu

    while IFS='' read -r game || [[ -n "$game" ]]; do
        dialog --infobox "Installing overlay for \"$game\"..." 4 60

        rom_zip_cfg="$(ls "$game"/*.zip.cfg)"
        ovl_cfg="${rom_zip_cfg/%zip.cfg/cfg}"
        rom="$(basename "$rom_zip_cfg")"
        rom="${rom%.zip.cfg}"

        if ! [[ -f "$rom_zip_cfg" ]]; then
            # TODO: put some error message
            continue
        fi

        cp "$rom_zip_cfg" "$romdir"

        iniGet input_overlay "$rom_zip_cfg"
        ovl_dir="$(dirname "$ini_value")"
        mkdir -p "$ovl_dir"
        cp "$ovl_cfg" "$ini_value"
        ovl_cfg="$ini_value"
        # TODO: se @UDb23 aceitar a convencao _ovl.png tenho que adaptar isso
        cp "$game"/*.png "$ovl_dir"

        # TODO: se @UDb23 aceitar a convencao _ovl.png tenho que adaptar isso
        ovl_img=( $(ls "$ovl_dir/$rom"_*.png | xargs basename -a ) )

        if [[ ${#ovl_img[@]} -eq 1 ]]; then
            iniSet overlay0_overlay "$ovl_img" "$ovl_cfg"
            continue
        fi

        while true; do
            choice=$(dialog --no-items --menu "You have more than one overlay option for \"$game\".\n\nChoose a file to preview and then you'll have a chance to accept it or not." 22 76 16 "${ovl_img[@]}" 2>&1 > /dev/tty) \
            || break

            # TODO: add a preview fbi/feh command
            dialog --yesno "Do you accept the file \"$choice\" as the overlay for \"$game\"?" 7 60 2>&1 > /dev/tty \
            && break
        done
    done < "$tmpfile"
}


readonly tmpfile=$(mktemp)

install_overlays

rm -f "$tmpfile"
