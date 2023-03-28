#!/bin/bash
set -x

# if LOOP_DEV or $1 is not set or VOLUME_NAME or $2 is not set, exit
if [ -z "$LOOP_DEV" ] && [ -z "$1" ] || [ -z "$VOLUME_NAME" ] && [ -z "$2" ]; then
    echo "usage: s4 docker create <loop device> <volume name>"
    exit 1
fi

LOOP_DEV=${LOOP_DEV:-$1}
VOLUME_NAME=${VOLUME_NAME:-$2}

# create docker volume
echo "Creating docker volume $VOLUME_NAME using loop device: $LOOP_DEV"
docker volume create --driver local --opt type=btrfs --opt device=$LOOP_DEV $VOLUME_NAME
