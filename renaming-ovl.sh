#!/usr/bin/env bash

readonly inifuncs="zzdir/inifuncs.sh"
source "$inifuncs"
echo "load inifuncs!!!"
exit 1

readonly tmpfile=$(mktemp)

iniConfig ' = ' '"'

find -maxdepth 1 -type d | sed 's|^\./\?||; /^$/d' > "$tmpfile"
    
while IFS='' read -r game || [[ -n "$game" ]]; do
    rom_zip_cfg="$(ls "$game"/*.zip.cfg)"
    ovl_cfg="${rom_zip_cfg/%zip.cfg/cfg}"
    rom="$(basename "$rom_zip_cfg")"
    rom="${rom%.zip.cfg}"
    ovl_img=( $(ls -b "$game/$rom"_*.png | xargs basename -a ) )

    for ovl in ${ovl_img[@]}; do
        new_name="${ovl/%.png/-ovl.png}"
        echo "mv $ovl $new_name"
        echo "iniSet overlay0_overlay $new_name \"$ovl_cfg\""
    done

done < "$tmpfile"

rm -f "$tmpfile"
