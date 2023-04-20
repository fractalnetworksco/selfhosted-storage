import pytest
import sh
import subprocess
from os import chdir
# cant call teardown function just `teardown` for some reason
from s4_test_helpers import setup, cleanup, volume_size_mb

@pytest.mark.no_teardown
def test_no_arg_invocation():
    with pytest.raises(sh.ErrorReturnCode) as error:
        sh.s4()
    assert b'usage: s4.sh <subcommand> <args>' in error.value.stdout

def test_volume_init_of_pwd(s4_configure_test):
    # sanity check make sure there is no existing volume mounted at /tmp/s4-test
    assert '/tmp/s4-test' not in sh.df()
    s4_configure_test(setup, cleanup)
    sh.s4('init', '--yes')
    # assert there is a volume mounted at /tmp/s4-test
    assert '/tmp/s4-test' in sh.df()
    # volume size should default to 120M when `s4 init`ing an empty dir
    assert volume_size_mb('/tmp/s4-test') == 120

def test_volume_init_with_size(s4_configure_test):
    assert '/tmp/s4-test' not in sh.df()
    s4_configure_test(setup, cleanup)
    sh.s4('init', '--yes', '--size', '500')
    assert '/tmp/s4-test' in sh.df()
    assert volume_size_mb('/tmp/s4-test') == 500

def test_volume_init_no_size_should_double(s4_configure_test):
    '''
    calling `s4 init` with out the --size argument should create volume that is double the size of the source folder
    '''
    def double_size_setup():
        setup()
        sh.dd('if=/dev/zero', 'of=/tmp/s4-test/testfile', 'bs=1M', 'count=250')

    assert '/tmp/s4-test' not in sh.df()
    s4_configure_test(double_size_setup, cleanup)
    sh.s4('init', '--yes')
    assert '/tmp/s4-test' in sh.df()
    assert volume_size_mb('/tmp/s4-test') == 502

def test_volume_init_invalid_size_should_fail(s4_configure_test):
    assert '/tmp/s4-test' not in sh.df()
    s4_configure_test(setup, lambda: None)
    with pytest.raises(sh.ErrorReturnCode) as error:
        sh.s4('init', '--yes', '--size', '0')
    assert b'File size invalid or not specified' in error.value.stdout

def test_volume_init_existing_volume_fails(s4_configure_test):
    assert '/tmp/s4-test' not in sh.df()
    s4_configure_test(setup, cleanup)
    sh.s4('init', '--yes')
    assert '/tmp/s4-test' in sh.df()
    with pytest.raises(sh.ErrorReturnCode) as error:
        # calling init again should fail
        sh.s4('init', '--yes')
    assert b'already a s4 volume' in error.value.stdout

def test_s4_clone_exits_when_ssh_errors():
    with pytest.raises(sh.ErrorReturnCode) as error:
        sh.s4('clone', 'test@localhost:22/test')
    assert b'Connection closed by remote host. Is borg working on the server?' in error.value.stderr
