# import tushare as ts
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns

from collections import defaultdict
import logging
import datetime
from dateutil.relativedelta import relativedelta

# hs300_k_data = pd.read_hdf('storage.h5', 'hs300_k_data_hfq')
# security_count = hs300_k_data.groupby('date').count()

hs300_k_data = pd.read_hdf('jqstorage.h5', 'prices')
security_count = hs300_k_data['close'].count(axis=1)

def get_security_count(date):
    index = date.strftime('%Y-%m-%d')
    if index not in security_count.index:
        return 0
    else:
        return security_count.loc[index]


def get_sample_point(start_date=(2015, 7, 1), points=30, month_gap=1, count_thresh=250):
    sample_points = []
    date = datetime.datetime(start_date[0], start_date[1], start_date[2])
    for i in range(points):
        tmp_date = date
        count = get_security_count(tmp_date)
        while count < count_thresh:
            tmp_date = tmp_date + relativedelta(days = 1)
            count = get_security_count(tmp_date)
        date = date + relativedelta(months = month_gap)
        sample_points.append((tmp_date, count))
    return sample_points
