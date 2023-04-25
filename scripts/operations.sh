#!/bin/bash
SCRIPT_DIR=$(dirname $(readlink -f $0))

function is_initialized() {
    source $SCRIPT_DIR/base.sh
    local REMOTE_NAME=$1
    local REMOTE_INIT_STATE=$(s4 config get remotes $REMOTE_NAME.initialized)
    local REMOTE=$(s4 config get remotes $REMOTE_NAME)
    if [ "$REMOTE_INIT_STATE" -eq 0 ]; then
        is_remote_initialized $REMOTE
        if [ "$?" -eq 0 ]; then
            echo "WARNING: Remote is already initialized, but local state does not reflect this."
            exit 1
        fi
        echo "Initializing remote $REMOTE_NAME"
        init_remote $REMOTE
        # check exit code
        if [ "$?" -eq 0 ]; then
            echo "Remote $REMOTE_NAME initialized successfully"
            s4 config set remotes $REMOTE_NAME.initialized 1

        else
            echo "Failed to init remote $REMOTE_NAME"
            exit 1
        fi
    else
        return 0
    fi
}

function push() {
    source $SCRIPT_DIR/base.sh
    local REMOTE_NAME=$1
    local REMOTE
    # if $1 not set use default remote
    if [ -z "$REMOTE_NAME" ]; then
        REMOTE_NAME=$(s4 config get default remote)
        REMOTE=$(s4 config get remotes $REMOTE_NAME)
    else
        REMOTE=$(s4 config get remotes $REMOTE_NAME)
    fi
    # if $REMOTE is empty exit
    if [ "$?" -ne 0 ]; then
        echo "No remote configured for volume $(s4 config get volume name)"
        exit 1
    fi
    is_initialized $REMOTE_NAME
    local VOLUME_PATH=$(pwd)
    local VOLUME_NAME=$(s4 config get volume name)
    local SNAPSHOT_UUID=$(generate_uuid)
    local prev_generation
    prev_generation=$(s4 config get ~/.s4/volumes/$VOLUME_NAME state generation)
    # if return code is not 0, exit
    if [ "$?" -ne 0 ]; then
        prev_generation=-1
    fi
    local generation=$(get_generation $VOLUME_PATH)
    # check if the generation has changed since the last snapshot
    # if VERBOSE is set, print the generation numbers
    if [ ! -z "$VERBOSE" ]; then
        echo "Remote is $REMOTE"
        echo "Previous generation: $prev_generation"
        echo "Current generation: $generation"
    fi
    if [ $generation -ne $prev_generation ]; then
        # update volume metadata before replicating
        if [ -z "$TZ" ]; then
            export TZ='America/Chicago'
        fi
        s4 config set volume last_replicated "$(date -u +'%Y-%m-%dT%H:%M:%SZ')"
        s4 config set volume size "$(du -sm $VOLUME_PATH | cut -f1)"
        s4 config set volume last_snapshot $SNAPSHOT_UUID
        # need to read volume config after writing to ensure the above writes are synced during this push operation
        # without this, pending writes are not flushed which causes continuous empty replication
        cat $VOLUME_PATH/.s4/config > /dev/null
        echo "Taking new snapshot"
        take_snapshot $VOLUME_PATH $SNAPSHOT_UUID
        cd $VOLUME_PATH/.s4/snapshots/snapshot-$SNAPSHOT_UUID
        borg create --progress $REMOTE::$SNAPSHOT_UUID . --exclude ".s4/synced" --exclude ".s4/snapshots"
        # exit if replication failed
        if [ $? -ne 0 ]; then
            echo "Failed to replicate borg snapshot"
            exit 1
        fi
        cd $VOLUME_PATH
        # cleanup snapshots
        cleanup_snapshots $VOLUME_PATH/.s4/snapshots
        # sync again to account for snapshots and cleanup
        sync
        # store the current generation in the global volume config so we can detect changes going forward
        s4 config set ~/.s4/volumes/$VOLUME_NAME state generation $(get_generation $VOLUME_PATH)

        # write current time into synced file
        if [ -z "$TZ" ]; then
            export TZ='America/Chicago'
        fi

        # store last push timestamp in global volume config
        s4 config set ~/.s4/volumes/$VOLUME_NAME state last_push "$(date)"

        # necessary for the agent docker health check to pass
        echo "$(date)" > $(pwd)/.s4/synced
    else
        echo "No changes since last push"
    fi
}

function pull () {
    source $SCRIPT_DIR/base.sh
    check_is_s4
    # if $REMOTE_NAME empty, use default remote
    if [ -z "$REMOTE_NAME" ]; then
        REMOTE_NAME=$(s4 config get default remote)
    fi
    # if 2 args passed we are specifying remote and archive to pull
    if [ "$#" -eq 2 ]; then
        REMOTE_NAME=$1
        ARCHIVE=$2
    # single argument means we are pulling $ARCHIVE from the default repo (for . this volume)
    elif [ "$#" -eq 1 ]; then
            ARCHIVE=$1
    else
        # no args means we are pulling latest archive from default remote
        echo "Checking with remote \"$REMOTE_NAME\" for new snapshots..."
        ARCHIVE=$(new_snapshot_exists $REMOTE_NAME)
        # exit if return code not equal 0
        if [ "$?" -ne 0 ]; then
            echo "Volume is up to date"
            return 0
        fi
    fi
    # assert that NEW_SNAPSHOT is a uuidv4
    # make me a function
    # if ! [[ $ARCHIVE =~ ^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$ ]]; then
    #     echo "new_snapshot_exists returned invalid uuid: $ARCHIVE"
    #     return 1
    # fi
    REMOTE=$(get_remote $REMOTE_NAME)
    TMP_MOUNT="/tmp/s4/$ARCHIVE/"
    mkdir -p $TMP_MOUNT
    echo "New changes found, syncing from remote \"$REMOTE_NAME\""
    mount_archive $REMOTE_NAME $TMP_MOUNT $ARCHIVE
    # sync mounted volume with local volume
    rsync -avzh --delete $TMP_MOUNT $(pwd)
    #borg --bypass-lock extract --progress $REMOTE::$ARCHIVE
    umount $TMP_MOUNT

    # write current time into synced file
    if [ -z "$TZ" ]; then
        export TZ='America/Chicago'
    fi
    echo "$(date)" > $(pwd)/.s4/synced

    echo "Latest changes synced from remote \"$REMOTE_NAME\""
}

function new_snapshot_exists() {
    # check remote for new snapshots return snapshot uuid if new snapshot exists
    source $SCRIPT_DIR/base.sh
    REMOTE_NAME=$1
    REMOTE=$(get_remote $REMOTE_NAME)
    CURRENT_SNAPSHOT=$(s4 config get volume last_snapshot)
    LATEST_SNAPSHOT=$(get_latest_archive $REMOTE) || exit 1
    # if CURRENT_SNAPSHOT not equal LATEST_SNAPSHOT, return 0
    if [ "$CURRENT_SNAPSHOT" != "$LATEST_SNAPSHOT" ]; then
        echo $LATEST_SNAPSHOT
    else
        return 1
    fi

}

function resize() {
    source $SCRIPT_DIR/base.sh
    check_is_s4
    LOOP_DEV_FILE=$1
    NEW_SIZE=$2 # ie 2G
    LOOP_DEV=$(losetup_sudo -j $LOOP_DEV_FILE| awk -F: '{print $1}')
    VOLUME_PATH=$(pwd)
    truncate -s $NEW_SIZE $LOOP_DEV_FILE
    losetup_sudo --set-capacity $LOOP_DEV
    btrfs_sudo filesystem resize max $VOLUME_PATH
}
