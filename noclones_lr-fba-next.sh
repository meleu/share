#!/bin/bash

gamelist_url="https://raw.githubusercontent.com/libretro/libretro-fba/master/gamelist.txt"
gamelist="/tmp/lr-fba-next_gamelist.txt"
noclone_list=$(mktemp /tmp/noclonelist.XXXX)
romset_dir="$1"
noclone_romset_dir="$2"

rm -f "$noclone_list"

# the path to romset is mandatory
if [[ -z "$romset_dir" || -z "$2" ]]; then
    echo 'missing argument!' >&2
    echo "usage: $(basename $0) /path/to/original/romset /noclone/romset/destination" >&2
    exit 1
fi

# creating the noclones destination directory
mkdir -p "$noclone_romset_dir"

# checking the directories
for dir in "$romset_dir" "$noclone_romset_dir"; do
    if ! [[ -d "$dir" ]]; then
        echo "invalid directory: $dir" >&2
        exit 1
    fi
done

# get the game list from the libretro-fba github repository
if ! [[ -f "$gamelist" ]]; then
    if ! wget -O "$gamelist" "$gamelist_url"; then
        echo "failed to get the remote gamelist.txt" >&2
        exit 1
    fi
fi

# excluding the header info and getting the game list table only
sed -i '/^\+-----/,/^\+-----/!d' "$gamelist"

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

    rom="${content[1]}"
    rom_status="${content[2]}"
    parent="${content[4]}"

    # X = eXcluded from build; D = included in Debug build only; NW = Not Working
    if [[ "$rom_status" =~ X|D|NW ]]; then
        echo "Ignoring $rom - Reason: status not OK." >&2
        continue
    fi
    
    # if it has a parent then it's a clone
    if ! [[ "$parent" =~ ^[[:blank:]]*$ ]]; then
        echo "Ignoring $rom - Reason: clone." >&2
        continue
    fi

    # if the script reaches this point, the rom is working and is not a clone

    # the sed trick is to delete the leading/trailing spaces/tabs
    rom=$(echo $rom | sed -e 's/^[[:blank:]]*//; s/[[:blank:]]*$//').zip
    if [[ -f "$romset_dir/$rom" ]]; then
        # create a list of the roms that we want
        echo "\"$romset_dir/$rom\"" >> "$noclone_list"
    fi
done < "$gamelist"


# checking if the noclone rom list has something
if ! [[ -s "$noclone_list" ]]; then
    echo "There's no ROM to copy!" >&2
    exit 1
fi


echo "The list of working/noclone roms is ready!"

# copying the roms that we want to the destination dir
while read -r rom; do
    echo -n "Copying: "
    cp -v "$rom" "$noclone_romset_dir"
done < "$noclone_list"

rm -f "$gamelist" "$noclone_list"

