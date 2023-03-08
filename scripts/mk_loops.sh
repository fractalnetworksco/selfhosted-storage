#!/bin/bash

MAX_LOOPS=5000

for ((i=0; i<$MAX_LOOPS; i++)); do
    LOOP_DEV="/dev/loop$i"
    if [ -e $LOOP_DEV ]; then
        echo "$LOOP_DEV already exists, skipping..."
    else
        mknod -m 660 $LOOP_DEV b 7 $i
        echo "Created $LOOP_DEV"
    fi
done