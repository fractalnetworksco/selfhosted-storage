#!/bin/bash
 set -e
#script dir
SCRIPT_DIR=$(dirname $(readlink -f $0))
# DEFAULT PORT to 2222 if not specified
REMOTE_PORT=${PORT:-2222}

#volume dir
VOL_DIR=/var/lib/fractal

source $SCRIPT_DIR/double.sh
source $SCRIPT_DIR/loop_dev.sh

cd $1

# set VOL to $2 if it set, otherwise set to basename of dir referenced by $1
[ -n "$2" ] && VOL=$2 || VOL=$(basename $(pwd))

echo "Creating s4 volume: $VOL"

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
    # generate an ssh keypair with no interaction
    ssh-keygen -t ed25519 -N '' -f ~/.ssh/id_ed25519-$VOL
    borg --rsh "ssh -p $REMOTE_PORT" init --encryption=none $REMOTE/$VOL
    # strip everything afte : from the remote
    REMOTE=$(echo $REMOTE | cut -d':' -f1)
    PUB_KEY=$(<~/.ssh/id_ed25519-$VOL.pub)
    echo $PUB_KEY
    # s4admin uses sudo to run su_add_ssh_key which calls add_ssh_key as the borg user
    # replace ssh user borg with s4admin user
    ADMIN_REMOTE=$(echo $REMOTE | sed "s/borg/s4admin/")

    # add volume ssh key to borg user's authorized_keys, only s4admin can do this
    ssh -p $REMOTE_PORT $ADMIN_REMOTE sudo su_add_ssh_key $VOL \"$PUB_KEY\"
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
# IF $NODOCKER is set, don't create docker volume
if [ -z "$NODOCKER" ]; then
    docker volume create --label s4.volume --driver local --opt type=btrfs\
     --opt device=$(get_loop_device_for_file $VOL_DIR/$VOL) $VOL
fi


