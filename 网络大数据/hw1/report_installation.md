# 《网络大数据管理理论和应用》实验报告

题目：Hadoop分布式环境安装

要求：完成Hadoop分布式环境的搭建，并实现课上讲的in-mapper-combine的word count程序。

 

姓名：吴先

学号：1701214017

日期：2017年11月8日

 

实验环境：Ubuntu 16.04.3, Java 1.8.0_151, Hadoop 2.8.1

 

[TOC]

## Hadoop分布式环境搭建

### Ubuntu系统安装

宿主机windows server 2012，VMWare Workstation 8.0.3。

虚拟机ubuntu 16.04.3，4G内存（不够再加），网络采用桥接（主要是为了ssh方便）。VMWare的easy install对于安装这种一次性的环境太友好了。

安装好openssh-server，截图，纪念一下最后一次连远程桌面，以后ssh见。

![屏幕快照 2017-10-18 下午4.51.08](/Users/wuxian/Documents/assignment/网络大数据/hw1/屏幕快照 2017-10-18 下午4.51.08.png)

### 基础环境搭建

好吧openssh-server应该在这一项的，放在上面了。

可以看到，两个ubuntu server的ip分别为162.105.86.104和162.105.86.107，只要没人抢ip，就不会变了（虽然我曾经被一台惠普的激光打印机抢过ip）。

规定**107为Master，104位Slave1**。

修改hostname、hosts。按照群里小伙伴的说法，不删除localhost，而是添加Master和Slave1的真实ip。

修改后hosts内容如下：

```
27.0.0.1       localhost
127.0.1.1       ubuntu
162.105.86.104  Slave1
162.105.86.107  Master
```

然后安装java，配置路径，不再赘述。

验证安装：

```
wuxian@ubuntu:/usr/local$ java -version
java version "1.8.0_151"
Java(TM) SE Runtime Environment (build 1.8.0_151-b12)
Java HotSpot(TM) 64-Bit Server VM (build 25.151-b12, mixed mode)
```

### Hadoop安装

验证安装：

```
wuxian@ubuntu:/usr/local$ hadoop version
Hadoop 2.8.1
Subversion https://git-wip-us.apache.org/repos/asf/hadoop.git -r 20fe5304904fc2f5a18053c389e43cd26f7a70fe
Compiled by vinodkv on 2017-06-02T06:14Z
Compiled with protoc 2.5.0
From source with checksum 60125541c2b3e266cbf3becc5bda666
This command was run using /usr/local/hadoop-2.8.1/share/hadoop/common/hadoop-common-2.8.1.jar
```

### Hadoop测试

