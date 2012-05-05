# -*- Mode: Cython -*-

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
    
