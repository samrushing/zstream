# -*- Mode: Python -*-

import zstream
import sys
W = sys.stderr.write

def file_gen (path):
    f = open (path, 'rb')
    while 1:
        block = f.read (8000)
        if not block:
            break
        else:
            yield block

# do it the first time without a dictionary

f0 = open ('/tmp/test.z', 'wb')
for block in zstream.compress (file_gen ('../zstream.pyx'), size=1024):
    W ('compressed %d bytes\n' % (len(block),))
    f0.write (block)
f0.close()

f0 = open ('/tmp/test.txt', 'wb')
for block in zstream.uncompress (file_gen ('/tmp/test.z'), size=1024):
    W ('uncompressed %d bytes\n' % (len(block),))
    f0.write (block)
f0.close()

# try it all again with a dictionary

words = set (open ('../zstream.pyx', 'rb').read().split())
import random
words = list(words)
random.shuffle (words)
zdict = ''.join (words)

f0 = open ('/tmp/test_dict.z', 'wb')
for block in zstream.compress (file_gen ('../zstream.pyx'), size=1024, dict=zdict):
    W ('compressed %d bytes\n' % (len(block),))
    f0.write (block)
f0.close()

f0 = open ('/tmp/test_dict.txt', 'wb')
for block in zstream.uncompress (file_gen ('/tmp/test_dict.z'), size=1024, dict=zdict):
    W ('uncompressed %d bytes\n' % (len(block),))
    f0.write (block)
f0.close()
