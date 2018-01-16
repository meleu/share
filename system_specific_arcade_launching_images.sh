# START of the trick for custom arcade launching images #######################
function custom_arcade_launching_images() {
    if [[ "$1" != "arcade" ]]; then
        return
    fi
    local emulator="$2"
    local rom_name="$(basename "$3")"
    local rom_no_ext="${rom_name%.*}"
    local arcade_imgs_dir="$HOME/RetroPie/roms/arcade/images"
    local img_no_ext="$arcade_imgs_dir/$rom_no_ext"
    local img
    local config_dir="/opt/retropie/configs"
    local system
    local system_img_no_ext
    local system_img
    local ext

    # checking if it's mame or fba emulator
    if grep -q "^$emulator \?=" "$config_dir/mame-libretro/emulators.cfg"; then
        system="mame-libretro"
    elif grep -q "^$emulator \?=" "$config_dir/fba/emulators.cfg"; then
        system="fba"
    elif grep -q "^$emulator \?=" "$config_dir/mame-advmame/emulators.cfg"; then
        system="mame-advmame"
    elif grep -q "^$emulator \?=" "$config_dir/mame-mame4all/emulators.cfg"; then
        system="mame-mame4all"
    else
        return 1 # system not found
    fi

    # checking if there's a launching image for the respective system
    system_img_no_ext="$config_dir/$system/launching"
    for ext in jpg png; do
        if [[ -f "$system_img_no_ext.$ext" ]]; then
            system_img="$system_img_no_ext.$ext"
            break
        fi
    done
    if [[ -z "$system_img" ]]; then
        return
    fi

    # checking if the game already has a dedicated launching-image.
    for ext in jpg png; do
        if [[ -f "$img_no_ext.$ext" ]]; then
            img="$img_no_ext.$ext"
            break
        fi
    done
    # if the image is not a symlink, then do not change it
    if [[ -f "$img" && ! -L "$img" ]]; then
        return
    fi

    # if the file doesn't exists OR is a symbolic link, then we can mess with it
    rm -f "$img"

    # avoiding duplicated launching images with different extensions
    ext="${system_img##*.}"
    case "$ext" in
        jpg) rm -f "$img_no_ext.png" ;;
        png) rm -f "$img_no_ext.jpg" ;;
    esac

    # Phew! We're finally ready to create the symbolic link!
    ln -s "$system_img" "$img_no_ext.$ext"
}

custom_arcade_launching_images "$@"
# END of the trick for custom arcade launching images #########################
