#!/bin/bash

# $1 name of the volume
# $2 ssh pubkey
# $3 optional comment for key

su -c "/usr/bin/add_ssh_key $1 \"$2\" \"$3\"" borg
