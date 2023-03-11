#!/bin/bash

# list volumes in the repo
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source $SCRIPT_DIR/config.sh


S4_REMOTE_PORT=${S4_REMOTE_PORT:-2222}

# for
while IFS='=' read -r remote
do
    echo "[$remote]"
    while IFS='=' read -r volume
    do
        echo "$remote:/volumes/$volume"
    done < <(ssh -p $S4_REMOTE_PORT $remote "ls -1 /volumes" </dev/null) #https://unix.stackexchange.com/a/66178
done < <(get_config ~/.s4/config "remote")