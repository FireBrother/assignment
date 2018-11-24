import sys
import csv

from nltk.corpus import brown, gutenberg, reuters
from gensim.models import Word2Vec
import numpy as np

sys.path.append('../')
from hw1.data_helper import normalize_tokens, stemmer, global_truth_path, calc_sim

model_path = 'w2v.bin'


def train():
    paras = brown.paras() + gutenberg.paras() + reuters.paras()
    total = len(paras)
    texts = []
    for i, para in enumerate(paras):
        if i % 1000 == 0:
            print(i, total)
        content = ' '.join(map(lambda x: ' '.join(x), para))
        texts.append(normalize_tokens(content))

    w2v = Word2Vec(texts, size=100, window=5, min_count=5, workers=4)
    w2v.save(model_path)


def predict():
    def calc(k1, k2):
        if k1 not in w2v.wv or k2 not in w2v.wv:
            return 0.5
        return w2v.wv.similarity(k1, k2)

    w2v = Word2Vec.load(model_path)
    reader = csv.reader(open(global_truth_path))
    y_pred = []
    y_true = []
    for line in reader:
        w1, w2, score = line
        y_pred.append(calc(*map(stemmer.stem, (w1, w2))))
        y_true.append(float(score))
    print(np.corrcoef(y_pred, y_true))


if __name__ == '__main__':
    # train()
    predict()
