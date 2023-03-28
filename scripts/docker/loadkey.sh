#!/bin/bash

# make sure at least one argument is passed, else exit
if [ $# -ne 1 ]; then
    echo "usage: s4 docker loadkey <container id>"
    exit 1
fi

# invoke s4 loadkey in the agent container passing the S4_PRIV_KEY env var
docker exec -it -e S4_PRIV_KEY="$S4_PRIV_KEY" $1 s4 loadkey