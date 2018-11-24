
SemEval-2017 Task 4: Sentiment Analysis in Twitter
http://alt.qcri.org/semeval2017/task4/

=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

The data enclosed is a compilation of all annotated sentiment datasets for the five 2017 tasks. 
It is divided by utility for a particular subtask in 2017:

A:   Message Polarity Classification
B,C: Topic-Based Message Polarity Classification	
D,E: Tweet quantification

Each file includes the year and type (dev/test/train) of download to refer to the collection from prior SemEval runs of this task: in 2013-2016.

=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

Please note that in Subtask A, there are 665 duplicate annotations across and within the files. We kept them in the file to preserve the dataset to prior years. We strongly encourage you to remove these duplicates when you train and test your system.

=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

Contact:

E-mail: semevaltweet@googlegroups.com

Sara Rosenthal, IBM Research 
Noura Farra, Columbia University 
Preslav Nakov, Qatar Computing Research Institute, HBKU 
Fabrizio Sebastiani, Qatar Computing Research Institute, HBKU 

=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

Summary of the subtasks:

Subtask A: Message Polarity Classification.
Given a message, classify whether the message is of positive, negative, or neutral sentiment.

Subtasks B-C: Topic-Based Message Polarity Classification.
Given a message and a topic, classify the message on
B) two-point scale: positive or negative sentiment towards that topic
C) five-point scale: sentiment conveyed by that tweet towards the topic on a five-point scale.

Subtasks D-E: Tweet quantification.
Given a set of tweets about a given topic, estimate the distribution of the tweets across
D) two-point scale: the "Positive" and "Negative" classes
E) five-point scale: the five classes of a five-point scale.

=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-


References:

Preslav Nakov, Sara Rosenthal, Svetlana Kiritchenko, Saif M. Mohammad, Zornitsa Kozareva, Alan Ritter, Veselin Stoyanov, Xiaodan Zhu. Developing a successful SemEval task in sentiment analysis of Twitter and other social media texts. Language Resources and Evaluation 50(1): 35-65 (2016).

Preslav Nakov, Alan Ritter, Sara Rosenthal, Fabrizio Sebastiani, and Veselin Stoyanov. SemEval-2016 Task 4: Sentiment Analysis in Twitter. In Proceedings of the 10th International Workshop on Semantic Evaluation (SemEval'2016), June 16-17, 2016, San Diego, California, USA.

Sara Rosenthal, Preslav Nakov, Svetlana Kiritchenko, Saif M Mohammad, Alan Ritter, and Veselin Stoyanov. SemEval-2015 Task 10: Sentiment Analysis in Twitter. In Proceedings of the 9th International Workshop on Semantic Evaluation (SemEval'2015), pp.451-463, June 4-5, 2016, Denver, Colorado, USA.

Sara Rosenthal, Preslav Nakov, Alan Ritter, Veselin Stoyanov. SemEval-2014 Task 9: Sentiment Analysis in Twitter. In Proceedings of International Workshop on Semantic Evaluation (SemEval’14), pp.73-80, August 23-24, 2014, Dublin, Ireland.

Preslav Nakov, Sara Rosenthal, Zornitsa Kozareva, Veselin Stoyanov, Alan Ritter, Theresa Wilson. SemEval-2013 Task 2: Sentiment Analysis in Twitter. In Proceedings of the Second Joint Conference on Lexical and Computational Semantics (*SEM'13), Volume 2: Proceedings of the Seventh International Workshop on Semantic Evaluation (SemEval'2013). pp. 312-320, June 17-19, 2013, Atlanta, Georgia, USA.
