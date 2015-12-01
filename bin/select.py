#!/usr/bin/env python
## (c) 2015 David A. van Leeuwen

import sqlalchemy

from sqlalchemy.ext.automap import automap_base
from sqlalchemy.orm import Session
from sqlalchemy import create_engine

Base = automap_base()

engine = create_engine("mysql://sn@127.0.0.1/sn")
Base.prepare(engine, reflect=True)

Questions = Base.classes.questions
session = Session(engine)

for q in session.query(Questions):
    print q.id, q.question
