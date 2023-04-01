#!/bin/bash
# list volumes in the repo
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source $SCRIPT_DIR/base.sh

check_is_s4
REMOTE_NAME=$1
REMOTE=$(get_remote $REMOTE_NAME)
borg list $REMOTE