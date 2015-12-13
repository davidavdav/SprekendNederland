#!/usr/bin/env python
## (c) 2015 David A. van Leeuwen

# import sqlalchemy, argparse
import sys

from sqlalchemy.ext.automap import automap_base
from sqlalchemy.orm import Session #, relationship
from sqlalchemy import create_engine, MetaData #, Column, Integer, String, ForeignKey

def nonint(i):
    return i if i else -1

engine = create_engine("mysql://sn@127.0.0.1/sn")

Base = automap_base()

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

if __name__ == "__main__":
    query = session.query(Questions)
    for q in query:
        print "Question %d %s: %d answers" % (q.id, q.question, len(q.tasks_collection))
        for t in q.tasks_collection:
            print "  task %d, recording %d, theme %d" % (t.id, nonint(t.question_recording_id), t.theme_id)
            if t.question_recording_id:
                ## a task about a recording
                for a, r in session.query(Answers, Recordings).filter(Answers.id==t.answer_id, Recordings.id==t.question_recording_id):
                    ## find out the recording text that went with this recording
                    text, _, _ = session.query(Texts, TaskText, Tasks).filter(Texts.id==TaskText.text_id, TaskText.task_id==Tasks.id, Tasks.recording_id==r.id).first()
                    print '    answer %d value %d given by %d about %d utterance "%s"' % (a.id, nonint(a.answer_numeric), t.profile_id, r.profile_id, text.text)
            else:
                ## a metadata task item
                for a in session.query(Answers).filter(Answers.id==t.answer_id):
                    if q.component_id == 1: ## slider
                        print "    answer %d value %d given by %d" % (a.id, nonint(a.answer_numeric), t.profile_id)
                    elif q.component_id == 4: ## location
                        _, loc = session.query(AnswerLocation, Locations).filter(AnswerLocation.answer_id==a.id, AnswerLocation.location_id==Locations.id).first()
                        print "    answer %d value (%8.6f,%8.6f,%d) given by %d" % (a.id, loc.latitude, loc.longitude, loc.mapzoom, t.profile_id)
                    else:
                        _, ao = session.query(AnswerOption, Options).filter(AnswerOption.answer_id==a.id, AnswerOption.option_id==Options.id).first()
                        print "    answer %d value %s given by %d" % (a.id, ao.value, t.profile_id)




