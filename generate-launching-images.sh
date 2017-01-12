# generate-launching-images.sh
############################
#
# This script creates launching images for a specific theme.
# If you don't know what it is, take a look at these links:
# - https://github.com/retropie/retropie-setup/wiki/runcommand#adding-custom-launching-images
# - https://retropie.org.uk/forum/topic/4611/runcommand-system-splashscreens
#
# Requirements:
# - RetroPie 4.0.3+
# - the theme installed (it's the default theme on RetroPie)
# - the imagemagick package installed (it means 26.1 MB of disk space used).
#
# TODO: 
# - polish the code
# - use trap to delete the /tmp files
# - add option to apply color to the logo
# - add option to apply color to the background
# - add option to use a solid color as a background
# - add an option to put a color belt as the logo background
# - add an option to change the text color. Color to make available:
#   black white gray gray10 gray25 gray50 gray75 gray90
#   pink red orange yellow green silver blue cyan purple brown

# globals ###################################################################

# the first string of ES_DIR array MUST be the /etc/emulationstation
readonly ES_DIR=("/etc/emulationstation" "$HOME/.emulationstation")
readonly CONFIGS="/opt/retropie/configs"
readonly TMP_BACKGROUND="/tmp/background.png"
readonly TMP_LOGO="/tmp/system_logo.png"
readonly TMP_LAUNCHING="/tmp/launching"

theme=
theme_dir=
system=
failed=()
background=
bg_color=
logo=
font=
loading_text_color="white"
press_a_button_text_color="gray50"

# if you're running it over SSH, you won't be able to see the images to
# accept it. If you want to accept it anyway, set the "yes_flag" to true.
yes_flag=false


# functions #################################################################

