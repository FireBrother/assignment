# coding: utf-8

import tushare as ts
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns

from collections import defaultdict
import logging

class Simulator:
    logger = logging.getLogger(__name__)
    
    def __init__(self, data_key='hs300_k_data_hfq', data_path=None, start_cash=100000, start_date='2015-01-01', AUX_EXP_FACTOR=0.0003, AUX_EXP_MIN=5, STAMPS_FACTOR=0.001):
        if data_path is not None:
            self.logger.info('【模拟器初始化】数据路径：%s，起始现金：%s，起始日期：%s，手续费：%s%%（最低%s元)，印花税：%s%%', data_path, start_cash, start_date, AUX_EXP_FACTOR * 100, AUX_EXP_MIN, STAMPS_FACTOR * 100)
            self.hs300_k_data = pd.read_json(data_path)
            self.hs300_k_data['code']=self.hs300_k_data['code'].astype(str)
        elif data_key is not None:
            self.logger.info('【模拟器初始化】数据key：%s，起始现金：%s，起始日期：%s，手续费：%s%%（最低%s元)，印花税：%s%%', data_key, start_cash, start_date, AUX_EXP_FACTOR * 100, AUX_EXP_MIN, STAMPS_FACTOR * 100)
            self.hs300_k_data = pd.read_hdf('storage.h5', data_key)
        else:
            self.logger.warning('【模拟器初始化】无股价数据，起始现金：%s，起始日期：%s，手续费：%s%%（最低%s元)，印花税：%s%%', start_cash, start_date, AUX_EXP_FACTOR * 100, AUX_EXP_MIN, STAMPS_FACTOR * 100)

        self.stock = defaultdict(int)
        self.start_cash = start_cash
        self.start_date = start_date
        self.cash = start_cash
        self.date = start_date

        self.AUX_EXP_FACTOR = AUX_EXP_FACTOR
        self.AUX_EXP_MIN = AUX_EXP_MIN
        self.STAMPS_FACTOR = STAMPS_FACTOR
    
    def reset(self):
        self.cash = self.start_cash
        self.date = self.start_date
        self.stock.clear()

    def get_asset(self, date=None):
        if date is None:
            date = self.date
        asset = self.cash
        hs300_k_data = self.hs300_k_data
        for security in self.stock:
            data = hs300_k_data[(hs300_k_data.code==security) & (hs300_k_data.date==date)]
            if data.empty:
                data = hs300_k_data[(hs300_k_data.code==security) & (hs300_k_data.date<date)]
                if not data.empty:
                    self.logger.warning('【资产统计】无股价数据，股票代码：%s，采用临近日期估计：%s', security, data['date'].values[-1])
                else:
                    self.logger.warning('【资产统计】无股价数据，股票代码：%s，无临近日期', security)
                    continue
            asset += data['close'].values[-1] * self.stock[security]
        return asset

    def _order(self, code, amount):
        self.logger.debug('【发生交易】股票代码：%s，数量：%d，日期：%s', code, amount, self.date)
        hs300_k_data = self.hs300_k_data
        data = hs300_k_data[(hs300_k_data.code==code) & (hs300_k_data.date==self.date)]
        if data.empty:
            self.logger.warning('【交易失败】无股价数据 股票代码：%s，数量：%d，日期：%s', code, amount, self.date)
            return
        if data['volume'].values[0] == 0:
            self.logger.warning('【交易失败】当日真实交易量为0 股票代码：%s，数量：%d，日期：%s', code, amount, self.date)
            return
        aux_exp = 0 if amount == 0 else max(data['close'].values[0] * abs(amount) * self.AUX_EXP_FACTOR, self.AUX_EXP_MIN)
        stamps = 0 if amount > 0 else data['close'].values[0] * abs(amount) * self.STAMPS_FACTOR
        self.stock[code] += amount
        self.cash -= data['close'].values[0] * amount
        self.cash -= aux_exp + stamps
        self.logger.debug('【交易成功】手续费：%.2f，印花税：%.2f，当前持仓量：%d，现金：%f', aux_exp, stamps, self.stock[code], self.cash)

    def order_value(self, code, money):
        hs300_k_data = self.hs300_k_data
        self.logger.debug('【创建固定金额交易】股票代码：%s，金额：%d，日期：%s', code, money, self.date)
        data = hs300_k_data[(hs300_k_data.code==code) & (hs300_k_data.date==self.date)]
        if data.empty:
            self.logger.warning('【交易失败】无股价数据 股票代码：%s，日期：%s', code, self.date)
            return
        return self._order(code, money//data['close'].values[0])

    def order_target(self, code, target):
        self.logger.debug('【创建目标股数交易】股票代码：%s，股数：%d，日期：%s', code, target, self.date)
        return self._order(code, target-self.stock[code])
