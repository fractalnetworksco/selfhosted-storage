#!/bin/bash
#/code/scripts/double.sh $(pwd) myfile
# create a file of double the size of the current directory
function dd_sudo() {
    if [[ $(id -u) -ne 0 ]]; then
        sudo dd $@
    else
        dd $@
    fi
}

function create_double_size_file() {
    # creates a file of double the size of the current directory

    # args:
    #   $1 is the directory to get the size of
    #   $2 is the file to create
    #   $3 is the size to use

    echo "Creating file that is double the size of $1 at $2"
    # if $3 is not given, get the size of $1
    if [ -z $3 ]; then
        size=$(du -sm $1 | awk '{print $1}')
    # $3 was given, so use that as the size
    else
        size=$3
    fi

    if [ -f $2 ]; then
        echo "$2 already exists"
        exit 1
    fi

    doubled=$((size * 2))
    # make sure $1 has enough space + 20%
    FREE_SPACE=$(df -m $1 | awk 'NR==2{print $4}')
    # add 20% to FREE_SPACE
    FREE_SPACE=$((FREE_SPACE + (FREE_SPACE / 5)))
    if [ $doubled -gt $FREE_SPACE ]; then
        echo "Not enough space to create file of size $doubled"
        exit 1
    fi
    # if double less that 120MB, set to 120MB
    if [ $doubled -lt 120 ]; then
        doubled=120
    fi
    dd_sudo if=/dev/zero of=$2 bs=1M count=$doubled
}