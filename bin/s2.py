#!/usr/bin/env python

## faster select, do the joins in SQL.

from sn import *

import argparse, sys

## load gender table

p = argparse.ArgumentParser()
p.add_argument("question", type=int)
args = p.parse_args()

question = session.query(Questions).filter(Questions.id == args.question).first()
if not question:
    print "Culd not find question"
    sys.exit(1)

## some metadata: sex
q = session.query(Tasks, Answers, AnswerOption, Options).filter(Tasks.answer_id== Answers.id, AnswerOption.answer_id==Answers.id, AnswerOption.option_id==Options.id, Tasks.question_id==7)
sex = dict()
for t, a, ao, o in q:
    sex[a.profile_id] = o.value

## location (question 3)
q = session.query(Tasks, Answers, AnswerLocation, Locations).filter(Tasks.answer_id== Answers.id, Answers.id == AnswerLocation.answer_id, AnswerLocation.location_id == Locations.id,Tasks.question_id == 3)
loc = dict()
for t, a, al, l in q:
    loc[a.profile_id] = (l.latitude, l.longitude, l.mapzoom)

if question.component_id==1:
    print "speaker", "ssex", "slong", "slat", "listener", "lsex", "llong", "llat", "value"
    q = session.query(Tasks, Answers, Recordings).filter(Tasks.answer_id== Answers.id, Tasks.question_recording_id==Recordings.id, Tasks.question_id==args.question)
    for t, a, r in q:
        sr = sex.get(r.profile_id, "NA")
        sa = sex.get(a.profile_id, "NA")
        sloc = loc.get(r.profile_id, ["NA", "NA"])
        lloc = loc.get(a.profile_id, ["NA", "NA"])
        print r.profile_id, sr, sloc[1], sloc[0], a.profile_id, sa, lloc[1], lloc[0], a.answer_numeric
elif question.component_id==2:
    q = session.query(AnswerOption, Options).filter(AnswerOption.answer_id == Answers.id, AnswerOption.option_id == Options.id)
elif question.component_id==4:
    print "speaker", "slong", "slat", "listener", "llong", "llat", "along", "alat"
    q = session.query(Tasks, Answers, Recordings, AnswerLocation, Locations).filter(Tasks.answer_id== Answers.id, Tasks.question_recording_id==Recordings.id, AnswerLocation.answer_id == Answers.id, AnswerLocation.location_id == Locations.id,  Tasks.question_id==args.question)
    for t, a, r, al, l in q:
        sloc = loc.get(r.profile_id, ["NA", "NA"])
        lloc = loc.get(a.profile_id, ["NA", "NA"])
        if not sloc or not lloc:
            continue
        print r.profile_id, sloc[1], sloc[0], a.profile_id, lloc[1], lloc[0], l.longitude, l.latitude


