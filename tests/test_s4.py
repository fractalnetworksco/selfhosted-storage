import os

import pytest
import sh

# cant call cleanup function just `teardown`
from s4_test_helpers import setup_pwd, cleanup_pwd, volume_size_mb, create_file, get_ip_for_hostname

# best way to chill pylint out about sh.Command not having attributes
sh.s4 = sh.Command('s4')
sh.df = sh.Command('df')


@pytest.mark.no_teardown
def test_no_arg_invocation():
    with pytest.raises(sh.ErrorReturnCode) as error:
        sh.s4()
    assert b'usage: s4.sh <subcommand> <args>' in error.value.stdout


def test_volume_init_pwd_push(s4_configure_test):
    # sanity check make sure there is no existing volume mounted at /tmp/s4-test
    reenter, volume_name, _ = s4_configure_test(setup_pwd, cleanup_pwd)
    assert volume_name not in sh.df()
    sh.s4('init', '--yes')
    # assert there is a volume mounted at /tmp/
    assert f'/tmp/{volume_name}' in sh.df()
    # volume size should default to 120M when `s4 init`ing an empty dir
    assert volume_size_mb(f'/tmp/{volume_name}') == 120

    # enable debug (tracing -x) leaving here for debugging help
    # os.environ['DEBUG'] = '1'
    # try:
    #    sh.s4('push')
    # except sh.ErrorReturnCode as error:
    #    print(error.stderr.decode().replace(b'\\n', b'\n'))
    #    raise error

    # reenter so that the new mount will resolve, UGH!
    reenter()
    sh.s4('remote', 'add', 'origin',
          f'borg@s4-target:/home/borg/{volume_name}')
    sh.s4('push')
    out = sh.s4('log')
    assert len(out.split(' ')[0]) == 36


def test_volume_init_with_size(s4_configure_test):
    assert '/tmp/s4-test' not in sh.df()
    s4_configure_test(setup_pwd, cleanup_pwd, 's4-test')
    sh.s4('init', '--yes', '--size', '500')
    assert '/tmp/s4-test' in sh.df()
    assert volume_size_mb('/tmp/s4-test') == 500


def test_volume_init_no_size_should_double(s4_configure_test):
    '''
    calling `s4 init` with out the --size argument should create volume that is double the size of the source folder
    '''
    def double_size_setup(volume_name):
        setup_pwd(volume_name)
        # create a file so that we can test the volume will be double the size of the source folder
        create_file('250M', 'test-file')
    assert '/tmp/s4-test' not in sh.df()
    s4_configure_test(double_size_setup, cleanup_pwd, 's4-test')
    sh.s4('init', '--yes')
    assert '/tmp/s4-test' in sh.df()
    assert volume_size_mb('/tmp/s4-test') == 502


def test_volume_init_invalid_size_should_fail(s4_configure_test):
    assert '/tmp/s4-test' not in sh.df()
    s4_configure_test(setup_pwd, lambda x: lambda: None, 's4-test')
    with pytest.raises(sh.ErrorReturnCode) as error:
        sh.s4('init', '--yes', '--size', '0')
    assert b'File size invalid or not specified' in error.value.stdout


def test_volume_init_existing_volume_fails(s4_configure_test):
    assert '/tmp/s4-test' not in sh.df()
    s4_configure_test(setup_pwd, cleanup_pwd, 's4-test')
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


def test_s4_entrypoint():
    '''
    s4.sh is a wrapper around s4's subcommands and bash functions, this test makes sure that the entrypoint is working as expected
    '''
    output = sh.s4('version')
    assert 's4 Version' in output
    output = sh.s4('get_version')
    assert 's4 Version' in output


def test_s4_clone(s4_configure_test):
    '''
    create a volume, push it, delete it, clone it back from a different target and make sure the volume config is updated
    '''
    reenter, volume_name, remove_volume = s4_configure_test(setup_pwd, cleanup_pwd)
    sh.s4('init', '--yes')
    reenter()
    sh.s4('remote', 'add', 'origin',
          f'borg@s4-target:/home/borg/{volume_name}')
    sh.s4('push')
    # cleanup so we can clone (avoid conflicting loop dev filename)
    remove_volume()
    remote_ipv4 = get_ip_for_hostname('s4-target')
    os.environ['DEBUG'] = '1'
    sh.s4('clone', f'borg@{remote_ipv4}:/home/borg/{volume_name}')
    assert volume_name in sh.df()
    assert volume_size_mb(f'/tmp/{volume_name}') == 120
    os.chdir(volume_name)
    # make sure we update the remote to the remote we cloned from in the volume config
    assert sh.s4('config', 'get', 'remotes', 'origin').strip() == f'borg@{remote_ipv4}:/home/borg/{volume_name}'
    assert sh.s4('config', 'get', 'default', 'remote').strip() == f'origin'

# pylint: disable=no-member
