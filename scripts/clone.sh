#!/bin/bash

SCRIPT_DIR=$(dirname $(readlink -f $0))
source $SCRIPT_DIR/base.sh

# define default values for optional arguments
DOCKER=false
ORIGIN_NAME="origin"

# parse optional arguments using getopts with long options
OPTS=$(getopt -o n:v:d:s:o: --long name:,volume-label:,size:,docker,origin: -- "$@")
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
    -v|--volume-label)
      VOLUME_LABEL="$2"
      shift 2
      ;;
    -s|--size)
      SIZE="$2"
      shift 2
      ;;
    -o|--origin)
      ORIGIN_NAME="$2"
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

export REMOTE="$1"
CLONE_PATH="$2"

# exit if a remote was not given
if [ -z "$REMOTE" ]; then
    echo "Usage: s4 clone <remote> [--name <volume_name>] [--docker]"
    exit 1
# exit if a label was specified but docker not specified
elif [[ "$DOCKER" = false && -n "$VOLUME_LABEL" ]]; then
  echo "Error: --docker must be set if --label specified"
  exit 1
fi

# if clone path is set, use it was the volume name
# if volume name is not set, default to basename of remote (last part of remote path)
if [ ! -z "$CLONE_PATH" ]; then
    VOLUME_NAME=$(basename $(realpath $CLONE_PATH))
    CLONE_PATH=$(realpath $CLONE_PATH)
else
    VOLUME_NAME=$(basename $REMOTE)
    # default clone path to PWD/volume_name if no path is given
    CLONE_PATH="$(pwd)/$VOLUME_NAME"
fi

# ensure clone path directory exists
mkdir -p "$CLONE_PATH"

# try to get the lastest archive from provided remote
LATEST=$(get_latest_archive $REMOTE) || exit 1
if [ -z "$LATEST" ]; then
    echo "No snapshots for $REMOTE archive found"
    exit 1
fi

# if size is not provided, get size from the remote
if [ -z "$SIZE" ]; then
  VOLUME_SIZE=$(borg --bypass-lock extract --stdout $REMOTE::$LATEST .s4/config | grep "^size=" | cut -d "=" -f 2)
  if [ -z "$VOLUME_SIZE" ]; then
    echo "Failed to get size from remote $REMOTE::$LATEST"
    exit 1
  fi
else
  VOLUME_SIZE="$SIZE"
fi

# create loop device that is double the size of VOLUME_SIZE
LOOP_DEV=$(get_next_loop_device)
s4 create "$S4_LOOP_DEV_PATH/$VOLUME_NAME" --size "$VOLUME_SIZE" --loop-device "$LOOP_DEV"
if [ "$?" -ne 0 ]; then
  echo "Failed to create volume: $VOLUME_NAME"
  exit 1
fi

# create docker volume if --docker flag is set
if [ "$DOCKER" = true ]; then
  s4 docker create "$LOOP_DEV" "$VOLUME_NAME" "$VOLUME_LABEL"
fi

# mount loop device at clone path
echo "Mounting $LOOP_DEV at $CLONE_PATH"
mount_sudo "$LOOP_DEV" "$CLONE_PATH"
if [ "$?" -ne 0 ]; then
  echo "Failed to mount volume: $VOLUME_NAME"
  exit 1
fi

# if not root, ensure user owns the files
if [ "$EUID" -ne 0 ]; then
  chown_sudo -R $EUID:$EUID "$CLONE_PATH"
fi

# enter after mount
cd "$CLONE_PATH"

# ensure .s4 directory exists inside volume
mkdir -p "$CLONE_PATH/.s4"

# write loop file
s4 config set volume loop_file "$(get_file_for_loop_device $LOOP_DEV)"

# extract s4 config file from remote in order for `s4 pull` to work
borg --bypass-lock extract "$REMOTE::$LATEST" .s4/config
if [ "$?" -ne 0 ]; then
  echo "Failed to extract s4 config from remote $REMOTE::$LATEST"
  exit 1
fi


# pull in latest snapshot from remote
echo "Pulling latest snapshot from $REMOTE"

# set volume's remote to the provided remote
s4 config set remotes "$ORIGIN_NAME" "$REMOTE"
s4 config set default remote "$ORIGIN_NAME"

if ! pull "$ORIGIN_NAME" "$LATEST"; then
  echo "Failed to pull latest changes for volume: $VOLUME_NAME"
  exit 1
fi

# write current time into synced file
if [ -z "$TZ" ]; then
    export TZ='America/Chicago'
fi

# write .s4/synced file to indicate that volume is synced
date > "$CLONE_PATH/.s4/synced"
# unset latest snapshot so that `s4 pull` will pull in latest snapshot
s4 config set volume last_snapshot ""

# reset the volume's remote to the provided remote again since it was overwwritten by `pull`
s4 config set remotes "$ORIGIN_NAME" "$REMOTE"
s4 config set default remote "$ORIGIN_NAME"

# return to the original directory in order to know if the user cloned to the current directory
cd - &> /dev/null

if [ $CLONE_PATH = "$(pwd)" ]; then
  echo "Done. You will need to re-enter this directory \`cd $VOLUME_PATH\` to continue."
fi
