#!/bin/bash

original_file="/tmp/lr-fba-next_gamelist.txt"
gamelist=$(mktemp /tmp/gamelist.XXXX)
gamelist_url="https://raw.githubusercontent.com/libretro/libretro-fba/master/gamelist.txt"
romset_dir="$1"

# the path to romset is mandatory
if [[ -z "$romset_dir" ]]; then
    echo 'missing argument!' >&2
    echo "usage: $(basename $0) /path/to/the/romset" >&2
    exit 1
fi

# get the game list from the libretro-fba github repository
if ! [[ -f "$original_file" ]]; then
    wget -O "$original_file" "$gamelist_url"
fi

# excluding the header info and getting the game list table only
sed '/^\+-----/,/^\+-----/!d' "$original_file" > "$gamelist"

# reading the gamelist.txt line by line
while read -r line; do
    if [[ "$line" =~ ^\+----- ]]; then
        continue
    fi

    # using '|' as the field separator
    oldIFS="$IFS"
    IFS='|'
    content=( $line )
    IFS="$oldIFS"

    # the sed trick is to delete the leading/trailing spaces/tabs
    rom=$(echo ${content[1]} | sed -e 's/^[[:blank:]]*//; s/[[:blank:]]*$//').zip
    rom_status=${content[2]}
    full_name=${content[3]}
    parent=$( echo ${content[4]} | sed -e 's/^[[:blank:]]*//; s/[[:blank:]]*$//')

    # X = eXcluded from build; D = included in Debug build only; NW = Not Working
    if [[ "$rom_status" =~ X|D|NW ]]; then
        echo "Trying to delete \"$rom\". Reason: status not OK." >&2
        rm -vf "$romset_dir/$rom"
        continue
    fi
    
    # if it has a parent then it's a clone
    if [[ -n "$parent" ]]; then
        echo "Trying to delete \"$rom\". Reason: clone." >&2
        rm -vf "$romset_dir/$rom"
        continue
    fi
    
    if [[ -f "$romset_dir/$rom" ]]; then
        echo "Keeping $rom: $full_name" >&2
    fi
done < "$gamelist"

rm -f "$gamelist"
