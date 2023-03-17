#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
# infinite source loop, do we need it?
#source $SCRIPT_DIR/base.sh

function create_s4_volume() {
    # usage: create_volume borg@192.168.1.190:/volumes/myvolume
    # Args:
    #   $1 - Volume path
    #   $2 [OPTIONAL] - Private key
    #   $3 [OPTIONAL] - Public key

    # volume name is everything after the last slash
    VOLUME=${1##*/}

    echo "volume: $VOLUME"
    mkdir data
    mkdir snapshots
    mkdir .s4
    write_config .s4/config $VOLUME $1

    # use provided public/private keys if provided or generate one
    if [[ -n "$2" && -n "$3" ]]; then
        PRIV_KEY_PATH=".s4/id_ed25519-$VOLUME"
        PUB_KEY_PATH=".s4/id_ed25519-$VOLUME.pub"

        # write private and public keys into their respective paths
        echo "create_s4_volume: Writing $2 to $PRIV_KEY_PATH"
        echo "$2" > "$PRIV_KEY_PATH"
        echo "create_s4_volume: Writing $3 to $PUB_KEY_PATH"
        echo "$3" > "$PUB_KEY_PATH"

        # ensure key permissions are set correctly
        echo "create_s4_volume: setting permissions"
        chmod 600 "$PRIV_KEY_PATH"
        chmod 600 "$PUB_KEY_PATH"
    else
        ssh-keygen -t ed25519 -N '' -f .s4/id_ed25519-$VOLUME &>/dev/null
    fi
    echo "Created s4 volume $VOLUME"
}
