# 《网络大数据管理理论和应用》实验报告

题目：倒排索引建立

要求：在Hadoop分布式环境中实现课上讲的对语料库构建倒排索引的程序。

 

姓名：吴先

学号：1701214017

日期：2017年11月8日

 

实验环境：Ubuntu 16.04.3, Java 1.8.0_151, Hadoop 2.8.1

[TOC]

## 思路

任务需要对所有词语做倒排索引，最后的输出是每个词语和他们出现过的文章以及出现次数。

不考虑in mapper combine的机制，那么需要手写一个combiner以实现计数的功能，在最后的reducer里实现倒排的功能。

数据的流如下：

​	map阶段：输入为文章id和一个文件行，将其拆分成单词；因为combiner需要对来自不同文件的同一个词分别计数，所以输出的key为“词[分隔符]文章id”，value为1*。

​	combine阶段：接收到	<词[分隔符]文章id, 1>的key-value对，进行计数，并对key进行拆分，输出的key为词，value为“文章id：词频”

​	reduce阶段：接收到<词, 文章id：词频>的value对，将相同词的“文章id：词频”的信息拼接成一个list即可。

\* 这里遇到了关于数据类型的一些问题。原本我设计的是`Mapper<Object, Text, Text, IntWritable>`，Combiner:`Reducer<Text, IntWritable, Text, Text`, Reducer:`Reducer<Text, Text, Text, Text>`。然而运行之后在combiner报错，说需要`IntWritable`类型的输出。我已经用`setMapOutputValueClass`单独设置过Mapper的输出类型了，不知为何还报错。最后索性都用`Text`作为传输的类型了。

## 代码

```java
public class InvertedIndex {
    private static String delim = "[@DELIM]";

    public static class TokenizerMapper
            extends Mapper<Object, Text, Text, Text> {

        private Text keyInfo = new Text();
        private Text one = new Text("1");
        private FileSplit split;

        // 将输入文件按照<word, doc_id>划分，交给combiner进行计数
        public void map(Object key, Text value, Context context
        ) throws IOException, InterruptedException {
            split = (FileSplit)context.getInputSplit();
            StringTokenizer itr = new StringTokenizer(value.toString());
            while (itr.hasMoreTokens()) {
                String word = itr.nextToken();
                keyInfo.set(word+delim+split.getPath());
                context.write(keyInfo, one);
            }
        }
    }

    public static class IntSumCombiner
            extends Reducer<Text, Text, Text, Text> {
        private Text keyInfo = new Text();
        private Text result = new Text();

        // 以<word, doc_id>为key进行计数，计数后得到的是一个词在一篇文章中的出现次数。
        // 将其以word为key，以<doc_id, cnt>为value，交给reducer构造倒排索引。
        public void reduce(Text key, Iterable<Text> values,
                           Context context
        ) throws IOException, InterruptedException {
            Integer sum = 0;
            for (Text val : values) {
                sum += Integer.parseInt(val.toString());
            }
            int index = key.find(delim);
            keyInfo.set(key.toString().substring(0, index));
            result.set(key.toString().substring(index+delim.length())+":"+sum.toString());
            context.write(keyInfo, result);
        }
    }

    public static class IndexingReducer
            extends Reducer<Text, Text, Text, Text> {
        private Text result = new Text();

        public void reduce(Text key, Iterable<Text> values,
                           Context context
        ) throws IOException, InterruptedException {
            StringBuilder buff = new StringBuilder();
            for (Text val : values) {
                buff.append(val.toString()).append("; ");
            }
            result.set(buff.toString());
            context.write(key, result);
        }
    }

    public static void main(String[] args) throws Exception {
        Configuration conf = new Configuration();
        Job job = Job.getInstance(conf, "inverted index");
        job.setJarByClass(InvertedIndex.class);
        job.setMapperClass(TokenizerMapper.class);
        job.setMapOutputKeyClass(Text.class);
        job.setMapOutputValueClass(Text.class);

        job.setCombinerClass(IntSumCombiner.class);
        job.setReducerClass(IndexingReducer.class);
        job.setOutputKeyClass(Text.class);
        job.setOutputValueClass(Text.class);
        FileInputFormat.addInputPath(job, new Path(args[0]));
        FileOutputFormat.setOutputPath(job, new Path(args[1]));
        System.exit(job.waitForCompletion(true) ? 0 : 1);
    }
}
```

## 结果及分析

截取了一部分结果如下：

```
Making  hdfs://Master:9000/data/InvertedIndex/news01.txt:2; hdfs://Master:9000/data/InvertedIndex/news02.txt:1; hdfs://Master:9000/data/InvertedIndex/news06.txt:1;
Manhattan       hdfs://Master:9000/data/InvertedIndex/news10.txt:1;
Many    hdfs://Master:9000/data/InvertedIndex/news09.txt:1; hdfs://Master:9000/data/InvertedIndex/news02.txt:1;
Marr    hdfs://Master:9000/data/InvertedIndex/news08.txt:1;
Marx    hdfs://Master:9000/data/InvertedIndex/news01.txt:1;
Master  hdfs://Master:9000/data/InvertedIndex/news09.txt:1;
Mastery,        hdfs://Master:9000/data/InvertedIndex/news10.txt:1;
Max     hdfs://Master:9000/data/InvertedIndex/news08.txt:1;
Medical hdfs://Master:9000/data/InvertedIndex/news01.txt:1;
Medicare        hdfs://Master:9000/data/InvertedIndex/news10.txt:1;
Medicine        hdfs://Master:9000/data/InvertedIndex/news01.txt:1;
Mental  hdfs://Master:9000/data/InvertedIndex/news10.txt:1; hdfs://Master:9000/data/InvertedIndex/news09.txt:1;
MetaMaster      hdfs://Master:9000/data/InvertedIndex/news09.txt:1;
Michael hdfs://Master:9000/data/InvertedIndex/news09.txt:1;
Might   hdfs://Master:9000/data/InvertedIndex/news02.txt:1;
Military        hdfs://Master:9000/data/InvertedIndex/news09.txt:1;
Milton  hdfs://Master:9000/data/InvertedIndex/news09.txt:2;
Modeling        hdfs://Master:9000/data/InvertedIndex/news06.txt:1;
Modern  hdfs://Master:9000/data/InvertedIndex/news09.txt:1;
Money   hdfs://Master:9000/data/InvertedIndex/news06.txt:1;
More    hdfs://Master:9000/data/InvertedIndex/news06.txt:1;
```

在本地小数据集上验证无误。

大数据集与同学的结果对拍，一致。