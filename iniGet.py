#!/usr/bin/python

import re
import sys

def ini_get(key, cfg_file):
    try:
        ini_file = open(cfg_file, 'r')
    except:
        return ""
    
    pattern = r'[ |\t]*' + key + r'[ |\t]*=[ |\t]*'
    value_m = r'"*([^"\|\r]*)"*'
    value = ""
    for line in ini_file:
        if re.match(pattern, line):
            value = re.sub(pattern + value_m + '.*', r'\1', line)
            break
    ini_file.close()
    return value

print ini_get(sys.argv[1], sys.argv[2])
