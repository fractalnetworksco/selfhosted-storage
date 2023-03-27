# compute cumulative md5sum for all files in a directory
# usage: md5_dir.sh <directory>
set -ex

ls -1 $1/* | while read file; do md5sum $1/$file; done | md5sum

