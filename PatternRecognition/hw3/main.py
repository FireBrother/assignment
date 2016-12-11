# coding=utf-8
from collections import defaultdict
import numpy as np
import matplotlib.pyplot as pl
from mpl_toolkits.mplot3d import Axes3D


def load_data(filename):
    data = defaultdict(list)
    with open(filename) as f:
        for line in f:
            v = line.split()
            data[float(v[3])].append([float(x) for x in v[:3]])
    for k in data:
        data[k] = np.array(data[k])
    return data


class TASK1:
    """
    Fisher criteria
    """
    def __init__(self, data):
        self.data = data
        self.m = {}
        self.S = {}
        for k in self.data:
            self.m[k] = np.array([self.data[k].mean(0)])
            self.S[k] = np.sum([(x - self.m[k]).T.dot((x - self.m[k])) for x in self.data[k]], 0)
        self.b = None
        self.w = None

    def estimate(self):
        self.w = np.linalg.inv(self.S[0] + self.S[1]).dot((self.m[0] - self.m[1]).T)
        self.b = -1.0 / 2 * (self.m[0] + self.m[1]).dot(self.w)
        print self.b, self.w

    def plot(self):
        p_x = np.arange(0, 10, 0.1)
        p_y = np.arange(0, 10, 0.1)
        p_x, p_y = np.meshgrid(p_x, p_y)
        p_z = -1 * 1.0 / self.w[2] * (self.w[0] * p_x + self.w[1] * p_y + self.b)
        ax.plot_surface(p_x, p_y, p_z, color='b')


class TASK2:
    """
    MSE criteria
    """
    def __init__(self, data):
        self.data = data
        self.m = {}
        self.S = {}
        for k in self.data:
            self.m[k] = np.array([self.data[k].mean(0)])
            self.S[k] = np.sum([(x - self.m[k]).T.dot((x - self.m[k])) for x in self.data[k]], 0)
        self.St = self.S[0] + self.S[1]
        self.b = None
        self.w = None

    def estimate(self):
        self.w = len(self.data[0])*len(self.data[1])/(len(self.data[0])+len(self.data[1])) * \
                 np.linalg.inv(self.St).dot((self.m[0] - self.m[1]).T)
        self.b = -1.0 / 2 * (self.m[0] + self.m[1]).dot(self.w)
        print self.b, self.w

    def plot(self):
        p_x = np.arange(0, 10, 0.1)
        p_y = np.arange(0, 10, 0.1)
        p_x, p_y = np.meshgrid(p_x, p_y)
        p_z = -1 * 1.0 / self.w[2] * (self.w[0] * p_x + self.w[1] * p_y + self.b)
        ax.plot_surface(p_x, p_y, p_z, color='r')


if __name__ == '__main__':
    data = load_data('A.txt')
    fig = pl.figure()
    ax = fig.add_subplot(111, projection='3d')
    cs = ['b', 'r']
    ms = ['*', '+']
    for i, k in enumerate(data):
        ax.scatter([x[0] for x in data[k]], [x[1] for x in data[k]], [x[2] for x in data[k]], c=cs[i], marker=ms[i])

    task1 = TASK1(data)
    task1.estimate()
    task1.plot()
    task2 = TASK2(data)
    task2.estimate()
    # task2.plot()

    pl.show()
