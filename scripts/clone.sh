#!/bin/bash

set -x

SCRIPT_DIR=$(dirname $(readlink -f $0))

source $SCRIPT_DIR/config.sh
source $SCRIPT_DIR/borg.sh

# if $1 use it as the remote
if [ -n "$1" ]; then
    export BORG_RSH="ssh -p 2222 -o BatchMode=yes -o StrictHostKeyChecking=accept-new"
    # volume is the part after the last slash
    REMOTE_VOLUME=${1##*/}
    REMOTE=$1
    mkdir $REMOTE_VOLUME
    cd $REMOTE_VOLUME
else
    export BORG_RSH="ssh -p 2222 -o BatchMode=yes -i /s4/.s4/id_ed25519 -o StrictHostKeyChecking=accept-new"
    LOCAL_VOLUME=$(get_config /s4/.s4/config volume)
    REMOTE=$(get_config /s4/.s4/config remote)

fi

# get the lastest archive from a borg repo and fetch it to the local machine
latest=$(get_latest_archive $REMOTE)

# we're cloning a placeholder dir from a catalog
if [ -n "$LOCAL_VOLUME" ]; then
    if [ "$(ls -A /s4/data)" ]; then
        echo "/s4/data is not empty"
        exit 1
    fi
    cd /s4/data
fi

# set VOLUME to LOCAL_VOLUME or REMOTE_VOLUME
VOLUME=${LOCAL_VOLUME:-$REMOTE_VOLUME}

echo "Cloning latest snapshot of $VOLUME"
borg extract --progress $REMOTE::$latest