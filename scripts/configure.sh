#!/bin/bash

SCRIPT_DIR=$(dirname $(readlink -f $0))
source $SCRIPT_DIR/config.sh

# if ~/.s4/config exists exit
if [ -f ~/.s4/config ]; then
    echo "Config file already exists"
    exit 1
fi

# prompt use for remote url
read -p "Remote url: " REMOTE_URL
# write remote url to config file
write_remote ~/.s4/config $REMOTE_URL