function usage() {
    echo
    echo "USAGE: $(basename $0) theme-name"
    echo
    echo "Available themes on your system:"
    local dir=
    for dir in "${ES_DIR[@]}"; do
        ls -d "$dir"/themes/*/ | xargs basename -a
    done
}



function check_dep() {
    # checking if we have the imagemagick installed
    if ! which convert > /dev/null; then
        echo "ERROR: The imagemagick package isn't installed!"
        echo "Please install it with 'sudo apt-get install imagemagick'."
        exit 1
    fi

    # if we are running under X we need feh
    if [[ -n "$DISPLAY" ]] && ! which feh > /dev/null; then
        echo "ERROR: The feh package isn't installed!"
        echo "Please install it with 'sudo apt-get install feh'."
        exit 1
    fi
}



function check_args() {
    if [[ -z "$1" ]]; then
        echo "ERROR: Missing theme name."
        usage
        exit 1
    fi

    theme="$1"

    local dir=
    # XXX: it'll look for the themes on /etc/emulationstation first.
    #      Maybe it should look at the $HOME/.emulationstation first.
    for dir in "${ES_DIR[@]}"; do
        theme_dir="$dir/themes/$theme"
        [[ -d "$theme_dir" ]] && break
    done

    if ! [[ -d "$theme_dir" ]]; then
        echo "ERROR: there's no theme named \"$1\" installed."
        usage
        exit 1
    fi
}



# Get the useful data for a theme of a specific system. The "system" global
# variable must be filled.
function get_data_from_theme_xml() {
    if [[ -z "$1" ]]; then
        echo "ERROR: get_data_from_theme_xml(): missing argument."
        echo "Available options: background font logo tile bg_color"
        exit 1
    fi

    if [[ -z "$system" ]]; then
        echo "ERROR: get_data_from_theme_xml(): the system is undefined."
        exit 1
    fi

    local xml_path=
    local system_theme_dir=
    local xml_file=
    local data=""

    system_theme_dir=$(
        xmlstarlet sel -t -v \
          "/systemList/system[name='$system']/theme" \
          "$ES_DIR/es_systems.cfg"
    )

    xml_file="$theme_dir/$system_theme_dir/theme.xml"

    case "$1" in
    "background")
        xml_path="/theme/view[contains(@name,'system')]/image[@name='background']/path"
        ;;
    "tile")
        xml_path="/theme/view[contains(@name,'system')]/image[@name='background']/tile"
        ;;
    "bg_color")
        xml_path="/theme/view[contains(@name,'system')]/image[@name='background']/color"
        ;;
    "logo")
        xml_path="/theme/view[contains(@name,'detailed')]/image[@name='logo']/path"
        ;;
    "font")
        xml_path="/theme/view[contains(@name,'detailed')]/textlist/fontPath"
        ;;
    *)
        echo "ERROR: get_data_from_theme_xml(): invalid argument"
        exit 1
        ;;
    esac


    data=$(
        xmlstarlet sel -t -v \
          "$xml_path" \
          "$xml_file" 2> /dev/null
    )
    
    # if don't find the wanted data on the theme.xml, let's see if there's
    # some <include>d file in it and look for the data there.
    if [[ -z "$data" ]]; then
        local included_xml=$(
            xmlstarlet sel -t -v \
              "/theme/include" \
              "$xml_file" 2> /dev/null
        )

        [[ -z "$included_xml" ]] && return

        xml_file="$(dirname $xml_file)/$included_xml"

        data=$(
            xmlstarlet sel -t -v \
              "$xml_path" \
              "$xml_file" 2> /dev/null
        )
    fi

    [[ -z "$data" ]] && return

    if [[ "$1" = "tile" || "$1" = "bg_color" ]]; then
        echo "$data"
        return
    fi
    
    # dealing with known issues in themes
    if [[ "$theme" = "carbon" ]]; then
        if [[ "$1" = "logo" ]]; then
            # due to color problems, we use system3.png for gameandwatch
            # and system2.png for steam
            # TODO: deal with the gamecube also...
            case "$system" in
            "gameandwatch")
                data="${data/%system.svg/system3.svg}"
                ;;
            "steam")
                data="${data/%system.svg/system2.svg}"
                ;;
            esac
        fi

    fi

    echo "$(dirname $xml_file)/$data"
} # end of get_data_from_theme_xml()


function create_launching_image() {
    if [[ -z "$system" ]]; then
        echo "ERROR: get_data_from_theme_xml(): the system is undefined."
        exit 1
    fi

    #############################
    # getting the background file
    background=$(get_data_from_theme_xml background)
    if [[ -z "$background" ]]; then
        echo "WARNING: No background found for \"$system\" system."
        return 1
    fi

    ##############################
    # getting the background color
    bg_color=$(get_data_from_theme_xml bg_color)
    if [[ -n "$bg_color" ]]; then
        # XXX: dealing with a known issue with the material theme.
        #      This is an ugly workaround.
        if [[ "$theme" = material ]]; then
            convert -fill "#$bg_color" -colorize 100,100,100 \
              "$background" "$TMP_BACKGROUND"
            background="$TMP_BACKGROUND"
        else
            convert -fill "#$bg_color" -colorize 25,25,25 \
              "$background" "$TMP_BACKGROUND"
            background="$TMP_BACKGROUND"
        fi
    fi

    #######################
    # getting the logo file
    logo=$(get_data_from_theme_xml logo)
    if [[ -z "$logo" ]]; then
        echo "WARNING: No logo found for \"$system\" system."
        return 1
    fi

    convert -background none \
      -resize "450x176" \
      "$logo" "$TMP_LOGO"
    
    if ! [[ -f "$TMP_LOGO" ]]; then
        echo "WARNING: we had some problem when converting \"$system\" logo image."
        return 1
    fi

    #######################
    # getting the font file
    font=$(get_data_from_theme_xml font)
    if [[ -z "$font" ]]; then
        echo "WARNING: No font found for \"$system\" system."
        return 1
    fi


    convert_cmd=(convert)
    if [[ "$(get_data_from_theme_xml tile)" =~ ^[Tt][Rr][Uu][Ee]$ ]]; then
        convert_cmd+=(-size 800x600 "tile:")
    else
        convert_cmd+=(-resize 'x600' " ") # the trailing space is needed
    fi
    
    # the convert commands are nested to ensure that everything runs fine
    ${convert_cmd[@]}"$background" \
      -gravity center "$TMP_LOGO" \
      -composite "$TMP_LAUNCHING.png" \
    && convert "$TMP_LAUNCHING.png" \
      -gravity center \
      -font "$font" \
      -weight 700 \
      -pointsize 24 \
      -fill "$loading_text_color" \
      -annotate +0+170 "NOW LOADING" \
      "$TMP_LAUNCHING.png" \
    && convert "$TMP_LAUNCHING.png" \
      -gravity center \
      -font "$font" \
      -weight 700 \
      -pointsize 14 \
      -fill "$press_a_button_text_color" \
      -annotate +0+230 "PRESS A BUTTON TO CONFIGURE LAUNCH OPTIONS" \
      "$TMP_LAUNCHING.png" \
    && convert "$TMP_LAUNCHING.png" -quality 80 "$TMP_LAUNCHING.jpg" \
    && echo "Launching image for \"$system\" created with success!" \
    || failed+=($system)


    # XXX: this is ugly!
    if [[ "$yes_flag" =~ ^[Tt][Rr][Uu][Ee]$ ]]; then
        mv "$TMP_LAUNCHING.jpg" "$CONFIGS/$system/launching.jpg"
    else
        show_image "$TMP_LAUNCHING.jpg"
        dialog \
          --yesno "Do you accept this as the launching image for \"$system\" system?" \
          8 55 \
          && mv "$TMP_LAUNCHING.jpg" "$CONFIGS/$system/launching.jpg"
          return 0
    fi
} # end of creating_launching_image



function show_image() {
    if [[ -z "$1" ]]; then
        echo "ERROR: show_image(): missing image file name."
        exit 1
    fi
    local image="$1"

    # if we are running under X use feh otherwise try and use fbi
    # TODO: display the image until user press enter (no timeout)
    if [[ -n "$DISPLAY" ]]; then
        feh -F -N -Z -Y -q "$image" & &>/dev/null
        IMG_PID=$!
        sleep 5
        kill -SIGINT "$IMG_PID" 2>/dev/null
    else
        fbi -1 -t 5 -noverbose -a "$image" </dev/tty &>/dev/null
    fi
}

# start here ################################################################

check_dep

check_args "$@"

installed_systems=$(
    xmlstarlet sel -t -v \
      "/systemList/system/name" \
      "$ES_DIR/es_systems.cfg"
)
# ignoring retropie menu
installed_systems="${installed_systems/retropie/}"

# XXX: this is ugly!
if [[ "$yes_flag" =~ ^[Tt][Rr][Uu][Ee]$ ]]; then
    dialog \
      --yesno "You chose to not see the generated images before installing them. Do you want to proceed?" \
      10 55 || exit
else
    dialog \
      --msgbox "We're going to show the generated launching images for the systems you have.\n\nEach image will be displayed for 5 seconds and then you have to accept it or not." \
      10 55
fi

for system in $installed_systems; do
    if ! create_launching_image ; then
        echo "The launching image for \"$system\" was NOT created."
        failed+=($system)
        continue
    fi
done

if [[ -n "$failed" ]]; then
    echo "Failed to create images for the following systems: ${failed[@]}"
fi

