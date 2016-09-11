This is my tweak to display a custom "launching" image instead of the traditional runcommand dialog.

The image will be used rather than the dialog if, and only if, there is a file named "launching.jpg" (or .png) in `$configdir/$system` or `$configdir/all` directory (`$system` takes precedence).

My inspiration was the @rookervik [forum post here](https://retropie.org.uk/forum/topic/3262/loading-a-custom-image-on-the-run-command). I tested with some cool launching images @lilbud made and put [here in the forum](https://retropie.org.uk/forum/topic/36/splashscreens/97).

```
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
