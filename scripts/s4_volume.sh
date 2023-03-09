#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source $SCRIPT_DIR/base.sh

function create_s4_volume() {
    # usage: create_volume borg@192.168.1.190:/volumes/myvolume
    # volume name is everything after the last slash
    VOLUME=${1##*/}
    mkdir data
    mkdir snapshots
    mkdir .s4
    write_config .s4/config $VOLUME $1
    ssh-keygen -t ed25519 -N '' -f .s4/id_ed25519-$VOLUME &>/dev/null
    echo "Created s4 volume $VOLUME"
}
