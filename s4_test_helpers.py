import socket
from os import chdir, statvfs
import sh

sh.rm = sh.Command('rm')
sh.mkdir = sh.Command('mkdir')
sh.losetup = sh.Command('losetup')
sh.umount = sh.Command('umount')
sh.dd = sh.Command('dd')


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
    '''
    helper for cleaning up after an s4 volume pytest, should be passed
    to request.addfinalizer to ensure cleanup after test regardless of outcome
    '''
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
    return vol_statvfs.f_frsize * vol_statvfs.f_blocks // 1048576  # 1024^2


def create_file(size: int, path: str):
    '''
    The main difference between the two commands is the block size and the number of blocks copied.
    A larger block size may result in faster copying due to reduced overhead in reading and writing
    the data, but it can also be more memory-intensive. In contrast, smaller block sizes may be slower
    but require less memory. The optimal block size and count depend on factors like the storage devices
    being used and the system's hardware configuration.
    '''
    sh.dd('if=/dev/zero', f'of={path}', f'bs={size}', 'count=1')


def get_ip_for_hostname(hostname: str):
    '''
    get the ip address for the hostname of the current machine
    '''
    return socket.gethostbyname(hostname)
