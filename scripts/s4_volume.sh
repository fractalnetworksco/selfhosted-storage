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
    #   $1 - Remote Volume path
    #   $2 [OPTIONAL]: Read Private key
    #   $3 [OPTIONAL]: Read Public key
    REMOTE_VOLUME_PATH="$1"
    READ_PRIVATE_KEY="$2"
    READ_PUBLIC_KEY="$3"

    # volume name is everything after the last slash
    VOLUME=${1##*/}

    # create .s4 directory as well as .s4/snapshot directory
    mkdir -p .s4/snapshots
    write_config .s4/config $VOLUME $REMOTE_VOLUME_PATH

    # use provided public/private keys if provided or generate one
    if [[ -n "$READ_PRIVATE_KEY" && -n "$READ_PUBLIC_KEY" ]]; then
        # write read private and public keys into volume's .s4 directory
        write_key "$READ_PRIVATE_KEY" ".s4/read_id_ed25519-$VOLUME"
        write_key "$READ_PUBLIC_KEY" ".s4/read_id_ed25519-$VOLUME.pub"

    else
        ssh-keygen -t ed25519 -N '' -f .s4/write_id_ed25519-$VOLUME &>/dev/null
        ssh-keygen -t ed25519 -N '' -f .s4/read_id_ed25519-$VOLUME &>/dev/null
    fi
    echo "Created s4 volume $VOLUME"
}
