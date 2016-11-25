import numpy as np
from sklearn import metrics
from sklearn.svm import SVC


def load_data(filename):
    X = []
    y = []
    with open(filename) as f:
        for line in f:
            v = [float(x) for x in line.split()]
            X.append(v[:-1])
            y.append(v[-1])
    X = np.array(X)
    y = np.array(y)
    return X, y


def k_folder(X, y, k):
    index = range(len(X))
    np.random.shuffle(index)
    aucs = []
    part = len(X)/k
    for i in xrange(k):
        X_train = []
        y_train = []
        X_validation = []
        y_validation = []
        for j in xrange(k):
            if j == i:
                X_validation.extend(X[index[j*part:min((j+1)*part, len(X))]])
                y_validation.extend(y[index[j*part:min((j+1)*part, len(X))]])
            else:
                X_train.extend(X[index[j * part:min((j + 1) * part, len(X))]])
                y_train.extend(y[index[j * part:min((j + 1) * part, len(X))]])
        clf = SVC(C=1.0, kernel='rbf', probability=True)
        clf.fit(X_train, y_train)
        y_predict = clf.predict(X_validation)
        aucs.append(metrics.roc_auc_score(y_validation, y_predict))
    print np.mean(aucs)


if __name__ == '__main__':
    X, y = load_data('A.txt')
    k_folder(X, y, 10)
