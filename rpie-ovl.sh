#!/usr/bin/env bash
# IT'S A WORK IN PROGRESS! CURRENTLY USELESS!
#
# TODO:
# - adicionar opcao de instalar todos os overlays
# - adicionar opcao de em qual diretorio estao as ROMs
# - use _ovl.png in overlay filenames
# - install the overlay for a different core (maybe lr-fba)
# - dealing with "options", such as the "Burning Force/Option 1"

#readonly romdir="/home/$USER/RetroPie/roms/mame-libretro"
readonly romdir="/home/$USER/RetroPie/roms/arcade"
#readonly romdir="/home/$USER/RetroPie/roms/fba"
if ! [[ -d "$romdir" ]]; then
    echo "It seems that you put your roms in some unusual directory. Aborting..." >&2
    exit 1
fi

source /opt/retropie/lib/inifuncs.sh || exit 2

function show_image() {
    local image="$1"
    local timeout=5

    [[ -f "$image" ]] || return 1

    if [[ -n "$DISPLAY" ]]; then
        feh \
            --cycle-once \
            --hide-pointer \
            --fullscreen \
            --auto-zoom \
            --no-menus \
            --slideshow-delay $timeout \
            --quiet \
            "$image"
    else
        fbi \
            --once \
            --timeout "$timeout" \
            --noverbose \
            --autozoom \
            "$image" </dev/tty &>/dev/null
    fi
}

function games_menu() {
    local cmd=( dialog --checklist "Select the games you want to install the overlay." 18 70 60 )
    local options=()
    local choice
    local i=1

    find -maxdepth 1 -type d ! -name .git ! -name . | sed 's|^\./\?||' | sort > "$tmpfile"
    
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

        # TODO: if there is more than one .zip.cfg file, install both (Moon Cresta case)
        rom_zip_cfg="$(ls "$game"/*.zip.cfg | head -1)"
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
        cp "$game"/*-ovl.png "$ovl_dir"

        ovl_img=( $(ls "$ovl_dir/$rom"*-ovl.png | xargs basename -a ) )

        if [[ ${#ovl_img[@]} -eq 1 ]]; then
            iniSet overlay0_overlay "$ovl_img" "$ovl_cfg"
            continue
        fi

        while true; do
            choice=$(dialog --no-items --menu "You have more than one overlay option for \"$game\".\n\nChoose a file to preview and then you'll have a chance to accept it or not." 22 76 16 "${ovl_img[@]}" 2>&1 > /dev/tty) \
            || break

            show_image "$ovl_dir/$choice"
            dialog --yesno "Do you accept the file \"$choice\" as the overlay for \"$game\"?" 7 60 2>&1 > /dev/tty \
            && break
        done
    done < "$tmpfile"
}


readonly tmpfile=$(mktemp)

install_overlays

rm -f "$tmpfile"
