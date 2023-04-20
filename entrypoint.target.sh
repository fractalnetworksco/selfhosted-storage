#!/bin/ash

echo $S4_PUB_KEY > /home/borg/.ssh/authorized_keys
chown -R borg:borg /home/borg/.ssh
chmod -R 700 /home/borg/.ssh

# start sshd in the foreground
/usr/sbin/sshd -D -e
