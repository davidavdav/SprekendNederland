#!/usr/bin/env python

## This script adds "FOREIGN KEY" expressions to the Sprekend Nederland database dump

import sys, re

tablere = re.compile("CREATE TABLE `(\w+)`")
keyre = re.compile("KEY `(\w+)_id_index` \(`(\w+)_id`\)")
#keyre = re.compile("KEY")

ignore = ["question_recording", "user"]

for line in sys.stdin:
    m = tablere.search(line)
    if m:
        table = m.group(1)
        i = 1
    m = keyre.search(line)
    if m:
        index = m.group(1)
        key = m.group(2)
        if not key in ignore:
            comma = "," if line.strip()[-1] == "," else ""
            print " KEY `%s_id_index` (`%s_id`),\n CONSTRAINT `%s_ibfk_%d` FOREIGN KEY (`%s_id`) REFERENCES `%ss` (`id`) ON DELETE CASCADE%s" % (index, key, table, i, key, key, comma)
            i += 1
            continue

    line = line.replace("ENGINE=MyISAM", "ENGINE=InnoDB")
    print line.strip()
