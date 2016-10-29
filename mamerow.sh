#!/bin/bash
# mamerow.sh
############
#
# Show info about the ROM from MAME ROW gamelist.
#

set -o nounset                              # Treat unset variables as an error

readonly gamelist=mamerow_gamelist.txt

USAGE="
Usage:
$(basename $0) number1 [number2 [number3]]
"

if [[ -z "$1" ]]; then
    echo "$USAGE"
    exit 1
fi


for number in $@; do
    # checking if it's a number
    if ! [[ $number =~ ^[0-9]+$ ]]; then
        echo "Ignoring \"$number\": not an integer." >&2
        continue
    fi

    rom_info="$(sed -n ${number}p "$gamelist")"

    game_name=$(echo "$rom_info" | cut -d\; -f2 )
    company=$(  echo "$rom_info" | cut -d\; -f11)
    year=$(     echo "$rom_info" | cut -d\; -f10)
    rom_file=$( echo "$rom_info" | cut -d\; -f1 )
    bios=$(     echo "$rom_info" | cut -d\; -f7 )

    echo "
$number
**Game Name:** $game_name
**Company:** $company
**Year:** $year
**ROM file name: ${rom_file}.zip
**BIOS:** ${bios:--}
"
done
