#!/usr/bin/env python
## (c) 2015 David A. van Leeuwen

## Simply dump all tables from the database.
## The can probably be done more efficiently using MySQL directly,
## but probably also requires a lot more weaseling

## This program fudges locations in the tables "answers" and "recordings"
## with a random Gaussian noise of approximately 1 km for privacy reasons.

import os, math, random
from . import Base, session


def string(x):
    """Helper function for writing tables in csv format"""
    if x == None:
        return "NA"
    elif type(x) in [int, long, float]:
        return str(x)
    else:
        return '"' + str(x).replace('"', '""') + '"'

def writerow(fd, row):
    print >>fd, ",".join([string(x) for x in row])

ignore = ["password_resets", "migrations", "messages", "sessions"]
earthcirc = 40075.0 ## km
kmperdg =  {"longitude": earthcirc/360/math.sin(52*math.pi/180), "latitude": earthcirc/360}

def dump(dir="tables/dump", limited=True):
    m = Base.metadata
    tables = m.tables.values();
    if limited:
        tables = [t for t in tables if t.name not in ignore]
    for table in tables:
        fd = open(os.path.join(dir, table.name + ".csv"), "w")
        writerow(fd, [c.name for c in table.columns])
        fudge = {i:1.0/kmperdg[c.name] for i,c in enumerate(table.columns) if c.name in kmperdg}
        if table.name == "locations":
            for k in fudge.keys():
                fudge[k] = 0.0
        print table.name, fudge
        q = session.query(table)
        for r in q.yield_per(100):
            row =[]  ## local, writeable copy of result row
            for i, x in enumerate(r):
                if i in fudge and x:
                    row.append(round(float(x) + random.gauss(0, fudge[i]), 6))
                else:
                    row.append(x)
            writerow(fd, row)
