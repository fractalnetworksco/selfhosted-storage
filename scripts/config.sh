#!/bin/bash

function get_config() {
    echo $(crudini --get $1 $2 $3)
}


function set_config() {
    crudini --set $1 $2 $3 $4
}