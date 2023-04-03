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
CLONE_PATH="$2"

if [ -z "$REMOTE" ]; then
    echo "Usage: s4 clone <remote> [--name <volume_name>] [--docker] [<clone_path>]"
    exit 1
elif [ -z "$CLONE_PATH" ]; then
    CLONE_PATH=$(pwd)
elif [ -z "$VOLUME_NAME" ]; then
    VOLUME_NAME=$(basename $(pwd))
fi

# change into directory to clone into
cd $CLONE_PATH

# get the lastest archive from provided remote
LATEST=$(get_latest_archive $REMOTE)
if [ -z "$LATEST" ]; then
    echo "No snapshots for $REMOTE archive found"
    exit 1
fi

# ensure .s4 directory exists
mkdir -p $CLONE_PATH/.s4

# extract s4 config file from remote in order to get volume size
borg extract $REMOTE::$LATEST .s4/config

# get volume size from config
VOLUME_SIZE=$(s4 config get volume size)

# create loop device that is double the size of VOLUME_SIZE
LOOP_DEV=$(get_next_loop_device)
s4 create "$S4_LOOP_DEV_PATH/$VOLUME_NAME" --size "$VOLUME_SIZE" --loop-device "$LOOP_DEV"

if [ "$?" -ne 0 ]; then
  echo "Failed to create volume: $VOLUME_NAME"
  exit 1
fi

# create docker volume if --docker flag is set
if [ "$DOCKER" = true ]; then
  s4 docker create $LOOP_DEV "$VOLUME_NAME"
fi

# mount loop device at clone path
echo "Mounting $LOOP_DEV at $CLONE_PATH"
mount_sudo $LOOP_DEV $CLONE_PATH

# ensure user owns the files
chown_sudo -R $USER:$USER $CLONE_PATH

# reenter after mount
cd $CLONE_PATH

mkdir -p $CLONE_PATH/.s4

# extract s4 config file from remote in order to get volume size
borg extract $REMOTE::$LATEST .s4/config

# unset latest snapshot (for now)
s4 config set volume last_snapshot ""

# pull in latest changes from remote
s4 pull

if [ "$?" -ne 0 ]; then
  echo "Failed to pull latest changes for volume: $VOLUME_NAME"
  exit 1
fi

echo "Successfully pulled latest changes for volume: $VOLUME_NAME. You will need to re-enter this directory \`cd $CLONE_PATH\` to continue."

