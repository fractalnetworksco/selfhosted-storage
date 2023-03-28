#!/bin/bash

function verify_copy() {
  if [ $# -ne 2 ]; then
    echo "Usage: verify_same_directory dir_path_1 dir_path_2"
    return 1
  fi

  local dir1=$(realpath "$1")
  local dir2=$(realpath "$2")

  if [ ! -d "$dir1" ]; then
    echo "Error: $dir1 is not a valid directory."
    return 1
  fi

  if [ ! -d "$dir2" ]; then
    echo "Error: $dir2 is not a valid directory."
    return 1
  fi
  prev_dir=$(pwd)

  cd "$dir1"
  local hash1=$(find . -type f -print0 | sort -z | xargs -0 sha1sum | sha1sum | awk '{ print $1 }')

  cd "$dir2"
  local hash2=$(find . -type f -print0 | sort -z | xargs -0 sha1sum | sha1sum | awk '{ print $1 }')
    
  cd "$prev_dir"

  if [ "$hash1" == "$hash2" ]; then
    echo "Directories are exactly the same."
    return 0
  else
    echo "Error: Directories are not the same."
    return 1
  fi
}
