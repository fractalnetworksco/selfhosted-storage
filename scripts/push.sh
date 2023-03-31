#!/bin/bash

SCRIPT_DIR=$(dirname $(readlink -f $0))
source $SCRIPT_DIR/base.sh

check_is_s4
# parse optional arguments using getopts with long options
OPTS=`getopt -o v -- "$@"`
eval set -- "$OPTS"
while true; do
  case "$1" in
    -v)
      export VERBOSE=1
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

REMOTE_NAME=$1
push "$REMOTE_NAME"