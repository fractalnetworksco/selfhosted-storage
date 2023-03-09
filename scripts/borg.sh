#!/bin/bash
function get_latest_archive() {
    export BORG_RSH="ssh -p 2222 -o BatchMode=yes -o StrictHostKeyChecking=accept-new"
    borg list --short --last 1 $1
}
