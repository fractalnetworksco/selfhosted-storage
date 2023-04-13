#!/bin/bash
function get_latest_archive() {
    REPO=$1
    borg --bypass-lock list --short --last 1 $REPO
}

function check_repo_exists() {
    get_latest_archive $1
}

function is_remote_initialized() {
    local REMOTE=$1
    borg info $REMOTE &> /dev/null
}

function init_remote() {
    local REMOTE=$1
    borg init --encryption=none $REMOTE
}

function mount_archive() {
    check_is_s4
    source $SCRIPT_DIR/base.sh
    REMOTE_NAME=$1
    REMOTE=$(get_remote $REMOTE_NAME)
    MOUNT_POINT=$2
    if [ -z "$3" ]; then
        ARCHIVE=$(get_latest_archive $REMOTE)
    else
        ARCHIVE=$3
    fi
    borg --bypass-lock mount $REMOTE::$ARCHIVE $MOUNT_POINT
    # exit if mount failed
    if [ "$?" -ne 0 ]; then
        echo "Failed to mount archive"
        exit 1
    fi
    echo "Mounted latest archive for volume $REMOTE::$ARCHIVE to $MOUNT_POINT"
}