#!/usr/bin/env bash

source /opt/retropie/lib/inifuncs.sh

readonly tmpfile=$(mktemp)

iniConfig ' = ' '"'

find -maxdepth 1 -type d | sed 's|^\./\?||; /^$/d' > "$tmpfile"
    
while IFS='' read -r game || [[ -n "$game" ]]; do
    [[ "$game" == ".git" ]] && continue
    rom_zip_cfg="$(ls "$game"/*.zip.cfg)"
    ovl_cfg="${rom_zip_cfg/%zip.cfg/cfg}"
    rom="$(basename "$rom_zip_cfg")"
    rom="${rom%.zip.cfg}"
    ovl_img=( $(ls -b "$game/$rom"_*.png | xargs basename -a ) )

    i=1
    for ovl in ${ovl_img[@]}; do
        new_name="${ovl/%.png/-ovl.png}"
        if [[ "$ovl" != *-ovl.png ]]; then
            mv -v "$game/$ovl" "$game/$new_name"
            if [[ $i -eq 1 ]]; then
                iniSet overlay0_overlay "$new_name" "$ovl_cfg"
            fi
        fi
        ((i++))
    done

done < "$tmpfile"

rm -f "$tmpfile"
