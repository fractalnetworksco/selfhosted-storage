#!/bin/bash

# wrapper script that calls s4 sub commands in the scripts folder
# usage: s4.sh <subcommand> <args>

# if not $1 print usage and exit
if [ -z "$1" ]; then
    echo "usage: s4.sh <subcommand> <args>"
    exit 1
fi
# get the subcommand
SUBCOMMAND=$1
shift

# call the subcommand
/home/balaa/selfhosted-storage/scripts/$SUBCOMMAND.sh $@
