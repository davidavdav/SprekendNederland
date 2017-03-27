#!/usr/bin/env python
## (c) 2016 David A. van Leeuwen

import random
import os

from sn.tables import dump

if not "SEED" in os.environ:
    raise ValueError("Run as SEED=seed dump-tables.py")

random.seed(int(os.environ["SEED"]))
dump()
