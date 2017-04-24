#!/usr/bin/python

import re
import sys

def iniGet(key, cfg_file):
    ini_file = open(cfg_file, 'r')
    pattern = r'[ |\t]*' + key + r'[ |\t]*=[ |\t]*'
    value_m = r'"*([^"\|\r]*)"*'

    for line in ini_file:
        if re.match(pattern, line):
            value = re.sub(pattern + value_m + '.*', r'\1', line)
            print value

iniGet(sys.argv[1], sys.argv[2])
