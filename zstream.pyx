# -*- Mode: Cython -*-

# [Simplified BSD, see http://www.opensource.org/licenses/bsd-license.html]
# 
# Copyright (c) 2012, Sam Rushing
# All rights reserved.
# 
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are
# met:
# 
#     * Redistributions of source code must retain the above copyright
#       notice, this list of conditions and the following disclaimer.
# 
#     * Redistributions in binary form must reproduce the above
#       copyright notice, this list of conditions and the following disclaimer
#       in the documentation and/or other materials provided with the
#       distribution.
# 
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
# "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
# LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
# A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
# HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
# SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
# LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
# DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
# THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

# zlib generator interface, with support for inflateSetDictionary and deflateSetDictionary
#
# see http://www.zlib.net/zlib_how.html
#
# sample usage:
# to compress:
# >>> f0 = open ('/tmp/test.z', 'wb')
# >>> for block in zstream.compress (file_gen ('test.txt'), size=1024):
# >>>     f0.write (block)
# >>> f0.close()
#
# to uncompress:
# >>> f0 = open ('/tmp/test.txt', 'wb')
# >>> for block in zstream.uncompress (file_gen ('/tmp/test.z'), size=1024):
# >>>     f0.write (block)
# >>> f0.close()

cimport zlib
from cpython.mem cimport PyMem_Malloc, PyMem_Free

class ZlibError (Exception):
    "A problem with zlib"

def compress (data_gen, int level=zlib.Z_DEFAULT_COMPRESSION, int size=16384, dict=None):
    cdef zlib.z_stream zstr
    cdef char * buffer
    cdef bytes block
    cdef int flush = zlib.Z_NO_FLUSH
    cdef int r
    zstr.zalloc = NULL
    zstr.zfree = NULL
    zstr.opaque = NULL
    r = zlib.deflateInit (&zstr, level)
    if r != zlib.Z_OK:
        raise ZlibError (r)
    buffer = <char *> PyMem_Malloc (size)
    if not buffer:
        raise MemoryError
    if dict is not None:
        r = zlib.deflateSetDictionary (&zstr, dict, len(dict))
        if r != zlib.Z_OK:
           raise ZlibError (r)
    try:
        while 1:
            try:
                block = data_gen.next()
            except StopIteration:
                flush = zlib.Z_FINISH
            zstr.next_in = <unsigned char *> block
            zstr.avail_in = len(block)
            while zstr.avail_in or flush == zlib.Z_FINISH:
                zstr.next_out = <unsigned char *> (&buffer[0])
                zstr.avail_out = size
                r = zlib.deflate (&zstr, flush)
                if r == zlib.Z_STREAM_END:
                    yield buffer[:size - zstr.avail_out]
                    return
                elif r != zlib.Z_OK:
                    raise ZlibError (r)
                elif size - zstr.avail_out > 0:
                    yield buffer[:size - zstr.avail_out]
                else:
                    # Z_OK, but no data
                    pass
    finally:
        zlib.deflateEnd (&zstr)
        PyMem_Free (buffer)
        
        
def uncompress (data_gen, int level=zlib.Z_DEFAULT_COMPRESSION, int size=16384, dict=None):
    cdef zlib.z_stream zstr
    cdef char * buffer
    cdef bytes block
    cdef int flush = zlib.Z_NO_FLUSH
    cdef int r
    zstr.zalloc = NULL
    zstr.zfree = NULL
    zstr.opaque = NULL
    r = zlib.inflateInit (&zstr)
    if r != zlib.Z_OK:
        raise ZlibError (r)
    buffer = <char *> PyMem_Malloc (size)
    if not buffer:
        raise MemoryError
    try:
        while 1:
            try:
                block = data_gen.next()
            except StopIteration:
                flush = zlib.Z_FINISH
            zstr.next_in = <unsigned char *> block
            zstr.avail_in = len(block)
            while zstr.avail_in or flush == zlib.Z_FINISH:
                zstr.next_out = <unsigned char *> (&buffer[0])
                zstr.avail_out = size
                r = zlib.inflate (&zstr, flush)
                if r == zlib.Z_NEED_DICT and dict is not None:
                    r = zlib.inflateSetDictionary (&zstr, dict, len(dict))
                    if r != zlib.Z_OK:
                        raise ZlibError (r)
                elif r == zlib.Z_STREAM_END:
                    yield buffer[:size - zstr.avail_out]
                    return
                elif r != zlib.Z_OK:
                    raise ZlibError (r)
                elif size - zstr.avail_out > 0:
                    yield buffer[:size - zstr.avail_out]
                else:
                    # Z_OK, but no data
                    pass
    finally:
        zlib.inflateEnd (&zstr)
        PyMem_Free (buffer)
    
