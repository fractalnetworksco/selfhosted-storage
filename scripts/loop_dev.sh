#!/bin/bash

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
    DEVICE="$1" #/dev/loop0
    FILE="$2" #/path/to/some/file
    losetup_sudo -P $DEVICE $FILE
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
    # creates a dense file of the specified size OR a dense file double the size of the directory specified by $1

    # args:
    #   $1 is the directory to get the size of
    #   $2 is the file to create
    #   $3 is the size to use
    DIR="$1"
    LOOP_FILE="$2"
    SIZE="$3"

    # exit if $LOOP_FILE already exists
    if [ -f $LOOP_FILE ]; then
        echo "$LOOP_FIVE already exists"
        exit 1
    fi

    # if $SIZE is not given, get the size of $DIR and double it later
    if [ -z "$SIZE" ]; then
        SIZE=$(du -sm "$DIR" | awk '{print $1}')
        DOUBLE=1
    fi
    # make sure $SIZE is defined and a number else exit
    if [ -z $SIZE ] || ! [[ $SIZE =~ ^[0-9]+$ ]]; then
        echo "File size invalid or not specified, got: $SIZE"
        echo "Please provide the size of the volume in megabytes."
        exit 1
    fi

    if [ ! -z $DOUBLE ]; then
        SIZE=$((SIZE * 2))
    fi
    # make sure we have enough space to create the file + 20%
    FREE_SPACE=$(df -m $S4_LOOP_DEV_PATH | awk 'NR==2{print $4}')
    # add 20% to FREE_SPACE
    FREE_SPACE=$((FREE_SPACE + (FREE_SPACE / 5)))
    if [ $SIZE -gt $FREE_SPACE ]; then
        echo "Not enough space to create file of size $SIZE"
        exit 1
    fi
    # if $SIZE less than btrfs minimum, set to 120MB
    if [ $SIZE -lt 120 ]; then
        SIZE=120
    fi

    dd_sudo if=/dev/zero of="$LOOP_FILE" bs=1M count=$SIZE
}