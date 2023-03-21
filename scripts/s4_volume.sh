#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
# infinite source loop, do we need it?
#source $SCRIPT_DIR/base.sh

function write_key() {
    # args:
    #   $1: Raw key (as if you `cat` the file)
    #   $2: Path to write key to
    CONTENTS="$1"
    KEY_PATH="$2"

    # write contents to desired path
    echo "$CONTENTS" > "$KEY_PATH"

    # ensure key permissions are set correctly
    chmod 600 "$KEY_PATH"
}

function create_s4_volume() {
    # usage: create_volume borg@192.168.1.190:/volumes/myvolume
    # Args:
    #   $1 - Volume path
    #   $2 [OPTIONAL] - Private key
    #   $3 [OPTIONAL] - Public key

    # volume name is everything after the last slash
    VOLUME=${1##*/}

    # create .s4 directory as well as .s4/snapshot directory
    mkdir -p .s4/snapshots
    write_config .s4/config $VOLUME $1

    # use provided public/private keys if provided or generate one
    if [[ -n "$2" && -n "$3" ]]; then
        PRIV_KEY_PATH=".s4/id_ed25519-$VOLUME"
        PUB_KEY_PATH=".s4/id_ed25519-$VOLUME.pub"

        # write private and public keys into their respective paths
        write_key "$2" "$PRIV_KEY_PATH"
        write_key "$3" "$PUB_KEY_PATH"
    else
        ssh-keygen -t ed25519 -N '' -f .s4/id_ed25519-$VOLUME &>/dev/null
    fi
    echo "Created s4 volume $VOLUME"
}
