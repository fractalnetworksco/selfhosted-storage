
import sh
from os import chdir


def setup():
    sh.mkdir('-p', '/tmp/s4-test')
    chdir('/tmp/s4-test')

def cleanup():
    chdir('/tmp')
    sh.umount('/tmp/s4-test')
    sh.rm('-rf', '/tmp/s4-test')