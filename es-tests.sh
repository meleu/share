#!/usr/bin/env bash
# es-tests.sh
#############
# This script lets you install a non-official emulationstation mod in RetroPie.
# It is for those who want to test and help devs with feedback.
#
# Bear in mind that many of those mods are still in development, and you need
# to know how to fix things if something break.
#
# meleu - May-2017

# globals ####################################################################
REPO_FILE="es-repos.txt"
BACKTITLE="es-test.sh: Installing EmulationStation mods on your RetroPie"
REPO_URL_TEMPLATE="https://github.com/"
SRC_DIR="$HOME/src"
RP_SETUP_DIR="$HOME/RetroPie-Setup"
RP_HELPERS_SH="$RP_SETUP_DIR/scriptmodules/helpers.sh"
RP_SUPPLEMENTARY_SRC_DIR="$RP_SETUP_DIR/scriptmodules/supplementary"
RP_PACKAGES_SH="$RP_SETUP_DIR/retropie_packages.sh"
RP_SUPPLEMENTARY_DIR="/opt/retropie/supplementary"

# TESTERS: comment the line below if you don't want to see that warning message.
dialog --backtitle "W A R N I N G !" --title " WARNING! " --yesno "\nThis script lets you install a non-official emulationstation mod in RetroPie. It is for those who want to test and help devs with feedback.\n\nBear in mind that many of those mods are still in development, and you need to know how to fix things if something break!\n\n\nDo you want to proceed?" 15 75 2>&1 > /dev/tty || exit


# dialog functions ##########################################################

function dialogMenu() {
    local text="$1"
    shift
    dialog --no-mouse \
        --backtitle "$BACKTITLE" \
        --cancel-label "Back" \
        --ok-label "OK" \
        --menu "$text\n\nChoose an option." 17 75 10 "$@" \
        2>&1 > /dev/tty
}

function dialogYesNo() {
    dialog --no-mouse --backtitle "$BACKTITLE" --yesno "$@" 15 75 2>&1 > /dev/tty
}

function dialogMsg() {
    dialog --no-mouse --ok-label "OK" --backtitle "$BACKTITLE" --msgbox "$@" 20 70 2>&1 > /dev/tty
}

function dialogInfo {
    dialog --infobox "$@" 8 50 2>&1 >/dev/tty
}

# end of dialog functions ###################################################


function main_menu() {
    local choice

    while true; do
        choice=$(dialog --backtitle "$BACKTITLE" --title " MAIN MENU " \
            --ok-label OK --cancel-label Exit \
            --menu "What do you want to do?" 17 75 10 \
            B "Build an ES repo/branch from the list" \
            E "Edit the ES repo/branch list" \
            C "Choose an installed ES branch to be the default" \
            R "Remove an installed ES branch" \
            2>&1 > /dev/tty)

        case "$choice" in
            B)  build_es_branch_menu ;;
            E)  edit_repo_branch_menu ;;
            C)  set_default_es_menu ;;
            R)  remove_installed_es_menu ;;
            *)  break ;;
        esac
    done
}


function build_es_branch_menu() {
    if [[ ! -s "$REPO_FILE" ]]; then
        dialogMsg "\"$REPO_FILE\" is empty!\n\nAdd some ES repo/branch first."
        return 1
    fi

    local options=()
    local choice
    local i

    while true; do
        i=1
        options=()
        while read -r repo branch; do
            options+=( $((i++)) "$repo ~ $branch" )
        done < "$REPO_FILE"
        choice=$(dialogMenu "List of available ES repository/branch to download, build and install (from \"$REPO_FILE\")." "${options[@]}") \
        || return 1
        repo=$(  echo "${options[2*choice-1]}" | tr -d ' ' | cut -d'~' -f1)
        branch=$(echo "${options[2*choice-1]}" | tr -d ' ' | cut -d'~' -f2)
        es_download_build_install "$repo" "$branch"
    done
}


