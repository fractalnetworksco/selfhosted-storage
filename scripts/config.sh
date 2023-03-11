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

function write_config() {
    # declare heredoc with sample ini file
    cat << EOF > $1
[volume]
name = $2
[remote]
url = $3
EOF
}

function write_remote() {
    mkdir -p ~/.s4
    # declare heredoc with sample ini file
    cat << EOF > $1
[remote]
url = $2
EOF
}