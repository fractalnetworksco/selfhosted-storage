import pytest
import sh
from os import chdir

from faker import Faker

faker = Faker()

@pytest.fixture(scope='function')
def s4_configure_test(request):
    '''
    convenience function for configuring the setup and teardown of an s4 volume pytest
    '''
    def configure(setup, teardown, volume_name = None):
        if not volume_name:
            volume_name = '-'.join(faker.words(2))
        # for now we run tests as root
        # TODO figure out a clean strategy to avoid this
        if sh.whoami().strip() != 'root':
            raise Exception('This test must be run as root')
            exit(1)
        # run test setup return a function to reenter the test dir
        reenter = setup(volume_name)
        # don't register teardown if test is marked with no_teardown
        if request.node.get_closest_marker('no_teardown'):
            return
        # setup cleanup step after test
        cleanup = teardown(volume_name)
        request.addfinalizer(cleanup)
        return reenter, volume_name, cleanup
    return configure


from _pytest.assertion import truncate
truncate.DEFAULT_MAX_LINES = 9999
truncate.DEFAULT_MAX_CHARS = 9999
