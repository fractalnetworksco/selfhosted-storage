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
    REMOTE_VOLUME_PATH="$1"


    # volume name is everything after the last slash
    VOLUME=${1##*/}

    # create .s4 directory as well as .s4/snapshot directory
    mkdir -p .s4/snapshots
    echo "Created s4 volume $VOLUME"
}
