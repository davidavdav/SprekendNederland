#!/usr/bin/env python

## This script extracts all metadata, and generates a big table

from sn import *
from sqlalchemy import or_

import logging, argparse, sys

def addto(d, key1, key2, value):
    if not key1 in d:
        d[key1] = dict()
    d[key1][key2] = value

def string(x):
    if x == None:
        return "NA"
    elif type(x) == str:
        return '"'+x+'"'
    else:
        return str(x)

logging.basicConfig(level=logging.INFO)

qq = session.query(Questions).join(QuestionGroups, Components).filter(QuestionGroups.name == "Meta vragen")

meta = dict()
cols = set()
for q in qq.filter(or_(Components.type == "yesno", Components.type == "option")):
    logging.info("Question %d: %s", q.id, q.question)
    qid = "q%02d" % q.id
    cols.add(qid)
    aq = session.query(Tasks, Options).join(Answers, AnswerOption).filter(Tasks.question_id == q.id, AnswerOption.option_id == Options.id)
    for t, o in aq:
        pid = t.profile_id
        addto(meta, pid, qid, o.value)

for q in qq.filter(Components.type == "slider"):
    logging.info("Question %d: %s", q.id, q.question)
    qid = "q%02d" % q.id
    cols.add(qid)
    aq = session.query(Answers).join(Tasks).filter(Tasks.question_id == q.id)
    for a in aq:
        pid = a.profile_id
        addto(meta, pid, qid, a.answer_numeric)

for q in qq.filter(Components.type == "location"):
    logging.info("Question %d: %s", q.id, q.question)
    qids = ["q%02d-%s" % (q.id, s) for s in ["long", "lat", "zoom"]]
    for qid in qids:
        cols.add(qid)
    aq = session.query(Tasks, Locations).join(Answers, AnswerLocation).filter(Tasks.question_id == q.id, AnswerLocation.location_id == Locations.id)
    for t, l in aq:
        pid = t.profile_id
        if not pid in meta:
            meta[pid] = dict()
        for k, v in zip(qids, [l.longitude, l.latitude, l.mapzoom]):
            meta[pid][k] = v

logging.info("Total %d pids found", len(meta))
## dump the data in a big table
cols = sorted(cols)
print  ",".join([string(col) for col in ["pid"] + cols])
for pid in sorted(meta.keys()):
    m = meta[pid]
    print ",".join([string(pid)] + [string(m.get(qid)) for qid in cols])


