#!/bin/bash

# $1 not provided exit with usage
if [ $# -ne 1 ]; then
    echo "usage: s4 docker replicate path/to/ssh/privkey | stop"
    exit 1
fi


SCRIPT_DIR=$(dirname $(readlink -f $0))

source $SCRIPT_DIR/../base.sh

check_is_s4

VOLUME_NAME=$(get_config .s4/config volume name)

# if last argument is stop then stop the container
if [ "${@: -1}" == "stop" ]; then
    docker rm -f s4-agent-$VOLUME_NAME
    exit 0
else
    # read contents of file referenced $1 to variable
    S4_PRIV_KEY=$(cat $1)
fi



container_id=$(docker run --cap-add SYS_ADMIN --restart always --name s4-agent-$VOLUME_NAME -v $VOLUME_NAME:/s4 -d s4-agent:latest replicate)
sleep 1
S4_PRIV_KEY=$S4_PRIV_KEY s4 docker loadkey $container_id