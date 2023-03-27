#!/bin/bash
# set -e # maybe. We may want to clean up so maybe we should handle errors manually

# usage: s4 import <loop_dev>

set -ex

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

# md5 original data at directory
ORIGINAL_DATA_MD5="$(s4 md5_dir $VOLUME_PATH)"

# copy data to s4-tmp directory
S4_TMP_PATH="/tmp/s4-tmp-$VOLUME_NAME"
mkdir -p "$S4_TMP_PATH"

# makes sure hidden files are moved as well
cp -a $VOLUME_PATH $S4_TMP_PATH

# md5 the moved data. Make sure matches with original
# md5 original data at directory
MOVED_DATA_MD5="$(s4 md5_dir $S4_TMP_PATH)"

# md5 the moved data. Make sure matches with original
if [ "$ORIGINAL_DATA_MD5" != "$MOVED_DATA_MD5" ]; then
    echo "Error: md5 of original data does not match md5 of moved data"
    # cleanup s4-tmp
    rm -r $S4_TMP_PATH
    exit 1
fi

# mount at original directory
mount_sudo $LOOP_DEV $VOLUME_PATH

chown_sudo -R $USER:$USER $VOLUME_PATH

# copy copied data into mounted directory
cp -a $S4_TMP_PATH/* $VOLUME_PATH

# md5 that data. Make sure matches with original
FINAL_MOVE_MD5="$(s4 md5_dir $VOLUME_PATH)"

# if everything not okay then restore original data by moving copy
if [ "$FINAL_MOVE_MD5" != "$MOVED_DATA_MD5" ]; then
    echo "Error: md5 of moved data does not match md5 of backup data"
    umount_sudo $LOOP_DEV
    exit 1
fi

# create .s4 directory
mkdir -p $VOLUME_PATH/.s4/snapshots

# everything matches. Good to clean up backup
# remove everything in backup directory
rm -r $S4_TMP_PATH

# remove everything in original directory if no-preserve flag is set
if [ -n "$NO_PRESERVE" ]; then
    umount_sudo $VOLUME_PATH
    rm -r $VOLUME_PATH
    mount_sudo $LOOP_DEV $VOLUME_PATH
fi
