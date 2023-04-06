#!/bin/bash

if [[ "$1" == "set" ]]; then
    # number of arguments is 4 set file to .s4/config
    # create the config file if it doesn't exist
    if [[ $# -eq 4 ]]; then
        file=".s4/config"
        section=$2
        key=$3
        value=$4
    elif [[ $# -eq 5 ]]; then
        file=$2
        section=$3
        key=$4
        value=$5
    else
        echo "Invalid number of arguments"
        exit 1
    fi
    # if the file doesn't exist, create it
    if [[ ! -f "$file" ]]; then
        mkdir -p $(dirname "$file")
        touch "$file"
    fi
    # escape any special characters in the value
    value=$(sed -E 's/([\/&])/\\\1/g' <<< "$value")
    if ! grep -q "^\[$section\]" "$file"; then
        echo "[$section]" >> "$file"
        # need these syncs here so btrfs generatiob counter updates
        sync
    fi
    if grep -q "^\[$section\]" "$file"; then
        if grep -qE "^\s*$key\s*=" "$file"; then
            sed -i -E "s/(^\s*$key\s*=).*/\1${value}/" "$file"
        else
            sed -i "/^\[$section\]/a $key=${value}" "$file"
        fi
        # need these syncs here so btrfs generatiob counter updates
        sync
    fi
elif [[ "$1" == "get" ]]; then
    # number of arguments is 3 set file to .s4/config
    if [[ $# -eq 3 ]]; then
        file=".s4/config"
        section=$2
        key=$3
    elif [[ $# -eq 4 ]]; then
        file=$2
        section=$3
        key=$4
    else
        echo "Invalid number of arguments"
        exit 1
    fi
    if grep -q "^\[$section\]" "$file"; then
        value=$(awk -F= -v section="$section" -v key="$key" '
            /^\[.*\]$/ { in_section = (/^\['"$section"'\]$/) }
            in_section && $1 ~ /^'"$key"'$/ { print $2; exit }
        ' "$file")
        if [[ -n "$value" ]]; then
            echo "$value"
        else
            echo "Key not found"
            exit 1
        fi
    else
        echo "Section not found"
        exit 1
    fi
else
    echo "Invalid command. Use 'set' or 'get'."
    exit 1
fi