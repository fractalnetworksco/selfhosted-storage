#!/bin/bash

SCRIPT_DIR=$(dirname $(readlink -f $0))
source $SCRIPT_DIR/../base.sh

# make sure 2 arguments are passed, else exit
if [ $# -ne 2 ]; then
    echo "usage: s4 remote add <name> <url>"
    exit 1
fi

s4 config set remotes $1 "$2"
s4 config set remotes $1.initialized 0

# if $1 is origin set it as the default remote
if [ $1 = "origin" ]; then
    s4 config set default remote origin
fi