#!/bin/bash


function is_btrfs() {
    if [[ $(blkid $(get_device $1)) =~ "btrfs" ]]; then
        return 0
    else
        return 1
    fi
}

# give a path, return the device that contains the path
function get_device() {
    df $1|awk 'NR==2{print $1}'
} 