# -*- Mode: Python -*-

from distutils.core import setup
from distutils.extension import Extension
from Cython.Distutils import build_ext

ext_modules = [
    Extension (
        'zstream',
        ['zstream.pyx'],
        libraries=['z'],
        depends=['zlib.pxd']
        ),
        ]

setup (
    name         = 'zstream',
    version      = '0.1',
    author       = 'Sam Rushing',
    description  = "streaming/generator interface for zlib in Cython",
    license      = "Simplified BSD",
    keywords     = "zlib streaming generator",
    url          = 'http://github.com/samrushing/zstream/',
    # pip demands the project-version in the #egg= section
    download_url = "http://github.com/samrushing/zstream/tarball/v0.1#egg=zstream-0.1",
    ext_modules  = ext_modules,
    cmdclass     = {'build_ext': build_ext}
    )
