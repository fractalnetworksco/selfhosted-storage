#!/bin/bash

SCRIPT_DIR=$(dirname $(readlink -f $0))

function push() {
    source $SCRIPT_DIR/base.sh
    SUBVOLUME=$(pwd)
    prev_generation=$(cat $GENERATION_FILE)
    generation=$(get_generation $SUBVOLUME)
    # check if the generation has changed since the last snapshot
    if [ $generation -ne $prev_generation ]; then
        echo "Taking new snapshot"
        echo $SUBVOLUME
        # create a read-only snapshot of the subvolume
        take_snapshot $SUBVOLUME $GENERATION_FILE $generation
        cd $VOLUME_PATH/snapshots/snapshot-$generation
        borg create --progress $REMOTE::$VOLUME-$generation .
        cd ../../
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