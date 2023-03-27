#!/bin/bash
set -x

function losetup_sudo() {
    if [[ $(id -u) -ne 0 ]]; then
        sudo losetup $@
    else
        losetup $@
    fi
}

function mknod_sudo(){
    if [[ $(id -u) -ne 0 ]]; then
        sudo mknod $@
    else
        mknod $@
    fi
}

function create_loop_device() {
    losetup_sudo -P $1 $2
}

function get_loop_device_for_file() {
    # get loopback device
    losetup_sudo -a | grep $1 | awk -F: '{print $1}'
}


function get_next_loop_device() {
    next_device=$(losetup_sudo -f)
    # check if next_device exist if not create it
    if [ ! -e $next_device ]; then
        mknod_sudo $next_device b 7 $(echo $next_device | sed 's/\/dev\/loop//')
    fi
    echo $next_device
}

function clone_remote_into_mounted_volume() {
    # args:
    #  $1 - remote to clone
    #  $2 - mounted volume to clone into
    REMOTE="$1"
    MOUNT="$2"

    cd $MOUNT

    echo "Cloning latest snapshot of $REMOTE into $MOUNT"
    borg extract --progress "$REMOTE"

    cd -
}

function create_btrfs_loop_device_and_volume() {
    # args:
    #   $1 - Name of volume to create
    #   $2 [OPTIONAL] - Size of volume to create
    #   $3 [OPTIONAL] - If set, will clone from specified remote into mounted volume

    VOL="$1"
    VOL_SIZE="$2"
    REMOTE_TO_CLONE="$3"

    # store the loop device name in the backing file
    # this is because we cannot update a docker volume once
    # it is created and would have to recreat the volume otherwise
    LOOP_DEV=$(get_next_loop_device)

    LOOP_DEV_FILE=$VOL_DIR/$VOL-$(basename $LOOP_DEV)

    # if VOL_SIZE is set, create a file of that size
    if [ ! -z "$VOL_SIZE" ]; then
        create_loop_file $(pwd) $LOOP_DEV_FILE $VOL_SIZE
    else
        # allocate file twice the size of the current directory being initialized
        create_loop_file $(pwd) $LOOP_DEV_FILE
    fi

    # create loop device
    create_loop_device $LOOP_DEV $LOOP_DEV_FILE

    echo "Created loop device"

    # format loop device btrfs
    mkfs_btrfs $LOOP_DEV

    echo "Formatted $LOOP_DEV as BTRFS"

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

    # if remote to clone is set, clone remote into mounted volume
    if [ ! -z "$REMOTE_TO_CLONE" ]; then
        # clone remote into mounted volume
        clone_remote_into_mounted_volume $REMOTE_TO_CLONE $TMP_MOUNT
    fi

    umount_sudo $TMP_MOUNT
}

#/code/scripts/double.sh $(pwd) myfile
# create a file of double the size of the current directory
function dd_sudo() {
    if [[ $(id -u) -ne 0 ]]; then
        sudo dd $@
    else
        dd $@
    fi
}

function create_loop_file() {
    # creates a file of double the size of the current directory

    # args:
    #   $1 is the directory to get the size of
    #   $2 is the file to create
    #   $3 is the size to use

    echo "Creating file that is double the size of $1 at $2"
    # if $3 is not given, get the size of $1
    if [ -z $3 ]; then
        size=$(du -sm $1 | awk '{print $1}')
    # $3 was given, so use that as the size
    else
        size=$3
    fi

    if [ -f $2 ]; then
        echo "$2 already exists"
        exit 1
    fi

    doubled=$((size * 2))
    # make sure $1 has enough space + 20%
    FREE_SPACE=$(df -m $S4_LOOP_DEV_PATH | awk 'NR==2{print $4}')
    # add 20% to FREE_SPACE
    FREE_SPACE=$((FREE_SPACE + (FREE_SPACE / 5)))
    if [ $doubled -gt $FREE_SPACE ]; then
        echo "Not enough space to create file of size $doubled"
        exit 1
    fi
    # if double less that 120MB, set to 120MB
    if [ $doubled -lt 120 ]; then
        doubled=120
    fi
    dd_sudo if=/dev/zero of=$2 bs=1M count=$doubled
}