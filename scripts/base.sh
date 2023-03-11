#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source $SCRIPT_DIR/config.sh
source $SCRIPT_DIR/btrfs.sh

export VOLUME_PATH=$(pwd)
export GENERATION_FILE=$VOLUME_PATH/.s4/generation

function mount_sudo() {
    if [[ $(id -u) -ne 0 ]]; then
        sudo mount $@
    else
        mount $@
    fi
}

function umount_sudo() {
    if [[ $(id -u) -ne 0 ]]; then
        sudo umount $@
    else
        umount $@
    fi
}

function chown_sudo(){
    if [[ $(id -u) -ne 0 ]]; then
        sudo chown $@
    else
        chown $@
    fi
}

function mkdir_sudo(){
    if [[ $(id -u) -ne 0 ]]; then
        sudo mkdir $@
    else
        mkdir $@
    fi
}


function set_owner_current_user() {
    chown_sudo $(id -u):$(id -g) $1
}

function push() {
    SUBVOLUME=$1
    prev_generation=$(cat $GENERATION_FILE)
    generation=$(get_generation $SUBVOLUME)
    # check if the generation has changed since the last snapshot
    if [ $generation -ne $prev_generation ]; then
        echo "Taking new snapshot"
        echo $(pwd)
        # create a read-only snapshot of the subvolume
        take_snapshot $SUBVOLUME $GENERATION_FILE $generation
        cd $VOLUME_PATH/snapshots/snapshot-$generation/data
        borg create --progress $REMOTE::$VOLUME-$generation .
        cd ../../..
        # exit if last command not successful
        if [ $? -ne 0 ]; then
            echo "Failed to replicate borg snapshot"
            exit 1
        fi
        # cleanup old snapshots
        cleanup_snapshots $VOLUME_PATH/snapshots
        # write current_time to /s4/.s4/last_replicated
        export TZ='America/Chicago'
        echo $(date) > $VOLUME_PATH/.s4/last_replicated
        # write out size of volume in bytes
        du -sm $VOLUME_PATH/data | cut -f1 > $VOLUME_PATH/.s4/volume_size
        sync
        prev_generation=$(get_generation $SUBVOLUME)
    else
        echo "No changes since last push"
    fi
}