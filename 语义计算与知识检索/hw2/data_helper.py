import json

from torch.utils.data import Dataset
import numpy as np


class TwitterDataSet(Dataset):
    def __init__(self, vocab_path, data_path, max_sentence_len=100):
        self.vocab = json.load(open(vocab_path))
        self.word2idx = {k: v for v, k in enumerate(self.vocab)}
        self.sentences = []
        self.sentence_len = []
        self.cates = []
        self.max_sentence_len = max_sentence_len
        for line in open(data_path):
            cate, tokens = line.split('\t')
            tokens = tokens.split()
            self.cates.append(int(cate))
            self.sentence_len.append(min(len(tokens), max_sentence_len))
            ids = list(map(lambda x: self.word2idx.get(x, 0), tokens))
            ids = ids[:max_sentence_len] + [0]*(max_sentence_len-len(tokens))
            self.sentences.append(ids)

    def __len__(self):
        return len(self.sentences)

    def __getitem__(self, index):
        sample = {'input': np.array(self.sentences[index]),
                  'len': self.sentence_len[index],
                  'output': self.cates[index]}
        return sample
