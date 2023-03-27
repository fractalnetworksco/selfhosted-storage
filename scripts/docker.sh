#!/bin/bash

# wrapper script that calls s4 docker sub commands in the scripts folder
# usage: docker.sh <subcommand> <args>

SCRIPT_DIR=$(dirname $(readlink -f $0))

# if not $1 print usage and exit
if [ -z "$1" ]; then
    echo "usage: docker.sh <subcommand> <args>"
    exit 1
fi
# get the subcommand
SUBCOMMAND=$1
shift

# call the subcommand
$SCRIPT_DIR/docker/$SUBCOMMAND.sh "$@"

