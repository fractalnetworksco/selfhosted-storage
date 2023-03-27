#!/bin/bash
 set -e

# Usage: create <volume_name>

# script dir
SCRIPT_DIR=$(dirname $(readlink -f $0))

# Parse optional arguments using getopts with long options
OPTS=`getopt -o s --long size: -- "$@"`
eval set -- "$OPTS"
while true; do
  case "$1" in
    -s|--size)
      SIZE="$2"
      shift 2
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

source $SCRIPT_DIR/base.sh

LOOP_FILE_PATH="$1"

export LOOP_DEV=$(get_next_loop_device)
LOOP_DEV_FILE=$LOOP_FILE_PATH-$(basename $LOOP_DEV)

# if SIZE is set, create a file of that size
if [ -n "$SIZE" ]; then
    create_loop_file $(pwd) $LOOP_DEV_FILE $SIZE
else
    # allocate file twice the size of the current directory being initialized
    create_loop_file $(pwd) $LOOP_DEV_FILE
fi

# create loop device
create_loop_device $LOOP_DEV $LOOP_DEV_FILE

# format loop device btrfs
mkfs_btrfs $LOOP_DEV &> /dev/null

# exit if not successful
if [ $? -ne 0 ]; then
    echo "Failed to create volume: $VOLUME_NAME"
    exit 1
fi

echo $LOOP_DEV
