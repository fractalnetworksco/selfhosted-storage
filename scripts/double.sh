#!/bin/bash
#/code/scripts/double.sh $(pwd) myfile
# create a file of double the size of the current directory

function create_double_size_file() {
    # create a file of double the size of the current directory + 20%
    # $1 is the directory to get the size of
    # $2 is the file to create

    echo "Creating file that is double the size of $1 at $2"
    if [ -f $2 ]; then
        echo "$2 already exists"
        exit 1
    fi
    size=$(du -sm $1 | awk '{print $1}')
    doubled=$((size * 2))
    # make sure $1 has enough space + 20%
    FREE_SPACE=$(df -m $1 | awk 'NR==2{print $4}')
    # add 20% to FREE_SPACE
    FREE_SPACE=$((FREE_SPACE + (FREE_SPACE / 5)))
    if [ $doubled -gt $FREE_SPACE ]; then
        echo "Not enough space to create file of size $doubled"
        exit 1
    fi
    dd if=/dev/zero of=$2 bs=1M count=$doubled
}