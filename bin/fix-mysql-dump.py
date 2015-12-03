#!/usr/bin/env python

## This script adds "FOREIGN KEY" expressions to the Sprekend Nederland database dump

import sys, re

tablere = re.compile("CREATE TABLE `(\w+)`")
keyre = re.compile("KEY `(\w+)_id_index` \(`(\w+)_id`\)")
#keyre = re.compile("KEY")

for line in sys.stdin:
    m = tablere.search(line)
    if m:
        table = m.group(1)
        i = 1
    m = keyre.search(line)
    if m:
        index = m.group(1)
        key = m.group(2)
        comma = "," if line.strip()[-1] == "," else ""
        print "KEY `%s_id_index` (`%s_id`), CONSTRAINT `%s_ibfk_%d` FOREIGN KEY (`%s_id`) REFERENCES `%s` (`id`)%s ON DELETE CASCADE" % (index, key, table, i, key, key, comma)
        i += 1
    else:
        print line.strip()
