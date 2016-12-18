import random
from collections import defaultdict

import numpy as np
import math
from sklearn import tree
from sklearn.ensemble import RandomForestClassifier


def load_data(filename):
    X = []
    y = []
    with open(filename) as f:
        for line in f:
            v = [float(x) for x in line.split()]
            X.append(v[:-1])
            y.append(int(v[-1]))
    X = np.array(X)
    y = np.array(y)
    index = range(len(X))
    random.shuffle(index)

    X_train = X[index[:int(0.8 * len(X))]]
    y_train = y[index[:int(0.8 * len(y))]]
    X_test = X[index[int(0.8 * len(X)):]]
    y_test = y[index[int(0.8 * len(y)):]]
    return X_train, y_train, X_test, y_test


class SimpleClassifier:
    def __init__(self, X, y):
        self.X = X
        self.y = y
        self.classifier = tree.DecisionTreeClassifier(criterion="entropy")
        # self.classifier = RandomForestClassifier(criterion="entropy")

    def fit(self):
        self.classifier.fit(self.X, self.y)

    def test(self, X, y):
        correct = 0
        pred = self.classifier.predict(X)
        for a, b in zip(pred, y):
            correct += 1 if a == b else 0
        print '[SimpleClassifier] Precision is {:.2f}%.'.format(100.0 * correct / len(X))


class AdaBoost:
    def __init__(self, X, y, K):
        self.X = X
        self.y = y
        self.K = K
        self.basic_classifiers = [tree.DecisionTreeClassifier(criterion="entropy") for _ in xrange(self.K)]
        self.weight = [0] * self.K

    def fit(self):
        part = len(self.X) / self.K
        index = range(len(self.X))
        random.shuffle(index)
        index_part = [index[i * part:min((i + 1) * part, len(self.X))] for i in xrange(self.K)]
        for i in xrange(self.K):
            self.basic_classifiers[i].fit(self.X[index_part[i]], self.y[index_part[i]])
            X_test = []
            y_test = []
            for j in range(self.K):
                if i != j:
                    X_test.extend(self.X[index_part[j]])
                    y_test.extend(self.y[index_part[j]])
            pred = self.basic_classifiers[i].predict(X_test)
            error = 0
            for a, b in zip(pred, y_test):
                error += 1 if a != b else 0
            eps = 1.0 * error / 9000
            alpha = 0.5 * math.log((1 - eps) / eps)
            self.weight[i] = alpha
        print 'weight is {}'.format(self.weight)

    def test(self, X, y):
        res = []
        correct = 0
        for classifier in self.basic_classifiers:
            res.append(classifier.predict(X))
        for i in xrange(len(X)):
            count = defaultdict(int)
            for j in xrange(len(self.basic_classifiers)):
                count[res[j][i]] += self.weight[j]
            pred = 0
            maxcount = 0
            for k in count:
                if count[k] > maxcount:
                    pred = k
                    maxcount = count[k]
            if pred == y[i]:
                correct += 1
        print '[AdaBoost] Precision is {:.2f}%.'.format(100.0 * correct / len(X))


if __name__ == '__main__':
    X_train, y_train, X_test, y_test = load_data('B.txt')
    simple = SimpleClassifier(X_train, y_train)
    adaboost = AdaBoost(X_train, y_train, 100)
    simple.fit()
    adaboost.fit()
    simple.test(X_test, y_test)
    adaboost.test(X_test, y_test)
