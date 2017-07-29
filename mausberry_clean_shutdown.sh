#!/bin/bash
# Before using this script you need to install inotify-tools:
#
#    sudo apt-get install inotify-tools
#
# I'm just trying to help with the script logic here.
# I DON'T HAVE A MAUSBERRY AND DIDN'T TEST THE GPIO STUFF HERE!
#
#########################################################
#  U S E   I T   A T   Y O U R   O W N   R I S K ! ! !  #
#########################################################
#
# meleu - July/2017
# kudos for @cyperghost , who is very persistent in help you guys! :-)

#this is the GPIO pin connected to the lead on switch labeled OUT
GPIOpin1=23

#this is the GPIO pin connected to the lead on switch labeled IN
GPIOpin2=24

echo "$GPIOpin1" > /sys/class/gpio/export
echo "in" > /sys/class/gpio/gpio$GPIOpin1/direction
echo "$GPIOpin2" > /sys/class/gpio/export
echo "out" > /sys/class/gpio/gpio$GPIOpin2/direction
echo "1" > /sys/class/gpio/gpio$GPIOpin2/value

file="/sys/class/gpio/gpio$GPIOpin1/value"

# up to here this code is executed at booting (/etc/rc.local)
# let's wait for the creation of the "/sys/class/gpio/gpio$GPIOpin1/value"
sleep 30 # not sure if 30 seconds is a good value...

while inotifywait -qq -e modify "$file" ; do
    power="$(cat "$file")"
    [[ "$power" == 0 ]] && continue

    # explaining the crazy command below:
    # 1. get 4th line of runcommand.info (aka "emulator command"
    # 2. delete backslash '\' character
    # 3. replace every character that has a special meaning in a 
    #    regex context with a dot '.'
    emu_command="$(sed -n 4p /dev/shm/runcommand.info | tr -d '\\"' | tr '^$[]*.()|+?{}' '.')"
    [[ -n "$emu_command" ]] && pkill -f "$emu_command" && sleep 10

    espid=$(pgrep -f "/opt/retropie/supplementary/.*/emulationstation([^.]|$)")
    if [[ "$espid" ]]; then
        touch /tmp/es-shutdown && chown pi:pi /tmp/es-shutdown
        kill "$espid"
        exit
    fi

    sudo poweroff
done
