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

VOLUME_PATH=$(pwd)
VOLUME_NAME=$(basename $VOLUME_PATH)
LOOP_DEV=${LOOP_DEV:-$1}

# copy data to s4-tmp directory
S4_TMP_PATH="/tmp/s4-tmp-$VOLUME_NAME"
mkdir -p "$S4_TMP_PATH"

# makes sure hidden files are moved as well
cp -a $VOLUME_PATH/* $S4_TMP_PATH

# sha256 the moved data. Make sure matches with original
# sha256 original data at directory
verify_copy $VOLUME_PATH $S4_TMP_PATH

# exit if return code not 0
if [ $? -ne 0 ]; then
    echo "Error: sha256 of moved data does not match sha256 of original data"
    rm -r $S4_TMP_PATH
    exit 1
fi

# create s4 directory inside original directory
mkdir -p $VOLUME_PATH/s4

# mount at created s4 directory
mount_sudo $LOOP_DEV $VOLUME_PATH/s4

# ensure current user owns the mounted directory
chown_sudo -R $USER:$USER $VOLUME_PATH

# copy copied data into mounted directory
cp -a $S4_TMP_PATH/* $VOLUME_PATH/s4

# create .s4 directory
mkdir -p $VOLUME_PATH/s4/.s4/snapshots

# everything matches so clean up backup
# remove everything in backup directory
rm -rf $S4_TMP_PATH
echo "s4 volume successfully created at $VOLUME_PATH/s4"

# ask the user if they want to remove the original data if they didn't specify --no-preserve
if [ -z "$NO_PRESERVE" ]; then
  read -p "WARNING: Do you want to remove the original data? [y/N] " -n 1 -r
  echo
  if [[ $REPLY =~ ^[Yy]$ ]]; then
      # remove everything except the s4 directory
      find $VOLUME_PATH -maxdepth 1 -mindepth 1 -not -name "s4" -exec rm -r {} \;
  fi
fi
