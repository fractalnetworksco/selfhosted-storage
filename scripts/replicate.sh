#!/bin/bash
set -u

SCRIPT_DIR=$(dirname $(readlink -f $0))
source $SCRIPT_DIR/base.sh

init_volume

# read generation from $3
if [ -f $GENERATION_FILE ]; then
    # read the generation from the file
    generation=$(cat $GENERATION_FILE)
else
    # write generation to file
    write_generation $1 $GENERATION_FILE
fi

echo "Starting replication loop for $VOLUME to $REMOTE"

# store last positional argument as SUBVOLUME
SUBVOLUME=$VOLUME_PATH

# default interval to 1 second
REPLICATION_INTERVAL=1
while [[ $# -gt 0 ]]; do
    key="$1"
    case $key in
        --interval)
            REPLICATION_INTERVAL="$2"
            shift # past argument
            shift # past value
            ;;
        *)    # unknown option
            shift # past argument
            ;;
    esac
done

# set to 0 so we always replicate a snapshot on the first run
prev_generation=0
while true; do

    generation=$(get_generation $SUBVOLUME)
    # check if the generation has changed since the last snapshot
    if [ $generation -ne $prev_generation ]; then
        # create a read-only snapshot of the subvolume
        echo "Taking new snapshot of $(pwd)"
        take_snapshot $SUBVOLUME $GENERATION_FILE $generation

        cd $VOLUME_PATH/.s4/snapshots/snapshot-$generation
        echo "In snapshot directory: $(pwd)"

        echo "Replicating snapshot to remote"
        borg create --progress $REMOTE::$VOLUME-$generation .

        # exit if last command not successful
        if [ $? -ne 0 ]; then
            echo "Failed to replicate borg snapshot"
            cd $VOLUME_PATH
            exit 1
        fi

        cd $VOLUME_PATH

        # cleanup old snapshots
        cleanup_snapshots $VOLUME_PATH/.s4/snapshots

        # write current_time to /s4/.s4/last_replicated
        export TZ='America/Chicago'
        echo $(date) > $VOLUME_PATH/.s4/last_replicated

        # write out size of volume in bytes
        pwd
        du -sm $VOLUME_PATH | cut -f1 > $VOLUME_PATH/.s4/volume_size

        sync

        prev_generation=$(get_generation $SUBVOLUME)
    else
        echo "No new snapshot"
    fi
    sleep $REPLICATION_INTERVAL
done
