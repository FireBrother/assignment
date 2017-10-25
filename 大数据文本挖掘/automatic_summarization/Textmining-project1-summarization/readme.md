## DUC单文档摘要数据说明


# 数据说明
	* data.json:  处理后的DUC2004 Task 1 数据集 （包含 train/dev/test数据，json格式）
		['data']    The input document (tokenized)
		['label']   Four reference summaries (tokenized)
		['set']     Indication for train/dev/test


	* 以上给定的数据集为 DUC2004 Task 1预处理后的数据 ( DUC说明参见 http://duc.nist.gov/duc2004/tasks.html ）
	* 课程最终评分主要参考本小组模型的创新性（鼓励模型中有自己的想法）以及 在测试集(test)上的ROUGE指标 
	* 鼓励深度神经摘要模型



	* 对于传统摘要方法，可以使用 train/dev 数据进行训练（也可以使用外部同源数据集）
	* 对于深度神经摘要模型，该数据集数据规模较小，可以使用外部的同源数据集进行模型训练，如：
		* Gigaword： http://forum.opennmt.net/t/text-summarization-on-gigaword-and-rouge-scoring/85
		* CNN-Dailymail:    https://github.com/abisee/cnn-dailymail



# 模型评测
推荐使用 pythonrouge https://github.com/tagucci/pythonrouge
ps. 也可以使用官方ROUGE脚本，其使用较为复杂


# 时间安排
* 2017/10/27 proposal due
* 2017/10/30 presentation
* 2017/11/25 project 1 due


# 备注
* 不能使用现有的摘要算法库，如：PKUSUMSUM／NLTK 等等
