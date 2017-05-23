#!/usr/bin/env bash

REPO_FILE="es-repos.txt"

dialog --backtitle "W A R N I N G !" --title " WARNING! " \
    --yesno "\nThis script lets you install a non-official emulationstation mod in RetroPie. It is for those who want to test and help devs with feedback.\n\nBear in mind that many of those mods are still in development, and you need to know how to fix things if something break!\n\n\nDo you want to proceed?" \
    15 75 2>&1 > /dev/tty \
    || exit


function install_es() {
    repo="$1"
    branch="$2"
    curl -Is "${repo}/tree/${branch}" | grep -q '^Status: 200' \
    || (echo "Invalid repo/branch. Aborting..."; exit 1)

    for action in depends sources build install configure clean; do
        [[ "$action" == "sources" ]] && action+=" $repo $branch"
        sudo ~/RetroPie-Setup/retropie_packages.sh emulationstation $action
    done
}


if [[ -s "$REPO_FILE" ]]; then
    choice=$(dialog --menu "What do you want to do?" 17 75 10 \
        1 "Select an ES repo/branch from \"es-repos.txt\"" \
        2 "Enter an arbitrary ES repo/branch" \
        2>&1 > /dev/tty) \
        || exit
    
    if [[ "$choice" == 1 ]]; then
        i=1
        while read -r repo branch; do
            options+=( $((i++)) "$repo - $branch" )
        done < "$REPO_FILE"

        while true; do
            choice=$(dialog --menu "Choose an ES repository/branch." 17 75 10 "${options[@]}" 2>&1 > /dev/tty) \
            || exit

            repo=$(echo "${options[2*choice-1]}" | tr -d ' ' | cut -d- -f1)
            branch=$(echo "${options[2*choice-1]}" | tr -d ' ' | cut -d- -f2)

            dialog --yesno "Are you sure you want to install emulationstation branch \"$branch\" from \"$repo\"?" 15 75 2>&1 > /dev/tty \
            || continue
            break
        done
    fi

    install_es "$repo" "$branch"
    exit
fi


form=( $(dialog --form "Enter the repository URL and the branch name of the emulationstation you want to compile and install"  17 75 5 \
    "URL    :" 1 1 "https://github.com/RetroPie/EmulationStation" 1 10 80 0 \
    "branch :" 2 1 "master" 2 10 30 0 \
    2>&1 > /dev/tty) ) \
    || exit

repo="${form[0]}"
branch="${form[@]:1}"

install_es "$repo" "$branch"
