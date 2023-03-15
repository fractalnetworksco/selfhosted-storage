#!/bin/bash

# $1 name of the volume
# $2 ssh pubkey
# $3 optional comment for key

function add_volume_pubkey(){
    # check if name or pubkey already exists in authorized_keys
    if grep -q "$1" ~/.ssh/authorized_keys || grep -q "$2" ~/.ssh/authorized_keys; then
        exit 0
    fi

    # write ssh pubkey to ~/.ssh/authorized_keys
    echo "command=\"borg serve --restrict-to-path /volumes/$1\",restrict $2 $3" >> ~/.ssh/authorized_keys
}

add_volume_pubkey $1 "$2" "$3"
