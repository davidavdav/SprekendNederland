#!/usr/bin/env python
## (c) 2015 David A. van Leeuwen

# import sqlalchemy, argparse
import sys

from sqlalchemy.ext.automap import automap_base
from sqlalchemy.orm import Session #, relationship
from sqlalchemy import create_engine, MetaData #, Column, Integer, String, ForeignKey

engine = create_engine("mysql://sn@127.0.0.1/sn")

metadata = MetaData()
metadata.reflect(engine, only=["questions", "tasks"])

Base = automap_base(metadata=metadata)

#class Question_groups(Base):
#    __tablename__ = "question_groups"
#    id = Column(Integer, primary_key=True)
#    name = Column(String)

#class Questions(Base):
#    __tablename__ = "questions"
#    id = Column(Integer, primary_key=True)
#    question = Column(String)
#    question_group_id = Column(ForeignKey("question_groups.id"))

Base.prepare(engine, reflect=True)

Questions = Base.classes.questions
Tasks = Base.classes.tasks
Themes = Base.classes.themes
Question_groups = Base.classes.question_groups

session = Session(engine)

query = session.query(Questions, Question_groups).filter(Question_groups.id == Questions.question_group_id)
for q, qg in query:
    print q.id, q.question, qg.name, dir(q)

