#!/bin/bash

SCRIPT_DIR=$(dirname $(readlink -f $0))
source $SCRIPT_DIR/base.sh

# define default values for optional arguments
DOCKER=false

# parse optional arguments using getopts with long options
OPTS=`getopt -o n:d --long name:,docker -- "$@"`
eval set -- "$OPTS"
while true; do
  case "$1" in
    -n|--name)
      VOLUME_NAME="$2"
      shift 2
      ;;
    -d|--docker)
      DOCKER=true
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

REMOTE="$1"

if [ -z "$REMOTE" ]; then
    echo "Usage: s4 clone <remote> [--name <volume_name>] [--docker]"
    exit 1
elif [ -z "$VOLUME_NAME" ]; then
    VOLUME_NAME=$(basename $(pwd))
fi

CLONE_PATH="$(pwd)/$VOLUME_NAME"

# create a directory in the current directory with the volume name
mkdir -p $CLONE_PATH

# try to get the lastest archive from provided remote
LATEST=$(get_latest_archive $REMOTE)
if [ -z "$LATEST" ]; then
    echo "No snapshots for $REMOTE archive found"
    exit 1
fi

# get volume's `size` from config file on the remote
VOLUME_SIZE=$(borg --bypass-lock extract --stdout $REMOTE::$LATEST .s4/config | grep "^size=" | cut -d "=" -f 2)

# create loop device that is double the size of VOLUME_SIZE
LOOP_DEV=$(get_next_loop_device)
s4 create "$S4_LOOP_DEV_PATH/$VOLUME_NAME" --size "$VOLUME_SIZE" --loop-device "$LOOP_DEV"
if [ "$?" -ne 0 ]; then
  echo "Failed to create volume: $VOLUME_NAME"
  exit 1
fi

# create docker volume if --docker flag is set
if [ "$DOCKER" = true ]; then
  s4 docker create "$LOOP_DEV" "$VOLUME_NAME"
fi

# mount loop device at clone path
echo "Mounting $LOOP_DEV at $CLONE_PATH"
mount_sudo "$LOOP_DEV" "$CLONE_PATH"
if [ "$?" -ne 0 ]; then
  echo "Failed to mount volume: $VOLUME_NAME"
  exit 1
fi

# ensure user owns the files
chown_sudo -R "$USER":"$USER" "$CLONE_PATH"

# ensure .s4 directory exists inside volume
mkdir -p "$CLONE_PATH/.s4"

# move created .s4 directory into volume
mv "$(pwd)/.s4" "$CLONE_PATH/.s4"

# enter after mount
cd "$CLONE_PATH"

# extract s4 config file from remote in order for `s4 pull` to work
borg --bypass-lock extract "$REMOTE::$LATEST" .s4/config
if [ "$?" -ne 0 ]; then
  echo "Failed to extract s4 config from remote $REMOTE::$LATEST"
  exit 1
fi

# unset latest snapshot so that `s4 pull` will pull in latest snapshot
s4 config set volume last_snapshot ""

# pull in latest snapshot from remote
s4 pull
if [ "$?" -ne 0 ]; then
  echo "Failed to pull latest changes for volume: $VOLUME_NAME"
  exit 1
fi
