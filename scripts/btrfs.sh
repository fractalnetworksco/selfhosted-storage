#!/bin/bash

function blkid_sudo() {
    if [[ $(id -u) -ne 0 ]]; then
        sudo blkid $1
    else
        blkid $1
    fi
}

function btrfs_sudo() {
    if [[ $(id -u) -ne 0 ]]; then
        sudo btrfs $@
    else
        btrfs $@
    fi
}

function is_btrfs() {
    if [[ $(blkid_sudo $(get_device $1)) =~ "btrfs" ]]; then
        return 0
    else
        return 1
    fi
}

# give a path, return the device that contains the path
function get_device() {
    df $1|awk 'NR==2{print $1}'
}


function get_generation() {
    # get the generation of a subvolume
    btrfs_sudo subvolume show $1 | grep Generation | awk '{print $2}'
}

function take_snapshot() {
    # create a read-only snapshot of the subvolume
    btrfs_sudo subvolume snapshot -r $1 snapshots/snapshot-$3
    write_generation $1 $2
}

function write_generation() {
    # write the generation to a file
    echo $(get_generation $1) > $2
}

function cleanup_snapshots() {
    btrfs_sudo sub list $1|awk '{print $9}'|while read subvol; do btrfs_sudo sub delete $subvol; done
}

function create_subvolume() {
    btrfs_sudo subvolume create $1
}

function mkfs_btrfs() { 
    # create a btrfs filesystem
    if [[ $(id -u) -ne 0 ]]; then
        sudo mkfs.btrfs $1
    else
        mkfs.btrfs $1
    fi
}

# if pwd is btrfs set BTRFS to true
if is_btrfs .; then
    export BTRFS=true
else
    export BTRFS=false
fi