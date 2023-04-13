#!/bin/bash

SCRIPT_DIR=$(dirname $(readlink -f $0))
source $SCRIPT_DIR/base.sh

REMOTE_NAME=$1

while true; do
    if [ -z "$REMOTE_NAME" ]; then
        REMOTE_NAME=$(s4 config get default remote)
    fi
    echo "Pulling from $REMOTE_NAME"
    pull
    sleep 1
done