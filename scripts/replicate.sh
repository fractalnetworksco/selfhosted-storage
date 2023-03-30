#!/bin/bash

SCRIPT_DIR=$(dirname $(readlink -f $0))
source $SCRIPT_DIR/base.sh

check_is_s4

# start ssh-agent with socket at /tmp/ssh-agent.sock
eval `ssh-agent -a /tmp/ssh-agent.sock`
VOLUME_PATH=$(pwd)

# read generation from $3
if [ -f $GENERATION_FILE ]; then
    # read the generation from the file
    generation=$(cat $GENERATION_FILE)
else
    # write generation to file
    write_generation "$VOLUME_PATH" $GENERATION_FILE
fi

VOLUME_NAME=$(get_config $VOLUME_PATH/.s4/config volume name)
#TODO optinally pass remote as --remote option
DEFAULT_REMOTE="origin"
REMOTE=$(get_config $VOLUME_PATH/.s4/config remotes $DEFAULT_REMOTE)
echo "Starting replication loop for $VOLUME_NAME to $REMOTE"


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

    generation=$(get_generation $VOLUME_PATH)
    # check if the generation has changed since the last snapshot
    if [ $generation -ne $prev_generation ]; then
        # create a read-only snapshot of the subvolume
        echo "Taking new snapshot of $(pwd)"
        take_snapshot $VOLUME_PATH $GENERATION_FILE $generation

        cd $VOLUME_PATH/.s4/snapshots/snapshot-$generation
        echo "In snapshot directory: $(pwd)"

        echo "Replicating snapshot to remote"
        borg create --progress $REMOTE::$VOLUME_NAME-$generation .

        # exit if last command not successful
        if [ $? -ne 0 ]; then
            echo "Failed to replicate borg snapshot"
        fi

        cd $VOLUME_PATH

        # cleanup old snapshots
        cleanup_snapshots $VOLUME_PATH/.s4/snapshots

        # write current_time to /s4/.s4/last_replicated
        export TZ='America/Chicago'
        s4 config set volume last_replicated "$(echo $(date))"

        # write out size of volume in bytes
        s4 config set volume size "$(du -sm $VOLUME_PATH | cut -f1)"
        sync

        prev_generation=$(get_generation $VOLUME_PATH)
    else
        echo "No new snapshot"
    fi
    sleep $REPLICATION_INTERVAL
done
