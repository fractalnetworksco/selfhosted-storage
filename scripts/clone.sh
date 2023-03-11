#!/bin/bash

SCRIPT_DIR=$(dirname $(readlink -f $0))

source $SCRIPT_DIR/base.sh
source $SCRIPT_DIR/config.sh
source $SCRIPT_DIR/borg.sh
source $SCRIPT_DIR/btrfs.sh

# if $1 use it as the remote
if [ -n "$1" ]; then
    export BORG_RSH="ssh -p 2222 -o BatchMode=yes -o StrictHostKeyChecking=accept-new"
    # volume is the part after the last slash
    # if $2 set it as REMOTE_VOLUME
    if [ -n "$2" ]; then
        REMOTE_VOLUME=$2
    else
        REMOTE_VOLUME=${1##*/}
    fi
    REMOTE=$1
else
    # if no .s4 dir exists, exit
    if [ ! -d "/s4/.s4" ]; then
        echo "No .s4 dir found"
        exit 1
    fi
    export BORG_RSH="ssh -p 2222 -o BatchMode=yes -i /s4/.s4/id_ed25519 -o StrictHostKeyChecking=accept-new"
    LOCAL_VOLUME=$(get_config /s4/.s4/config volume)
    REMOTE=$(get_config /s4/.s4/config remote)

fi

# get the lastest archive from a borg repo and fetch it to the local machine
latest=$(get_latest_archive $REMOTE)
# if not latest exit
if [ -z "$latest" ]; then
    echo "No snapshots for $REMOTE_VOLUME archive found"
    exit 1
fi

# if REMOTE_VOLUME is  set
if [ -n "$REMOTE_VOLUME" ]; then
    # if current volume is btrfs create subvolume else exit
    # if $BTRFS is true create subvolume
    if [ "$BTRFS" = true ]; then
        create_subvolume $REMOTE_VOLUME
        set_owner_current_user $REMOTE_VOLUME
    else
        # if NO_BTRFS is defined continue
        if [ -z "$NO_BTRFS" ]; then
            echo "Current volume is not btrfs, set NO_BTRFS if you are ok with cloning to a non-btrfs volume"
            exit 1
        fi
        mkdir $REMOTE_VOLUME
    fi
    cd $REMOTE_VOLUME
fi

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