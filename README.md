# s4: Simple Self-hosted Storage System
*s4 is under active development.*
<hr>
s4 is a simple, secure and reliable personal storage solution with zero-configurarion automatic backups powered by BorgBackup.

s4 also includes optional first-class support for real-time docker volume replication to enable Fractal Network [application portability](https://blog.fractalnetworks.co/portable-self-hosted-applications-2/).

## Quick Start
1. Create an s4 volume from an existing folder:
```
[~/]$ cd my-existing-folder
[~/my-existing-folder]$ s4 init
Initialized empty s4 volume in /home/fractal-networks/my-existing-folder/.s4/
```
2. Add a remote to your new s4 volume: 
(borgbackup must be installed on the remote)
```
[~/my-existing-folder]$ s4 remote add origin s4@mys4remote:/volumes
```
3. Create a 10MB file of random data and push the volume to the remote:
```
[~/my-existing-folder]$ dd if=/dev/urandom of=10MB.dat bs=1M count=10
10+0 records in
10+0 records out
10485760 bytes (10 MB, 10 MiB) copied, 0.0135028 s, 777 MB/s
[~/my-existing-folder]$ s4 push origin
```
4. From another host, clone the `my-existing-folder` volume:
```
[~/]$ s4 clone s4@mys4remote:/volumes/my-existing-folder
Cloning into 'my-existing-folder'...
```

## Design
s4 mirrors git's decentralized architecture by efficently replicating volumes to remote hosts via ssh (as borg archives) and can be incrementally synced by other hosts. 

With a command-line interface inspired by `git`, the s4 command-line interface should feel familair to anyone who uses `git`.

### BTRFS
s4 optionally leverages BTRFS, a modern copy-on-write filesystem, to provide atomic snapshots of volumes. This allows for consistent near-real-time replication of volumes to remote hosts.

#### Loop Devices
s4 can optionally use loop devices to create btrfs volumes. This enables s4 to work across all platform that supports docker. s4 can intelligently resizes loop devices to efficently utilize disk space.


### Docker Volumes
s4 can optionally be used to manage docker volumes. This enables s4 to be used as a docker-native backup solution for self-hosted applications.

#### Docker Volume Replication
s4 can optionally be used to replicate s4 docker volumes to remote hosts in near-real-time. This enables s4 to be used as a docker-native backup solution for self-hosted applications.

To enable replication for an s4 volumes, simply run `s4 replicate` on the host where the volume is mounted. This will start a background process that will replicate the volume to the remote host specified by the `origin` remote. Thanks to BTRFS replication operations are effecient and atomic, only incremental changes are replicated to the remote host.

s4 ships with a docker container that handles volumes replication. Here's an example of how to use it:
```
~/$ docker run --name my-existing-folder-replicator -v my-existing-folder:/s4 --workdir /s4 s4-agent:latest replicate
```

## Development

Coming soon.

## Project Goals
- Simple, secure and reliable personal storage solution with zero-configurarion automatic backups powered by BorgBackup.
- Docker native backup solution for self-hosted applications.
- Quickly add backups to existing Docker compose based application deployments.
- Redundant (near) real-time atomic snapshot replication powered by BorgBackup and BTRFS
- Ability to restore to point-in-time backup (time machine)
- User friendly command-line interface
- Lightweight REST Mgmt API