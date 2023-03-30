#!/bin/bash
if [[ $# -eq 3 || $# -eq 4 ]]; then
    file=".s4/config"
    section=$2
    key=$3
    value=$4
    if [ ! -d .s4 ]; then
        echo "Error: "$PWD" is not a s4 volume"
    exit 1
    fi
else
    # if $2 doesb't exist create it
    if [[ ! -f "$2" && "$1" == "set" ]]; then
        mkdir -p $(dirname "$2")
        touch "$2"
    fi
    file=$2
    section=$3
    key=$4
    value=$5
fi

if [[ "$1" == "set" ]]; then
    if ! grep -q "^\[$section\]" "$file"; then
        echo "[$section]" >> "$file"
    fi
    if grep -q "^\[$section\]" "$file"; then
        if grep -qE "^\s*$key\s*=" "$file"; then
            sed -i -E "s/(^\s*$key\s*=).*/\1$value/" "$file"
        else
            sed -i "/^\[$section\]/a $key=$value" "$file"
        fi
    fi
elif [[ "$1" == "get" ]]; then
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