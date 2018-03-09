#!/usr/bin/env python3

patch_file = 'boot/config.txt.patch'
config_file = '/boot/config.txt'

with open(patch_file, 'r') as pf, open(config_file, 'a') as cf:
    cf.writelines(pf)