function es_download_build_install() {
    if [[ ! -s "$RP_HELPERS_SH" ]]; then
        dialogMsg "Unable to find "$RP_HELPERS_SH".\n\nThe RetroPie-Setup must be installed in your home dir."
        return 1
    fi
    source "$RP_HELPERS_SH"

    local developer=$(echo "$repo" | sed "s#.*https://github.com/\([^/]*\)/.*#\1#")
    local es_src_dir=$(friendly_repo_branch_name)
    local es_install_dir="${RP_SUPPLEMENTARY_DIR}/$es_src_dir"
    es_src_dir="$SRC_DIR/$es_src_dir"

    dialogYesNo "Are you sure you want to download, build and install ${developer}'s $branch ES branch?\n\n(Note: source files will be stored at \"$es_src_dir\")" \
    || return

    dialogInfo "Downloading source files for ${developer}'s $branch ES branch..."
    gitPullOrClone "$es_src_dir" "$repo" "$branch"

    dialogInfo "Building ${developer}'s $branch ES branch..."
    if ! build_es; then
        echo "====== W A R N I N G !!! ======"
        echo "= SOMETHING WRONG HAPPENED!!! ="
        echo "==============================="
        read -t 30 -p "Look for error messages above. Press <enter> to continue."
        dialogMsg "Failed to build ${developer}'s $branch ES branch. :(\n\n(you should have seen the error messages, right?)"
        return 1
    fi

    dialogInfo "Installing ${developer}'s $branch ES branch in \"$es_install_dir\"."
    if ! install_es; then
        echo "====== W A R N I N G !!! ======"
        echo "= SOMETHING WRONG HAPPENED!!! ="
        echo "==============================="
        read -t 30 -p "Look for error messages above. Press <enter> to continue."
        dialogMsg "Failed to install ${developer}'s $branch ES branch in \"$es_install_dir\". :(\n\n(you should have seen the error messages, right?)"
        return 1
    fi

    dialogMsg "SUCCESS!\n\nThe ${developer}'s EmulationStation $branch branch was successfully installed!\n\nThis ES version is now the default emulationstation on your system.\n\nYou can choose which ES version will be the default one using the \"C\" option at Main Menu."
}


function build_es() {
    local ret=0

    cd "$es_src_dir"
    rpSwap on 512
    cmake . -DFREETYPE_INCLUDE_DIRS=/usr/include/freetype2/ || ret=1
    # following RetroPie user Hex's suggestion [https://retropie.org.uk/forum/post/81034]
    # do not "make clean" for a faster compilation
    #make clean
    make || ret=1
    rpSwap off
    cd -
    return $ret
}


function install_es() {
    local ret=0

    sudo mkdir -p "$es_install_dir"
    sudo cp -f "$es_src_dir/CREDITS.md" "$es_install_dir/"
    sudo cp -f "$es_src_dir/emulationstation" "$es_install_dir/" || return 1
    sudo cp -f "$es_src_dir/emulationstation.sh" "$es_install_dir/" || return 1
    sudo cp -f "$es_src_dir/GAMELISTS.md" "$es_install_dir/"
    sudo cp -f "$es_src_dir/README.md" "$es_install_dir/"
    sudo cp -f "$es_src_dir/THEMES.md" "$es_install_dir/"

    rp_scriptmodule_action configure || return 1
}


function rp_scriptmodule_action() {
    [[ -z "$1" ]] && return 1

    local action="$1"
    local module_id="$2"
    local scriptmodule
    local ret=0

    [[ -z "$module_id" ]] && module_id=$(basename "$es_src_dir")
    scriptmodule="$RP_SUPPLEMENTARY_SRC_DIR/${module_id}.sh"

    cat > "$scriptmodule" << _EoF_
#!/usr/bin/env bash

rp_module_id="$module_id"
rp_module_desc="${developer}'s EmulationStation $branch branch"
rp_module_section="exp"

function configure_${module_id}() {
        configure_emulationstation
}
_EoF_

    sudo "$RP_PACKAGES_SH" "$module_id" "$action" || ret=1
    rm -f "$scriptmodule"

    return $ret
}


function edit_repo_branch_menu() {
    local options=()
    local choice
    local i=1
    local repo
    local branch

    while true; do
        options=(A "Add an ES repo/branch to the list")
        [[ -s "$REPO_FILE" ]] && options+=(D "DELETE ALL REPO/BRANCHES IN THE LIST")

        while read -r line; do
            line_number=$(echo "$line" | cut -d: -f1)
            developer=$(echo "$line" | sed "s#.*https://github.com/\([^/]*\)/.*#\1#")
            branch=$(echo "$line" | sed "s,[^ ]* *,,")
            options+=( "$line_number" "Delete ${developer}'s \"$branch\" branch" )
        done < <(nl -s: -w1 "$REPO_FILE")

        choice=$(dialogMenu "Edit the ES repository/branch list \"$REPO_FILE\"." "${options[@]}") \
        || return 1

        case "$choice" in
            A)  add_repo_branch
                ;;
            D)  dialogYesNo "Are you sure you want to delete every single entry in \"$REPO_FILE\"?" \
                || continue
                echo -n > "$REPO_FILE"
                ;;
            *)  repo=$(  sed -n ${choice}p "$REPO_FILE" | cut -d' ' -f1)
                branch=$(sed -n ${choice}p "$REPO_FILE" | cut -d' ' -f2)
                dialogYesNo "Are you sure you want to delete the following line from \"$REPO_FILE\"?\n\n$repo $branch" \
                || continue
                sed -i ${choice}d "$REPO_FILE"
                remove_source_files "$SRC_DIR/$(friendly_repo_branch_name)"
                ;;
        esac
    done
}


