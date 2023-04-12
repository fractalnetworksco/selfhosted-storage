#!/bin/bash
# set -e # maybe. We may want to clean up so maybe we should handle errors manually

# usage: s4 import <loop_dev> [--no-preserve] [--yes]

set -e


SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source $SCRIPT_DIR/base.sh

# Parse optional arguments using getopts with long options
OPTS=`getopt -o n --long no-preserve -- "$@"`
eval set -- "$OPTS"
while true; do
  case "$1" in
    -n|--no-preserve)
      NO_PRESERVE=true
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

LOOP_DEV=${LOOP_DEV:-$1}
VOLUME_PATH="${2:-$(pwd)}"
MOUNT_POINT="${3:-$VOLUME_PATH}"
TMP_FOLDER_NAME=$(basename $VOLUME_PATH)

# copy data to s4-tmp directory
S4_TMP_PATH="/tmp/s4-tmp-$TMP_FOLDER_NAME"

# makes sure hidden files are moved as well
cp -a $VOLUME_PATH $S4_TMP_PATH

# sha1 the copied data. Make sure matches with original
verify_copy $VOLUME_PATH $S4_TMP_PATH

# exit if return code not 0
if [ $? -ne 0 ]; then
    echo "Error: fingerprint of moved data does not match sha1 of original data, data could be in use"
    rm -r $S4_TMP_PATH
    exit 1
fi

# create mount point directory
mkdir -p $MOUNT_POINT

# mount directory
mount_sudo $LOOP_DEV $MOUNT_POINT

# if not root, ensure current user owns the mounted directory
if [ "$EUID" -ne 0 ]; then
  chown_sudo -R $EUID:$EUID $MOUNT_POINT
fi

# copy copied data into mounted directory
cp -a $S4_TMP_PATH/. $MOUNT_POINT

# create .s4 directory at mounted directory
mkdir -p $MOUNT_POINT/.s4/snapshots

# everything matches so clean up backup
# remove everything in backup directory
rm -rf $S4_TMP_PATH
echo "S4 volume successfully created at $MOUNT_POINT"

# ask the user if they want to remove the original data if they didn't specify --no-preserve
if [ -z "$NO_PRESERVE" ]; then
  read -p "WARNING: Do you want to remove the original data? [Y/N] " -n 1 -r
  echo
  if [[ $REPLY =~ ^[Nn]$ ]]; then
      exit 0
  fi
fi

# if mounted at PWD, then we need to re-enter the directory
if [ "$MOUNT_POINT" = "$VOLUME_PATH" ]; then
  # unmount and remove everything in the directory
  umount_sudo $VOLUME_PATH
  find $VOLUME_PATH -maxdepth 1 -mindepth 1 -exec rm -rf {} \;

  # remount at directory
  mount_sudo $LOOP_DEV $VOLUME_PATH
  echo "Done. You will need to re-enter this directory \`cd $VOLUME_PATH\` to continue."
else
  # remove everything from VOLUME_PATH
  find $VOLUME_PATH -maxdepth 1 -mindepth 1 -exec rm -rf {} \;
  echo "Done. S4 volume has been mounted at $MOUNT_POINT. Your data has been moved to $MOUNT_POINT. You can safely remove this directory."
fi
