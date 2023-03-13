#!/bin/bash
# list volumes in the repo
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source $SCRIPT_DIR/base.sh

init_globals

# for
while IFS='=' read -r remote
do
    # replace s4admin with borg in $remote
    vol_remote=${remote/s4admin/borg}
    echo "[$vol_remote]"
    while IFS='=' read -r volume
    do
        echo "$vol_remote:/volumes/$volume"
    done < <(ssh -p $S4_REMOTE_PORT $remote "ls -1 /volumes" </dev/null) #https://unix.stackexchange.com/a/66178
done < <(get_config ~/.s4/config "remote")