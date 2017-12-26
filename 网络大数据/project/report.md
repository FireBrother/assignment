# 《网络大数据管理理论和应用》大作业

题目：分别在MapReduce和Spark平台上实现微博用户重要度排序。可以通过计算用户的PageRank值实现，其它任选方法也可以。

要求：

提交一个报告，包括5个部分：

（1）实验环境部署

（2）方法介绍

（3）实验结果统计

（4）对两个平台上实现方法的对比（包括：程序的对比、数据加载时间、第一轮迭代用时、每轮迭代的平均时间、总的算法执行时间等）

（5）你在这门课上学到了什么，以及对这门课的建议。



姓名：吴先

学号：1701214017

日期：2017年11月8日



实验环境：Ubuntu 16.04.3, Java 1.8.0_151, Hadoop 2.8.1,Spark version 2.2.0 , Scala version 2.11.8

[TOC]

## 实验环境部署

### 集群和开发环境

截止到hw3，我们已经完成了服务器端hadoop和spark集群的搭建；也完成了开发端java和scala联合工程的配置，maven配置如下

```xml
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>

    <groupId>cn.edu.pku.wuxian</groupId>
    <artifactId>hadoop</artifactId>
    <version>1.0-SNAPSHOT</version>

    <repositories>
        <repository>
            <id>apache</id>
            <url>http://maven.apache.org</url>
        </repository>
    </repositories>

    <dependencies>
        <dependency>
            <groupId>org.apache.hadoop</groupId>
            <artifactId>hadoop-core</artifactId>
            <version>1.2.1</version>
        </dependency>
        <dependency>
            <groupId>org.apache.hadoop</groupId>
            <artifactId>hadoop-common</artifactId>
            <version>2.8.1</version>
        </dependency>
        <dependency>
            <groupId>org.apache.hadoop</groupId>
            <artifactId>hadoop-hdfs</artifactId>
            <version>2.8.1</version>
        </dependency>
        <!-- https://mvnrepository.com/artifact/org.apache.spark/spark-core -->
        <dependency>
            <groupId>org.apache.spark</groupId>
            <artifactId>spark-core_2.11</artifactId>
            <version>2.2.0</version>
        </dependency>
        <dependency>
            <groupId>org.scala-lang</groupId>
            <artifactId>scala-library</artifactId>
            <version>2.11.8</version>
        </dependency>
        <!-- https://mvnrepository.com/artifact/redis.clients/jedis -->
        <dependency>
            <groupId>redis.clients</groupId>
            <artifactId>jedis</artifactId>
            <version>2.9.0</version>
        </dependency>
    </dependencies>
</project>
```

只是要注意如果只编译hadoop的任务，要把scala目录排除掉，因为服务器端spark中的scala和环境中的scala版本不一样，开发端使用的是spark中的scala版本，所以运行会出问题。

### 辅助工具

在编写hadoop的程序的时候，用到redis作为全局变量的存储方案，所以在另一台服务器上搭建了redis-server。为了安全考虑没有监听全网ip`bind 0.0.0.0`，所以在Master和Slave1上通过正向代理，用本地6378端口来代理redis服务器所在的6379端口，命令如下 ：` ssh -CNL 6378:127.0.0.1:6379 wuxian@162.105.86.208`。这样就可以正常访问redis服务器了。

## 方法介绍

### Hadoop

#### 使用全局变量的版本

基本的pagerank算法，我选择的公式是带Random Jump的版本，所以需要统计出图上的节点数量和出边数量。因为不想进行预处理，所以打算用全局变量的方式记录这些数据。因此第一版的思路是，在迭代开始前进行一次数据统计，将节点数、出边数量和pagerank值都记录在全局变量上。

代码如下：

