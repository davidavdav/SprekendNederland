#!/usr/bin/env python

from sn import *
from sqlalchemy import or_

import logging

def norm(s):
    return s.strip().decode("unicode_escape").encode("ascii", "ignore")

def addto(d, key, value):
    if not key in d:
        d[key] = []
    d[key].append(value)

def string(x):
    if x == None:
        return "NA"
    elif type(x) == str:
        return '"' + x + '"'
    else:
        return str(x)

def prompt(task):
    sp_text = text.get(task.question_recording_id, None)
    if sp_text:
        return "/".join(sp_text)
    else:
        return None

logging.basicConfig(level=logging.INFO)
#logging.getLogger('sqlalchemy.engine').setLevel(logging.INFO)

## find text with recording_id
text = dict()
speaker = dict()
qq = session.query(Tasks, Texts).join(TaskText).filter(TaskText.text_id == Texts.id).order_by(Texts.id)
for ta, te in qq:
    if not ta.recording_id:
        continue
    addto(text, ta.recording_id, norm(te.text))
    if ta.recording_id in speaker:
        if speaker[ta.recording_id] != ta.profile_id:
            print "Inconsistent", speaker[ta.recording_id], ta.profile_id
    else:
        speaker[ta.recording_id] = ta.profile_id
logging.info("Number of recordings: %d", len(text))

## main loop over questions
qq = session.query(Questions).join(QuestionGroups, Components).filter(QuestionGroups.name.like("Vragenlijst%"))

print ", ".join([string(x) for x in ["qid", "qtype", "lid", "sid", "value", "prompt"]])

for q in qq.filter(Components.type == "slider"):
    logging.info("Question %d: %s", q.id, q.question)
    qid = "q%02d" % q.id
    aq = session.query(Tasks, Answers).filter(Tasks.question_id == q.id, Answers.id == Tasks.answer_id)
    for t, a in aq.order_by(Answers.created_at):
        print ",".join([string(x) for x in [qid, q.components.type, t.profile_id, speaker.get(t.question_recording_id), a.answer_numeric, prompt(t)]])

for q in qq.filter(or_(Components.type == "yesno", Components.type == "option")):
    logging.info("Question %d: %s", q.id, q.question)
    qid = "q%02d" % q.id
    aq = session.query(Tasks, Options).join(Answers, AnswerOption).filter(Tasks.question_id == q.id, AnswerOption.option_id == Options.id)
    for t, o in aq.order_by(Answers.created_at):
        print ",".join([string(x) for x in [qid, q.components.type, t.profile_id, speaker.get(t.question_recording_id), o.value, prompt(t)]])

for q in qq.filter(Components.type == "location"):
    logging.info("Question %d: %s", q.id, q.question)
    qid = "q%02d" % q.id
    aq = session.query(Tasks, Locations).join(Answers, AnswerLocation).filter(Tasks.question_id == q.id, AnswerLocation.location_id == Locations.id)
    for t, l in aq:
        loc = "%8.6f/%8.6f/%d" % (l.longitude, l.latitude, l.mapzoom)
        print ",".join([string(x) for x in [qid, q.components.type, t.profile_id, speaker.get(t.question_recording_id), loc, prompt(t)]])

