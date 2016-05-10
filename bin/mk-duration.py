#!/usr/bin/env python

import subprocess, os, csv

with open("durations.csv", "w") as out:
    writer = csv.writer(out, quoting=csv.QUOTE_NONNUMERIC)
    writer.writerow(["pid", "file", "dur"])
    for root, dirs, files in os.walk("audio/upload-sites.omroep.nl"):
        for f in files:
            if f.endswith(".m4a") or f.endswith(".mp4"):
                speaker = os.path.basename(root)
                recfile = os.path.join(speaker, f)
                s = subprocess.Popen("avprobe %s 2>&1 | awk '/Duration/{print $2}'" % os.path.join(root, f), stdout=subprocess.PIPE, shell=True)
                dur = s.stdout.readline().strip()[0:-1]
                if dur:
                    h, m, s = [float(x) for x in dur.split(":")]
                    writer.writerow([speaker, recfile, s + 60 * (m + 60 * h)])
        print root
    
