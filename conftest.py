import pytest
import sh
from os import chdir


@pytest.fixture(scope='function')
def s4_configure_test(request):
    def configure(setup, teardown):
        # for now we run tests as root
        # TODO figure out a clean strategy to avoid this
        if sh.whoami().strip() != 'root':
            raise Exception('This test must be run as root')
            exit(1)
        # run test setup
        setup()
        # don't register teardown if test is marked with no_teardown
        if request.node.get_closest_marker('no_teardown'):
            return
        # cleanup after test
        request.addfinalizer(teardown)
    return configure