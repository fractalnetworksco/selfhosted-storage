# Simple Self-hosted Storage Service (s4)
Easy, secure and reliable personal backups powered by BorgBackup and BTRFS


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

