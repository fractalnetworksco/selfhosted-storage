#/bin/bash

# $1 of the volume
# $2 ssh pubkey

function add_volume_pubkey(){
    # check if pubkey already exists in authorized_keys
    if grep -q "$2" ~/.ssh/authorized_keys; then
        exit 0
    fi

    # write ssh pubkey to ~/.ssh/authorized_keys
    echo "command=\"borg serve --restrict-to-path /volumes/$1\",restrict $2" >> ~/.ssh/authorized_keys
}

add_volume_pubkey $1 "$2"
