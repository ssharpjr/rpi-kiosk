#!/usr/bin/env python3

patch_file = 'etc/rc.local.patch'
config_file = '/etc/rc.local'

with open(patch_file) as pf, open(config_file, 'w') as cf:
    cf.writelines(pf)
