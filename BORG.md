# Simple Selfhosted Storage System (s4)

s4 is a personal data storage frontend that makes it easy to keep personal data safe.

s4 is designed to be familiar to git users. It combines Borg Backups, BTRFS and Rsync to enable near real-time replication and synchronization of local files and folders via BTRFS snapshots and borg backups to provide an intuituve and user-friendly automated backup solution for your files and folders. It provides a simple agent for replicating local docker volumes and keeping a local synchronized copy of remote docker volumes.



## Resizing

truncate -s 5G btrfs.img
losetup -c /dev/loop0
btrfs fi resize max .


## Components

agent container -> replicates data to 
target container -> runs on hosts to which data is replicated

## Syncing


## Replicating
s4 volumes "replicate" by:
 1) btrfs subvolume snapshot volume

 ## Migrating to s4 volumes

## creating a s4 volume
- create a backing file specifying its size, 1G for example
- create a loopback device associated with the backing file
- format the loopback device with btrfs
- create a docker volume of type btrfs that references the loopback device
    - volume labels
        - s4.volume
        - s4.interval=12
        - s4.target=root@localhost:2222

## automatic volume backups
    - volumes are optionally set ro if agent is not running?


### Borg Examples
```
BORG_RSH="ssh -i ./borg_key -p 2222" borg init -e=none borg@localhost:~/repo
BORG_RSH="ssh -i /code/borg_key -p 2222" borg create --progress --content-from-command borg@172.17.0.1:~/repo::snap-2 -- btrfs send snap-04
```

# FAQ

What about ZFS?

Support for ZFS would be welcomed as a contribution from our community. The s4 architechture is such that support for ZFS can be plugged in.

What about Podman, LXC etc?

Community contributions for adding support for alternative container runtimes is encouraged.