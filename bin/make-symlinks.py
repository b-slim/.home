#!/usr/bin/env python
# -*- coding: utf-8 -*-

import os

links_to_add = ['.vimrc', '.screenrc', '.hgrc', 'bin']

HOME = os.getenv('HOME', '/home/gvsmirnov')
ROOT = os.path.abspath(
    os.path.join(
        os.path.dirname(os.path.abspath( __file__ )),
        os.pardir
    )
)

for link in links_to_add:
    source = os.path.join(ROOT, link)
    dest = os.path.join(HOME, link)

    print source + ', ' + dest

    def link_file(dest, source):
        if not os.path.exists(dest):
            print ' + Adding symlink: ' + dest + ' -> ' + source
            os.symlink(source, dest)
        else:
            print ' - File exists: ' + dest

    if os.path.isfile(source):
        link_file(dest, source)
    elif os.path.isdir(source): #TODO: consider nested directories
        if os.path.islink(dest):
            print ' ! Encountered a target dir that is a symlink, skipping' + dest
        else:
            if not os.path.exists(dest):
                print ' + Making dir: ' + dest
                os.makedirs(dest)
            for file_name in os.listdir(source):
                link_file(os.path.join(dest, file_name), os.path.join(source, file_name))
