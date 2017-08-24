#!/bin/bash
# images-cleaner.sh
#####################
#
# This script looks at each image filename in [IMAGE_DIR] and searches for the
# filename in the equivalent [GAMELIST_DIR] gamelist.xml matching the system.
# Change the default directories if needed
#
# WARNING: Images will be deleted unless -t|--test option is supplied
#
# Run the script with '--help' to get more info.
# 
# sano - initial code in forum post
# kaltinril - 2017-08-20 - converted into script with command-line arguments
#
# TODO:
# 1. find every image file (png|jpg) on ~/.emulationstation/downloaded_images/
# 2. loop every file searching for an occurrence in the respective gamelist.
# 2.1 if there's no occurrence, delete it.


# Global Variables
REPLACE_GAMELIST=false
GAMELISTS_DIR="$HOME/.emulationstation/gamelists"
IMAGES_DIR="$HOME/.emulationstation/downloaded_images"
TEST_ONLY=false
SUMMMARY_ONLY=false
IMAGES_DELETED=0
SYSTEMS_CHECKED=0
IMAGES_FILESIZE=0


# Read only Variables
readonly SCRIPT_DIR="$(dirname "$0")"
readonly SCRIPT_NAME="$(basename "$0")"
readonly SCRIPT_FULL="$SCRIPT_DIR/$SCRIPT_NAME"
readonly SCRIPT_URL="https://raw.githubusercontent.com/meleu/share/master/images-cleaner.sh"

readonly USAGE="Usage:
$0 [OPTIONS] [gamelist.xml]...
"

readonly EXAMPLE="Examples:
  Normal:       $0
  Test only:    $0 -t
  Summary only: $0 -s
  Gamelist dir: $0 -g /home/pi/RetroPie/roms
  Images dir:   $0 -i /home/pi/./emulationstation/downloaded_images
"

readonly HELP="
This script looks at each image filename in IMAGE_DIR and searches for the
filename in the equivalent GAMELIST_DIR gamelist.xml matching the system.

Change the default directories if needed

WARNING: Images will be deleted unless -t|--test option is supplied

$USAGE
$EXAMPLE
The OPTIONS are:

-h|--help           print this message and exit.

-u|--update         update the script and exit.

-t|--test           test only, do not actually delete anything.

-i|--images DIR     specifies the IMAGEs directory. Default:
                    $IMAGES_DIR

-g|--gamelist DIR   specifies the gamelist directory.  Default:
                    $GAMELISTS_DIR
                    
-s|--summary        Only print a summary when done.
"

function update_script() {
    local err_flag=0
    local err_msg

    if err_msg=$(wget "$SCRIPT_URL" -O "/tmp/$SCRIPT_NAME" 2>&1); then
        if diff -q "$SCRIPT_FULL" "/tmp/$SCRIPT_NAME" >/dev/null; then
            echo "You already have the latest version. Nothing changed."
            rm -f "/tmp/$SCRIPT_NAME"
            exit 0
        fi
        err_msg=$(mv "/tmp/$SCRIPT_NAME" "$SCRIPT_FULL" 2>&1) \
        || err_flag=1
    else
        err_flag=1
    fi

    if [[ $err_flag -ne 0 ]]; then
        err_msg=$(echo "$err_msg" | tail -1)
        echo "Failed to update \"$SCRIPT_NAME\": $err_msg" >&2
        exit 1
    fi
    
    chmod a+x "$SCRIPT_FULL"
    echo "The script has been successfully updated. You can run it again."
    exit 0
}

function print_summary() {
    echo
    echo "Summary of work:"
    echo " - Systems checked: $SYSTEMS_CHECKED"
    [[ "$TEST_ONLY" == true ]] && echo " ---- TEST ONLY, NO DELETIONS ----"
    echo " - Images deleted:  $IMAGES_DELETED"
    echo " - Space freed:     $IMAGES_FILESIZE"
}

# Get all the user passed in arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help)
            echo "$HELP" >&2
            exit 0
            ;;
        -u|--update)
            update_script
            ;;
        -g|--gamelist)
            shift
            GAMELISTS_DIR="$1"
            ;;
        -i|--images)
            shift
            IMAGES_DIR="$1"
            ;;
        -t|--test)
            TEST_ONLY=true
            echo " ==TESTING MODE=="
            ;;
        -s|summary)
            SUMMMARY_ONLY=true
            ;;
        *)
            echo "ERROR: \"$1\": invalid option" >&2
            echo "$HELP" >&2
            exit 1
            ;;
    esac
    shift
done

# Loop over all systems in the images folder
for sys in $IMAGES_DIR/*
    do    
    # Extract just the basename
    sys=$(basename "$sys")
    
    [[ "$SUMMMARY_ONLY" == false ]] && echo
    [[ "$SUMMMARY_ONLY" == false ]] && echo "Working on system: $sys"
    ((++SYSTEMS_CHECKED))
    
    # Loop over all the images in the system
    for file in $IMAGES_DIR/$sys/*
        do
        # XML Encode the & symbol
        cfile=`echo $file | sed s/\&/\&amp\;/g`
        
        # Get just the filename and extension, we don't care about the path really, and, it might not be there.
        cfile=$(basename "$cfile")
        file_size=$(stat -c%s "$file")
        
        # If no gamelist is found, could be user supplied bad root gamelist folder
        if [[ ! -s "$GAMELISTS_DIR/$sys/gamelist.xml" ]]; then
            echo "ERROR: Could not find gamelist for system $sys at location \"$GAMELISTS_DIR\"" >&2
            break
        fi
        
        # Check for the image in the gamelist, grep return code 0 if found, 1 if not, 2 if error
        grep_result=$(grep -q -F "$cfile" $GAMELISTS_DIR/$sys/gamelist.xml)
        grep_rc=$?
        
        # Another check, being certain the gamelist was found
        if [ "$grep_rc" == "2" ] ; then
            echo "ERROR: Unable to access gamelist for system $sys at location \"$GAMELISTS_DIR\"" >&2
            echo "ERROR: File was: $cfile" >&2
            break
        fi
        
        # If the image filename was NOT found in the system's gamelist, delete it
        if [[ "$grep_rc" == "1" ]]; then
            ((++IMAGES_DELETED))
            IMAGES_FILESIZE=$((IMAGES_FILESIZE + file_size))
            
            [[ "$SUMMMARY_ONLY" == false ]] && echo "Deleting: $file"
            [[ "$TEST_ONLY" == false ]] && rm "$file"
        fi
    done
done

print_summary
