#!/bin/bash


SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source $SCRIPT_DIR/btrfs.sh
source $SCRIPT_DIR/config.sh
source $SCRIPT_DIR/loop_dev.sh
source $SCRIPT_DIR/s4_volume.sh
source $SCRIPT_DIR/sha1-compare.sh
source $SCRIPT_DIR/operations.sh

export S4_REMOTE_PORT=${S4_REMOTE_PORT:-2222}
export S4_LOOP_DEV_PATH=${S4_LOOP_DEV_PATH:-/var/lib/fractal}
export GENERATION_FILE=.s4/generation

if [ -z "$BORG_RSH" ]; then
    export BORG_RSH="ssh -p $S4_REMOTE_PORT -o BatchMode=yes -o StrictHostKeyChecking=accept-new"
fi
# ensure that volume directory exists
mkdir -p $S4_LOOP_DEV_PATH

function mount_sudo() {
    if [[ $(id -u) -ne 0 ]]; then
        sudo mount $@
    else
        mount $@
    fi
}

function umount_sudo() {
    if [[ $(id -u) -ne 0 ]]; then
        sudo umount $@
    else
        umount $@
    fi
}

function chown_sudo(){
    if [[ $(id -u) -ne 0 ]]; then
        sudo chown $@
    else
        chown $@
    fi
}

function mkdir_sudo(){
    if [[ $(id -u) -ne 0 ]]; then
        sudo mkdir $@
    else
        mkdir $@
    fi
}

function set_owner_current_user() {
    chown_sudo $(id -u):$(id -g) $1
}

function check_is_s4() {
    # make sure .s4 exists in the current directory, else exit
    if [ ! -d .s4 ]; then
        echo "Error: "$PWD" is not a s4 volume"
        exit 1
    fi
}