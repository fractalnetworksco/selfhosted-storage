#!/bin/bash

# Usage: ready <volume_path>
# this script is used as a Docker container healthcheck for s4 agents
# in order to ensure that the S4 volume is ready to be used

# script dir
SCRIPT_DIR=$(dirname $(readlink -f $0))

source $SCRIPT_DIR/base.sh

# if $1 is specified, set VOLUME_PATH to $1, otherwise use pwd
VOLUME_PATH=${1:-$(pwd)}

# ensure the given path is an s4 volume
check_is_s4 $VOLUME_PATH

# exit 0 if $VOLUME_PATH/.s4/.synced exists
if [ -f "$VOLUME_PATH/.s4/.synced" ]; then
    echo "$VOLUME_PATH is synced"
    exit 0
else
    echo "$VOLUME_PATH is not synced"
    exit 1
fi
