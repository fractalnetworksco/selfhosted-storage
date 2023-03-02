#!/bin/ash

# write while loop that run 10 times
i=0
while [ $i -le $1 ]; do
    # generate a file with random name
    dd if=/dev/urandom of=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1).dat bs=1M count=$2
    i=$((i+1))
done