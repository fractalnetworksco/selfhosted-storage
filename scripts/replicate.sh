#!/bin/bash

SCRIPT_DIR=$(dirname $(readlink -f $0))
source $SCRIPT_DIR/base.sh

check_is_s4

# start ssh-agent with socket at /tmp/ssh-agent.sock
# eval `ssh-agent -a /tmp/ssh-agent.sock`

REMOTE_NAME=$1
# if remote name is not set, use default remote
if [ -z "$REMOTE_NAME" ]; then
    REMOTE_NAME=$(s4 config get default remote)
fi
VOLUME_NAME=$(s4 config get volume name)
REMOTE=$(s4 config get remotes $REMOTE_NAME)
# read generation from $3
echo "Starting replication loop for s4 $VOLUME_NAME to remote $REMOTE"

# default interval to 1 second
REPLICATION_INTERVAL=1
while [[ $# -gt 0 ]]; do
    key="$1"
    case $key in
        --interval)
            REPLICATION_INTERVAL="$2"
            shift # past argument
            shift # past value
            ;;
        *)    # unknown option
            shift # past argument
            ;;
    esac
done

while true; do
    push "$REMOTE_NAME"
    sleep $REPLICATION_INTERVAL
done
