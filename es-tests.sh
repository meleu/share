#!/usr/bin/env bash

dialog --backtitle "W A R N I N G !" --title " WARNING! " \
    --yesno "\nThis script lets you install a non-official emulationstation mod in RetroPie. It is for those who want to test and help devs with feedback.\n\nBear in mind that many of those mods are still in development, and you need to know how to fix things if something break!\n\n\nDo you want to proceed?" \
    15 75 2>&1 > /dev/tty \
    || exit


function dialogMsg() {
    dialog --no-mouse --backtitle "$BACKTITLE" --msgbox "$@" 20 70 2>&1 > /dev/tty
}


form=( $(dialog --form "Enter the repository URL and the branch name of the emulationstation you want to compile and install"  17 75 5 \
    "URL    :" 1 1 "https://github.com/RetroPie/EmulationStation" 1 10 80 0 \
    "branch :" 2 1 "master" 2 10 30 0 \
    2>&1 > /dev/tty) ) \
    || exit

repo="${form[0]}"
branch="${form[@]:1}"

curl -Is "${repo}/tree/${branch}" | grep -q '^Status: 200' \
|| (echo "Invalid repo/branch. Aborting..."; exit 1)

for action in depends sources build install configure clean; do
    [[ "$action" == "sources" ]] && action+=" $repo $branch"
    sudo ~/RetroPie-Setup/retropie_packages.sh emulationstation $action
done
