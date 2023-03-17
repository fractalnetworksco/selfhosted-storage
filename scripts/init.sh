#!/bin/bash
 set -e

# script dir
SCRIPT_DIR=$(dirname $(readlink -f $0))

# change to directory to init
VOL_PATH=$1
cd $VOL_PATH

source $SCRIPT_DIR/base.sh

# set VOL to $2 if it set, otherwise set to basename of dir referenced by $1
[ -n "$2" ] && VOL=$2 || VOL=$(basename $(pwd))

# read --remote argument from command line
while [[ $# -gt 0 ]]; do
    key="$1"
    case $key in
        --remote)
            REMOTE="$2"
            shift # past argument
            shift # past value
            ;;
        --catalog)
            CATALOG="$2"
            shift # past argument
            shift # past value
            ;;
        --mosaic)
            MOSAIC="$2"
            shift # past argument
            shift # past value
            ;;
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
        *)    # unknown option
            shift # past argument
            ;;
    esac
done

if [ -n "$REMOTE" ]; then
    # ensure BTRFS variable is set to true
    if [ "$BTRFS" != true ]; then
        echo "Failed to init S4 volume: Directory must be BTRFS."
        exit 1
    fi

    # exit if either a private key or public key is provided but not both
    if [[ -n "$PRIV_KEY" && -z "$PUB_KEY" ]]; then
        echo "Error: A private key was provided but not a public key. Please provide both or neither."
        exit 1
    elif [[ -z "$PRIV_KEY" && -n "$PUB_KEY" ]]; then
        echo "Error: A public key was provided but not a private key. Please provide both or neither."
        exit 1
    fi

    echo "Initializing volume: $VOL"

    # create s4 volume that generates ssh keys if keys were not provided
    if [[ -z "$PRIV_KEY" && -z "$PUB_KEY" ]]; then
        init_volume "$REMOTE/$VOL"

    # init volume with provided keys
    else
        init_volume "$REMOTE/$VOL" "$PRIV_KEY" "$PUB_KEY"
    fi

    # dont attempt to register volume if mosaic flag is set
    if [ -z "$MOSAIC" ]; then
        # strip everything afte : from the remote
        SSH_REMOTE=$(echo $REMOTE | cut -d':' -f1)
        PUB_KEY=$(<$(pwd)/.s4/id_ed25519-$VOL.pub)

        # s4admin uses sudo to run su_add_ssh_key which calls add_ssh_key as the borg user
        # replace ssh user borg with s4admin user
        ADMIN_REMOTE=$(echo $SSH_REMOTE | sed "s/borg/s4admin/")

        # add volume ssh key to borg user's authorized_keys, only s4admin can do this
        ssh -p $S4_REMOTE_PORT $ADMIN_REMOTE sudo su_add_ssh_key $VOL \"$PUB_KEY\"
    fi

    cd -

    # create borg repo on remote
    borg init --encryption=none $REMOTE/$VOL

else
    echo "Error: You must specify a remote for $VOL with --remote borg@remote:/volumes"
    exit 1
fi
# exit if not successful
if [ $? -ne 0 ]; then
    echo "Failed to initialize borg repo"
    exit 1
fi

echo "Done."
