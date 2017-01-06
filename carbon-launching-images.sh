# carbon-launching-images.sh
############################
#
# This script creates launching images for the Carbon theme.
# If you don't know what it is, take a look at these links:
# - https://github.com/retropie/retropie-setup/wiki/runcommand#adding-custom-launching-images
# - https://retropie.org.uk/forum/topic/4611/runcommand-system-splashscreens
#
# Requirements:
# - RetroPie 4.0.3+
# - the carbon theme installed (it's the default theme on RetroPie)
# - the imagemagick package installed (it means 26.1 MB of disk space used).
#
# Special thanks:
# - RetroPie team in the first place!
# - Rookervik for making the Carbon theme.
# - daeks for sharing his ImageMagick knowledge.

configs_path="/opt/retropie/configs"
carbon_path="/etc/emulationstation/themes/carbon/"
carbon_bg="${carbon_path}/art/carbon_fiber.png"
carbon_font="${carbon_path}/art/Cabin-Bold.ttf"

installed_systems="$(ls -1 $configs_path)"
installed_systems="${installed_systems/all/}"

# checking if we have the imagemagic installed
if ! which convert > /dev/null; then
    echo "ERROR: The imagemagick package isn't installed!"
    echo "Please install it with 'sudo apt-get install imagemagick'."
fi


# We will create launching screens only for the installed systems
for system in $installed_systems; do
    launching_image="${configs_path}/${system}/launching.png"

    echo "converting the svg file to png for the \"$system\" system..."

    # due to color problems, we use system3.png for gameandwatch and
    # system2.png for steam
    # TODO: deal with the gamecube also...
    if [[ "$system" != "gameandwatch" && "$system" != "steam" ]]; then
        convert -resize "x235>" -resize "600x>" "${carbon_path}/${system}/art/system.svg" /tmp/system.png
    elif [[ "$system" = "gameandwatch" ]]; then
        convert -resize "x235>" -resize "600x>" "${carbon_path}/${system}/art/system3.svg" /tmp/system.png
    elif [[ "$system" = "steam" ]]; then
        convert -resize "x235>" -resize "600x>" "${carbon_path}/${system}/art/system2.svg" /tmp/system.png
    fi

    if ! [[ -f /tmp/system.png ]]; then
        echo "ERROR: it seems that we had some problem when converting the SVG file to PNG!".
        echo "Aborting..."
        exit 1
    fi

    echo "Creating the launching image for the \"$system\" system."
    convert -size 800x600 tile:"$carbon_bg" -gravity center /tmp/system.png -composite "$launching_image"

    if [[ -f "$launching_image" ]]; then
        convert "$launching_image" -gravity center -font "$carbon_font" -weight 700 -pointsize 24 -fill white -annotate +0+170 "NOW LOADING" "$launching_image"
    fi

    if [[ -f "$launching_image" ]]; then
        convert "$launching_image" -gravity center -font "$carbon_font" -weight 700 -pointsize 14 -fill gray -annotate +0+230 "PRESS A BUTTON TO CONFIGURE\nLAUNCH OPTIONS" "$launching_image"
    fi

    if [[ -f "$launching_image" ]]; then
        convert "$launching_image" -quality 80 "$launching_image"
    fi

    echo "File \"$launching_image\" created with success!"
    echo
done

rm /tmp/system.png
