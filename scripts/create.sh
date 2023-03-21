#!/bin/bash
 set -e

# Usage: create <volume_name>

# script dir
SCRIPT_DIR=$(dirname $(readlink -f $0))

# ensure that volume directory exists
VOL_DIR=/var/lib/fractal
mkdir -p $VOL_DIR

source $SCRIPT_DIR/base.sh

# set VOL to $1 if it's set, otherwise set to basename of dir referenced by
# current directory.
[ -n "$1" ] && VOL=$1 || VOL=$(basename $(pwd))

echo "Creating volume: $VOL"

if [[ -n $VOL ]]; then
    # create btrfs backed docker volume
    create_btrfs_loop_device_and_volume $VOL
else
    echo "Usage: create <volume_name>"
    exit 1
fi

# exit if not successful
if [ $? -ne 0 ]; then
    echo "Failed to create volume: $VOL"
    exit 1
fi

# copy data to new volume
echo "Successfully created volume: $VOL"
