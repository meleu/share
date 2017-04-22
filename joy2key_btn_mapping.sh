#!/bin/bash

. /opt/retropie/lib/inifuncs.sh
readonly CONFIGDIR=/opt/retropie/configs
iniConfig ' = ' '"'

function joy2key_btn_mapping() {
    local dev="$1"
    [[ "$dev" != "/dev/input/js"* ]] && return 1

    local dev_name
    local dev_path
    local retroarchcfg="$CONFIGDIR/all/retroarch.cfg"
    local joypadcfg
    local enter_btn=a
    local enter_btn_num
    local tab_btn=b
    local tab_btn_num
    local biggest_num
    local i
    local params

    iniGet menu_swap_ok_cancel_buttons "$retroarchcfg"
    if [[ "$ini_value" == true ]]; then
        enter_btn=b
        tab_btn=a
    fi

    udevadm info --name=$dev 2> /dev/null | grep -q "ID_INPUT_JOYSTICK=1" || return 1

    dev_path="$(udevadm info --name=$dev | grep DEVPATH | cut -d= -f2)"
    dev_name="$(</$(dirname sys$dev_path)/name)"

    # get the retroarch config file for this joypad
    joypadcfg="$(grep -l "input_device *= *\"$dev_name\"" "$CONFIGDIR/all/retroarch-joypads/"*.cfg)"
    [[ -f "$joypadcfg" ]] || output_params
    iniGet input_device "$joypadcfg"
    [[ "$ini_value" != "$dev_name" ]] && output_params

    enter_btn_num=$(get_btn_number "$enter_btn") || output_params
    tab_btn_num=$(get_btn_number "$tab_btn") || output_params

    biggest_num=$tab_btn_num
    [[ "$tab_btn_num" -lt "$enter_btn_num" ]] && biggest_num=$enter_btn_num

    for i in $(seq 0 $biggest_num); do
        case $i in
            $enter_btn_num) params+=" 0x0a" ;;
            $tab_btn_num)   params+=" 0x09" ;;
            *)              params+=" ''" ;;
        esac
    done

    output_params
}


function get_btn_number() {
    local btn="$1"
    iniGet input_${btn}_btn "$joypadcfg"
    if [[ -z "$ini_value" ]]; then
        iniGet input_player1_${btn}_btn "$joypadcfg"
        [[ -z "$ini_value" ]] && return 1
    fi
    echo "$ini_value"
}

function output_params() {
    # default button mappings: 0 = enter; 1 = tab
    [[ -z "$params" ]] && params="0x0a 0x09"

    echo $params
    exit
}

joy2key_btn_mapping "$1"
