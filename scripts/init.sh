#!/bin/bash
set -e

# usage:
# s4 init <volume_name> --docker --path <path_to_init>

# script dir
SCRIPT_DIR=$(dirname $(readlink -f $0))

source $SCRIPT_DIR/base.sh

# Define default values for optional arguments
DOCKER=false

# Parse optional arguments using getopts with long options
OPTS=`getopt -o s:d:n --long size:,name:,docker -- "$@"`
eval set -- "$OPTS"
while true; do
  case "$1" in
    -s|--size)
      SIZE="$2"
      shift 2
      ;;
    -d|--docker)
      DOCKER=true
      shift
      ;;
    -n|--name)
      NAME=true
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


VOLUME_PATH="$1"

if [ -z $VOLUME_PATH ]; then
  VOLUME_PATH="."
fi

# change to directory to init volume at
cd $VOLUME_PATH

# set BTRFS variable to true if volume is btrfs
is_btrfs $VOLUME_PATH

export VOLUME_NAME=$(basename $VOLUME_PATH)

# Use the arguments in your script
echo "Positional argument 1 (volume path): $VOLUME_PATH"
echo "Optional argument 1: $SIZE"
echo "Optional argument 2: $DOCKER"
echo "Optional argument 3: $VOLUME_NAME"

# call s4 create to create loop device
LOOP_DEV=$(s4 create "$S4_LOOP_DEV_PATH/$VOLUME_NAME" --size "$SIZE")

if [ "$?" -ne 0 ]; then
  echo "Failed to create volume: $VOLUME_NAME"
  exit 1
fi

if [ "$DOCKER" = true ]; then
  s4 docker create $LOOP_DEV "$VOLUME_NAME"
fi

s4 import "$LOOP_DEV"
