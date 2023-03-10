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