#!/usr/bin/env bash

# This file is part of The RetroPie Project
#
# The RetroPie Project is the legal property of its developers, whose names are
# too numerous to list here. Please refer to the COPYRIGHT.md file distributed with this source.
#
# See the LICENSE.md file at the top-level directory of this distribution and
# at https://raw.githubusercontent.com/RetroPie/RetroPie-Setup/master/LICENSE.md
#

rp_module_id="yarman"
rp_module_desc="YARMan (Yet Another RetroPie Manager): PHP and JQuery based web frontend for managing your retropie installation"
rp_module_help="After launching yarman open a browser and go to http://your_retropie_ip:8080/"
rp_module_section="exp"
rp_module_flags="noinstclean"

function depends_yarman() {
    getDepends sqlite php php-sqlite
}

function install_bin_yarman() {
    gitPullOrClone "$md_inst" "https://github.com/daeks/yarman"
}

function install_yarman() {
    cd "$md_inst"
    chown -R $user:$user "$md_inst"
    sudo -u $user make install
}

function _is_enabled_yarman() {
    grep -q 'yarman\.sh.*--start' /etc/rc.local
    return $?
}

function enable_yarman() {
    local config="\"$md_inst/yarman.sh\" --start --user $user 2>\&1 > /dev/null \&"

    if _is_enabled_yarman; then
        dialog --yesno "yarman is already enabled in /etc/rc.local with the following config:\n\n$(grep "yarman\.sh" /etc/rc.local)\n\nDo you want to update it?" 22 76 2>&1 >/dev/tty \
        || return
    fi

    sed -i "/yarman\.sh.*--start/d" /etc/rc.local
    sed -i "s|^exit 0$|${config}\\nexit 0|" /etc/rc.local
    if _is_enabled_yarman; then
        printMsgs "dialog" "yarman enabled in /etc/rc.local\n\nIt will be started on next boot."
    else
        printMsgs "dialog" "Failed to enable yarman in /etc/rc.local!"
    fi
}

function disable_yarman() {
    if _is_enabled_yarman; then
        dialog --yesno "Are you sure you want to disable yarman on boot?" 22 76 2>&1 >/dev/tty \
        || return

        sed -i "/yarman\.sh.*--start/d" /etc/rc.local
        printMsgs "dialog" "yarman configuration in /etc/rc.local has been removed."
    else
        printMsgs "dialog" "yarman was already disabled in /etc/rc.local."
    fi
}

function remove_yarman() {
    sed -i "/yarman\.sh.*--start/d" /etc/rc.local
    rm -R "$md_inst"
}

function gui_yarman() {
    local cmd=()
    local options=(
        1 "Start yarman now"
        2 "Stop yarman now"
        3 "Enable yarman on Boot"
        4 "Disable yarman on Boot"
    )
    local choice
    local yarman_status
    local error_msg

    while true; do
        if [[ -f "$md_inst/yarman.sh" ]]; then
            yarman_status="$($md_inst/yarman.sh --isrunning)\n\n"
        fi
        if _is_enabled_yarman; then
            yarman_status+="yarman is currently enabled on boot"
        else
            yarman_status+="yarman is currently disabled on boot"
        fi
        cmd=(dialog --backtitle "$__backtitle" --menu "$yarman_status\n\nChoose an option." 22 86 16)
        choice=$("${cmd[@]}" "${options[@]}" 2>&1 >/dev/tty)
        if [[ -n "$choice" ]]; then
            case $choice in
                1)
                    dialog --infobox "Starting yarman" 4 30 2>&1 >/dev/tty
                    error_msg="$("$md_inst/yarman.sh" --start 2>&1 >/dev/null)" \
                    || printMsgs "dialog" "$error_msg"
                    ;;

                2)
                    dialog --infobox "Stopping yarman" 4 30 2>&1 >/dev/tty
                    error_msg="$("$md_inst/yarman.sh" --stop 2>&1 >/dev/null)" \
                    || printMsgs "dialog" "$error_msg"
                    ;;

                3)  enable_yarman
                    ;;

                4)  disable_yarman
                    ;;
            esac
        else
            break
        fi
    done
}
