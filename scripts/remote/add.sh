#!/bin/bash

# make sure .s4 exists in the current directory, else exit
if [ ! -d .s4 ]; then
    echo "Error: "$PWD" is not a s4 volume"
    exit 1
fi

# make sure 2 arguments are passed, else exit
if [ $# -ne 2 ]; then
    echo "usage: s4 remote add <name> <url>"
    exit 1
fi

crudini --set .s4/config remotes $1 $2

