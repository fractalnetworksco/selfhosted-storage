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

VOLUME_PATH=$(pwd)
TMP_FOLDER_NAME=$(basename $VOLUME_PATH)
LOOP_DEV=${LOOP_DEV:-$1}

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

# create s4 directory inside original directory
mkdir -p $VOLUME_PATH

# mount at created s4 directory
mount_sudo $LOOP_DEV $VOLUME_PATH

# ensure current user owns the mounted directory

# if not root, chown to current user
if [ "$EUID" -ne 0 ]; then
  chown_sudo -R $USER:$USER $VOLUME_PATH
fi

# copy copied data into mounted directory
cp -a $S4_TMP_PATH/. $VOLUME_PATH


# create .s4 directory
mkdir -p $VOLUME_PATH/.s4/snapshots

# everything matches so clean up backup
# remove everything in backup directory
rm -rf $S4_TMP_PATH
echo "s4 volume successfully created at $VOLUME_PATH"

# ask the user if they want to remove the original data if they didn't specify --no-preserve
if [ -z "$NO_PRESERVE" ]; then
  read -p "WARNING: Do you want to remove the original data? [y/N] " -n 1 -r
  echo
  if [[ $REPLY =~ ^[Nn]$ ]]; then
      exit 0
  fi
fi

umount_sudo $VOLUME_PATH
find $VOLUME_PATH -maxdepth 1 -mindepth 1 -exec rm -rf {} \;
mount_sudo $LOOP_DEV $VOLUME_PATH

echo "Done. You will need to re-enter this directory \`cd $VOLUME_PATH\` to continue."
