
import sh
from os import chdir, statvfs


def setup_pwd(volume_name):
    '''
    setup a volume for an s4 test that will use the current working directory as the volume
    '''
    sh.rm('-rf', f'/tmp/{volume_name}')
    sh.rm('-rf', f'/var/lib/fractal/{volume_name}')
    sh.mkdir('-p', f'/tmp/{volume_name}')
    sh.rm('-rf', f'/var/lib/fractal/{volume_name}-loop')
    chdir(f'/tmp/{volume_name}')
    def reenter():
        chdir(f'/tmp/{volume_name}')
    return reenter

def cleanup_pwd(volume_name):
    def cleanup():
        chdir('/tmp')
        sh.umount(f'/tmp/{volume_name}')
        sh.rm('-rf', f'/tmp/{volume_name}')
        sh.rm('-rf', f'/var/lib/fractal/{volume_name}')
        sh.rm('-rf', f'/var/lib/fractal/{volume_name}-loop')
        sh.losetup('-D')
    return cleanup
def volume_size_mb(volume_path: str):
    '''
    return the size of volume_path in MB
    '''
    vol_statvfs = statvfs(volume_path)
    return vol_statvfs.f_frsize * vol_statvfs.f_blocks // 1048576 # 1024^2
