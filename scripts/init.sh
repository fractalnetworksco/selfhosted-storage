#!/bin/bash
set -e

# usage:
# s4 init <volume_name> --docker --yes --path <path_to_init>

# script dir
SCRIPT_DIR=$(dirname $(readlink -f $0))

source $SCRIPT_DIR/base.sh

# define default values for optional arguments
DOCKER=false

# parse optional arguments using getopts with long options
OPTS=`getopt -o s:d:l:n:y --long size:,name:,label:,docker,yes -- "$@"`
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
    -l|--label)
      DOCKER_LABEL="$2"
      shift 2
      ;;
    -n|--name)
      VOLUME_NAME="$2"
      shift 2
      ;;
    -y|--yes)
      YES=true
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

# exit if a label was specified but docker not specified
if [[ "$DOCKER" = false && -n "$DOCKER_LABEL" ]]; then
  echo "Error: --docker must be set if --label specified"
  exit 1
fi

# if volume path is not set, default to current directory
VOLUME_PATH="${1:-$(pwd)}"

# if volume path is a relative path, get its absolute path
if [[ $VOLUME_PATH != /* ]]; then
  VOLUME_PATH="$(realpath $VOLUME_PATH)"
fi

# if mount point is not set, default to volume path
MOUNT_POINT="${2:-$VOLUME_PATH}"

# if volume name is not set, default to basename of volume path
if [ -z $VOLUME_NAME ]; then
  VOLUME_NAME="$(basename $VOLUME_PATH)"
fi

# prompt the user if they didn't specify the --yes flag
if [ -z $YES ]; then
# bigger scary multiline ascii art warning message
cat <<EOF
+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
WARNING: This command will overwrite the contents of the loop device.
         This will destroy any data on the loop device.
         This command is intended for importing data from a backup.
         If you are not sure what you are doing, please exit now.
+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
EOF
  read -p "Contents of $VOLUME_PATH will be copied into a new s4 volume at $MOUNT_POINT, are you sure? [y/N] " -n 1 -r
  # continue if y
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo
  else
    echo
    exit 1
  fi
fi

# set BTRFS variable to true if volume is btrfs
check_btrfs $MOUNT_POINT

echo "Positional argument 1 (volume path): $VOLUME_PATH"
echo "Positional argument 2 (mount point): $MOUNT_POINT"
echo "Optional argument 1: $SIZE"
echo "Optional argument 2: $DOCKER"
echo "Optional argument 3: $VOLUME_NAME"

# get loop device to init volume with
LOOP_DEV=$(get_next_loop_device)

# check if volume path exists and is a directory
if [ ! -d "$MOUNT_POINT" ]; then
  mkdir -p $MOUNT_POINT
fi

# change to directory to init volume from
cd $VOLUME_PATH

# call s4 create to create loop device
s4 create "$S4_LOOP_DEV_PATH/$VOLUME_NAME" --size "$SIZE" --loop-device "$LOOP_DEV"

if [ "$?" -ne 0 ]; then
  echo "Failed to create volume: $VOLUME_NAME"
  exit 1
fi

# create docker volume if --docker flag is set
if [ "$DOCKER" = true ]; then
    s4 docker create $LOOP_DEV "$VOLUME_NAME" "$DOCKER_LABEL"
fi

if [ -z "$YES" ]; then
  s4 import "$LOOP_DEV" "$VOLUME_PATH" "$MOUNT_POINT"
else
  s4 import "$LOOP_DEV" "$VOLUME_PATH" "$MOUNT_POINT" --no-preserve
fi

cd $MOUNT_POINT
s4 config set volume name $VOLUME_NAME
s4 config set ~/.s4/volumes/$VOLUME_NAME state generation -1