```java
	private static HashMap<String, Double> pagerank = new HashMap<String, Double>();
    private static HashMap<String, Integer> out_degree = new HashMap<String, Integer>();
    private static int num_node;

    private static void init_statistics(String hdfsPath) throws IOException {
        pagerank.clear();
        out_degree.clear();
        num_node = 0;

        Configuration conf = new Configuration();
        FileSystem fs = FileSystem.get(URI.create(hdfsPath), conf);
        FileStatus[] status = fs.listStatus(new Path(hdfsPath));
        for (FileStatus file : status) {
            FSDataInputStream hdfsInStream = fs.open(file.getPath());
            BufferedReader bufferedReader = new BufferedReader(new InputStreamReader(hdfsInStream));
            String line;
            while ((line = bufferedReader.readLine()) != null) {
                StringTokenizer itr = new StringTokenizer(line);
                String from = itr.nextToken();
                String to = itr.nextToken();
                if (to.equals("0")) {
                    continue;
                }
                if (!pagerank.containsKey(from))
                    pagerank.put(from, 1.0);
                if (!pagerank.containsKey(to))
                    pagerank.put(to, 1.0);
                if (out_degree.containsKey(from))
                    out_degree.put(from, out_degree.get(from) + 1);
                else
                    out_degree.put(from, 1);
            }
            hdfsInStream.close();
        }
        num_node = out_degree.keySet().size();
        fs.close();
    }

public void map(Object key, Text value, Context context
        ) throws IOException, InterruptedException {
            StringTokenizer itr = new StringTokenizer(value.toString());
            String from = itr.nextToken();
            String to = itr.nextToken();
            if (to.equals("0")) {
                return;
            }

            keyInfo.set(to);
            pr.set(pagerank.get(from)/out_degree.get(from));

            context.write(keyInfo, pr);
        }
    }

    public static class PRSumReducer
            extends Reducer<Text, DoubleWritable, Text, DoubleWritable> {

        private DoubleWritable result = new DoubleWritable();
        private static double change = 0.0;

        public void reduce(Text key, Iterable<DoubleWritable> values,
                           Context context
        ) throws IOException, InterruptedException {
            double pr = 0.0;
            for (DoubleWritable value: values) {
                pr += value.get();
            }
            pr = 0.15*(1.0/num_node)+0.85*pr;
            result.set(pr);
            change += Math.abs(pagerank.get(key.toString())-pr);
            pagerank.put(key.toString(), result.get());
            context.write(key, result);
        }
    }
```

在单机和小数据的环境上没有问题。但是在分布式环境下出现了问题。因为三个静态变量在Slave节点上并未初始化，所以这里考虑的思路是如何**在hadoop上做到全局变量的维护，使所有变化都实时反馈**。

#### 用redis维护全局信息的hadoop

Configuration是可以在不同的节点之间保持信息的。但是因为两个HashMap都非常大，所以想能不能只传递想要的值。想到这里，就想到不如用redis来保持这些需要在不同的节点上维护的相同的信息。

思路是，用redis作为全局变量的map，用"out:id"表示id节点的出边数量，用"pr:id"表示id节点的pagerank值，每次更新和查询在redis上完成。

在修改成redis的版本之后，发现就连初始化的时间都变成了原来的十几倍。考虑发起和断开链接的成本，考虑减少与redis的通信次数。此时的思路转换成了**在hadoop上同步全局变量，在map或reduce开始和结束时保证一致性**。

将out_degree和num_node在每个节点都保持一个副本，如果副本不存在则从redis上读取；pagerank则直接写入文件，在下一轮迭代开始时也是通过文件读取来初始化，可以解决脏读脏写的问题，因为reduce本身就是把结果写入到文件里的。

最后的代码如下：

