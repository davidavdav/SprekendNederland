#!/usr/bin/env python

## Prepare data for scikit-learn.
## input: <category>.txt file, 1 doc / line
## output: categories/<category>/<i>.txt, 1 doc/file

import argparse, os

if __name__ == "__main__":
    p = argparse.ArgumentParser()
    p.add_argument("catfiles", nargs="+", help="Files: 1 file/category, 1 line/document")
    p.add_argument("--destdir", default="categories")
    args = p.parse_args()
    for file in args.catfiles:
        cat, _ = os.path.splitext(os.path.basename(file))
        dir = os.path.join(args.destdir, cat)
        if not os.path.isdir(dir):
            os.mkdir(dir)
        for i, doc in enumerate(open(file)):
            with open(os.path.join(dir, "%d.txt" % i), "w") as fd:
                fd.write(doc)

