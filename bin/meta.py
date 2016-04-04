#!/usr/bin/env python
## (c) 2015 David A. van Leeuwen

## This script extracts all metadata, and generates a big table

## We distort location information by random gaussian noise of about one km

from sqlalchemy import or_
import logging, random, argparse

from sn import *
from sn.tables import kmperdg

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

def distort(location, sd):
    l = location.__dict__
    for kind in ["longitude", "latitude"]:
        l[kind] = float(l[kind]) + random.gauss(0, sd/kmperdg[kind])
    return l

if __name__ == "__main__":

    p = argparse.ArgumentParser()
    p.add_argument("--no-distort", action="store_false", dest="distort")
    args = p.parse_args()

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

    sd = 1.0 if args.distort else 0.0 ## standard deviation (in km) for random noise added
    for q in qq.filter(Components.type == "location"):
        logging.info("Question %d: %s", q.id, q.question)
        qid = "q%02d" % q.id
        cols.add(qid)
        aq = session.query(Tasks, Locations).join(Answers, AnswerLocation).filter(Tasks.question_id == q.id, AnswerLocation.location_id == Locations.id)
        for t, l in aq:
            pid = t.profile_id
            loc = distort(l, sd)
            addto(meta, pid, qid, "%8.6f/%8.6f/%d" % (loc["longitude"], loc["latitude"], l.mapzoom))
            ## in R, split such a column using
            ## spl <- function(x, n) as.numeric(strsplit(as.character(x), "/")[[1]][n])
            ## q03long <- mapply(spl, m$q03, 1)

    logging.info("Total %d pids found", len(meta))
    ## dump the data in a big table
    cols = sorted(cols)
    print  ",".join([string(col) for col in ["pid"] + cols])
    for pid in sorted(meta.keys()):
        m = meta[pid]
        print ",".join([string(pid)] + [string(m.get(qid)) for qid in cols])


