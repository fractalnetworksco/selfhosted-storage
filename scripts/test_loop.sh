#!/bin/bash
#  run /code/scripts/init.sh in a loop with a different volume name each time
while true; do
    RANDOM=$$$(date +%s)
    /code/scripts/init.sh /data test-$RANDOM --remote borg@192.168.1.190:/volumes
done