```java
    private static void init_statistics(String hdfsPath) throws IOException {
        out_degree.clear();
        num_node = 0;

        Configuration conf = new Configuration();
        FileSystem fs = FileSystem.get(URI.create(hdfsPath), conf);
        FileStatus[] status = fs.listStatus(new Path(hdfsPath));
        for (FileStatus file : status) {
            FSDataInputStream hdfsInStream = fs.open(file.getPath());
            BufferedReader bufferedReader = new BufferedReader(new InputStreamReader(hdfsInStream));
            String line;
            while ((line = bufferedReader.readLine()) != null) {
                StringTokenizer itr = new StringTokenizer(line);
                String from = itr.nextToken();
                String to = itr.nextToken();
                if (to.equals("0")) {
                    continue;
                }
                if (out_degree.containsKey(from))
                    out_degree.put(from, out_degree.get(from) + 1);
                else
                    out_degree.put(from, 1);
            }
            hdfsInStream.close();
        }
        num_node = out_degree.keySet().size();
        fs.close();
        Jedis jedis = new Jedis("localhost", 6378);
        jedis.select(4);
        jedis.set("out_degree", out_degree.toString());
        jedis.set("num_node", String.valueOf(num_node));
        jedis.close();
    }

    private static void load_statistics() {

        if (num_node == 0) {
            Jedis jedis = new Jedis("localhost", 6378);
            jedis.select(4);
            String json = jedis.get("out_degree");
            json = json.substring(1, json.length()-1);
            String[] keyValuePairs = json.split(",");

            for(String pair : keyValuePairs) {
                String[] entry = pair.split("=");
                out_degree.put(entry[0].trim(), Integer.parseInt(entry[1].trim()));
            }

            num_node = Integer.parseInt(jedis.get("num_node"));
            jedis.close();
        }
    }

    private static void load_pagerank(String hdfsPath) throws IOException {
        if (hdfsPath.equals("NULL"))
            return;
        Configuration conf = new Configuration();
        FileSystem fs = FileSystem.get(URI.create(hdfsPath), conf);
        FileStatus[] status = fs.listStatus(new Path(hdfsPath));
        for (FileStatus file : status) {
            FSDataInputStream hdfsInStream = fs.open(file.getPath());
            BufferedReader bufferedReader = new BufferedReader(new InputStreamReader(hdfsInStream));
            String line;
            while ((line = bufferedReader.readLine()) != null) {
                StringTokenizer itr = new StringTokenizer(line);
                String id = itr.nextToken();
                Double pr = Double.parseDouble(itr.nextToken());
                pagerank.put(id, pr);
            }
            hdfsInStream.close();
        }
        fs.close();
    }

    public static class PRContribMapper
            extends Mapper<Object, Text, Text, DoubleWritable> {

        private Text keyInfo = new Text();
        private DoubleWritable pr = new DoubleWritable();

        public void map(Object key, Text value, Context context
        ) throws IOException, InterruptedException {
            if (num_node == 0) load_statistics();
            if (pagerank.size() == 0) {
                Configuration conf = context.getConfiguration();
                load_pagerank(conf.get("pagerank_path"));
            }

            StringTokenizer itr = new StringTokenizer(value.toString());
            String from = itr.nextToken();
            String to = itr.nextToken();
            if (to.equals("0")) {
                return;
            }

            keyInfo.set(to);
            pr.set(pagerank.getOrDefault(from, 1.0)/out_degree.get(from));

            context.write(keyInfo, pr);
        }
    }

    public static class PRSumReducer
            extends Reducer<Text, DoubleWritable, Text, DoubleWritable> {

        private DoubleWritable result = new DoubleWritable();
        private static double change = 0.0;

        public void reduce(Text key, Iterable<DoubleWritable> values,
                           Context context
        ) throws IOException, InterruptedException {
            if (num_node == 0) load_statistics();
            if (pagerank.size() == 0) {
                Configuration conf = context.getConfiguration();
                load_pagerank(conf.get("pagerank_path"));
            }

            double pr = 0.0;
            for (DoubleWritable value: values) {
                pr += value.get();
            }
            pr = 0.15*(1.0)+0.85*pr;
            result.set(pr);
            change += Math.abs(pagerank.getOrDefault(key.toString(), 1.0))-pr;
            pagerank.put(key.toString(), result.get());
            context.write(key, result);
        }
    }
```

### Spark

这玩意写起来比hadoop简单多了，而且根本不用考虑变量同步的问题。

