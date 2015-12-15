#!/usr/bin/env python

from sqlalchemy.ext.automap import automap_base
from sqlalchemy.orm import Session #, relationship
from sqlalchemy import create_engine, MetaData #, Column, Integer, String, ForeignKey

engine = create_engine("mysql://sn@127.0.0.1/sn")

Base = automap_base()

Base.prepare(engine, reflect=True)

Questions = Base.classes.questions
Tasks = Base.classes.tasks
Themes = Base.classes.themes
QuestionGroups = Base.classes.question_groups
AnswerLocation = Base.classes.answer_location
Locations = Base.classes.locations
AnswerOption = Base.classes.answer_option
Options = Base.classes.options
Answers = Base.classes.answers
Components = Base.classes.components
Recordings = Base.classes.recordings
Texts = Base.classes.texts
TaskText = Base.classes.task_text

session = Session(engine)

