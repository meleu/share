This is my tweak to display a custom "launching" image instead of the traditional runcommand dialog.

The intention is to use an image rather than the dialog only if the original conditions to show the dialog are satisfied **AND** there is a file named "launching.jpg" (or .png) in `$configdir/$system` or `$configdir/all` directory (`$system` takes precedence). If there is no "launching" image, the traditional dialog will be used.

Some points:
- it by no means changes the functionality of the runcommand configs (launch menu, launch menu art, and launch menu joystick control).
- Keep the capability to access the runcommand menu while launching a game ("press a button to config").
- The launching image can be system specific (in `$configdir/$system/`) or a more general one (in `$configdir/all/`).

My inspiration was the @rookervik [forum post here](https://retropie.org.uk/forum/topic/3262/loading-a-custom-image-on-the-run-command) and I tested with some cool launching images @lilbud made and put [here in the forum](https://retropie.org.uk/forum/topic/36/splashscreens/97).

```sh
# checking for a custom "launching" images
for path in "$configdir/$system" "$configdir/all" ; do
    if [[ -f "$path/launching.jpg" ]]; then
        image="$path/launching.jpg"
        break
    elif [[ -f "$path/launching.png" ]]; then
        image="$path/launching.png"
        break
    fi
done
# display the custom "launching" image if it was found
if [[ -n "$image" ]]; then
    fbi -1 -t 2 -noverbose -a "$image" </dev/tty &>/dev/null &
else
    local launch_name
    if [[ -n "$rom_bn" ]]; then
        launch_name="$rom_bn ($emulator)"
    else
        launch_name="$emulator"
    fi
    DIALOGRC="$configdir/all/runcommand-launch-dialog.cfg" dialog --infobox "\nLaunching $launch_name ...\n\nPress a button to configure\n\nErrors are logged to $log" 9 60
fi
```
