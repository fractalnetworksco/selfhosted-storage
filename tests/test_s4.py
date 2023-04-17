import pytest
import sh
import subprocess
from os import chdir
# cant call teardown function just `teardown` for some reason
from s4_test_helpers import setup, cleanup 

@pytest.mark.no_teardown
def test_no_arg_invocation():
    with pytest.raises(sh.ErrorReturnCode) as error:
        sh.s4()
    assert b'usage: s4.sh <subcommand> <args>' in error.value.stdout

def test_volume_init_of_pwd(s4_configure_test):
    s4_configure_test(setup, cleanup)
    sh.s4('init', '--yes')
    # assert there is a volume mounted at /tmp/s4-test
    assert sh.mount().stdout.decode().find('/tmp/s4-test') != -1


