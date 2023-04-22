#!/bin/bash

SCRIPT_DIR=$(dirname $(readlink -f $0))
source $SCRIPT_DIR/base.sh

check_is_s4

borg list --bypass-lock $(get_remote)

