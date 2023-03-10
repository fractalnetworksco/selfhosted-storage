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
source $SCRIPT_DIR/config.sh
source $SCRIPT_DIR/s4_volume.sh
source $SCRIPT_DIR/btrfs.sh

cd $1

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
        *)    # unknown option
            shift # past argument
            ;;
    esac
done

if [ -n "$REMOTE" ]; then
    # get the next available loop device
    # we need to make sure loop device name is consistent across reboots so we
    # store the loop device name in the backing file
    # this is because we cannot update a docker volume once
    # it is created and would have to recreat the volume otherwise
    LOOP_DEV=$(get_next_loop_device)

    LOOP_DEV_FILE=$VOL_DIR/$VOL-$(basename $LOOP_DEV)
    # allocate file twice the size of the current directory being initialized
    create_double_size_file $(pwd) $LOOP_DEV_FILE

    # create loop device
    create_loop_device $LOOP_DEV $LOOP_DEV_FILE

    # format loop device btrfs
    mkfs_btrfs $LOOP_DEV

    # create btrfs backed docker volume
    # IF $NODOCKER is set, don't create docker volume
    if [ -z "$NODOCKER" ]; then
        docker volume create --label s4.volume --driver local --opt type=btrfs\
        --opt device=$LOOP_DEV $VOL
    fi
    # create borg repo
    borg --rsh "ssh -o StrictHostKeyChecking=accept-new -p $REMOTE_PORT" init --encryption=none $REMOTE/$VOL
    TMP_MOUNT=/mnt/tmp
    mkdir_sudo -p $TMP_MOUNT
    mount_sudo $LOOP_DEV $TMP_MOUNT
    #chown /tmp with current user and group id
    # store current user and group id in variables
    USER_ID=$(id -u)
    GROUP_ID=$(id -g)
    chown_sudo $USER_ID:$GROUP_ID $TMP_MOUNT
    cd $TMP_MOUNT

    create_s4_volume $REMOTE/$VOL
    cd -

    # strip everything afte : from the remote
    SSH_REMOTE=$(echo $REMOTE | cut -d':' -f1)
    PUB_KEY=$(<$TMP_MOUNT/.s4/id_ed25519-$VOL.pub)
    # s4admin uses sudo to run su_add_ssh_key which calls add_ssh_key as the borg user
    # replace ssh user borg with s4admin user
    ADMIN_REMOTE=$(echo $SSH_REMOTE | sed "s/borg/s4admin/")

    # add volume ssh key to borg user's authorized_keys, only s4admin can do this
    ssh -p $REMOTE_PORT $ADMIN_REMOTE sudo su_add_ssh_key $VOL \"$PUB_KEY\"
else
    echo "Error: You must specify a remote for $VOL with --remote borg@remote:/volumes"
    exit 1
fi
# exit if not successful
if [ $? -ne 0 ]; then
    echo "Failed to initialize borg repo"
    exit 1
fi

# copy data to new volume
echo "Copying data to new volume..."
cp -r . $TMP_MOUNT/data
umount_sudo $TMP_MOUNT
echo "Done."