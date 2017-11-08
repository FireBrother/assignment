# Hadoop&Spark实例报告

[TOC]

## Hadoop

一开始yarn-site.xml写错了，所以报了些错误。修改之后，**记得重启yarn，删除/output/wordcount中的内容**，然后重新实验即可。

```
wuxian@Master:/usr/local/hadoop/sbin$ hadoop jar /usr/local/hadoop/share/hadoop/mapreduce/hadoop-mapreduce-examples-2.8.1.jar wordcount /data/wordcount/WordCount /output/wordcount
17/10/18 09:36:22 INFO client.RMProxy: Connecting to ResourceManager at Master/162.105.86.107:8032
17/10/18 09:36:23 INFO input.FileInputFormat: Total input files to process : 1
17/10/18 09:36:24 WARN hdfs.DataStreamer: Caught exception
java.lang.InterruptedException
	at java.lang.Object.wait(Native Method)
	at java.lang.Thread.join(Thread.java:1252)
	at java.lang.Thread.join(Thread.java:1326)
	at org.apache.hadoop.hdfs.DataStreamer.closeResponder(DataStreamer.java:927)
	at org.apache.hadoop.hdfs.DataStreamer.endBlock(DataStreamer.java:578)
	at org.apache.hadoop.hdfs.DataStreamer.run(DataStreamer.java:755)
17/10/18 09:36:24 INFO mapreduce.JobSubmitter: number of splits:9
17/10/18 09:36:24 INFO mapreduce.JobSubmitter: Submitting tokens for job: job_1508344568756_0001
17/10/18 09:36:27 INFO impl.YarnClientImpl: Submitted application application_1508344568756_0001
17/10/18 09:36:27 INFO mapreduce.Job: The url to track the job: http://Master:8088/proxy/application_1508344568756_0001/
17/10/18 09:36:27 INFO mapreduce.Job: Running job: job_1508344568756_0001
17/10/18 09:36:40 INFO mapreduce.Job: Job job_1508344568756_0001 running in uber mode : false
17/10/18 09:36:40 INFO mapreduce.Job:  map 0% reduce 0%
17/10/18 09:37:00 INFO mapreduce.Job:  map 6% reduce 0%
17/10/18 09:37:06 INFO mapreduce.Job:  map 7% reduce 0%
17/10/18 09:37:08 INFO mapreduce.Job:  map 11% reduce 0%
17/10/18 09:37:27 INFO mapreduce.Job:  map 11% reduce 4%
17/10/18 09:37:31 INFO mapreduce.Job:  map 15% reduce 4%
17/10/18 09:37:37 INFO mapreduce.Job:  map 17% reduce 4%
17/10/18 09:37:38 INFO mapreduce.Job:  map 24% reduce 4%
17/10/18 09:37:39 INFO mapreduce.Job:  map 27% reduce 4%
17/10/18 09:37:45 INFO mapreduce.Job:  map 30% reduce 4%
17/10/18 09:37:46 INFO mapreduce.Job:  map 33% reduce 4%
17/10/18 09:37:51 INFO mapreduce.Job:  map 34% reduce 4%
17/10/18 09:37:58 INFO mapreduce.Job:  map 35% reduce 4%
17/10/18 09:38:11 INFO mapreduce.Job:  map 36% reduce 4%
17/10/18 09:38:17 INFO mapreduce.Job:  map 40% reduce 4%
17/10/18 09:38:23 INFO mapreduce.Job:  map 41% reduce 7%
17/10/18 09:38:29 INFO mapreduce.Job:  map 44% reduce 7%
17/10/18 09:38:30 INFO mapreduce.Job:  map 46% reduce 7%
17/10/18 09:38:35 INFO mapreduce.Job:  map 51% reduce 7%
17/10/18 09:38:36 INFO mapreduce.Job:  map 52% reduce 7%
17/10/18 09:38:42 INFO mapreduce.Job:  map 53% reduce 7%
17/10/18 09:38:49 INFO mapreduce.Job:  map 54% reduce 7%
17/10/18 09:39:01 INFO mapreduce.Job:  map 55% reduce 7%
17/10/18 09:39:07 INFO mapreduce.Job:  map 57% reduce 7%
17/10/18 09:39:08 INFO mapreduce.Job:  map 60% reduce 7%
17/10/18 09:39:09 INFO mapreduce.Job:  map 61% reduce 7%
17/10/18 09:39:14 INFO mapreduce.Job:  map 65% reduce 7%
17/10/18 09:39:16 INFO mapreduce.Job:  map 66% reduce 7%
17/10/18 09:39:20 INFO mapreduce.Job:  map 67% reduce 7%
17/10/18 09:39:45 INFO mapreduce.Job:  map 68% reduce 7%
17/10/18 09:39:47 INFO mapreduce.Job:  map 71% reduce 7%
17/10/18 09:39:51 INFO mapreduce.Job:  map 74% reduce 7%
17/10/18 09:39:52 INFO mapreduce.Job:  map 77% reduce 7%
17/10/18 09:39:56 INFO mapreduce.Job:  map 77% reduce 11%
17/10/18 09:39:57 INFO mapreduce.Job:  map 78% reduce 11%
17/10/18 09:40:13 INFO mapreduce.Job:  map 81% reduce 11%
17/10/18 09:40:16 INFO mapreduce.Job:  map 82% reduce 11%
17/10/18 09:40:17 INFO mapreduce.Job:  map 83% reduce 11%
17/10/18 09:40:18 INFO mapreduce.Job:  map 84% reduce 11%
17/10/18 09:40:21 INFO mapreduce.Job:  map 84% reduce 15%
17/10/18 09:40:24 INFO mapreduce.Job:  map 90% reduce 15%
17/10/18 09:40:25 INFO mapreduce.Job:  map 92% reduce 15%
17/10/18 09:40:27 INFO mapreduce.Job:  map 95% reduce 15%
17/10/18 09:40:28 INFO mapreduce.Job:  map 100% reduce 19%
17/10/18 09:40:34 INFO mapreduce.Job:  map 100% reduce 71%
17/10/18 09:40:40 INFO mapreduce.Job:  map 100% reduce 87%
17/10/18 09:40:46 INFO mapreduce.Job:  map 100% reduce 98%
17/10/18 09:40:47 INFO mapreduce.Job:  map 100% reduce 100%
17/10/18 09:40:48 INFO mapreduce.Job: Job job_1508344568756_0001 completed successfully
17/10/18 09:40:48 INFO mapreduce.Job: Counters: 50
	File System Counters
		FILE: Number of bytes read=514639020
		FILE: Number of bytes written=750524118
		FILE: Number of read operations=0
		FILE: Number of large read operations=0
		FILE: Number of write operations=0
		HDFS: Number of bytes read=1203968804
		HDFS: Number of bytes written=143917142
		HDFS: Number of read operations=30
		HDFS: Number of large read operations=0
		HDFS: Number of write operations=2
	Job Counters
		Killed map tasks=8
		Launched map tasks=17
		Launched reduce tasks=1
		Data-local map tasks=17
		Total time spent by all maps in occupied slots (ms)=2463472
		Total time spent by all reduces in occupied slots (ms)=215926
		Total time spent by all map tasks (ms)=2463472
		Total time spent by all reduce tasks (ms)=215926
		Total vcore-milliseconds taken by all map tasks=2463472
		Total vcore-milliseconds taken by all reduce tasks=215926
		Total megabyte-milliseconds taken by all map tasks=2522595328
		Total megabyte-milliseconds taken by all reduce tasks=221108224
	Map-Reduce Framework
		Map input records=25896865
		Map output records=84932253
		Map output bytes=1543651192
		Map output materialized bytes=234522387
		Input split bytes=972
		Combine input records=97501223
		Combine output records=22711314
		Reduce input groups=6915182
		Reduce shuffle bytes=234522387
		Reduce input records=10142344
		Reduce output records=6915182
		Spilled Records=32853658
		Shuffled Maps =9
		Failed Shuffles=0
		Merged Map outputs=9
		GC time elapsed (ms)=10392
		CPU time spent (ms)=221590
		Physical memory (bytes) snapshot=2402140160
		Virtual memory (bytes) snapshot=19379572736
		Total committed heap usage (bytes)=1623904256
	Shuffle Errors
		BAD_ID=0
		CONNECTION=0
		IO_ERROR=0
		WRONG_LENGTH=0
		WRONG_MAP=0
		WRONG_REDUCE=0
	File Input Format Counters
		Bytes Read=1203967832
	File Output Format Counters
		Bytes Written=143917142
```

