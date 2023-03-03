# remove all btrfs subvols in dir
btrfs sub list snapshots/|awk '{print $9}'|while read subvol; do btrfs sub delete $subvol; done