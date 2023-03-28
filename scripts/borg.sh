#!/bin/bash
function get_latest_archive() {
    borg list --short --last 1 $1
}


function check_repo_exists() {
    get_latest_archive $1
}
