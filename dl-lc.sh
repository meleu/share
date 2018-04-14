#!/bin/bash
# dl-lc.sh
##################
# Using a youtube-dl trick to download laracasts videos.
#
# DEPENDENCIES: wget youtube-dl

# globals #####################################################################
readonly DEPS=(wget youtube-dl)
readonly LARACASTS_SITE="https://laracasts.com"

LARACASTS_SERIES=(
    "php-for-beginners"
    "laravel-from-scratch-2017"
    "how-to-be-awesome-in-phpstorm"
)


# functions ###################################################################

function help_and_exit() {
    echo "USAGE: $0 [OPTIONS]"
    echo
    echo "Where OPTIONS can be:"
    echo
    sed '/^#H /!d; s/^#H //' "$0"
    echo
    echo "When using with no arguments, the script will show a small list of the available"
    echo "laracasts series and let you choose which one you want to download the videos."
    echo
    exit 1
}

function check_deps() {
    local pkg
    local ret=0

    for pkg in "${DEPS[@]}"; do
        if ! which "$pkg" 2>&1 > /dev/null; then
            echo "ERROR: \"$pkg\" not found" >&2
            ret=1
        fi
    done

    if [[ "$ret" != 0 ]]; then
        echo "Aborting..." >&2
        exit 1
    fi
}


# gets an episode's URL and echoes the respective vimeo-id.
# returns non-zero if there's no vimeo-id
function get_vimeoid() {
    local url="$1"
    local vimeoid

    [[ "$url" != "$LARACASTS_SITE"* ]] && return 1

    vimeoid="$(
        wget -q "$url" -O - \
        | grep -o 'vimeo-id="[^"]*"' \
        | cut -d= -f2 | tr -d \"
    )"

    [[ "$vimeoid" =~ ^[[:digit:]]+ ]] || return 1

    echo "$vimeoid"
}


# gets a URL of a single serie and echoes the URL list of the episodes
# returns non-zero if there's no episodes
function get_episodes_url() {
    local serie="$1"
    local episodes=()
    local episode

    # ugly hack to check if an array contains an element
    [[ "${LARACASTS_SERIES[@]//$serie/}" == "${LARACASTS_SERIES[@]}" ]] && return 1

    episodes=(
        $(wget -q "$LARACASTS_SITE/series/$serie" -O - \
        | grep -o 'href="[^"]*/episodes/.\{,2\}"' \
        | uniq | cut -d= -f2 | tr -d \"
        )
    )

    [[ "${#episodes[@]}" == "0" ]] && return 1

    for episode in "${episodes[@]}"; do
        echo "${LARACASTS_SITE}$episode"
    done
}


function get_all_series() {
    LARACASTS_SERIES=(
        $(wget -q "$LARACASTS_SITE/series" -O - \
        | grep -o 'href="/series/[^"]*"' \
        | uniq | cut -d= -f2 | tr -d \" \
        | sed 's,/series/,,'
        )
    )

    [[ "${#LARACASTS_SERIES[@]}" == "0" ]]
}


function parse_args() {
    [[ -z "$@" ]] && return

    case "$1" in

#H -h|--help            print this help message and exit
#H 
        -h|--help)
            help_and_exit
            ;;
#H -a|--all-series      get the list of all available series
#H                      WARNING: the list will be huge (65+ items) and most
#H                               of the series is NOT free!
        -a|--all-series)
            get_all_series
            ;;
        *)
            echo "WARNING: ignoring invalid option '$1'" >&2
            ;;
    esac
}


# main ########################################################################

function main() {
    check_deps
    parse_args "$@"

    local serie
    local episodes=()
    local episode
    local vimeoid

    echo "Which series do you want to download the videos from?"
    select serie in "${LARACASTS_SERIES[@]}" exit; do
        echo "You have chose \"$serie\"..."
        [[ "$serie" == "exit" ]] && break

        episodes=( $(get_episodes_url "$serie") )
        if [[ "${#episodes[@]}" == "0" ]]; then
            echo "Ooops! Unable to get the episodes list." >&2
            echo "Check your connection and try again." >&2
            continue
        fi

        for episode in "${episodes[@]}"; do
            echo -e "\nChecking \"$episode\"..."
            vimeoid="$(get_vimeoid "$episode")"

            if [[ -z "$vimeoid" ]]; then
                echo "Ooops! Looks like this episode isn't free!" >&2
                continue
            fi

            echo youtube-dl \
                -o "$serie/%(title)s-%(id)s.%(ext)s" \
                "http://player.vimeo.com/video/$vimeoid" --referer "$episode"
        done

        echo "Which series do you want to download the videos from?"
    done
}

main "$@"
