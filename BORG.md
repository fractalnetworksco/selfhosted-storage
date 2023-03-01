# Simple Selfhosted Storage System (s4)

Selfhosted-storage leverages incremental BTRFS snapshots and borgbackups to provide an intuituve and user-friendly automated backup solution for your docker based applications's docker volumes.

## Components

agent container -> runs on hosts that have data to replicate
target container -> runs on hosts to which data is replicated


### Create a borg repo
```
BORG_RSH="ssh -i ./borg_key -p 2222" borg init -e=none borg@localhost:~/repo
```

# FAQ

What about ZFS?

Support for ZFS would be welcomed as a contribution from our community. The s4 architechture is such that support for ZFS can be plugged in.

What about Podman, LXC etc?

Community contributions for adding support for alternative container runtimes is encouraged.