```scala
import org.apache.spark.{HashPartitioner, SparkConf, SparkContext}

object PageRankScala {
  def main(args:Array[String]) {
    println(args(1))
    val conf = new SparkConf().setAppName("Page Rank Scala").setMaster("local")
    val sc = new SparkContext(conf)
    val textFile = sc.textFile(args(0))
    val links = textFile.map(line=>line.split(" ")).map(x=>(x(0),List(x(1)))).reduceByKey(_++_).partitionBy(new HashPartitioner(100)).persist()
    var ranks=links.mapValues(v=>1.0)
    for (i <- 0 until 10) {
      val contributions=links.join(ranks).flatMap {
        case (pageId,(links,rank)) => links.map(dest=>(dest,rank/links.size))
      }
      ranks=contributions.reduceByKey((x,y)=>x+y).mapValues(v=>0.15+0.85*v)
    }
    ranks.sortByKey(ascending = True).collect()
    ranks.saveAsTextFile(args(1))
  }
}

```

## 实验结果统计

```
("2803301701",12284.015275608788)
("2656274875",10926.054792409313)
("1644489953",10398.96450612886)
("1189591617",8733.714545202942)
("1749990115",5686.634193229287)
("1651428902",5466.704932868942)
("1989660417",4833.720017838931)
("1699540307",3769.314438717531)
("1843443790",3497.2532746113716)
("1642909335",3359.9801646859773)
("1154814715",3136.467950275516)
("1576621374",3027.9195684523784)
("1618051664",2870.3365625657957)
("1704116960",2864.091754077639)
("2003347594",2695.2433864993236)
("1191258123",2362.7925264391683)
("1939419914",2359.934464208993)
("1730336902",2236.7706064187414)
("1749150833",2030.8316380456413)
("1742566624",1908.870697427335)
("1644395354",1894.830705238482)
("2607374962",1851.3583403039845)
("1735950160",1745.638167316327)
("1813080181",1707.6114662464554)
("1764222885",1653.377481651667)
("1266321801",1557.264523385907)
("2214257545",1533.1316291461865)
("2093047690",1514.042500000008)
("1193476843",1466.6445465518213)
("1700648435",1433.0773779266249)
("1761179351",1424.1594946042367)
("1642591402",1358.3152595310921)
("1780417033",1255.2854535127067)
("2646679797",1235.6148809523913)
("1401563867",1096.6152785840375)
("2208446650",1079.5073098855958)
("1422308692",1061.206753595636)
("2457719390",956.2981411871111)
("1644114654",928.6027637028011)
("1662214194",922.3151207141834)
("1182391231",896.2830053082579)
("2328516855",894.6543974678704)
("1874640257",892.4409531249996)
("1742121542",867.0689386305397)
("3921730119",865.1122948642591)
("1299532580",855.6750000000138)
("2439251005",855.2641666666692)
("1182389073",791.6823220617977)
("1323527941",769.3565978359911)
("1859475354",763.3829005946094)
("1713926427",761.7044281037596)
("-1",754.9537632024961)
```

spark与hadoop的结果相差无几，估计是浮点精度的差异。

## 实验结果对比

|                  | Hadoop         | Spark          |
| ---------------- | -------------- | -------------- |
| 代码对比             | 见[方法介绍](@方法介绍) | 见[方法介绍](@方法介绍) |
| 数据加载时间(ms)       | 32819          | 2833           |
| 第一轮迭代时间(ms)      | 152532         | 13792          |
| 迭代平均时间(ms/epoch) | 142692         | 3823           |
| 总时间(ms)          | 3681732        | 94146          |

## 感悟与建议

除了技术上的东西，比如HDFS、HBased的概念，Hadoop、Spark的用法等等，我从这门课上学到的更重要的东西是处理大规模数据的方法和思路。

在做这个大作业的过程中，Hadoop版本的程序我还用着处理一般规模数据的思路，希望在不同的节点上维护全局信息。但是Hadoop的设计思路就是节点只要了解到上下文（Context）就足够运行了。所以要尽可能把信息分别交给mapper和reducer去处理，灵活使用文件作为交互接口。不要总想着需要在全局做同步或是修改，每一轮迭代完成一个任务，把状态保存起来；然后进入下一轮迭代。其他的事交给Hadoop就够了。

最后学到的是，scala真好用。