import sys
import btrfsutil

print(btrfsutil.subvolume_info(sys.argv[1]).generation)
