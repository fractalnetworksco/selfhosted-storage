#!/bin/ash

# shell script that creates a read-only snapshot of a btrfs subvolume if the generation has changed since the last snapshot
# usage: replicate.sh <subvolume>

GENERATION_FILE=/generation

function get_generation() {
    # get the generation of a subvolume
    btrfs subvolume show $1 | grep Generation | awk '{print $2}'
}

function take_snapshot() {
    # create a read-only snapshot of the subvolume
    btrfs subvolume snapshot -r $1 snapshots/snapshot-$generation
    btrfs filesystem sync $1
    local generation=$(get_generation $1)
    echo $generation > $GENERATION_FILE

}

# read generation from $3
if [ -f $GENERATION_FILE ]; then
    # read the generation from the file
    generation=$(cat $GENERATION_FILE)
else
    # create the file and write the generation
    generation=$(get_generation $1)
    take_snapshot $1
fi

# check if the generation has changed since the last snapshot
if [ $(get_generation $1) -ne $generation ]; then
    # create a read-only snapshot of the subvolume
    take_snapshot $1 $(get_generation $1)
fi

# read value from file into variable in while loop
while true; do
    # get the generation of a subvolume
    generation=$(get_generation $1)
    # check if the generation has changed since the last snapshot
    if [ $generation -ne $(cat $GENERATION_FILE) ]; then
        echo "Taking new snapshot"
        # create a read-only snapshot of the subvolume
        take_snapshot $1 $generation
        export BORG_RSH="ssh -i /code/borg_key -p 2222"
        borg create --progress borg@172.17.0.1:~/repo::snap-$generation snapshots/snapshot-$generation

    else
        echo "No new snapshot"
    fi
    sleep 1  
done