#!/bin/bash
#/code/scripts/double.sh $(pwd) myfile
# create a file of double the size of the current directory

function create_double_size_file() {
    # create a file of double the size of the current directory
    size=$(du -sm $1 | awk '{print $1}')
    doubled=$((size * 2))
    dd if=/dev/zero of=$2 bs=1M count=$doubled
}