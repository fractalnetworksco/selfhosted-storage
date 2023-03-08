#!/bin/bash
set -u

# shell script that creates a read-only snapshot of a btrfs subvolume if the generation has changed since the last snapshot
# usage: replicate.sh <subvolume>
SCRIPT_DIR=$(dirname $(readlink -f $0))
source $SCRIPT_DIR/config.sh
source $SCRIPT_DIR/btrfs.sh

GENERATION_FILE=/s4/.s4/generation

# read generation from $3
if [ -f $GENERATION_FILE ]; then
    # read the generation from the file
    generation=$(cat $GENERATION_FILE)
else
    # write generation to file
    write_generation $1 $GENERATION_FILE
fi

REMOTE_PORT=${PORT:-2222}
export BORG_RSH="ssh -p $REMOTE_PORT -o BatchMode=yes -i /s4/.s4/id_ed25519 -o StrictHostKeyChecking=accept-new"
export BORG_UNKNOWN_UNENCRYPTED_REPO_ACCESS_IS_OK=yes
REMOTE=$(get_config /s4/.s4/config remote)
VOLUME=$(get_config /s4/.s4/config volume)
echo "Starting replication loop for $VOLUME to $REMOTE"

prev_generation=$(cat $GENERATION_FILE)
while true; do

    generation=$(get_generation $1)
    # check if the generation has changed since the last snapshot
    if [ $generation -ne $prev_generation ]; then
        echo "Taking new snapshot"
        # create a read-only snapshot of the subvolume
        take_snapshot $1 $GENERATION_FILE $generation
        cd /s4/snapshots/snapshot-$generation/data
        borg create --progress $REMOTE::$VOLUME-$generation .
        # exit if last command not successful
        if [ $? -ne 0 ]; then
            echo "Failed to replicate borg snapshot"
            exit 1
        fi
        # write current_time to /s4/.s4/last_replicated
        export TZ='America/Chicago'
        echo $(date) > /s4/.s4/last_replicated
        cd ../../..
        sync
        prev_generation=$(get_generation $1)
    else
        echo "No new snapshot"
    fi
    sleep 1
done