```
wuxian@ubuntu:/usr/local$ hdfs namenode -format
17/10/18 08:09:47 INFO namenode.NameNode: STARTUP_MSG:
/************************************************************
STARTUP_MSG: Starting NameNode
STARTUP_MSG:   user = wuxian
STARTUP_MSG:   host = ubuntu/127.0.1.1
STARTUP_MSG:   args = [-format]
STARTUP_MSG:   version = 2.8.1
STARTUP_MSG:   ...
STARTUP_MSG:   build = https://git-wip-us.apache.org/repos/asf/hadoop.git -r 20fe5304904fc2f5a18053c389e43cd26f7a70fe; compiled by 'vinodkv' on 2017-06-02T06:14Z
STARTUP_MSG:   java = 1.8.0_151
************************************************************/
17/10/18 08:09:47 INFO namenode.NameNode: registered UNIX signal handlers for [TERM, HUP, INT]
17/10/18 08:09:47 INFO namenode.NameNode: createNameNode [-format]
Formatting using clusterid: CID-6f11f1a6-22f0-4e75-bfcb-06fdb2cfa888
17/10/18 08:09:48 INFO namenode.FSEditLog: Edit logging is async:false
17/10/18 08:09:48 INFO namenode.FSNamesystem: KeyProvider: null
17/10/18 08:09:48 INFO namenode.FSNamesystem: fsLock is fair: true
17/10/18 08:09:48 INFO namenode.FSNamesystem: Detailed lock hold time metrics enabled: false
17/10/18 08:09:48 INFO blockmanagement.DatanodeManager: dfs.block.invalidate.limit=1000
17/10/18 08:09:48 INFO blockmanagement.DatanodeManager: dfs.namenode.datanode.registration.ip-hostname-check=true
17/10/18 08:09:48 INFO blockmanagement.BlockManager: dfs.namenode.startup.delay.block.deletion.sec is set to 000:00:00:00.000
17/10/18 08:09:48 INFO blockmanagement.BlockManager: The block deletion will start around 2017 Oct 18 08:09:48
17/10/18 08:09:48 INFO util.GSet: Computing capacity for map BlocksMap
17/10/18 08:09:48 INFO util.GSet: VM type       = 64-bit
17/10/18 08:09:48 INFO util.GSet: 2.0% max memory 966.7 MB = 19.3 MB
17/10/18 08:09:48 INFO util.GSet: capacity      = 2^21 = 2097152 entries
17/10/18 08:09:48 INFO blockmanagement.BlockManager: dfs.block.access.token.enable=false
17/10/18 08:09:48 INFO blockmanagement.BlockManager: defaultReplication         = 2
17/10/18 08:09:48 INFO blockmanagement.BlockManager: maxReplication             = 512
17/10/18 08:09:48 INFO blockmanagement.BlockManager: minReplication             = 1
17/10/18 08:09:48 INFO blockmanagement.BlockManager: maxReplicationStreams      = 2
17/10/18 08:09:48 INFO blockmanagement.BlockManager: replicationRecheckInterval = 3000
17/10/18 08:09:48 INFO blockmanagement.BlockManager: encryptDataTransfer        = false
17/10/18 08:09:48 INFO blockmanagement.BlockManager: maxNumBlocksToLog          = 1000
17/10/18 08:09:48 INFO namenode.FSNamesystem: fsOwner             = wuxian (auth:SIMPLE)
17/10/18 08:09:48 INFO namenode.FSNamesystem: supergroup          = supergroup
17/10/18 08:09:48 INFO namenode.FSNamesystem: isPermissionEnabled = true
17/10/18 08:09:48 INFO namenode.FSNamesystem: HA Enabled: false
17/10/18 08:09:48 INFO namenode.FSNamesystem: Append Enabled: true
17/10/18 08:09:48 INFO util.GSet: Computing capacity for map INodeMap
17/10/18 08:09:48 INFO util.GSet: VM type       = 64-bit
17/10/18 08:09:48 INFO util.GSet: 1.0% max memory 966.7 MB = 9.7 MB
17/10/18 08:09:48 INFO util.GSet: capacity      = 2^20 = 1048576 entries
17/10/18 08:09:48 INFO namenode.FSDirectory: ACLs enabled? false
17/10/18 08:09:48 INFO namenode.FSDirectory: XAttrs enabled? true
17/10/18 08:09:48 INFO namenode.NameNode: Caching file names occurring more than 10 times
17/10/18 08:09:48 INFO util.GSet: Computing capacity for map cachedBlocks
17/10/18 08:09:48 INFO util.GSet: VM type       = 64-bit
17/10/18 08:09:48 INFO util.GSet: 0.25% max memory 966.7 MB = 2.4 MB
17/10/18 08:09:48 INFO util.GSet: capacity      = 2^18 = 262144 entries
17/10/18 08:09:48 INFO namenode.FSNamesystem: dfs.namenode.safemode.threshold-pct = 0.9990000128746033
17/10/18 08:09:48 INFO namenode.FSNamesystem: dfs.namenode.safemode.min.datanodes = 0
17/10/18 08:09:48 INFO namenode.FSNamesystem: dfs.namenode.safemode.extension     = 30000
17/10/18 08:09:48 INFO metrics.TopMetrics: NNTop conf: dfs.namenode.top.window.num.buckets = 10
17/10/18 08:09:48 INFO metrics.TopMetrics: NNTop conf: dfs.namenode.top.num.users = 10
17/10/18 08:09:48 INFO metrics.TopMetrics: NNTop conf: dfs.namenode.top.windows.minutes = 1,5,25
17/10/18 08:09:48 INFO namenode.FSNamesystem: Retry cache on namenode is enabled
17/10/18 08:09:48 INFO namenode.FSNamesystem: Retry cache will use 0.03 of total heap and retry cache entry expiry time is 600000 millis
17/10/18 08:09:48 INFO util.GSet: Computing capacity for map NameNodeRetryCache
17/10/18 08:09:48 INFO util.GSet: VM type       = 64-bit
17/10/18 08:09:48 INFO util.GSet: 0.029999999329447746% max memory 966.7 MB = 297.0 KB
17/10/18 08:09:48 INFO util.GSet: capacity      = 2^15 = 32768 entries
17/10/18 08:09:48 INFO namenode.FSImage: Allocated new BlockPoolId: BP-77929780-127.0.1.1-1508339388667
17/10/18 08:09:48 INFO common.Storage: Storage directory /usr/local/hadoop/tmp/dfs/name has been successfully formatted.
17/10/18 08:09:48 INFO namenode.FSImageFormatProtobuf: Saving image file /usr/local/hadoop/tmp/dfs/name/current/fsimage.ckpt_0000000000000000000 using no compression
17/10/18 08:09:48 INFO namenode.FSImageFormatProtobuf: Image file /usr/local/hadoop/tmp/dfs/name/current/fsimage.ckpt_0000000000000000000 of size 323 bytes saved in 0 seconds.
17/10/18 08:09:48 INFO namenode.NNStorageRetentionManager: Going to retain 1 images with txid >= 0
17/10/18 08:09:48 INFO util.ExitUtil: Exiting with status 0
17/10/18 08:09:48 INFO namenode.NameNode: SHUTDOWN_MSG:
/************************************************************
SHUTDOWN_MSG: Shutting down NameNode at ubuntu/127.0.1.1
************************************************************/
```



