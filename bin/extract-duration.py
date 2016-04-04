#!/usr/bin/env python

import subprocess, os

for root, dirs, files in os.walk("audio", topdown=False):
    for f in files:
        if f.endswith(".m4a") ||
        print os.path.join(root,f)

