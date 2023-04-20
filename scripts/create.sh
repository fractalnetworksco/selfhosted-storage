#!/bin/bash
 set -e
# Usage: create <volume_name>

# script dir
SCRIPT_DIR=$(dirname $(readlink -f $0))

# Parse optional arguments using getopts with long options
OPTS=`getopt -o s:d --long size:,loop-device: -- "$@"`
eval set -- "$OPTS"
while true; do
  case "$1" in
    -s|--size)
      SIZE="$2"
      shift 2
      ;;
    -d|--loop-device)
      LOOP_DEV="$2"
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
# exit if $1 is not set
if [ -z "$LOOP_FILE_PATH" ]; then
    echo "Usage: create <loop_file_path>"
    exit 1
fi

# if loop-device not set
if [ -z "$LOOP_DEV" ]; then
  LOOP_DEV=$(get_next_loop_device)
fi

# create a symlink that points the loop device so we have a path for the volume to give docker
ln_sudo -sf $LOOP_DEV $LOOP_FILE_PATH

# append -loop to the stable symlink path for the actual loop file path
LOOP_DEV_FILE=$LOOP_FILE_PATH-loop

# if SIZE is set, create a file of that size
if [ -n "$SIZE" ]; then
    echo "Got size: $SIZE"
    create_loop_file $(pwd) $LOOP_DEV_FILE $SIZE
else
    # allocate file twice the size of the current directory being initialized
    create_loop_file $(pwd) $LOOP_DEV_FILE
fi

# create loop device
create_loop_device $LOOP_DEV $LOOP_DEV_FILE

s4 config set volume loop_file $LOOP_DEV_FILE

# format loop device btrfs
mkfs_btrfs $LOOP_DEV

# exit if not successful
if [ $? -ne 0 ]; then
    echo "Failed to create volume: $VOLUME_NAME"
    exit 1
fi