```
wuxian@ubuntu:/usr/local/hadoop/sbin$ ./start-dfs.sh
Starting namenodes on [Master]
The authenticity of host 'master (162.105.86.107)' can't be established.
ECDSA key fingerprint is SHA256:RlHd4vHyrwJSey09BtACjCsRfUiIRvRXhegOAq+q4Sw.
Are you sure you want to continue connecting (yes/no)? yes
Master: Warning: Permanently added 'master,162.105.86.107' (ECDSA) to the list of known hosts.
Master: starting namenode, logging to /usr/local/hadoop-2.8.1/logs/hadoop-wuxian-namenode-ubuntu.out
Master: starting datanode, logging to /usr/local/hadoop-2.8.1/logs/hadoop-wuxian-datanode-ubuntu.out
Slave1: starting datanode, logging to /usr/local/hadoop-2.8.1/logs/hadoop-wuxian-datanode-ubuntu.out
Starting secondary namenodes [Master]
Master: starting secondarynamenode, logging to /usr/local/hadoop-2.8.1/logs/hadoop-wuxian-secondarynamenode-ubuntu.out
```

```
wuxian@ubuntu:/usr/local/hadoop/sbin$ ./start-yarn.sh
starting yarn daemons
starting resourcemanager, logging to /usr/local/hadoop-2.8.1/logs/yarn-wuxian-resourcemanager-ubuntu.out
Slave1: starting nodemanager, logging to /usr/local/hadoop-2.8.1/logs/yarn-wuxian-nodemanager-ubuntu.out
Master: starting nodemanager, logging to /usr/local/hadoop-2.8.1/logs/yarn-wuxian-nodemanager-ubuntu.out
```

```
wuxian@ubuntu:/usr/local/hadoop/sbin$ ./mr-jobhistory-daemon.sh start historyserver
starting historyserver, logging to /usr/local/hadoop-2.8.1/logs/mapred-wuxian-historyserver-ubuntu.out
```

Master:

```
wuxian@ubuntu:/usr/local/hadoop/sbin$ jps
7123 SecondaryNameNode
7284 ResourceManager
6917 DataNode
6806 NameNode
7766 JobHistoryServer
7422 NodeManager
7839 Jps
```

Slave1:

```
wuxian@ubuntu:/usr/local$ jps
7938 Jps
7816 NodeManager
7663 DataNode
```

然后通过master:50070查看，发现只有一个datanode。检查了Slave1上的日志和jps结果，一切正常。于是怀疑是未能正确识别节点。检查前面的操作，发现修改hostname需要重启系统。重启系统刷新hostname，问题解决，在管理页面上能看到两个节点。

![屏幕快照 2017-10-18 下午11.35.06](/Users/wuxian/Documents/assignment/网络大数据/hw1/屏幕快照 2017-10-18 下午11.35.06.png)

至此，Hadoop环境配置完成。

### Spark和Scala环境配置

直接上最后的截图了，没有需要注意的地方。

