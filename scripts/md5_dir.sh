# compute cumulative md5sum for all files in a directory
# usage: md5_dir.sh <directory>
set -e

ls -1 $1/* | while read file; do md5sum $file| awk '{print $1}'; done | md5sum

