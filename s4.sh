#!/bin/bash

# wrapper script that calls s4 sub commands in the scripts folder
# usage: s4.sh <subcommand> <args>

SCRIPT_DIR=$(dirname $(readlink -f $0))

# if not $1 print usage and exit
if [ -z "$1" ]; then
    echo "usage: s4.sh <subcommand> <args>"
    exit 1
fi
# get the subcommand
SUBCOMMAND=$1
shift

# check if the subcommand exists
if [ -f "$SCRIPT_DIR/scripts/$SUBCOMMAND.sh" ]; then
    # call the subcommand
    $SCRIPT_DIR/scripts/$SUBCOMMAND.sh "$@"
else
    # call defined functions passing args
    source $SCRIPT_DIR/scripts/base.sh
    ${SUBCOMMAND} "$@"
fi
