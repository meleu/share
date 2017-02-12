#!/bin/bash - 

readonly BACKTITLE="MAME ROW management tool"

LAST_ROUND=20
LAST_ROUND_GAME="Super Glob"


function dialogMenu() {
    local title="$1"
    shift
    dialog \
        --backtitle "$BACKTITLE" \
        --title "$title" \
        --menu "Choose an option" 15 75 10 "$@" \
        2>&1 > /dev/tty
}


function dialogInput() {
    local text="$1"
    shift
    dialog \
        --backtitle "$BACKTITLE" \
        --inputbox "$text" 0 70 "$@" \
        2>&1 > /dev/tty
}


function dialogYesNo() {
    dialog --backtitle "$BACKTITLE" --yesno "$@" 10 75 2>&1 >/dev/tty
}


function main_menu() {
    local choice
    local cmd=(dialogMenu " Main Menu "
        1 "Create post for MAME ROW #$[ LAST_ROUND + 1]"
        2 "Previous rounds"
        3 "Manage MAME ROW gamelist"
        4 "Settings"
    )

    while true; do
        choice=$("${cmd[@]}")
        case "$choice" in
            1)
                echo TODO: create new post
                read
                ;;

            2)
                echo TODO: previous rounds
                read
                ;;

            3)
                manage_gamelist
                ;;

            4)
                echo TODO: settings
                read
                ;;

            *)
                break
                ;;
        esac
    done
}


function manage_gamelist() {
    local choice
    local cmd=(dialogMenu " Manage MAME ROW gamelist "
        1 "Update gamelist with a new round information"
        2 "Edit a previous round information"
        3 "Get gamelist from the github repository"
        4 "Send the local gamelist to the github repository"
    )
    while true; do
        choice=$("${cmd[@]}")
        case "$choice" in
            1)
                update_gamelist
                ;;

            2)
                echo TODO: edit gamelist
                ;;

            3)
                echo TODO: get gamelist
                read
                ;;

            4)
                echo TODO: send gamelist
                read
                ;;

            *)
                break
                ;;
        esac
    done
}


function update_gamelist() {
    local round
    local game_number
    local url
    local next_round=$[ LAST_ROUND + 1 ]
    local is_ok=0

    while true; do
        round=$(dialogInput "Enter the round number" "$next_round")

        # Cancel
        [[ -z "$round" ]] && return

        # if it's not a number, ask again
        [[ "$round" =~ ^[[:digit:]]+$ ]] || continue

        # the right choice!
        [[ "$round" -eq "$next_round" ]] && break

        dialogYesNo "The next round should be #$next_round but you chose #$round.\n\nAre you sure you want to update info for round #$round?" \
        && break
    done
    
    echo TODO: really update gamelist
    read
}

main_menu
