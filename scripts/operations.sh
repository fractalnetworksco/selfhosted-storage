#!/bin/bash

SCRIPT_DIR=$(dirname $(readlink -f $0))

function push() {
    # if $1 not set use default remote
    if [ -z "$1" ]; then
        DEFAULT_REMOTE=$(s4 config get default remote)
        REMOTE=$(s4 config get remotes $DEFAULT_REMOTE)
    else
        REMOTE=$(s4 config get remotes $1)
    fi
    # if $REMOTE is empty exit
    if [ "$?" -ne 0 ]; then
        echo "Remote $1 is not configured for $(s4 config get volume name)"
        exit 1
    fi
    source $SCRIPT_DIR/base.sh
    VOLUME_PATH=$(pwd)
    VOLUME_NAME=$(s4 config get volume name)
    prev_generation=$(s4 config get ~/.s4/volumes/$VOLUME_NAME state generation)
    generation=$(get_generation $VOLUME_PATH)
    # check if the generation has changed since the last snapshot
    # if VERBOSE is set, print the generation numbers
    if [ ! -z "$VERBOSE" ]; then
        echo "Remote is $REMOTE"
        echo "Previous generation: $prev_generation"
        echo "Current generation: $generation"
    fi
    if [ $generation -ne $prev_generation ]; then
        echo "Taking new snapshot"
        s4 config set volume last_replicated "$(date)"
        s4 config set volume size "$(du -sm $VOLUME_PATH | cut -f1)"
        # create a read-only snapshot of the subvolume
        SNAPSHOT_UUID=$(generate_uuid)
        take_snapshot $VOLUME_PATH $SNAPSHOT_UUID
        cd $VOLUME_PATH/.s4/snapshots/snapshot-$SNAPSHOT_UUID
        borg create --progress $REMOTE::$SNAPSHOT_UUID .
        cd $VOLUME_PATH
        # exit if last command not successful
        if [ $? -ne 0 ]; then
            echo "Failed to replicate borg snapshot"
            exit 1
        fi
        # cleanup old snapshots
        cleanup_snapshots $VOLUME_PATH/.s4/snapshots
        # write last replicated time to volume config
        if [ -z "$TZ" ]; then
            export TZ='America/Chicago'
        fi
        sync
        s4 config set ~/.s4/volumes/$VOLUME_NAME state generation $(get_generation $VOLUME_PATH)
    else
        echo "No changes since last push"
    fi
}