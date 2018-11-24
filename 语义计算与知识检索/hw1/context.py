import sys
import csv

import pickle

import IPython
from nltk.corpus import brown, gutenberg, reuters
from sklearn.decomposition import TruncatedSVD
from sklearn.feature_extraction.text import CountVectorizer
import numpy as np

sys.path.append('../')
from hw1.data_helper import normalize_tokens, stemmer, global_truth_path, calc_sim

model_path = 'context.bin'
vocab_path = 'context_vocab.bin'
test_vocab_path = 'context_test_vocab.bin'

window_size = 2


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

    test_vocab = set()

    reader = csv.reader(open(global_truth_path))
    for line in reader:
        w1, w2, score = line
        test_vocab.add(stemmer.stem(w1))
        test_vocab.add(stemmer.stem(w2))
    test_vocab = {k: v for v, k in enumerate(test_vocab)}

    model = np.zeros((len(test_vocab), len(transformer.vocabulary_)))

    for text in texts:
        text = text.split()
        for i in range(len(text)):
            if text[i] not in test_vocab:
                continue
            for j in (i-window_size, i+window_size+1):
                if j < 0 or j >= len(text):
                    continue
                if text[j] not in transformer.vocabulary_:
                    continue
                model[test_vocab[text[i]]][transformer.vocabulary_[text[j]]] += 1
    model.dump(model_path)
    pickle.dump(transformer.vocabulary_, open(vocab_path, 'wb'))
    pickle.dump(test_vocab, open(test_vocab_path, 'wb'))


def predict():
    def calc(k1, k2):
        v1 = context[test_vocab[k1]]
        v2 = context[test_vocab[k2]]
        if sum(v1) == 0 or sum(v2) == 0:
            return 0.5
        return calc_sim(v1, v2)

    context = np.load(open(model_path, 'rb'))
    test_vocab = pickle.load(open(test_vocab_path, 'rb'))
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
