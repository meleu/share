#!/bin/bash
# n00b workaround to exclude joystick_selection entry from the gamelist.xml

line=$(grep -n '<path>\.\/joystick_selection\.sh' gamelist.xml | cut -d: -f1)

sed -i.bak "$((line-1)),$((line+4))d" gamelist.xml
