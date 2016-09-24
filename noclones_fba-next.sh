#!/bin/bash
# noclones_fba-next.sh
#########################
#
# This script was made to get, **from your existent romset**, only the ROMs
# that are working and are NOT clones.
#
# Usage: noclones_fba-next /path/to/original/romset /noclone/romset/destination
#
# How the script does it:
# - get the game list (txt file) from libretro fba repository.
# - make another list from the original game list, excluding the clones 
#   (ROMs that has a parent ROM) and the ROMs with a "not OK" flag.
# - from this new list (with good ROMs), copy those that you have in your
#   existing romset and copy to another directory.
#
# I'm pretty sure that clrmamepro and other romset managing tools do a better
# job, but I love to code! :D

gamelist_url="https://raw.githubusercontent.com/libretro/libretro-fba/master/gamelist.txt"
gamelist="/tmp/lr-fba-next_gamelist.txt"
noclone_list=$(mktemp /tmp/noclonelist.XXXX)

romset_dir="$1"
noclone_romset_dir="$2"

# the path to romsets are mandatory
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

# get the game list from the libretro-fba repository
if ! [[ -f "$gamelist" ]]; then
    if ! wget -O "$gamelist" "$gamelist_url"; then
        echo "failed to get the remote gamelist.txt" >&2
        exit 1
    fi
fi

# excluding the header info and getting the game list table only
sed -i '/^\+-----/,/^\+-----/!d' "$gamelist"

# delete the first and the last line of the table (those "-------" strings).
sed -i '1d;$d' "$gamelist"

# reading the gamelist.txt line by line
while read -r line; do
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

    # the sed trick below is to delete the leading/trailing spaces/tabs
    rom=$(echo $rom | sed -e 's/^[[:blank:]]*//; s/[[:blank:]]*$//').zip

    # create a list of the roms that we want and exist in the original romset
    if [[ -f "$romset_dir/$rom" ]]; then
        echo "$romset_dir/$rom" >> "$noclone_list"
    fi
done < "$gamelist"


# checking if the noclone rom list has something
if ! [[ -s "$noclone_list" ]]; then
    echo "There's no ROM to copy!" >&2
    exit 1
fi

echo "The list of working/noclone roms is ready!"
echo "Starting the copy..."

# copying the roms that we want to the destination dir
while read -r rom; do
    echo -n "Copying: "
    cp -v "$rom" "$noclone_romset_dir"
done < "$noclone_list"

# removing temp files
rm -f "$gamelist" "$noclone_list"

echo "Done!"
echo -n "Your new romset has $(ls -1 "$noclone_romset_dir" | wc -l) files "
echo "and takes $(du -hs "$noclone_romset_dir" | cut -f1) of your drive."
