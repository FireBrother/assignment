import numpy as np
import matplotlib.pyplot as pl


def load_data(filename):
    data = []
    with open(filename) as f:
        for line in f:
            data.append(float(line))
    return data


class HW1:
    def __init__(self, data):
        self.data = data
        self.theta = self.estimate_theta()
        self.sigma = self.estimate_sigma()
        print 'theta={}, sigma={}'.format(self.theta, self.sigma)

    # \hat\theta=\frac{1}{n}\sum^n_{i=1}\ln x
    def estimate_theta(self):
        return np.mean([np.log(x) for x in self.data])

    # \hat\sigma^2=\frac{1}{n}\sum^n_{i=1}(\ln x -\theta)^2
    def estimate_sigma(self):
        if not self.theta:
            self.theta = self.estimate_theta()
        return np.sqrt(np.mean([(np.log(x) - self.theta)**2 for x in self.data]))

    # \frac{1}{\sigma x\sqrt{2\pi}}\exp(-\frac{(\ln x-\theta)^2}{2\sigma^2})
    def fake_function(self, x):
        return 1/(self.sigma*x*np.sqrt(2*np.pi))*np.exp(-(np.log(x)-self.theta)**2/(2*self.sigma**2))

    def plot(self, left=0.1, right=200000, num_points=1000):
        x_show = np.linspace(left, right, num_points)
        pl.plot(x_show, [self.fake_function(x) for x in x_show], label='fitted curve 1.(1)')
        pl.legend()
        # pl.show()


class HW2:
    def __init__(self, data):
        self.data = data
        self.theta = self.estimate_theta()
        self.sigma = self.estimate_sigma()
        print 'theta={}, sigma={}'.format(self.theta, self.sigma)

    # \hat\theta=\frac{1}{n}\sum^n_{i=1}\ln x
    def estimate_theta(self):
        return np.mean(self.data)

    # \hat\sigma^2=\frac{1}{n}\sum^n_{i=1}(\ln x -\theta)^2
    def estimate_sigma(self):
        if not self.theta:
            self.theta = self.estimate_theta()
        return np.sqrt(np.mean([(x - self.theta)**2 for x in self.data]))

    # \frac{1}{\sigma x\sqrt{2\pi}}\exp(-\frac{(\ln x-\theta)^2}{2\sigma^2})
    def fake_function(self, x):
        return 1/(self.sigma*np.sqrt(2*np.pi))*np.exp(-1/2*((x-self.theta)/self.sigma)**2)

    def plot(self, left=0.1, right=150000, num_points=1000):
        x_show = np.linspace(left, right, num_points)
        pl.plot(x_show, [self.fake_function(x) for x in x_show], label='fitted curve 1.(2)')
        pl.legend()
        # pl.show()


if __name__ == '__main__':
    data = load_data('A.txt')
    hw1 = HW1(data)
    hw1.plot()
    hw2 = HW2(data)
    hw2.plot()
    pl.show()