关于报的Warning，有说法表明这是Hadoop的一个bug，详见https://issues.apache.org/jira/browse/HDFS-10429。

通过`hadoop fs -get /output/wordcount`，查看得到统计出的词频文件的前几条：

```
!       52
!!      2
!!!     52
!!!!    1
!!!\"   1
!!!_(album)     12
!!Destroy-Oh-Boy!!      6
!)      2
!@#$    1
!Action_Pact!   9
!Audacious      1
!Bang!  2
!Hero   4
!Hero_(album)   7
!Kung   2
!Kung_language  14
!Oka_Tokat      16
!PAUS3  7
!T.O.O.H.!      17
!Tang   2
!Women_Art_Revolution   8
!\"     4
!_(album)       8
!a\u0129si      1
!nterprise      1
!t      1
#       28
#!      1
#!!!    2
#!!!Fuck        1
#!!Destroy-Oh-Boy!!     1
#!Action        1
#!HERO  1
...
```

## Spark

参考上面hadoop输出的结果，如果让spark把结果输出到屏幕上太爆炸了，所以考虑了写入到文件。

```scala
scala> var file=sc.textFile("hdfs://Master:9000/data/wordcount/WordCount")
file: org.apache.spark.rdd.RDD[String] = hdfs://Master:9000/data/wordcount/WordCount MapPartitionsRDD[1] at textFile at <console>:24

scala> val count=file.flatMap(line => line.split(" ")).map(word => (word,1)).reduceByKey(_+_)
count: org.apache.spark.rdd.RDD[(String, Int)] = ShuffledRDD[4] at reduceByKey at <console>:26

scala> import java.io.PrintWriter
import java.io.PrintWriter

scala> import java.io.File
import java.io.File

scala> val writer = new PrintWriter(new File("spark_wordcount.txt"))
writer: java.io.PrintWriter = java.io.PrintWriter@10ac5a14

scala> count.collect().foreach(writer.println)
...
```

