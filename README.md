# Simple Self-hosted Storage Service (s4)
Easy, secure and reliable personal backups powered by BorgBackup and BTRFS

## Quick Start (intsructions are macOS docker-for-desktop specific for now) clever users should be able to figure out how to make it work anywhere Linux runs.

## These steps will migrate an existing folder to a s4 volume
- Add your ssh-key to the ssh-agent `ssh-add /path/to/key1
- Add your ssh pubkey to ./authorized_keys file in this repo

1. Build the agent and target docker containers
```
$ make docker
```
2. Launch the s4 target container on any host (`s4-target`) you'd like to use as a s4 remote. Note that /mnt/s4-volumes on the remote must be a btrfs partition for s4 syncing to work
```
$ docker run -p 2222:22 -v /mnt/s4-volumes:/volumes s4-target:latest 
```
3. Launch a shell, mounting in a folder you'd like to make an s4 volume
```
$ make docker-desktop-shell DATA_DIR=~/my-existing-folder
```
4. Initialize a s4 volume called `my-s4-volume`
```
$ BORG_RSH="ssh -p 2222" /code/scripts/init.sh /data my-s4-volume --remote borg@s4-target-host
```
5. Exit `docker-desktop` shell
```
$ exit
```
6. Launch docker container with your fancy new s4 volume
```
$ docker run --name my-s4-container -v my-s4-volume:/data s4-agent:latest
```
7. Enable automatic-replication for `my-s4-volume` (runs in foreground)
```
$ docker exec --workdir /data -it my-s4-container replicate
```
8. Enable syncing of `my-s4-volume` to another host (runs in foreground)
```
$ make docker-desktop-shell
$ /code/scripts/clone borg@s4-target-host:/volumes/my-s4-volume
$ exit
$ docker run -v my-s4-volume:/data --workdir /data s4-agent:latest sync
```

## Project Goals
- Docker native backup solution for self-hosted applications.
- Quickly add backups to existing Docker compose based application deployments.
- Redundant (near) real-time atomic snapshot replication powered by BorgBackup and BTRFS
- Ability to restore to point-in-time backup (time machine)
- User friendly command-line interface
- Lightweight REST Mgmt API


# Proposed CLI Interface

# create a volume
```
s4 init myvolume
```

# set volume remote

```
s4 remote add origin root@myserver
```

# clone volume

```
s4 clone root@myserver:volumes/jpb-videos
```

# update local volume
```
s4 pull
```

# update remote
```
s4 commit -m "Add latest JPB video"
```

# enable replication for volume
```
s4 replicate
```

# enable syncing from remote
```
s4 sync
```

# show s4 volumes
```
s4 status
```