这里有一个很神奇的事。通过master:50070可以看到Hadoop的状态；通过162.105.86.107:8080能看到spark的状态；但是通过master:8080就看不到spark的状态。

![屏幕快照 2017-10-19 上午12.10.00](/Users/wuxian/Documents/assignment/网络大数据/hw1/屏幕快照 2017-10-19 上午12.10.00.png)

## In-mapper-combine word count

### 代码及分析

以Hadoop教程中的mapreducde tutorial中WordCount v1.0作为蓝本进行修改，修改部分与修改思路在代码中以注释的方式给出。

```java
public class WordCount {

    public static class TokenizerMapper
            extends Mapper<Object, Text, Text, IntWritable> {

        private Text word = new Text();
        private IntWritable sum = new IntWritable();

        public void map(Object key, Text value, Context context
        ) throws IOException, InterruptedException {
            // 在mapper内利用一个hashmap存储词频
            HashMap<String, Integer> cache = new HashMap<String, Integer>();
            StringTokenizer itr = new StringTokenizer(value.toString());
            while (itr.hasMoreTokens()) {
                String w = itr.nextToken();
                // 不再是每遇到一个词就emit，而是在缓存中计数
                if (cache.containsKey(w)) {
                    cache.put(w, cache.get(w) + 1);
                }
                else {
                    cache.put(w, 1);
                }
            }
            // 最后将缓存中的<key, value>对一起emit
            for (Map.Entry entry: cache.entrySet()) {
                word.set(entry.getKey().toString());
                sum.set((Integer)entry.getValue());
                context.write(word, sum);
            }
        }
    }

    public static class IntSumReducer
            extends Reducer<Text, IntWritable, Text, IntWritable> {
        private IntWritable result = new IntWritable();

        public void reduce(Text key, Iterable<IntWritable> values,
                           Context context
        ) throws IOException, InterruptedException {
            int sum = 0;
            // 因为原来的reducer就是对value进行计数，所以无需修改
            for (IntWritable val : values) {
                sum += val.get();
            }
            result.set(sum);
            context.write(key, result);
        }
    }

    public static void main(String[] args) throws Exception {
        Configuration conf = new Configuration();
        Job job = Job.getInstance(conf, "word count");
        job.setJarByClass(WordCount.class);
        job.setMapperClass(TokenizerMapper.class);
        job.setCombinerClass(IntSumReducer.class);
        job.setReducerClass(IntSumReducer.class);
        job.setOutputKeyClass(Text.class);
        job.setOutputValueClass(IntWritable.class);
        FileInputFormat.addInputPath(job, new Path(args[0]));
        FileOutputFormat.setOutputPath(job, new Path(args[1]));
        System.exit(job.waitForCompletion(true) ? 0 : 1);
    }
}
```

### 结果及分析

在本地通过`Build Artifacts`将`WordCount`类打包成jar，上传至服务器运行。

WordCount v1.0的输出位于/output，in-mapper-combine的WordCount的输出位于/output2。

通过`diff`进行对拍，保证程序正确性。通过head查看前20条结果。

```
wuxian@Master:~/wordcount$ hadoop jar wordcount_v1.0.jar WordCount /data/WordCount /output
wuxian@Master:~/wordcount$ hadoop jar wordcount.jar WordCount /data/WordCount /output2
wuxian@Master:~/wordcount$ hadoop fs -get /output
wuxian@Master:~/wordcount$ hadoop fs -get /output2
wuxian@Master:~/wordcount$ diff output/part-r-00000 output2/part-r-00000
wuxian@Master:~/wordcount$ head -n 20 output4/part-r-00000
!	52
!!	2
!!!	52
!!!!	1
!!!\"	1
!!!_(album)	12
!!Destroy-Oh-Boy!!	6
!)	2
!@#$	1
!Action_Pact!	9
!Audacious	1
!Bang!	2
!Hero	4
!Hero_(album)	7
!Kung	2
!Kung_language	14
!Oka_Tokat	16
!PAUS3	7
!T.O.O.H.!	17
!Tang	2
```

### 关于效率

直觉上来看，in-mapper-combine版本的mapper没有做到一边处理一边输出，而且还需要自己维护一个`HashMap`来计数，可能效率还不如原版程序。

实验结果也是如此，原版程序平均耗时4分钟，in-mapper-combine平均耗时5分钟。