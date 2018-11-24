import torch
from torch import LongTensor
import torch.nn as nn
import torch.nn.functional as F
from torch.autograd import Variable
from torch.nn.utils.rnn import pack_padded_sequence, pad_packed_sequence
import numpy as np
import IPython


class Classifier(nn.Module):
    def __init__(self, config):
        super(Classifier, self).__init__()
        print(config)
        self.config = config

        self.embedding = nn.Embedding(config['vocab_size'], config['embedding_size'])
        self.rnn_feature = nn.LSTM(config['embedding_size'], config['rnn_hidden_size'],
                                           config['rnn_num_layers'], batch_first=True, dropout=0.1)
        self.classifier = nn.Linear(config['rnn_hidden_size'], config['num_categories'])

    def init_weights(self, weightings=None):
        if weightings is None:
            self.embedding.weight.data.uniform_(-0.1, 0.1)
        else:
            self.embedding.weight.data.copy_(weightings)

    def forward(self, sentences, sentences_len, hidden):
        sentences_len = sentences_len.cpu().data.numpy()

        idx = np.argsort(sentences_len).tolist()[::-1]
        ridx = np.argsort(idx).tolist()

        sentences = sentences[idx, :]
        sentences_len = sentences_len[idx, ]
        embedding = self.embedding(sentences)
        embedding = nn.Dropout(0.1)(embedding)

        packed_embedding = pack_padded_sequence(embedding, sentences_len, batch_first=True)
        packed_rnn_feature, hidden = self.rnn_feature(packed_embedding, hidden)
        sentence_feature, _ = pad_packed_sequence(packed_rnn_feature, batch_first=True)

        idx = Variable(LongTensor(sentences_len - 1))
        idx = idx.view(-1, 1).expand(sentence_feature.size(0), sentence_feature.size(2)).unsqueeze(1)
        if sentence_feature.is_cuda:
            idx = idx.cuda()
        sentence_feature = sentence_feature.gather(1, idx).squeeze()

        sentence_feature = sentence_feature[ridx, :]
        sentences_len = sentences_len[ridx, ]

        logits = self.classifier(sentence_feature)
        pred = F.log_softmax(logits, dim=0)
        return pred

    def init_hidden(self, bsz):
        weight = next(self.rnn_feature.parameters()).data
        return (Variable(weight.new(self.config['rnn_num_layers'], bsz, self.config['rnn_hidden_size']).zero_()),
                Variable(weight.new(self.config['rnn_num_layers'], bsz, self.config['rnn_hidden_size']).zero_()))
