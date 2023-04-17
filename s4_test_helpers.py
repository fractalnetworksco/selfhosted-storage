
import sh
from os import chdir, statvfs


def setup():
    sh.rm('-rf', '/tmp/s4-test')
    sh.rm('-rf', '/var/lib/fractal/s4-test')
    sh.mkdir('-p', '/tmp/s4-test')
    sh.rm('-rf', '/var/lib/fractal/s4-test-loop')
    chdir('/tmp/s4-test')

def cleanup():
    chdir('/tmp')
    sh.umount('/tmp/s4-test')
    sh.rm('-rf', '/tmp/s4-test')
    sh.rm('-rf', '/var/lib/fractal/s4-test')
    sh.rm('-rf', '/var/lib/fractal/s4-test-loop')

def volume_size_mb(volume_path: str):
    vol_statvfs = statvfs(volume_path)
    return vol_statvfs.f_frsize * vol_statvfs.f_blocks // 1048576 # 1024^2