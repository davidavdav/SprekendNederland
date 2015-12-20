#!/usr/bin/env python

import csv, os, math, random
from . import Base, session

ignore = ["password_resets", "migrations", "messages", "sessions"]
earthcirc = 40075
kmperdg =  {"longitude": earthcirc/360/math.sin(52*math.pi/180), "latitude": earthcirc/360}

def dump(dir="tables/dump", limited=True):
    m = Base.metadata
    tables = m.tables.values();
    if limited:
        tables = [t for t in tables if t not in ignore]
    for table in tables:
        fd = csv.writer(open(os.path.join(dir, table.name), "w"), quoting=csv.QUOTE_NONNUMERIC)
        fd.writerow([c.name for c in table.columns])
        fudge = {i:1.0/kmperdg[c.name] for i,c in enumerate(table.columns) if c.name in kmperdg}
        if table.name == "locations":
            for k in fudge.keys():
                fudge[k] = 0.0
        print table.name, fudge
        q = session.query(table)
        for r in q.yield_per(100):
            row =[]  ## local, writeable copy of result row
            for i, x in enumerate(r)
                if i in fudge and x:
                    x = round(float(x) + random.gauss(0, fudge[i]), 6)
                if not
            fd.writerow(r)


