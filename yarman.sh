#!/bin/bash
# yarman.sh
###########
#
# The yarman's manager.
#
# Execute it with --help to see the available options.
#

# global variables ##########################################################

yarman_dir=$(dirname $0)

usage="$(basename $0) OPTIONS"

help_message="Usage: $usage

The OPTIONS are:

-h|--help           print this message and exit

--start             start the yarman

--stop              stop the yarman

--isrunning         show if yarman is running and the
                    listening port and exit

The --start and --stop options are, obviously, mutually exclusive. If the
user uses both, only the first works."

# default TCP port to listen
port=8080

# TODO: is it necessary?
# the default is not save log files
log_command="&> /dev/null"

# TODO: is it necessary?
# getting the caller username
user="$SUDO_USER"
[[ -z "$user" ]] && user=$(id -un)



##############################################################################
# TODO: is it necessary?
# Set the user that will start the yarman. Only privileged users
# can use this function. The user MUST have a RetroPie directory tree in
# its homedir.
#
# Globals:
#   user
# Arguments:
#   $1  a valid RetroPie user name
# Returns:
#   0, if a the user is setted correctly
#   non-zero, otherwise
##############################################################################
function set_user() {
    if [[ $(id -u) -ne 0 ]]; then
        echo "Error: only privileged users (ex.: root) can use --user option." >&2
        return 1
    fi

    if [[ ! -d "/home/$1/RetroPie/" ]]; then
        echo "Error: the user '$1' is not a RetroPie user." >&2
        return 1
    fi

    user="$1"
    return 0
}


##############################################################################
# Check if yarman is running. If positive, fill the $port global
# variable with current listening port.
#
# Globals:
#   port
# Arguments:
#   None
# Returns:
#   0, if yarman is running
#   non-zero, otherwise
##############################################################################
function is_running() { 
    local return_value

    # TODO: check the command here.
    pgrep -f 'python.*manage\.py.*runserver' &>/dev/null
    return_value=$?

    if [[ "$return_value" != "0" ]]; then
        return $return_value
    fi

    # ok... maybe there is a more elegant way to obtain the current
    # listening port, but let's use this way for a while.
    # TODO: check the command here.
    port=$(
        ps ax \
        | grep -m 1 -o 'python.*manage\.py.*runserver.*--noreload' \
        | grep -o '0.0.0.0:[^ ]*' \
        | cut -d: -f2
    )
    return $return_value
}


##############################################################################
# Starts the yarman service. It gives an error if it's called
# directly by the root user, but if it's called by an "sudo environment",
# yarman is started by the sudo user.
#
# Globals:
#   log_command
#   user
# Arguments:
#   None
# Returns:
#   1, if it's unable to start yarman
#   0, if yarman is successfully started
##############################################################################
function start_service() {
    if is_running; then
        echo "Nothing done. yarman is already running and listening at $port." >&2
        return 1
    fi

    # TODO: check the command here.
    local startcmd="${yarman_dir}/bin/python \
                      ${yarman_dir}/manage.py \
                      runserver 0.0.0.0:$port \
                      --settings=project.settings_production \
                      --noreload \
                      $log_command"

    # yarman should not be started directly by the root user,
    # but we can deal if it's called by a "sudo environment" or with
    # the --user option.
    if [[ $(id -u) -eq 0 ]]; then
        if [[ $(id -u "$user") -eq 0 ]]; then
            echo "Error: yarman can't be started directly by root!" >&2
            echo "Try to use '--user' option" >&2
            return 1
        fi
        startcmd="su -c '$startcmd' $user"
    fi

    echo "Starting yarman..."
    eval $startcmd &>/dev/null &
    sleep 3
    if is_running; then
        echo "yarman is running and listening at port $port"
        return 0
    else
        echo "Error: It seems that yarman had some problem to start!" >&2
        return 1
    fi
}


##############################################################################
# Stops the yarman service if it's running.
#
# Globals:
#   None
# Arguments:
#   None
# Returns:
#   0, if yarman process is successfully killed
#   1, if unable to kill yarman
#   2, if yarman wasn't running from the start
##############################################################################
function stop_service() {
    if is_running; then
        echo "Stopping yarman..."
        # TODO: check the command here.
        sudo kill -9 $(pgrep -f 'python.*manage\.py.*runserver')
        sleep 1
        if is_running; then
            echo "Error: Unable to kill yarman process." >&2
            return 1
        else
            echo "yarman has been stopped."
            return 0
        fi
    fi

    echo "Nothing done. yarman wasn't running." >&2
    return 2
}


# starting point #############################################################

# TODO: is it really necessary?
# OBS.: the double [[ ]] test style doesn't work with '-a' or '-o' option.
if [ ! -x "$yarman_dir/bin/python" -a ! -f "$yarman_dir/manage.py" ]; then
    yarman_dir="/opt/retropie/supplementary/yarman"
    if [[ ! -d "$yarman_dir" ]]; then
        echo "Error: $(basename $0) MUST be in the yarman's directory" >&2
        exit 1
    fi
fi


if [[ -z "$1" ]]; then
    echo "Error: missing arguments" >&2
    echo "$help_message" >&2
    exit 1
fi


# the following variables work like flags. they are used to deal with 
# the command line options.
f_start=0
f_stop=0

while [[ "$1" ]]; do
    case "$1" in

    -h|--help)
        echo "$help_message"
        exit 0
    ;;

    --isrunning)
        if is_running; then
            echo "yarman is running and listening at port $port"
            exit 0
        else
            echo "yarman is not running"
            exit 1
        fi
    ;;

    --start)
        if [[ "$f_stop" == "1" ]]; then
            echo "Warning: ignoring '--start' option" >&2
            f_start=0
        else
            f_start=1
        fi
    ;;

    --stop)
        if [[ "$f_start" == "1" ]]; then
            echo "Warning: ignoring '--stop' option" >&2
            f_stop=0
        else
            f_stop=1
        fi
    ;;

    --log)
        if [[ "$f_start" != "1" ]]; then
            echo "Warning: ignoring '--log' option" >&2
            shift
            continue
        fi
        log_dir="${yarman_dir}/logs"
        mkdir -p "$log_dir"
        log_command="&> ${log_dir}/yarman-$(date +%Y-%m-%d-%H%M%S).log"
    ;;

    # TODO: is it really necessary?
    -u|--user)
        if [[ "$f_start" = "0" ]]; then
            echo "Error: the '--user' option is used with '--start' only" >&2
            exit 1
        fi
        shift
        set_user "$1" || exit $?
    ;;

    *)  echo "Invalid option: $1" >&2
        exit 1
    ;;
    esac

    # shifting for the next option
    shift
done

if [[ "$f_start" = "1" ]]; then
    start_service
    exit $?
fi

if [[ "$f_stop" = "1" ]]; then
    stop_service
    exit $?
fi