通过`less spark_wordcount.txt`，查询到的前几条结果如下：

```
(<http://www.limankoy.net>,1)
(Glyphoturris,10)
(#49.2286,4)
(\"Makis\",1)
(Hossein_Fekri__4,3)
(Lo_mejor_de_Bos%C3%A9,8)
(Bernard_Mendy__6,5)
(<http://rmtp.biz/content/index.php?option=com_comprofiler&task=userProfile&user=76&Itemid=44>,1)
(#Shanawdithit,3)
(Alexander_Perezhogin,20)
(Stachys_pycnantha,8)
(#75022,,1)
(T\u0103tarilor,1)
(3.6686,2)
(#M\u011B\u0161\u00EDn,1)
(Painchaud,1)
(Bouleaux,1)
(Raymond_Bonner,5)
(Fabrizio_Bracconeri,1)
(Jodenkoek,1)
(%C4%B0smail_G%C3%BCld%C3%BCren__5,5)
(Great_White_Shark_(comics),3)
(<http://www.had.gov.hk/>,1)
(Elizabeth_Rice__1,2)
(Bayerisch_Gmain,12)
(Church_of_Our_Saviour_(Killington,_Vermont),10)
(Izvorul_lui_C%C3%A2rstocea_River,5)
(#Mapmaker,1)
(#46.7161,2)
(\u0645\u0627\u0646\u0639,1)
(Michel_Fernando_Costa__1,2)
(Ironstone,3)
...
```

