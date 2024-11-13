# cdc-vagrant

## introduce

This project is for experiment of flink-cdc and doris.

CDC(Change Data Capture) is made up of two components, the CDD and the CDT. CDD is stand for Change Data Detection and CDT is stand for Change Data Transfer.

Extract, Load, Transform (ELT) is a data integration process for transferring raw data from a source server to a data system (such as a data warehouse or data lake) on a target server and then preparing the information for downstream uses.

Streaming ETL (Extract, Transform, Load) is the processing and movement of real-time data from one place to another. ETL is short for the database functions extract, transform, and load.

## architecture

### zookeeper cluster

| vm    | role      | ip             | xxx_home       |
|-------|-----------|----------------|----------------|
| vm101 | zookeeper | 192.168.56.101 | /opt/zookeeper |
| vm102 | zookeeper | 192.168.56.102 | /opt/zookeeper |
| vm103 | zookeeper | 192.168.56.103 | /opt/zookeeper |

```bash
cd /opt/zookeeper
./bin/zkServer.sh status
```

```bash
echo stat | nc 127.0.0.1 2181
Zookeeper version: 3.8.4-9316c2a7a97e1666d8f4593f34dd6fc36ecc436c, built on 2024-02-12 22:16 UTC
Clients:
 /127.0.0.1:39370[0](queued=0,recved=1,sent=0)

Latency min/avg/max: 0/6.375/41
Received: 10
Sent: 9
Connections: 1
Outstanding: 0
Zxid: 0x100000003
Mode: follower
Node count: 5
```



### HDFS cluster and YARN cluster

| vm    | role                                 | ip             | xxx_home    |
|-------|--------------------------------------|----------------|-------------|
| vm116 | NameNode(active),zkfc, JournalNode   | 192.168.56.116 | /opt/hadoop |
| vm117 | NameNode(standby),zkfc, JournalNode  | 192.168.56.117 | /opt/hadoop |
| vm118 | NameNode(observer),zkfc, JournalNode | 192.168.56.118 | /opt/hadoop |
| vm119 | DataNode                             | 192.168.56.119 | /opt/hadoop |
| vm120 | DataNode                             | 192.168.56.120 | /opt/hadoop |
| vm121 | DataNode                             | 192.168.56.121 | /opt/hadoop |


| vm    | role     | ip             | xxx_home    |
|-------|----------|----------------|-------------|
| vm116 | yarn RM  | 192.168.56.116 | /opt/hadoop |
| vm117 | yarn RM  | 192.168.56.117 | /opt/hadoop |
| vm118 | yarn RM  | 192.168.56.118 | /opt/hadoop |
| vm119 | yarn NM  | 192.168.56.119 | /opt/hadoop |
| vm120 | yarn NM  | 192.168.56.120 | /opt/hadoop |
| vm121 | yarn NM  | 192.168.56.121 | /opt/hadoop |

```bash
###########################################################
# 以下所有操作都需要在hduser用户下执行
# su -l hduser
###########################################################
# vm116
# hdfs --daemon start journalnode
# hdfs namenode -format (执行一次)
# hdfs zkfc -formatZK (执行一次)
# hdfs --daemon start namenode && hdfs --daemon start zkfc



# vm117 vm118
# hdfs --daemon start journalnode
# hdfs namenode -bootstrapStandby （执行一次）
# hdfs --daemon start namenode && hdfs --daemon start zkfc


## test hdfs HA
(
hdfs haadmin -getServiceState nn1
hdfs haadmin -getServiceState nn2
hdfs haadmin -getServiceState nn3
)

active
standby
standby


# vm119 vm120 vm121
# hdfs --daemon start datanode
```

```bash
# yarn --daemon start resourcemanager   //vm116 vm117 vm118
# yarn --daemon start nodemanager       //vm119 vm120 vm121
```

### flink standalone cluster

minio cluster and flink standalone cluster

Reuse the above virtual machines due to hardware constraints.

| vm    | role   | ip             | xxx_home   |
|-------|--------|----------------|------------|
| vm116 | minio  | 192.168.56.116 | /opt/minio |
| vm117 | minio  | 192.168.56.117 | /opt/minio |
| vm118 | minio  | 192.168.56.118 | /opt/minio |
| vm119 | minio  | 192.168.56.119 | /opt/minio |


| vm    | role                             | ip             | xxx_home   |
|-------|----------------------------------|----------------|------------|
| vm116 | sidekick, flink(masters+workers) | 192.168.56.116 | /opt/flink |
| vm117 | sidekick, flink(masters+workers) | 192.168.56.117 | /opt/flink |
| vm118 | sidekick, flink(masters+workers) | 192.168.56.118 | /opt/flink |
| vm119 | sidekick, flink(workers)         | 192.168.56.119 | /opt/flink |
| vm120 | sidekick, flink(workers)         | 192.168.56.120 | /opt/flink |
| vm121 | sidekick, flink(workers)         | 192.168.56.121 | /opt/flink |


> minio client

```bash
curl -o /usr/local/bin/mc -# -fSL https://dl.min.io/client/mc/release/linux-amd64/mc
chmod +x /usr/local/bin/mc
mc --help
```

```bash
mc alias set myminio http://localhost:9000 minioadmin minioadmin
mc admin user svcacct add --access-key "u5SybesIDVX9b6Pk" --secret-key "lOpH1v7kdM6H8NkPu1H2R6gLc9jcsmWM" myminio minioadmin
# mc admin user svcacct add --access-key "myuserserviceaccount" --secret-key "myuserserviceaccountpassword" myminio minioadmin
```

[mc](https://github.com/minio/mc)

> minio load balancer

```bash
bash /vagrant/scripts/install-minio-sidekick.sh --port "18000" --sites "http://vm{116...119}:9000"
```

```bash
mc mb myminio/flink
mc mb myminio/flink-state
```


```bash
# vm116 vm117 vm118 vm119 vm120 vm121
bash /vagrant/scripts/install-flink.sh
# https://blog.csdn.net/hiliang521/article/details/126860098

su -l hduser
cd /opt/flink

## start-cluster
bin/start-cluster.sh
## stop-cluster
bin/stop-cluster.sh



bin/flink run /opt/flink/examples/streaming/WordCount.jar
```

### flink cdc

```bash
bash /vagrant/scripts/install-flink-cdc.sh
```

this is an experimental environment of [基于 Flink CDC 构建 MySQL 和 Postgres 的 Streaming ETL](https://nightlies.apache.org/flink/flink-cdc-docs-release-3.2/docs/get-started/quickstart/mysql-to-doris/).





### flink-cdc version matrix

see <https://nightlies.apache.org/flink/flink-cdc-docs-master/docs/connectors/flink-sources/overview/#supported-flink-versions>

## ref

- [Deprecated Properties](https://hadoop.apache.org/docs/stable/hadoop-project-dist/hadoop-common/DeprecatedProperties.html)
- [HDFS High Availability](https://hadoop.apache.org/docs/stable/hadoop-project-dist/hadoop-hdfs/HDFSHighAvailabilityWithNFS.html)
- [HDFS High Availability Using the Quorum Journal Manager](https://hadoop.apache.org/docs/stable/hadoop-project-dist/hadoop-hdfs/HDFSHighAvailabilityWithQJM.html)
- [ResourceManager High Availability](https://hadoop.apache.org/docs/stable/hadoop-yarn/hadoop-yarn-site/ResourceManagerHA.html)
- [High Performance HTTP Sidecar Load Balancer](https://github.com/minio/sidekick)
- [https://github.com/apache/doris/tree/master/samples/doris-demo](https://github.com/apache/doris/tree/master/samples/doris-demo)