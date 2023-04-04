#!/bin/bash

# start ssh-agent with socket at /tmp/ssh-agent.sock
eval `ssh-agent -a /tmp/ssh-agent.sock`

# attempt to load S4_PRIV_KEY into ssh-agent
s4 loadkey

# run whatever command was given to the container
bash -c "$@"