function add_repo_branch() {
    local form=()
    local new_repo="$REPO_URL_TEMPLATE"
    local new_branch
    
    while true; do
        form=( $(dialog --form "Enter the ES repository URL and the branch name."  17 75 5 \
            "URL    :" 1 1 "$new_repo"   1 10 80 0 \
            "branch :" 2 1 "$new_branch" 2 10 30 0 \
            2>&1 > /dev/tty)
        ) || return 1
        new_repo="${form[0]}"
        new_branch="${form[@]:1}"

        dialogInfo "Adding \"$new_branch\" to the the list.\nPlease wait..."
        validate_repo_branch "$new_repo" "$new_branch" || continue
        echo "$new_repo $new_branch" >> "$REPO_FILE"
        return 0
    done
}


function validate_repo_branch() {
    local repo="$1"
    local branch="$2"

    if grep -qi "$repo *$branch" "$REPO_FILE" ; then
        dialogMsg "The \"$branch\" branch from \"$repo\" is already in the list!\n\nNothing will be changed."
        return 1
    fi

    if [[ "$repo" != ${REPO_URL_TEMPLATE}* ]]; then
        dialogMsg "The repository URL you provided is invalid (doesn't seem to be a github one): \"$repo\"\n\nThis script only works with github repositories."
        return 1
    fi

    if ! curl -Is "${repo}/tree/${branch}" | grep -q '^Status: 200'; then
        dialogMsg "This is an invalid repo/branch:\n${repo}/tree/${branch}\n(Or maybe your connection is down and the script is unable to validate repo/branch.)\n\nNothing will be changed."
        return 1
    fi
    return 0
}


function set_default_es_menu() {
    local options=()
    local choice
    local i
    local es_branch

    while true; do
        i=1
        for es_branch in $(get_installed_branches); do
            options+=( $((i++)) "$es_branch" )
        done

        choice=$(dialogMenu "List of installed ES branches on \"$RP_SUPPLEMENTARY_DIR\".\n\nWhich one you want to set as the default emulationstation?" "${options[@]}") \
        || return 1
        es_branch="${options[2*choice-1]}"

        dialogYesNo "Are you sure you want to set the \"$es_branch\" ES branch as the default one?" \
        || continue

        if rp_scriptmodule_action configure "$es_branch"; then
            dialogMsg "SUCCESS!\n\nThe \"$es_branch\" ES branch is now the default emulationstation!"
            return 0
        else
            dialogMsg "FAIL!!\n\nFailed to set the \"$es_branch\" ES branch as the default emulationstation."
            return 1
        fi
    done
}


function get_installed_branches() {
    local installed_branches=( $(find "$RP_SUPPLEMENTARY_DIR" -type f -name emulationstation.sh) )
    local b
    for b in "${installed_branches[@]}"; do
        basename "$(dirname "$b")"
    done
}


function remove_installed_es_menu() {
    local options=()
    local choice
    local i
    local es_branch

    while true; do
        i=1
        for es_branch in $(get_installed_branches); do
            options+=( $((i++)) "$es_branch" )
        done

        choice=$(dialogMenu "List of installed ES branches on \"$RP_SUPPLEMENTARY_DIR\".\n\nWhich one you want to uninstall?" "${options[@]}") \
        || return 1
        es_branch="${options[2*choice-1]}"

        dialogYesNo "Are you sure you want to uninstall the \"$es_branch\" ES branch?" \
        || continue

        remove_source_files "$SRC_DIR/$es_branch"

        if rp_scriptmodule_action remove "$es_branch"; then
            if sudo "$RP_PACKAGES_SH" emulationstation configure; then
                dialogMsg "SUCCESS!\n\nThe \"$es_branch\" ES branch was uninstalled!\nThe official RetroPie ES is now the default emulationstation."
                return 0
            else
                dialogMsg "WARNING!\n\nThe \"$es_branch\" ES branch was uninstalled.\nBut we failed to set the official RetroPie ES as the default emulationstation. You need to sort it."
                return 2
            fi
        else
            dialogMsg "FAIL!!\n\nFailed to uninstall the \"$es_branch\" ES branch."
            return 1
        fi
    done
}


function friendly_repo_branch_name() {
    local developer=$(echo "$repo" | sed "s#.*https://github.com/\([^/]*\)/.*#\1#")
    echo "es_${developer}_${branch}" | tr '[:upper:]' '[:lower:]'
}


function remove_source_files() {
    local es_src_dir="$1"
    if [[ -d "$es_src_dir" ]]; then
        dialogYesNo "Do you want to remove source files from \"$es_src_dir\" too?" \
        && rm -rf "$es_src_dir" \
        && dialogMsg "Source files from \"$es_src_dir\" has been removed." \
        || dialogMsg "Failed to remove \"$es_src_dir\"."
    fi
}

# START HERE #################################################################

main_menu
