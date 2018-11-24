import math
import sys
import time

import IPython
import torch
import torch.nn as nn
import torch.optim as optim
from torch.autograd import Variable
from torch.optim.lr_scheduler import LambdaLR
from torch.utils.data import DataLoader

sys.path.append('..')
from hw2.model import Classifier
from hw2.data_helper import TwitterDataSet
from hw2.utils import evaluate_labels

USE_GPU = False

train_set = TwitterDataSet('data/vocab.txt', 'data/train.txt')
dev_set = TwitterDataSet('data/vocab.txt', 'data/dev.txt')
test_set = TwitterDataSet('data/vocab.txt', 'data/test.txt')
trainloader = DataLoader(train_set, batch_size=64, shuffle=True)
testloader = DataLoader(test_set, batch_size=64)
config = {
    'embedding_size': 200,
    'vocab_size': max(train_set.word2idx.values())+1,
    'rnn_hidden_size': 200,
    'rnn_num_layers': 1,
    'num_categories': 3
}

clf = Classifier(config)
if USE_GPU:
    print('use GPU mode')
    clf = clf.cuda()
loss_function = nn.CrossEntropyLoss()
optimizer = optim.Adagrad(clf.parameters(), lr=0.01)
scheduler = LambdaLR(optimizer, [lambda x: 0.8 ** x])
# scheduler = StepLR(optimizer, step_size=2, gamma=0.8)

log_interval = 5
epochs = 10


def train(dataloader):
    clf.train()
    total_loss = 0
    start_time = time.time()
    for i_batch, sample_batched in enumerate(dataloader):
        inputs = Variable(sample_batched['input'])
        sent_len = Variable(sample_batched['len'])
        true_outputs = Variable(sample_batched['output'])
        hidden = clf.init_hidden(inputs.shape[0])
        if USE_GPU:
            inputs = inputs.cuda()
            sent_len = sent_len.cuda()
            true_outputs = true_outputs.cuda()
        clf.zero_grad()
        outputs = clf.forward(inputs, sent_len, hidden)
        loss = loss_function(outputs, true_outputs)
        loss.backward()
        total_loss += loss.data
        optimizer.step()

        if i_batch % log_interval == 0 and i_batch > 0:
            cur_loss = total_loss[0] / log_interval
            elapsed = time.time() - start_time
            print('| epoch {:3d} | {:5d}/{:5d} batches | lr {:04.4f} | ms/batch {:5.2f} | '
                  'loss {:5.2f} | ppl {:8.2f}'.format(
                epoch, i_batch, len(dataloader.dataset) // dataloader.batch_size, optimizer.param_groups[0]['lr'],
                                elapsed * 1000 / log_interval, cur_loss, math.exp(cur_loss)))
            total_loss = 0
            start_time = time.time()


def dev_evaluate(dataloader):
    total_loss = 0
    for batch in dataloader:
        inputs = Variable(batch['input'])
        sent_len = Variable(batch['len'])
        true_outputs = Variable(batch['output'])
        hidden = clf.init_hidden(inputs.shape[0])
        if USE_GPU:
            inputs = inputs.cuda()
            sent_len = sent_len.cuda()
            true_outputs = true_outputs.cuda()
        outputs = clf.forward(inputs, sent_len, hidden)
        outputs = outputs.detach()
        total_loss += len(batch.values()[0]) * loss_function(outputs, true_outputs).data
    return total_loss[0] / len(dataloader.dataset)


def evaluate(dataloader):
    y_pred = []
    y_true = []
    for batch in dataloader:
        inputs = Variable(batch['input'])
        sent_len = Variable(batch['len'])
        true_outputs = Variable(batch['output'])
        hidden = clf.init_hidden(inputs.shape[0])
        if USE_GPU:
            inputs = inputs.cuda()
            sent_len = sent_len.cuda()
            true_outputs = true_outputs.cuda()
        outputs = clf.forward(inputs, sent_len, hidden)
        outputs = outputs.detach()
        _, pred = torch.max(outputs, 1)
        y_pred.extend(pred.data)
        y_true.extend(true_outputs.data)
    return evaluate_labels(y_true, y_pred)

try:
    best_val_loss = 1000
    clf.init_weights()
    for epoch in range(1, epochs + 1):
        # scheduler.step()
        epoch_start_time = time.time()
        train(trainloader)
        val_loss = evaluate(testloader)
        print('-' * 89)
        print('| end of epoch {:3d} | time: {:5.2f}s | valid loss {:5.2f} | '
              'valid ppl {:8.2f}'.format(epoch, (time.time() - epoch_start_time),
                                         val_loss, math.exp(val_loss)))
        print('-' * 89)
        # Save the model if the validation loss is the best we've seen so far.
        if not best_val_loss or val_loss < best_val_loss:
            with open('model.pkl', 'wb') as f:
                torch.save(clf, f)
            best_val_loss = val_loss
        else:
            # Anneal the learning rate if no improvement has been seen in the validation dataset.
            pass
except KeyboardInterrupt:
    print('-' * 89)
    print('Exiting from training early')

evaluate(testloader)
