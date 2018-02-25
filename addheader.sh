#!/usr/bin/env bash

USAGE="$0 header.txt file1.c [file2.cpp ...]"

function main() {
    if [[ -z "$1" || "$1" == "-h" || "$1" == "--help" ]]; then
        echo "Uso: $USAGE"
        exit 0
    fi

    local header_file="$1"
    local header_text
    shift
    local files=( "$@" )


    if [[ ! -f "$header_file" || -z "${files[@]}" ]]; then
        echo "Faltam parâmetros ou parâmetros inválidos"
        echo "Uso: $USAGE"
        exit 1
    fi

    header_text="$(cat "$header_file")\n"

    for file in "${files[@]}"; do
        if [[ ! "$file" =~ \.(c|cpp|h)$ ]]; then
            echo "WARNING: ignorando \"$file\": extensão de arquivo inválida"
            continue
        fi
        if [[ ! -f "$file" ]]; then
            echo "WARNING: ignorando \"$file\": arquivo inexistente"
            continue
        fi
        if [[ ! -s "$file" ]]; then
            echo "WARNING: ignorando \"$file\": arquivo vazio"
            continue
        fi

        echo -n "Adicionando cabeçalho ao arquivo \"$file\"... "
        sed -i 1i"$header_text" "$file"
        echo "Feito!"
    done
}

main "$@"

