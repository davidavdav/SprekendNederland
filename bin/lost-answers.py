#!/usr/bin/env python
## (c) 2015 David A. van Leeuwen

## can we find what is going on with answers without questions?

from sn.db import *
from sqlalchemy import func

import logging, argparse, sys

q = session.query(Answers, func.count(Answers.profile_id)).join(Tasks, Questions).group_by(Answers.profile_id)
for a, c in q.filter():
    print c

