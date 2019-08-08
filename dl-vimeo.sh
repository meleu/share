#!/bin/bash
###########
# - Receives a file as input and read line by line.
# - if a line has a vimeo link
#   - save it in $vimeo_url
#   - if the next line has an url
#     - save it in $referrer
#     - youtube-dl "$vimeo_url" --referrer "$referrer"


INPUT_FILE="$1"
OUTPUT_DIR="$2"

[[ -f "$INPUT_FILE" ]] || exit 1
[[ -d "$OUTPUT_DIR" ]] || exit 1

readonly VIMEO_REGEX='^https:\/\/player\.vimeo\.com\/video\/[0-9]+'
readonly URL_REGEX='^http.:\/\/'

while IFS='' read -r line; do
    if [[ -n "$vimeo_url" ]]; then
        if [[ $line =~ $URL_REGEX ]]; then 
            echo "Baixando \"$vimeo_url\"..."
            youtube-dl -o "${OUTPUT_DIR}%(title)s-%(id)s.%(ext)s" -c "$vimeo_url" --referer "$line"
        fi
    fi

    if [[ $line =~ $VIMEO_REGEX ]]; then
        vimeo_url="$line"
        continue
    fi

    vimeo_url=''
done < "$INPUT_FILE"
