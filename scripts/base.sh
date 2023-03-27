#!/bin/bash
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source $SCRIPT_DIR/config.sh
source $SCRIPT_DIR/btrfs.sh
source $SCRIPT_DIR/double.sh
source $SCRIPT_DIR/loop_dev.sh
source $SCRIPT_DIR/s4_volume.sh

S4_REMOTE_PORT=${S4_REMOTE_PORT:-2222}

function init_globals(){
    export BORG_RSH="ssh -p $S4_REMOTE_PORT -o BatchMode=yes -o StrictHostKeyChecking=accept-new"
}

function init_volume(){
    # Args:
    #   $1: Remote path
    export VOLUME_PATH=$(pwd)
    export VOLUME_NAME=$(basename $VOLUME_PATH)

    REMOTE_PATH="$1"

    # check if the volume is already initialized
    if [ -d $VOLUME_PATH/.s4 ]; then
        echo "Volume $VOLUME_NAME already initialized"
        export REMOTE=$(get_config $VOLUME_PATH/.s4/config remote)
        export VOLUME=$(get_config $VOLUME_PATH/.s4/config volume)

    # initialize new volume
    else
        echo "Initializing volume $VOLUME_NAME at $VOLUME_PATH"

        # check if read private/public keys are set in environment, if so use them when creating volume
        if [[ -n "$READ_PRIVATE_KEY" && -n "$READ_PUBLIC_KEY" ]]; then
            # create s4 volume using provided read private & public keys (writes them into volume)
            echo "init_volume: Running create_s4_volume $REMOTE_PATH $READ_PRIVATE_KEY $READ_PUBLIC_KEY"
            create_s4_volume "$REMOTE_PATH" "$READ_PRIVATE_KEY" "$READ_PUBLIC_KEY"

        else
            echo "init_volume: Running create_s4_volume $1"
            # create s4 volume that will generate private & public keys
            create_s4_volume "$1"
        fi
    fi

    # if write keys given in environment, ensure they are written to /keys
    # TODO: Maybe should just register keys with ssh agent?
    if [[ -n "$WRITE_PRIVATE_KEY" && -n "$WRITE_PUBLIC_KEY" ]]; then
        echo "init_volume: Write keys in environment. Writing keys to /keys"
        export WRITE_KEY_PATH=/keys # directory where write keys will be written
        export WRITE_PRIVATE_KEY_PATH="$WRITE_KEY_PATH/write_id_ed25519-$VOLUME"
        export WRITE_PUBLIC_KEY_PATH="$WRITE_KEY_PATH/write_id_ed25519-$VOLUME.pub"
        write_key "$WRITE_PRIVATE_KEY" "$WRITE_PRIVATE_KEY_PATH"
        write_key "$WRITE_PUBLIC_KEY" "$WRITE_PUBLIC_KEY_PATH"

    # if keys were not set in environment, assume private key is written in .s4 volume
    else
        export WRITE_PRIVATE_KEY_PATH="$VOLUME_PATH/.s4/write_id_ed25519-$VOLUME"
    fi

    # set s4 and borg related environment variables
    export GENERATION_FILE=$VOLUME_PATH/.s4/generation
    export READ_PRIVATE_KEY_PATH="$VOLUME_PATH/.s4/read_id_ed25519-$VOLUME"
    export READ_PUBLIC_KEY_PATH="$VOLUME_PATH/.s4/read_id_ed25519-$VOLUME.pub"
    export BORG_RSH="ssh -p $S4_REMOTE_PORT -o BatchMode=yes -i $WRITE_PRIVATE_KEY_PATH -o StrictHostKeyChecking=accept-new"
    export BORG_UNKNOWN_UNENCRYPTED_REPO_ACCESS_IS_OK=yes
}

function mount_sudo() {
    if [[ $(id -u) -ne 0 ]]; then
        sudo mount $@
    else
        mount $@
    fi
}

function umount_sudo() {
    if [[ $(id -u) -ne 0 ]]; then
        sudo umount $@
    else
        umount $@
    fi
}

function chown_sudo(){
    if [[ $(id -u) -ne 0 ]]; then
        sudo chown $@
    else
        chown $@
    fi
}

function mkdir_sudo(){
    if [[ $(id -u) -ne 0 ]]; then
        sudo mkdir $@
    else
        mkdir $@
    fi
}

function check_if_keys_set_in_env(){
    # ensures that private and public keys are both set or that neither are set
    if [[ -n "$WRITE_PRIVATE_KEY" && -z "$WRITE_PUBLIC_KEY" ]]; then
        echo "Error: A private key was provided but not a public key. Please provide both or neither."
        exit 1
    elif [[ -z "$WRITE_PRIVATE_KEY" && -n "$WRITE_PUBLIC_KEY" ]]; then
        echo "Error: A public key was provided but not a private key. Please provide both or neither."
        exit 1
    elif [[ -n "$READ_PRIVATE_KEY" && -z "$READ_PUBLIC_KEY" ]]; then
        echo "Error: A private key was provided but not a public key. Please provide both or neither."
        exit 1
    elif [[ -z "$READ_PRIVATE_KEY" && -n "$READ_PUBLIC_KEY" ]]; then
        echo "Error: A public key was provided but not a private key. Please provide both or neither."
        exit 1
    fi
}

function set_owner_current_user() {
    chown_sudo $(id -u):$(id -g) $1
}

function push() {
    SUBVOLUME=$1
    prev_generation=$(cat $GENERATION_FILE)
    generation=$(get_generation $SUBVOLUME)
    # check if the generation has changed since the last snapshot
    if [ $generation -ne $prev_generation ]; then
        echo "Taking new snapshot"
        echo $(pwd)
        # create a read-only snapshot of the subvolume
        take_snapshot $SUBVOLUME $GENERATION_FILE $generation
        cd $VOLUME_PATH/snapshots/snapshot-$generation
        borg create --progress $REMOTE::$VOLUME-$generation .
        cd ../../
        # exit if last command not successful
        if [ $? -ne 0 ]; then
            echo "Failed to replicate borg snapshot"
            exit 1
        fi
        # cleanup old snapshots
        cleanup_snapshots $VOLUME_PATH/snapshots
        # write current_time to /s4/.s4/last_replicated
        export TZ='America/Chicago'
        echo $(date) > $VOLUME_PATH/.s4/last_replicated
        # write out size of volume in bytes
        du -sm $VOLUME_PATH/data | cut -f1 > $VOLUME_PATH/.s4/volume_size
        sync
        prev_generation=$(get_generation $SUBVOLUME)
    else
        echo "No changes since last push"
    fi
}