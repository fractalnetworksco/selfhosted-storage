#!/bin/bash

LOOP_DEV=${LOOP_DEV:-$1}
VOLUME_NAME=${VOLUME_NAME:-$2}

# create docker volume
echo "Creating docker volume $VOLUME_NAME using loop device: $LOOP_DEV"
docker volume create --driver local --opt type=btrfs --opt device=$LOOP_DEV $VOLUME_NAME
