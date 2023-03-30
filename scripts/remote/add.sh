#!/bin/bash

SCRIPT_DIR=$(dirname $(readlink -f $0))

source $SCRIPT_DIR/../base.sh

echo "SEEEE"
echo "$@"
# make sure 2 arguments are passed, else exit
if [ $# -ne 2 ]; then
    echo "usage: s4 remote add <name> <url>"
    exit 1
fi

s4 config set .s4/config remotes $1 $2

