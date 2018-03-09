#!/usr/bin/env python3

patch_file = 'etc/X11/Xwrapper.config.patch'
config_file = '/etc/X11/Xwrapper.config'

with open(patch_file, 'r') as pf, open(config_file, 'w') as cf:
    cf.writelines(pf)
