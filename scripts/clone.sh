#!/bin/bash

# usage: clone <remote> [Options] <path (Defaults to .)>

# Options:
#   [--private-key <OpenSSH formatted Private Key>]
#   [--public-key <OpenSSH formatted Public Key>]
#   [--volume-name <Name of volume>]

REMOTE="$1"

# read optional arguments from command line
while [[ $# -gt 0 ]]; do
    key="$1"
    case $key in
        --private-key)
            PRIV_KEY="$2"
            shift # past argument
            shift # past value
            ;;
        --public-key)
            PUB_KEY="$2"
            shift # past argument
            shift # past value
            ;;
        --volume-name)
            VOLUME_NAME="$2"
            shift # past argument
            shift # past value
            ;;
        --clone-path)
            CLONE_PATH="$2"
            shift # past argument
            shift # past value
            ;;
        *)    # unknown option
            shift # past argument
            ;;
    esac
done


# if clone path is set, use it or else use the current directory
if [ -n "$CLONE_PATH" ]; then
    cd $CLONE_PATH
fi

SCRIPT_DIR=$(dirname $(readlink -f $0))

source $SCRIPT_DIR/base.sh
source $SCRIPT_DIR/borg.sh
source $SCRIPT_DIR/btrfs.sh
source $SCRIPT_DIR/config.sh

if [ -n "$REMOTE" ]; then
    # volume is the part after the last slash
    # use VOLUME_NAME as REMOTE_VOLUME if set
    if [ ! -z "$VOLUME_NAME" ]; then
        REMOTE_VOLUME=$VOLUME_NAME
    else
        REMOTE_VOLUME=${REMOTE##*/}
    fi

    # exit if both a private key and public key are not set
    if [[ -z "$PRIV_KEY" && -z "$PUB_KEY" ]]; then
        echo "Clone Error: A private key was provided but not a public key. Please provide both."
        exit 1
    elif [[ -z "$PRIV_KEY" && -n "$PUB_KEY" ]]; then
        echo "Clone Error: A public key was provided but not a private key. Please provide both."
        exit 1
    elif [[ -n "$PRIV_KEY" && -z "$PUB_KEY" ]]; then
        echo "Clone Error: Neither a private key nor public key provided. Both are required in order to clone from a remote."
        exit 1
    fi

    # create .s4 directory which will also write provided keys into .s4
    init_volume "$REMOTE" "$PRIV_KEY" "$PUB_KEY"

else
    # if no .s4 dir exists, exit
    if [ ! -d ".s4" ]; then
        echo "No .s4 dir found"
        exit 1
    fi
    LOCAL_VOLUME=$(get_config .s4/config volume)
    REMOTE=$(get_config .s4/config remote)
    init_volume $REMOTE # sets the BORG_RSH variable, etc
fi

# get the lastest archive from a borg repo and fetch it to the local machine
latest=$(get_latest_archive $REMOTE)
# if not latest exit
if [ -z "$latest" ]; then
    echo "No snapshots for $REMOTE_VOLUME archive found"
    exit 404
fi

# if REMOTE_VOLUME is set
if [[ -n "$REMOTE_VOLUME" ]]; then
    # if current volume is btrfs create subvolume else exit
    # if $BTRFS is true create subvolume
    if [[ "$BTRFS" = true ]]; then
        echo "BTRFS set, creating subvolume"
        create_subvolume $REMOTE_VOLUME
        set_owner_current_user $REMOTE_VOLUME

        cd $REMOTE_VOLUME

        borg extract --progress $REMOTE::$latest

    else
        # read volume size from remote
        echo "Getting volume size from remote"
        borg extract $REMOTE::$latest .s4/volume_size
        VOLUME_SIZE=$(cat .s4/volume_size)
        echo "Volume size is $VOLUME_SIZE"

        # create loop device, format as btrfs, then attach to docker volume
        create_btrfs_loop_device_and_volume "$REMOTE_VOLUME" "$VOLUME_SIZE" "$REMOTE::$latest"

        # # if NO_BTRFS is defined continue
        # if [ -z "$NO_BTRFS" ]; then
        #     echo "Current volume is not btrfs, set NO_BTRFS if you are ok with cloning to a non-btrfs volume"
        #     exit 1
        # fi
        # mkdir $REMOTE_VOLUME
    fi
fi

# we're cloning a placeholder dir from a catalog
if [[ -n "$LOCAL_VOLUME" ]]; then
    if [ "$(ls -A ./data)" ]; then
        echo "$(pwd)/data is not empty"
        exit 1
    fi
    cd /s4/data
    borg extract --progress $REMOTE::$latest
fi
