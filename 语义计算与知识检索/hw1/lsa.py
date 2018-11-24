import sys
import csv

import pickle
from nltk.corpus import brown, gutenberg, reuters
from sklearn.decomposition import TruncatedSVD
from sklearn.feature_extraction.text import CountVectorizer
import numpy as np

sys.path.append('../')
from hw1.data_helper import normalize_tokens, stemmer, global_truth_path, calc_sim

model_path = 'lsa.bin'
vocab_path = 'lsa_vocab.bin'


def train():
    paras = brown.paras() + gutenberg.paras() + reuters.paras()
    total = len(paras)
    texts = []
    for i, para in enumerate(paras):
        if i % 1000 == 0:
            print(i, total)
        content = ' '.join(map(lambda x: ' '.join(x), para))
        texts.append(' '.join(normalize_tokens(content)))

    transformer = CountVectorizer()
    tf = transformer.fit_transform(texts)
    svd = TruncatedSVD(n_components=100)
    lsa = svd.fit_transform(tf.T)

    lsa.dump(open(model_path, 'wb'))
    pickle.dump(transformer.vocabulary_, open(vocab_path, 'wb'))


def predict():
    def calc(k1, k2):
        if k1 not in vocab or k2 not in vocab:
            return 0.5
        v1 = lsa[vocab[k1]]
        v2 = lsa[vocab[k2]]
        return calc_sim(v1, v2)

    lsa = np.load(open(model_path, 'rb'))
    vocab = pickle.load(open(vocab_path, 'rb'))
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
