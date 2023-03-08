#/bin/bash

# $1 of the volume
# $2 ssh pubkey

# write ssh pubkey to ~/.ssh/authorized_keys
function add_volume_pubkey(){
    echo "command=\"borg serve --restrict-to-path /volumes/$1\",restrict $2" >> ~/.ssh/authorized_keys
}


add_volume_pubkey $1 "$2"