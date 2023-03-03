#!/bin/bash
set -u
# usage s4.sh create 

# document scripts arguments



# function that inits borg repo
function init_borg() {
    echo "Initializing borg repo"
    # create borg repo
    borg init --encryption=none $1
}

# function that takes a size parameter and creates a loopback device and formats it btrfs
function create_btrfs_volume() {
    # create loopback device
    dd if=/dev/zero of=$1 bs=1M count=$2
    # create loopback device
    losetup -fP $1
    # create btrfs filesystem
    mkfs.btrfs $(get_loopback_device $1)
    # mount loopback device
}

# create docker volume backed by btrfs loopback device
function create_docker_volume() {
    docker volume create --label s4.volume --driver local --opt type=btrfs --opt device=$(get_loopback_device $1) $1
}

# function that returns the loopback device associated with a file
function get_loopback_device() {
    # get loopback device
    losetup -a | grep $1 | awk -F: '{print $1}'
}

function replicate() {
    docker run -e S4_TARGET=$2 -e VOLUME=$1 --cap-add SYS_ADMIN -it -v /run/host-services/ssh-auth.sock:/run/host-services/ssh-auth.sock -e SSH_AUTH_SOCK="/run/host-services/ssh-auth.sock" -v /var/run/docker.sock:/var/run/docker.sock -v $1:/s4 --restart always --name $1-s4-agent -d s4-agent:latest
}

# top-level create function that uses the functions above to implement the create command
function create() {
    vol_name=$(echo $1| awk -F/ '{print $NF}')
    echo "Creating s4 volume $vol_name"
    init_borg $1
    # exit if exit code was not 0
    if [ $? -ne 0 ]; then
        echo "Error initializing borg repo"
        exit 1
    fi
    create_btrfs_volume $vol_name $2
    create_docker_volume $vol_name
    replicate $vol_name $1
}

# call create function if $1 is "create"
if [ $1 = "init" ]; then
    create $2 $3
fi