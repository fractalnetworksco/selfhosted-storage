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
    # get the next available loop device
    # we need to make sure loop device name is consistent across reboots so we
    # store the loop device name in the backing file
    # this is because we cannot update a docker volume once
    # it is created and would have to recreat the volume otherwise
    LOOP_DEV=$(get_next_loop_device)

    LOOP_DEV_FILE=$VOL_DIR/$VOL-$(basename $LOOP_DEV)
    # allocate file twice the size of the current directory being initialized
    create_double_size_file $(pwd) $LOOP_DEV_FILE

    # create loop device
    create_loop_device $LOOP_DEV $LOOP_DEV_FILE

    echo "Created loop device"

    # format loop device btrfs
    mkfs_btrfs $LOOP_DEV

    echo "Formatted $LOOP_DEV as BTRFS"

    # create btrfs backed docker volume
    # IF $NODOCKER is set, don't create docker volume
    if [ -z "$NODOCKER" ]; then
        #if docker volume exists, remove it
        if docker volume ls -q | grep -q $VOL; then
            echo "Docker volume with name $VOL already exists"
            exit 1
        fi
        docker volume create --label s4.volume --driver local --opt type=btrfs\
        --opt device=$LOOP_DEV $VOL

        echo "Created docker volume: $VOL"
    fi

    TMP_MOUNT=/mnt/tmp
    mkdir_sudo -p $TMP_MOUNT
    mount_sudo $LOOP_DEV $TMP_MOUNT
    # chown /tmp with current user and group id
    # store current user and group id in variables
    set_owner_current_user $TMP_MOUNT
    umount_sudo $TMP_MOUNT

else
    echo "Usage: create <volume_path> <volume_name>"
    exit 1
fi

# exit if not successful
if [ $? -ne 0 ]; then
    echo "Failed to create volume: $VOL"
    exit 1
fi

# copy data to new volume
echo "Successfully created volume: $VOL"
