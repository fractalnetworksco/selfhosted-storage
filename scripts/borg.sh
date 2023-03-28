#!/bin/bash
function get_latest_archive() {
    if [ -z "$BORG_RSH" ]; then
        export BORG_RSH="ssh -p 2222 -o BatchMode=yes -o StrictHostKeyChecking=accept-new"
    fi
    borg list --short --last 1 $1
}


function check_repo_exists() {
    get_latest_archive $1
}
