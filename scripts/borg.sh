#!/bin/bash
function get_latest_archive() {
    borg list --short --last 1 $1
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