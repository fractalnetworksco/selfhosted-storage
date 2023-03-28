#!/bin/bash



export SSH_AUTH_SOCK=/tmp/ssh-agent.sock
echo "$S4_PRIV_KEY" > /tmp/s4_priv_key
chmod 600 /tmp/s4_priv_key
ssh-add /tmp/s4_priv_key
rm /tmp/s4_priv_key
