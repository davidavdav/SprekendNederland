#!/usr/bin/env python
## (c) 2015 David A. van Leeuwen

from sn.db import *
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
    prompttext = text.get(task.question_recording_id)
    if prompttext:
        return "/".join(prompttext)
    else:
        return None

def textinfo(rid):
    tt = texttype.get(rid)
    if tt:
        return [tt.key, tt.type]
    else:
        return [None, None]

logging.basicConfig(level=logging.INFO)
#logging.getLogger('sqlalchemy.engine').setLevel(logging.INFO)

## find text with recording_id
text = dict()
speaker = dict()
texttype= dict()
qq = session.query(Tasks, Texts, TextGroups).join(TaskText).filter(TaskText.text_id == Texts.id, TextGroups.id == Texts.text_group_id).order_by(Texts.id)
for ta, te, tg in qq:
    if not ta.recording_id:
        continue
    addto(text, ta.recording_id, norm(te.text))
    if ta.recording_id in speaker:
        if speaker[ta.recording_id] != ta.profile_id:
            print "Inconsistent", speaker[ta.recording_id], ta.profile_id
    else:
        speaker[ta.recording_id] = ta.profile_id
        texttype[ta.recording_id] = tg
logging.info("Number of recordings: %d", len(text))

## main loop over questions
qq = session.query(Questions).join(QuestionGroups, Components).filter(QuestionGroups.name.like("Vragenlijst%"))

print ", ".join([string(x) for x in ["qid", "atype", "qlist", "utype", "lid", "sid", "value", "prompt"]])

for q in qq.filter(Components.type == "slider"):
    logging.info("Question %d: %s", q.id, q.question)
    qid = "q%02d" % q.id
    aq = session.query(Tasks, Answers).filter(Tasks.question_id == q.id, Answers.id == Tasks.answer_id)
    for t, a in aq.order_by(Answers.created_at):
        rid = t.question_recording_id
        print ",".join([string(x) for x in [qid, q.components.type] + textinfo(rid) + [t.profile_id, speaker.get(rid), a.answer_numeric, prompt(t)]])

for q in qq.filter(or_(Components.type == "yesno", Components.type == "option")):
    logging.info("Question %d: %s", q.id, q.question)
    qid = "q%02d" % q.id
    aq = session.query(Tasks, Options).join(Answers, AnswerOption).filter(Tasks.question_id == q.id, AnswerOption.option_id == Options.id)
    for t, o in aq.order_by(Answers.created_at):
        rid = t.question_recording_id
        print ",".join([string(x) for x in [qid, q.components.type] + textinfo(rid) + [t.profile_id, speaker.get(rid), o.value, prompt(t)]])

for q in qq.filter(Components.type == "location"):
    logging.info("Question %d: %s", q.id, q.question)
    qid = "q%02d" % q.id
    aq = session.query(Tasks, Locations).join(Answers, AnswerLocation).filter(Tasks.question_id == q.id, AnswerLocation.location_id == Locations.id)
    for t, l in aq:
        loc = "%8.6f/%8.6f/%d" % (l.longitude, l.latitude, l.mapzoom)
        rid = t.question_recording_id
        print ",".join([string(x) for x in [qid, q.components.type] + textinfo(rid) + [t.profile_id, speaker.get(rid), loc, prompt(t)]])

