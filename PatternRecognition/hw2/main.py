import numpy as np
import matplotlib.pyplot as pl
import bisect


def load_data(filename):
    data = []
    with open(filename) as f:
        for line in f:
            data.append(float(line))
    return data


class TASK1:
    """
    Parzen Method
    """
    def __init__(self, data):
        self.data = sorted(data)

    def estimate(self, size=10000, left=0.1, right=500000, num_points=1000):
        x_show = np.linspace(left, right, num_points)
        pl.plot(x_show, [self.p_hat(x, size) for x in x_show], label='parzen with window size = {}'.format(size))
        pl.legend()
        # pl.savefig('parzen_plot/parzen_{}.png'.format(size))
        # pl.show()

    def p_hat(self, x, size):
        return 1.0 * (bisect.bisect_left(self.data, x+1.0*size/2) -
                      bisect.bisect_left(self.data, x-1.0*size/2)) / (size * len(self.data))


class TASK2:
    """
    KNN Method
    """
    def __init__(self, data):
        self.data = data

    def estimate(self, n=500, left=0.1, right=500000, num_points=1000):
        x_show = np.linspace(left, right, num_points)
        pl.plot(x_show, [self.p_hat(x, n) for x in x_show], label='knn with window n = {}'.format(n))
        pl.legend()
        # pl.savefig('knn_plot/knn_{}.png'.format(n))
        # pl.show()

    def p_hat(self, x, n):
        dis = sorted([abs(i - x) for i in self.data])
        size = 2 * dis[n]
        return 1.0 * n / (size * len(self.data))


if __name__ == '__main__':
    data = load_data('A.txt')
    # pl.scatter(data, [0] * len(data), marker='x', label='data')
    # pl.legend()
    # task1 = TASK1(data)
    # for i in range(5000, 25000, 1000):
    #     task1.estimate(i)
    #     pl.close()
    # task2 = TASK2(data)
    # for i in range(100, 1000, 50):
    #     task2.estimate(i)
    #     pl.close()
    task1 = TASK1(data)
    task1.estimate(13000)
    task2 = TASK2(data)
    task2.estimate(350)
    pl.savefig('plot.jpg')
    pl.show()
