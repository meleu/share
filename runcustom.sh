#!/usr/bin/env bash

# testing if it's a symbolic link
if [[ ! -L "$1" ]]; then
    dialog --msgbox "ERROR: \"$1\" is not a symbolic link." 0 0
    exit 1
fi

# getting the name of the file that the symbolic link points to
rom="$(readlink "$1")"

# getting the system based on the folder the rom is stored
system="$(echo "$rom" | sed 's|\(.*/RetroPie/roms/[^/]*\).*|\1|' | xargs basename)"

# looking for the custom launching image
image="$(find "$(dirname "$1")" -type f -name launching.png -o -name launching.jpg -print -quit)"

# show the custom launching image
fbi -1 -t 2 -noverbose -a "$image" </dev/tty &>/dev/null &

# now launch runcommand normally
/opt/retropie/supplementary/runcommand/runcommand.sh 0 _SYS_ "$system" "$rom"
