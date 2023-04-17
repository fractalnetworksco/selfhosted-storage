#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source $SCRIPT_DIR/btrfs.sh
source $SCRIPT_DIR/borg.sh
source $SCRIPT_DIR/loop_dev.sh
source $SCRIPT_DIR/sha1-compare.sh
source $SCRIPT_DIR/operations.sh

export S4_REMOTE_PORT=${S4_REMOTE_PORT:-2222}
export S4_LOOP_DEV_PATH=${S4_LOOP_DEV_PATH:-/var/lib/fractal}
export BORG_RELOCATED_REPO_ACCESS_IS_OK=yes
export BORG_UNKNOWN_UNENCRYPTED_REPO_ACCESS_IS_OK=yes

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

function truncate_sudo() {
    if [[ $(id -u) -ne 0 ]]; then
        sudo truncate $@
    else
        truncate $@
    fi
}

function dd_sudo() {
    if [[ $(id -u) -ne 0 ]]; then
        sudo dd $@
    else
        dd $@
    fi
}

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

function set_owner_current_user() {
    chown_sudo $(id -u):$(id -g) $1
}

function check_is_s4() {
    # use pwd if no volume path is given
    VOLUME_PATH="${1:-$(pwd)}"
    # make sure .s4 exists in the given directory, else exit
    if [ ! -d "$VOLUME_PATH/.s4" ]; then
        echo "Error: "$VOLUME_PATH" is not a s4 volume"
        exit 1
    fi
}

function check_is_not_s4() {
    # use pwd if no volume path is given
    VOLUME_PATH="${1:-$(pwd)}"
    # make sure .s4 exists in the given directory, else exit
    if [ -d "$VOLUME_PATH/.s4" ]; then
        echo "Error: "$VOLUME_PATH" is already an s4 volume"
        exit 1
    fi
}

function generate_uuid() {
    # use uuidgen if it exists in path else use uuid -v4
    if command -v uuidgen &> /dev/null; then
        uuidgen
    else
        uuid -v4
    fi
}

function get_remote() {
    local REMOTE_NAME=$1
    if [ -z "$REMOTE_NAME" ]; then
        REMOTE_NAME=$(s4 config get default remote)
    fi
    echo $(s4 config get remotes $REMOTE_NAME)
}
