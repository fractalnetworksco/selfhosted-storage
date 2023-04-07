#!/bin/ash
dd if=/dev/zero of=/var/lib/fractal/testvol bs=1M count=100
losetup -fP /var/lib/fractal/testvol &> /losetup.log

mkdir -p /run/docker/plugins
cd /plugin
gunicorn --bind unix:/run/docker/plugins/s4.sock plugin:app