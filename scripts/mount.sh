#!/bin/bash

SCRIPT_DIR=$(dirname $(readlink -f $0))
source $SCRIPT_DIR/base.sh

REMOTE_NAME=$1
MOUNT_POINT=$2
ARCHIVE=$3

mount_archive $REMOTE_NAME $MOUNT_POINT $ARCHIVE
