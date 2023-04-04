#!/bin/bash

SCRIPT_DIR=$(dirname $(readlink -f $0))
source $SCRIPT_DIR/base.sh

REMOTE=$1
MOUNT_POINT=$2

mount_latest_archive $REMOTE $MOUNT_POINT
