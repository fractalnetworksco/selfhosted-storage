#!/bin/bash

# wrapper script that calls s4 remote sub commands in the scripts folder
# usage: s4 remote <subcommand> <args>

SCRIPT_DIR=$(dirname $(readlink -f $0))

source $SCRIPT_DIR/base.sh
check_is_s4

# if not $1 print usage and exit
if [ -z "$1" ]; then
    echo "usage: s4 remote <subcommand> <args>"
    exit 1
fi
OPTS=`getopt -o v -- "$@"`
eval set -- "$OPTS"
while true; do
  case "$1" in
    -v)
      crudini --get --format ini .s4/config remotes
      exit 0
      shift
      ;;
    --)
      shift
      break
      ;;
    *)
      echo "Invalid option: $1" >&2
      exit 1
      ;;
  esac
done
# get the subcommand
SUBCOMMAND=$1
shift

# call the subcommand
$SCRIPT_DIR/remote/$SUBCOMMAND.sh "$@"

