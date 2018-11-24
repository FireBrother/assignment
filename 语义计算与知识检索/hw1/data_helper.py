import string

import nltk
from nltk import PorterStemmer
from nltk.corpus import stopwords
import numpy as np

translator = str.maketrans('', '', string.punctuation)
stemmer = PorterStemmer()

global_truth_path = 'MTURK-771.csv'


def normalize_tokens(sent):
    sent = sent.translate(translator).lower()
    tokens = nltk.word_tokenize(sent)
    tokens = list(map(lambda x: stemmer.stem(x), filter(lambda y: y not in stopwords.words('english'), tokens)))
    return tokens


def calc_sim(v1, v2):
    return 0.5 + 0.5 * v1.dot(v2) / (np.linalg.norm(v1) * np.linalg.norm(v2))


if __name__ == '__main__':
    print(normalize_tokens('I have a dream, one day...'))
