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
OPTS=`getopt -o s:d:l:v:n:y: --long size:,name:,label:,volume-label:,docker,yes -- "$@"`
eval set -- "$OPTS"
while true; do
  case "$1" in
    -d|--docker)
      DOCKER=true
      shift
      ;;
    -y|--yes)
      YES=true
      shift
      ;;
    -s|--size)
      SIZE="$2"
      shift 2
      ;;
    -v|--volume-label)
      VOLUME_LABEL="$2"
      echo "volume label: $VOLUME_LABEL"
      shift 2
      ;;
    -l|--label)
      LABEL="$2"
      echo "label: $LABEL"
      shift 2
      ;;
    -n|--name)
      VOLUME_NAME="$2"
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

# exit if a label was specified but docker not specified
if [[ "$DOCKER" = false && -n "$VOLUME_LABEL" ]]; then
  echo "Error: --docker must be set if --label specified"
  exit 1
fi

# if label is set, make sure it is in the form <key>=<value>
if [ ! -z $LABEL ]; then
  LABEL_KEY=$(echo $LABEL | awk -F "=" '{print $1}')
  LABEL_VALUE=$(echo $LABEL | awk -F "=" '{print $2}')

  if [ -z $LABEL_KEY ] || [ -z $LABEL_VALUE ]; then
    echo "Error: --label must be in the form <key>=<value>"
    exit 1
  fi
fi

# if volume path is not set, default to current directory
VOLUME_PATH="${1:-$(pwd)}"

# exit if $VOLUME_PATH is already an s4 volume
check_is_not_s4 $VOLUME_PATH

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
++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    The following command will perform the following operations:

         1) Copy the existing contents of $VOLUME_PATH to a temporary directory.
         2) Create a btrfs formatted loop device that is double the size of the contents of $VOLUME_PATH
         3) Verify that the copy is exactly the same as the original contents of $VOLUME_PATH
         4) Move the temporary copy to the btrfs loop device volume.
         5) Optionally, remove existing contents of $VOLUME_PATH
         6) Mount the loop device at the original path of the data $VOLUME_PATH.

    You will be prompted to remove the original data after the copy operation is complete.
    If you are not sure what you are doing, please exit now.
++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
EOF
read -p "Contents of $VOLUME_PATH will be copied into a new s4 volume and mounted at $MOUNT_POINT, are you sure? [y/N] " -n 1 -r
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

mkdir -p $MOUNT_POINT

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
    s4 docker create $LOOP_DEV "$VOLUME_NAME" "$VOLUME_LABEL"
fi

if [ -z "$YES" ]; then
  s4 import "$LOOP_DEV" "$VOLUME_PATH" "$MOUNT_POINT"
else
  s4 import "$LOOP_DEV" "$VOLUME_PATH" "$MOUNT_POINT" --no-preserve
fi

cd $MOUNT_POINT
s4 config set volume name $VOLUME_NAME
s4 config set volume id $(generate_uuid)
s4 config set ~/.s4/volumes/$VOLUME_NAME state generation -1

# TODO: Add support for multiple labels
if [ ! -z $LABEL ]; then
  s4 config set labels $LABEL_KEY $LABEL_VALUE
fi
