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


function get_generation() {
    # get the generation of a subvolume
    btrfs subvolume show $1 | grep Generation | awk '{print $2}'
}

function take_snapshot() {
    # create a read-only snapshot of the subvolume
    btrfs subvolume snapshot -r $1 snapshots/snapshot-$3
    write_generation $1 $2
}

function write_generation() {
    # write the generation to a file
    echo $(get_generation $1) > $2
}

function cleanup_snapshots() {
    btrfs sub list $1|awk '{print $9}'|while read subvol; do btrfs sub delete /s4/$subvol; done
}

function create_subvolume() {
    btrfs subvolume create $1
}


# if pwd is btrfs set BTRFS to true
if is_btrfs .; then
    export BTRFS=true
else
    export BTRFS=false
fi