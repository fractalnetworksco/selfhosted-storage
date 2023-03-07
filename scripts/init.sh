#!/bin/bash

#script dir
SCRIPT_DIR=$(dirname $(readlink -f $0))

#volume dir
VOL_DIR=/var/lib/fractal

source $SCRIPT_DIR/double.sh
source $SCRIPT_DIR/loop_dev.sh

cd $1

# set VOL to $2 if it set, otherwise set to basename of dir referenced by $1
[ -n "$2" ] && VOL=$2 || VOL=$(basename $(pwd))

echo "Creating volume: $VOL"

# read --remote argument from command line
while [[ $# -gt 0 ]]; do
    key="$1"
    case $key in
        --remote)
            REMOTE="$2"
            shift # past argument
            shift # past value
            ;;
        *)    # unknown option
            shift # past argument
            ;;
    esac
done
# if --remote is set init borg repo
if [ -n "$REMOTE" ]; then
    # create borg repo
    borg init --encryption=none $REMOTE/$VOL
fi
# exit if not successful
if [ $? -ne 0 ]; then
    echo "Failed to initialize borg repo"
    exit 1
fi

# allocate file twice the size of the current directory being initialized
create_double_size_file $(pwd) $VOL_DIR/$VOL

# create loop device
create_loop_device $VOL_DIR/$VOL

# format loop device btrfs
mkfs.btrfs $(get_loop_device_for_file $VOL_DIR/$VOL)

# create btrfs backed docker volume
docker volume create --label s4.volume --driver local --opt type=btrfs\
 --opt device=$(get_loop_device_for_file $VOL) $VOL




