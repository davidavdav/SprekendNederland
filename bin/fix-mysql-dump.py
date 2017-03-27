#!/usr/bin/env python
## (c) 2015 David A. van Leeuwen

## This script adds "FOREIGN KEY" expressions to the Sprekend Nederland database dump

import sys, re

tablere = re.compile("CREATE TABLE `(\w+)`")
keyre = re.compile("KEY `(\w+)_id_index` \(`(\w+)_id`\)")
skipre = re.compile("(CREATE TABLE|LOCK TABLES|INSERT INTO|ALTER TABLE) `(users|password_resets)`")
line1re = re.compile("(\s+KEY `sessions_user_id_index` \(`user_id`\)),")
line2re = re.compile("\s+CONSTRAINT `sessions_user_id_foreign` FOREIGN KEY \(`user_id`\) REFERENCES `users` \(`id`\)")
#keyre = re.compile("KEY")

ignore = ["question_recording", "user"]

skipping = False
for line in sys.stdin:
    if skipping:
        if line.strip() == "":
            skipping = False
        continue
    if skipre.search(line):
        skipping = True
        continue
    m = line1re.match(line)
    if m:
        print m.group(1)
        continue
    if line2re.match(line):
        continue
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
