#!/bin/bash

SCRIPT_DIR=$(dirname $(readlink -f $0))

source $SCRIPT_DIR/../base.sh


# make sure 2 arguments are passed, else exit
if [ $# -ne 2 ]; then
    echo "usage: s4 remote add <name> <url>"
    exit 1
fi

set_config .s4/config remotes $1 $2

