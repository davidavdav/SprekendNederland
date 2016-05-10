#!/usr/bin/env python

## routines for dealing with sklearn

from sklearn.feature_extraction.text import CountVectorizer
from sklearn.feature_extraction.text import TfidfTransformer
from sklearn.naive_bayes import MultinomialNB
from sklearn.pipeline import Pipeline

import os

def read_category(name):
    file = os.path.join("lists", "themes", name + ".txt")
    with open(file) as fd:
        lines = fd.readlines()
        return lines

def read_categories():
    themes = []
    lines = []
    categories = ["afgekeurd", "flirten", "muziek", "vakantie", "wonen"]
    for i, theme in enumerate(categories):
        l = read_category(theme)
        lines += l
        themes += [i] * len(l)
    return lines, themes, categories

def model():
    lines, themes, categories = read_categories()
    classifier = Pipeline([("vect", CountVectorizer()),
                           ("tfidf", TfidfTransformer()),
                           ("classifier", MultinomialNB()),
                           ])
    return classifier.fit(lines, themes), categories

