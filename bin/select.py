#!/usr/bin/env python
## (c) 2015 David A. van Leeuwen

import MySQLdb

db = MySQLdb.connect(read_default_file="~/.my.cnf")
c = db.cursor()

c.execute("""select * from questions""", ())

for row in c:
    print " ".join([str(x) for x in row[0:2]])
