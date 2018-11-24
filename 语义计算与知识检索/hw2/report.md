# 情感分类

姓名：吴先

学号：1701214017

邮箱：wuxian94@pku.edu.cn

要求：SemEval2017 Task4 Subtask A

## 目录

[TOC]

## 实验环境

语言：python 3.6.2

使用工具包：ekphrasis, pytorch

## 特征构建

本次实验采用了LSTM对输入的句子进行编码，将编码结果输入一个线性层和Softmax层输出分类结果。

当我们阅读句子时，会利用前文的信息来理解每个单词，而不需要抛弃掉前面的信息重新思考。人的思维是具有持久性的。

然而传统的神经网络不能做到这一点，传统的神经网络中的神经元节点接收来自$n$个其他神经元传递过来的信号，通过一个连接权值$W$对输入进行加权，计算加权和。神经元本身具有一个偏置$b$，得到输入的加权和之后，神经元会将其与偏置$b$相加，最后用一个激活函数进行激活，得到的值作为神经元的输出，传递到下一个神经元或作为网络的输出。

长短程记忆神经网络是一种特殊的RNN，能够学习到长距离的依赖关系。它们是由Hochreiter与Schmidhuber（1997）提出的，并随着计算能力的发展，在今年得到广泛的应用。

LSTM是特别设计以解决长距离依赖问题的。其网络结构默认它们能够记住长期的信息。其结构如下：

![lstm](/Users/wuxian/Documents/assignment/语义计算与知识检索/hw2/lstm.png)

与传统的RNN不同，RNN的重复模块仅仅具有非常简单的结构，比如仅仅由一个tanh层构成。LSTM的重复模块包含三个被称为“门”的部分，以比较复杂的方式进行交互。门是一种让信息通过网络的方式，它由sigmoid层和点乘操作组成。

## 实验设置

### 语料使用

训练集和验证集使用了提供的GOLD文件夹下的所有数据。对于五个Subtask，保留了所有情感标签和句子内容。特别的，对于SubtaskCE，将-2、-1视为negative，1、2视为positive；ABD可以直接采用标注的标签，读取时注意过滤topic即可。

测试集就是2017年的Task4 SubtaskA。

测试集与验证集以8:1进行随机分割，最终各部分条目数量如下：

| filename  | \#line |
| --------- | ------ |
| train.txt | 85789  |
| dev.txt   | 18918  |
| test.txt  | 12283  |

### 预处理

使用了Github上的开源项目ekphrasis进行处理。这个一个专门用于社交语料（尤其是Twitter）的预处理工具，可以把url、emoji、user id等识别出来，并进行标记或转写；同时也支持基本的英文预处理功能，比如分词、标准化、修正拼写等等。

预处理模块的配置直接采用Github上的Twitter Demo即可。

（除了下载字典慢的吓人，而且requirements.txt缺一大堆包以外，其预处理效果还是很令人满意的。

然后将tokenize的结果转化成index序列。经过对语料的分析，排除所有出现频率在5以下的词（全部替换成OOV），词典大小为15130，最长的句子长度为99。

（预处理后手动把这几个文件拖到了data目录下，所以utils.py里的路径跟其他部分差一层`data/`）

### 超参数设置

对于分类器的超参数，我们设置为

```
config = {
    'embedding_size': 200,
    'vocab_size': max(train_set.word2idx.values())+1,
    'rnn_hidden_size': 200,
    'rnn_num_layers': 1,
    'num_categories': 3
}
```

其中embedding随机初始化为-0.1~0.1的均匀分布。

### 其他细节

* 在各个feature的输出后面都加入了概率为0.1的dropout层；
* 采用了pytorch的pack_padded_sequence机制对变长序列进行处理；
* 优化器为Adagrad，learning rate=0.1；
* 学习率以$0.8^n$的速率降低，$n$为训练的epoch；
* 训练10个epoch后停止，没有early stop机制。

##结果与分析

log的最后几行和评测结果：

```
......
| epoch  10 |  1285/ 1340 batches | lr 0.0100 | ms/batch 19.05 | loss  0.44 | ppl     1.56
| epoch  10 |  1290/ 1340 batches | lr 0.0100 | ms/batch 19.99 | loss  0.42 | ppl     1.52
| epoch  10 |  1295/ 1340 batches | lr 0.0100 | ms/batch 19.54 | loss  0.35 | ppl     1.42
| epoch  10 |  1300/ 1340 batches | lr 0.0100 | ms/batch 20.30 | loss  0.33 | ppl     1.39
| epoch  10 |  1305/ 1340 batches | lr 0.0100 | ms/batch 19.69 | loss  0.36 | ppl     1.43
| epoch  10 |  1310/ 1340 batches | lr 0.0100 | ms/batch 19.13 | loss  0.38 | ppl     1.46
| epoch  10 |  1315/ 1340 batches | lr 0.0100 | ms/batch 20.17 | loss  0.36 | ppl     1.43
| epoch  10 |  1320/ 1340 batches | lr 0.0100 | ms/batch 20.62 | loss  0.25 | ppl     1.28
| epoch  10 |  1325/ 1340 batches | lr 0.0100 | ms/batch 18.90 | loss  0.41 | ppl     1.50
| epoch  10 |  1330/ 1340 batches | lr 0.0100 | ms/batch 19.83 | loss  0.30 | ppl     1.35
| epoch  10 |  1335/ 1340 batches | lr 0.0100 | ms/batch 20.12 | loss  0.31 | ppl     1.37
| epoch  10 |  1340/ 1340 batches | lr 0.0100 | ms/batch 19.79 | loss  0.37 | ppl     1.44
evaluation
	label:1 precision=0.6093, recall=0.5757, fmeasure=0.5920
	label:2 precision=0.3933, recall=0.6575, fmeasure=0.4922
	label:0 precision=0.6128, recall=0.4172, fmeasure=0.4964
accuracy=0.5403
-----------------------------------------------------------------------------------------
| end of epoch  10 | time: 28.29s | valid loss  0.54 | valid ppl     1.72
-----------------------------------------------------------------------------------------
evaluation
	label:1 precision=0.6102, recall=0.5774, fmeasure=0.5933
	label:2 precision=0.3964, recall=0.6605, fmeasure=0.4954
	label:0 precision=0.6139, recall=0.4187, fmeasure=0.4978
accuracy=0.5421
```

其中label1为中立，2为积极，0为消极。

## 想法

这里可能的改进还是有很多的。

* 没有采用自动化的超参数选择，而是自己对着dev集调来调去，很可能没有选到最好的超参数集；
* 网络结构也比较简单，而且用的是现在已经被前沿逐渐抛弃的LSTM；
* 另外关于情感分类，不把三个类别看成独立的，而是看成连续的回归问题，然后细致的选一下threshhold或许会更好，因为这三个类别其实是有渐变关系的，并不一定是“类别”；
* 或者，做成二分类问题，对于confidence不够高的结果输出“中立”分类，也许也更符合语义。

### 代码说明

model.py: 模型定义

data_helper.py: 采用了pytorch的dataset机制进行数据读入（坑真多）

train.py: 训练的代码，其实也包含了评测和输出

utils.py: 语料的预处理、评测的函数等辅助工具