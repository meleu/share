#!/bin/bash

readonly es_input="$HOME/.emulationstation/es_input.cfg"
readonly enter_btn=a     # es button to be used as enter in joy2key
readonly tab_btn=b       # es button to be used as tab in joy2key


function joy2key_input_config() {
    local dev
    local dev_name
    local path
    local enter_btn_num
    local tab_btn_num
    local biggest_num
    local i

    # "inspired" on configedit.sh code
    while read -r dev; do
        if udevadm info --name=$dev | grep -q "ID_INPUT_JOYSTICK=1"; then
            path="$(udevadm info --name=$dev | grep DEVPATH | cut -d= -f2)"
            dev_name="$(</$(dirname sys$path)/name)"

            enter_btn_num=$(get_btn_number "$enter_btn")
            tab_btn_num=$(get_btn_number "$tab_btn")

            [[ "$tab_btn_num" -gt "$enter_btn_num" ]] && biggest_num=$tab_btn_num || biggest_num=$enter_btn_num

            echo -n "$dev kcub1 kcuf1 kcuu1 kcud1 "

            for i in $(seq 0 $biggest_num); do
                if [[ $i -eq $enter_btn_num ]]; then
                    echo -n "0x0a "
                elif [[ $i -eq $tab_btn_num ]]; then
                    echo -n "0x09 "
                else
                    echo -n "\"\" "
                fi
            done
            echo
        fi
    done < <(find /dev/input -name "js*")
}


function get_btn_number() {
    local btn="$1"
    xmlstarlet sel -t -c \
        "/inputList/inputConfig[@deviceName='$dev_name']/input[@name='$btn']" "$es_input" \
        | grep -o 'id="[[:digit:]]\+"' | cut -d= -f2 | tr -d \"
}


joy2key_input_config
