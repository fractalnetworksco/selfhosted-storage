#!/bin/bash

function create_loop_device() {
    # create loop device
    losetup -P $1 $2
}

function get_loop_device_for_file() {
    # get loopback device
    losetup -a | grep $1 | awk -F: '{print $1}'
}

function get_next_loop_device() {
    # get next loop device
    next_device=$(losetup -f)
    # check if next_device exist if not create it
    if [ ! -e $next_device ]; then
        mknod $next_device b 7 $(echo $next_device | sed 's/\/dev\/loop//')
    fi
    echo $next_device
}