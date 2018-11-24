import json
import random
from collections import defaultdict, Counter

import os

def evaluate_labels(y_true, y_pred, ids=None, output=True):
    right = defaultdict(int)
    if ids is None:
        for y1, y2 in zip(y_true, y_pred):
            if y1 == y2:
                right[y2] += 1
    else:
        for y1, y2, id in zip(y_true, y_pred, ids):
            if y1 == y2:
                right[y2] += 1
    p = defaultdict(float)
    r = defaultdict(float)
    f = defaultdict(float)
    for k in right:
        p[k] = 1.0 * right[k] / len([i for i in y_pred if i == k])
        r[k] = 1.0 * right[k] / len([i for i in y_true if i == k])
        f[k] = 2.0 * p[k] * r[k] / (p[k] + r[k] + 0.0000001)
    if output:
        print('evaluation')
        for k in right:
            print('\tlabel:{} precision={:.4f}, recall={:.4f}, fmeasure={:.4f}'.format(k, p[k], r[k], f[k]))
    precision = 1.0 * sum([v for v in right.values()]) / len(y_pred)
    print('accuracy={:.4f}'.format(precision))
    return precision


def gen_corpus():
    from ekphrasis.classes.preprocessor import TextPreProcessor
    from ekphrasis.classes.tokenizer import SocialTokenizer
    from ekphrasis.dicts.emoticons import emoticons

    def extract(d, line):
        v = line.split('\t')
        cate = v[-2]
        sentence = v[-1]
        if len(cate) > 20:
            cate = v[-3]
            sentence = v[-2]
        if cate not in d:
            return None, None
        cate = d[cate]
        tokens = text_processor.pre_process_doc(sentence)
        return cate, tokens

    text_processor = TextPreProcessor(
        # terms that will be normalized
        normalize=['url', 'email', 'percent', 'money', 'phone', 'user',
                   'time', 'url', 'date', 'number'],
        # terms that will be annotated
        annotate={"hashtag", "allcaps", "elongated", "repeated",
                  'emphasis', 'censored'},
        fix_html=True,  # fix HTML tokens

        # corpus from which the word statistics are going to be used
        # for word segmentation
        segmenter="twitter",

        # corpus from which the word statistics are going to be used
        # for spell correction
        corrector="twitter",

        unpack_hashtags=True,  # perform word segmentation on hashtags
        unpack_contractions=True,  # Unpack contractions (can't -> can not)
        spell_correct_elong=False,  # spell correction for elongated words

        # select a tokenizer. You can use SocialTokenizer, or pass your own
        # the tokenizer, should take as input a string and return a list of tokens
        tokenizer=SocialTokenizer(lowercase=True).tokenize,

        # list of dictionaries, for replacing tokens extracted from the text,
        # with other expressions. You can pass more than one dictionaries.
        dicts=[emoticons]
    )
    for a, b, c in os.walk('2017_English_final/GOLD'):
        for cc in c:
            if cc == 'README.txt' or cc == '.DS_Store':
                continue
            path = os.path.join(a, cc)
            print(path)
            if a.endswith('A') or a.endswith('BD'):
                d = {
                    'negative': 0,
                    'neutral': 1,
                    'positive': 2
                }
            elif a.endswith('CE'):
                d = {
                    '-1': 0,
                    '-2': 0,
                    '0': 1,
                    '1': 2,
                    '2': 2
                }
            else:
                raise ValueError('Not supported task: {} {}'.format(a, cc))
            if random.random() > 0.888889:
                of = open('dev.txt', 'a')
            else:
                of = open('train.txt', 'a')
            for line in open(path, errors='ignore'):
                cate, tokens = extract(d, line)
                if cate is not None and tokens is not None:
                    try:
                        of.write('{}\t{}\n'.format(cate, ' '.join(tokens)))
                    except UnicodeEncodeError:
                        pass
    path = 'SemEval2017-task4-test/SemEval2017-task4-test.subtask-A.english.txt'
    d = {
        'negative': 0,
        'neutral': 1,
        'positive': 2
    }
    of = open('test.txt', 'a')
    for line in open(path, errors='ignore'):
        cate, tokens = extract(d, line)
        if cate is not None and tokens is not None:
            try:
                of.write('{}\t{}\n'.format(cate, ' '.join(tokens)))
            except UnicodeEncodeError:
                pass


def analyze_corpus():
    tf = Counter()
    max_len = 0
    paths = ['data/train.txt', 'data/test.txt', 'data/dev.txt']
    for path in paths:
        for line in open(path):
            tokens = line.split('\t')[1].split()
            max_len = max(max_len, len(tokens))
            tf.update(tokens)
    vocab = ['OOV']
    for t in tf:
        if tf[t] > 5:
            vocab.append(t)
    json.dump(vocab, open('vocab.txt', 'w'))
    print(max_len)
    print(len(vocab))


if __name__ == '__main__':
    # gen_corpus()
    analyze_corpus()

    # sentences = [
    #     "CANT WAIT for the new season of #TwinPeaks ＼(^o^)／!!! #davidlynch #tvseries :)))",
    #     "I saw the new #johndoe movie and it suuuuucks!!! WAISTED $10... #badmovies :/",
    #     "@SentimentSymp:  can't wait for the Nov 9 #Sentiment talks!  YAAAAAAY !!! :-D http://sentimentsymposium.com/."
    # ]
    # for s in sentences:
    #     print(" ".join(text_processor.pre_process_doc(s)))
