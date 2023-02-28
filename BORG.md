# BorgBackup


### Create a borg repo
```
BORG_RSH="ssh -i ./borg_key -p 2222" borg init -e=none borg@localhost:~/repo
```