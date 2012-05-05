zstream
=======

streaming/generator interface to zlib in Cython

installing
----------

Make sure you have Cython installed.

To build::

    $ python setup.py build

To install:

    # python setup.py install

usage
-----

to compress::
    >>> f0 = open ('/tmp/test.z', 'wb')
    >>> for block in zstream.compress (file_gen ('test.txt'), size=1024):
    >>>     f0.write (block)
    >>> f0.close()

to uncompress::
    >>> f0 = open ('/tmp/test.txt', 'wb')
    >>> for block in zstream.uncompress (file_gen ('/tmp/test.z'), size=1024):
    >>>     f0.write (block)
    >>> f0.close()
