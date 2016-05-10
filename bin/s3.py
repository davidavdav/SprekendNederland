#!/usr/bin/env python
## (c) 2015 David A. van Leeuwen

from sn.db import *

import argparse, sys

## load gender table

p = argparse.ArgumentParser()
p.add_argument("question", type=int)
args = p.parse_args()

question = session.query(Questions).filter(Questions.id == args.question)
if not question:
    print "Culd not find question"
    sys.exit(1)

q = session.query(Tasks).join("question_recording_id").filter(Tasks.question_id==args.question)
for t in q:
    print t.recordings.profile_id
