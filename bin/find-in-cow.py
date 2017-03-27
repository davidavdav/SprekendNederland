#!/usr/bin/env python

## Find sentences in COW text, so that we can find sentences not belonging to the classes as counter-examplens. 

import argparse, os, sys

if __name__ == "__main__":
    p = argparse.ArgumentParser()
    p.add_argument("classfiles", nargs="+")
    p.add_argument("--nlast", type=int, help="Number of sentences without any class seen in a row necessary to stop procesing", default=1000)
    p.add_argument("--write-to", type=str, dest="write_to")
    args = p.parse_args()

    d = dict()
    for file in args.classfiles:
        base, _ = os.path.splitext(os.path.basename(file))
        for i, line in enumerate(open(file)):
            id = "%s %d" % (base, i)
            d[line] = id

    if args.write_to:
        fd = open(args.write_to, "w")

    i = 0
    n = 0 ## since last seen
    nfound = 0

    for line in sys.stdin:
        if line in d:
            print d[line], line.strip()
            n = 0
            nfound += 1
        else:
            print "other", i, line.strip()
            if args.write_to:
                fd.write(line)
            i += 1
            n += 1
        if n > args.nlast:
            break
    print >>sys.stderr, "Found", nfound


