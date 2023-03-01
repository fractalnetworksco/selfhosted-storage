#!/usr/bin/env python3
import sys
import btrfsutil

print(btrfsutil.subvolume_info(sys.argv[1]).generation)
