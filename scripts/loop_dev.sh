#!/bin/bash

function create_loop_device() {
    # create loop device
    losetup -fP $1
}

function get_loop_device_for_file() {
    # get loopback device
    losetup -a | grep $1 | awk -F: '{print $1}'
}
