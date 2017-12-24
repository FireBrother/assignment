# 《网络大数据管理理论和应用》实验报告

题目：Spark平台安装和应用

要求：安装Spark平台，并运行wordCount程序。



姓名：吴先

学号：1701214017

日期：2017年11月8日



实验环境：Ubuntu 16.04.3, Java 1.8.0_151, Hadoop 2.8.1,Spark version 2.2.0 , Scala version 2.11.8

[TOC]

## Spark安装

在hw1中已经完成了Spark平台的安装，在这里展示安装完成的截图。![屏幕快照 2017-10-19 上午12.10.00](/Users/wuxian/Documents/assignment/网络大数据/hw3/屏幕快照 2017-10-19 上午12.10.00.png)

## WordCount

### spark-shell

参考上面hadoop输出的结果，如果让spark把结果输出到屏幕上太爆炸了，所以考虑了写入到文件。

```scala
wuxian@Master:~$ spark-shell
...

scala> var file=sc.textFile("hdfs://Master:9000/data/WordCountSmall")
file: org.apache.spark.rdd.RDD[String] = hdfs://Master:9000/data/WordCountSmall MapPartitionsRDD[1] at textFile at <console>:24

scala> val count=file.flatMap(line => line.split(" ")).map(word => (word,1)).reduceByKey(_+_)
count: org.apache.spark.rdd.RDD[(String, Int)] = ShuffledRDD[4] at reduceByKey at <console>:26

scala> import java.io.PrintWriter
import java.io.PrintWriter

scala> import java.io.File
import java.io.File

scala> val writer = new PrintWriter(new File("spark_wordcount.txt"))
writer: java.io.PrintWriter = java.io.PrintWriter@664f1c53

scala> count.collect().foreach(writer.println)
...
```

通过`head -n 20 spark_wordcount.txt`，查询到的前几条结果如下：

```
((often,1)
([15],,1)
(ratings.,1)
(previously,3)
(past,3)
(books,,1)
(have,41)
(order,11)
(type,1)
(imputation,1)
(several,6)
(“is,1)
(Dempster–Shafer,1)
(we,16)
(However,,16)
(been,20)
(rooms.,1)
(invested,1)
(reliable,1)
(challenges,1)
```

### spark-submit

#### 环境配置

刚才采用的是交互式的方法，考虑到下面的大作业也需要在ide中开发，所以这里也尝试在编译jar包并提交的方式。

因为之前采用了maven的管理方式，所以scala的程序我也选择在同一个工程下面，通过添加scala支持，并以不同的artifacts来区分不同的任务。

IntelliJ Idea下，使用maven配置scala环境的教程如下：http://www.jianshu.com/p/ecc6eb298b8f。

总之最后整个作业的工程目录如下：

![屏幕快照 2017-12-21 下午4.07.53](/Users/wuxian/Documents/assignment/网络大数据/hw3/屏幕快照 2017-12-21 下午4.07.53.png)

#### 代码和结果

代码如下：

```scala
import org.apache.spark.SparkConf
import org.apache.spark.SparkContext

object WordCountScala {
  def main(args:Array[String]) {
    val conf = new SparkConf().setAppName("Word Count Scala")
    val sc = new SparkContext(conf)
    val textFile = sc.textFile(args(0))
    val wordCounts = textFile.flatMap(line => line.split(" ")).map(
      word => (word, 1)).reduceByKey((a, b) => a + b)
    wordCounts.saveAsTextFile(args(1))
    println("Word Count program running results are successfully saved.")
  }
}
```

然后打包成jar，上传到master机器上，用如下命令运行。

```
spark-submit --class WordCountScala wordcountscala.jar hdfs://Master:9000/data/WordCountSmall hdfs://Master:9000/outputWordCountSmall
```

第一次尝试失败了，报如下错误：

```
Exception in thread "main" java.lang.BootstrapMethodError: java.lang.NoClassDefFoundError: scala/runtime/java8/JFunction2$mcIII$sp
	at WordCountScala$.main(WordCountScala.scala:11)
	at WordCountScala.main(WordCountScala.scala)
	at sun.reflect.NativeMethodAccessorImpl.invoke0(Native Method)
	at sun.reflect.NativeMethodAccessorImpl.invoke(NativeMethodAccessorImpl.java:62)
	at sun.reflect.DelegatingMethodAccessorImpl.invoke(DelegatingMethodAccessorImpl.java:43)
	at java.lang.reflect.Method.invoke(Method.java:498)
	at org.apache.spark.deploy.SparkSubmit$.org$apache$spark$deploy$SparkSubmit$$runMain(SparkSubmit.scala:755)
	at org.apache.spark.deploy.SparkSubmit$.doRunMain$1(SparkSubmit.scala:180)
	at org.apache.spark.deploy.SparkSubmit$.submit(SparkSubmit.scala:205)
	at org.apache.spark.deploy.SparkSubmit$.main(SparkSubmit.scala:119)
	at org.apache.spark.deploy.SparkSubmit.main(SparkSubmit.scala)
Caused by: java.lang.NoClassDefFoundError: scala/runtime/java8/JFunction2$mcIII$sp
	... 11 more
Caused by: java.lang.ClassNotFoundException: scala.runtime.java8.JFunction2$mcIII$sp
	at java.net.URLClassLoader.findClass(URLClassLoader.java:381)
	at java.lang.ClassLoader.loadClass(ClassLoader.java:424)
	at java.lang.ClassLoader.loadClass(ClassLoader.java:357)
	... 11 more
```

经查，是因为我本地编译使用的是scala 2.12.4，而spark上使用的scala是2.11.8（如实验环境所述）。更换到2.11.0进行编译后，在目标机器上可以正常运行。

从hadoop fs上把结果文件拉下来，与交互式版本的结果一样，不再赘述。