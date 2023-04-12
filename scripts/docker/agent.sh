#!/bin/bash

if [ $# -lt 1 ]; then
    echo "usage: s4 docker agent [replicate|sync] path/to/ssh/privkey | stop"
    exit 1
fi


SCRIPT_DIR=$(dirname $(readlink -f $0))

source $SCRIPT_DIR/../base.sh

check_is_s4

VOLUME_NAME=$(s4 config get volume name)

# if last argument is stop then stop the container
if [ "${@: -1}" == "stop" ]; then
    docker rm -f s4-agent-$VOLUME_NAME
    exit 0
else
    # read contents of file referenced $1 to variable
    PRIV_KEY_PATH=$2
    ACTION=$1
    S4_PRIV_KEY=$(cat $PRIV_KEY_PATH)
fi

# if action is sync give the container access to fuse
if [ "$ACTION" == "sync" ]; then
    FUSE_DEVICE="--device /dev/fuse --security-opt apparmor:unconfined"
fi

container_id=$(docker run $FUSE_DEVICE --cap-add SYS_ADMIN --restart always --name s4-agent-$VOLUME_NAME -v $(pwd):/s4 -d s4-agent:latest "s4 $ACTION")
sleep 1
S4_PRIV_KEY=$S4_PRIV_KEY s4 docker loadkey $container_id