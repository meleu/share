#!/bin/bash
###########
# - Receives a file as input and read line by line.
# - if a line has a vimeo link
#   - save it in $vimeo_url
#   - if the next line has an url
#     - save it in $referrer
#     - youtube-dl "$vimeo_url" --referrer "$referrer"


INPUT_FILE="$1"
OUTPUT_DIR=''

[[ -f "$INPUT_FILE" ]] || exit 1

readonly VIMEO_REGEX='^https:\/\/player\.vimeo\.com\/video\/[0-9]+'
readonly URL_REGEX='^http.:\/\/'

while IFS='' read -r line; do
    temp="$(echo "$line" | grep -Eo "$VIMEO_REGEX")"

    if [[ -n "$vimeo_url" ]]; then
        if [[ $temp =~ $URL_REGEX ]]; then 
            youtube-dl -o "$OUTPUT_DIR/%(title)s-%(id)s.%(ext)s" -c "$vimeo_url" --referrer "$temp"
        fi
    fi

    if [[ $temp =~ $VIMEO_REGEX ]]; then
        vimeo_url="$temp"
        continue
    fi

    vimeo_url=''
done < "$INPUT_FILE"


