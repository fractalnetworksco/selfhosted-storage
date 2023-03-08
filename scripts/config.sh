#!/bin/bash

function get_config() {
    while IFS='=' read -r key value
    do
        if [[ $key == \[*] ]]; then
            section=$(echo "$key" | sed 's/\[\(.*\)\]/\1/')
        elif [[ $key != "" ]]; then
            #echo "[$section] $key = $value"
            # if $section contains "remote" $remote to value
            # if $2 is remote echo $remote
            if [[ $2 == "remote" ]]; then
                if [[ $section =~ "remote" ]]; then
                    remote=$value
                    echo $value
                fi
            fi
            if [[ $2 == "volume" ]]; then
                if [[ $section =~ "volume" ]]; then
                    remote=$value
                    echo $value
                fi
            fi

        fi
    done < "$1"
}
