#!/usr/bin/env python

# -*- coding: utf-8 -*-

import os

links_to_add = ['.vimrc', '.screenrc', '.hgrc', 'bin']

HOME = os.getenv('HOME', '/home/gvsmirnov')

for link in links_to_add:
    source = HOME + '/.home/' + link
    dest = HOME + '/' + link
    if not os.path.exists(dest):
        print ' + Adding symlink: ' + source + ' -> ' + dest
        os.symlink(source, dest)
    else:
        print ' - File exists: ' + dest
