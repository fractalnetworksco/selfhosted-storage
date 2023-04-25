#!/bin/bash

function create_loop_device() {
    DEVICE="$1" #/dev/loop0
    LOOP_FILE="$2" #/path/to/some/file
    losetup_sudo -P $DEVICE $LOOP_FILE
}

function get_loop_device_for_file() {
    LOOP_FILE="$1"
    # get loopback device
    losetup_sudo -a | grep $1 | awk -F: '{print $1}'
}

function get_file_for_loop_device() {
    LOOP_DEV="$1"
    # get file associated with loop device
    losetup -l | grep "^$LOOP_DEV " | awk '{print $6}'
}

function get_next_loop_device() {
    next_device=$(losetup_sudo -f)
    # check if next_device exist if not create it
    if [ ! -e $next_device ]; then
        mknod_sudo $next_device b 7 $(echo $next_device | sed 's/\/dev\/loop//')
    fi
    echo $next_device
}

function create_loop_file() {
    # creates a dense file of the specified size OR a dense file double the size of the directory specified by $1
    # exit if not 2 argumetns
    if [ $# -lt 2 ]; then
        echo "Usage: create_loop_file <dir> <loop_file> [size]"
        exit 1
    fi

    # dir to use a size reference when $SIZE is not given
    DIR="$1"
    # path to file that will become a loop device
    LOOP_FILE="$2"
    # size of volume in MB
    SIZE="$3"

    # exit if $LOOP_FILE already exists
    if [ -f $LOOP_FILE ]; then
        echo "$LOOP_FILE already exists"
        exit 1
    fi

    # if $SIZE is not given, get the size of $DIR and double it later
    if [ -z "$SIZE" ]; then
        SIZE=$(du -sm "$DIR" | awk '{print $1}')
        # DOUBLE SIZE
        SIZE=$((SIZE * 2))
    fi
    # make sure size is a number else exit
    if ! [[ $SIZE =~ ^[0-9]+$ ]]; then
        echo "File size invalid or not specified, got: $SIZE"
        echo "Please provide the size of the volume in megabytes."
        exit 1

    elif [ $SIZE -lt 1 ]; then
        echo "File size invalid or not specified, got: $SIZE"
        echo "Please provide the size of the volume in megabytes."
        exit 1
    fi

    # make sure we have enough space to create the file + 20%
    FREE_SPACE=$(df -m $S4_LOOP_DEV_PATH | awk 'NR==2{print $4}')
    # add 20% to FREE_SPACE
    FREE_SPACE=$((FREE_SPACE + (FREE_SPACE / 5)))
    if [ $SIZE -gt $FREE_SPACE ]; then
        echo "Not enough space to create file of size $SIZE"
        exit 1
    fi

    # if not given a minimum size, use 1GB as default
    if [ -z $S4_DEFAULT_MIN_SIZE ]; then
        # if $SIZE less than 1GB, set to 1GB
        if [ $SIZE -lt 1024 ]; then
            SIZE=1024
        fi
    # if S4_DEFAULT_MIN_SIZE is set, use that as the minimum size
    else
        if [ $SIZE -lt $S4_DEFAULT_MIN_SIZE ]; then
            SIZE=$S4_DEFAULT_MIN_SIZE
        fi
    fi

    dd_sudo if=/dev/zero of="$LOOP_FILE" bs=1M count=$SIZE
}
